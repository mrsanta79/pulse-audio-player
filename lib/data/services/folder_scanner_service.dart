import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/utils/storage_path.dart';
import '../database/app_database.dart';
import 'metadata_service.dart';
import 'openrouter_mood_service.dart';

class ScanProgress {
  final int scanned;
  final int total;
  final String? currentFile;
  final bool done;

  const ScanProgress({
    required this.scanned,
    required this.total,
    this.currentFile,
    this.done = false,
  });
}

class FolderScannerService {
  FolderScannerService(this._db, this._metadata);

  final AppDatabase _db;
  final MetadataService _metadata;

  static const audioExtensions = {
    '.mp3',
    '.flac',
    '.m4a',
    '.ogg',
    '.wav',
    '.aac',
    '.opus',
  };

  /// Files written per transaction. Reading tags is the slow part, so the
  /// writes are grouped: one transaction per file made a large import spend
  /// most of its time in fsync, but holding the whole library in one
  /// transaction would lose everything if the scan were interrupted.
  static const _writeBatchSize = 50;

  Future<List<File>> collectAudioFiles(List<String> folderPaths) async {
    final filesByPath = <String, File>{};
    for (final rawPath in folderPaths) {
      // Guard against any SAF content URIs that were stored before conversion.
      final folderPath = resolvePickedDirectoryPath(rawPath);
      final dir = Directory(folderPath);
      if (!await dir.exists()) continue;
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;
        if (!audioExtensions.contains(p.extension(entity.path).toLowerCase())) {
          continue;
        }
        final canonicalPath = await _canonicalPath(entity.path);
        filesByPath.putIfAbsent(canonicalPath, () => File(canonicalPath));
      }
    }
    return filesByPath.values.toList();
  }

  Future<String> _canonicalPath(String path) async {
    if (path.startsWith('content://')) return path;
    try {
      return await File(path).resolveSymbolicLinks();
    } on FileSystemException {
      return p.normalize(p.absolute(path));
    }
  }

  Stream<ScanProgress> scanFolders(List<String> folderPaths) async* {
    final resolvedPaths = await Future.wait<String>(
      folderPaths.map((path) async {
        final resolved = resolvePickedDirectoryPath(path);
        if (resolved.startsWith('content://')) return resolved;
        try {
          return await Directory(resolved).resolveSymbolicLinks();
        } on FileSystemException {
          return p.normalize(p.absolute(resolved));
        }
      }),
    );
    final files = await collectAudioFiles(resolvedPaths);
    final filesByFilename = <String, List<File>>{};
    for (final file in files) {
      filesByFilename.putIfAbsent(_filenameKey(file.path), () => []).add(file);
    }

    // One query instead of one per file: the old code asked the database
    // whether each path was already known, which was a round trip per track.
    // Only the two columns needed, so a large library doesn't pull every tag
    // it already has into memory.
    final knownIds = await _trackIdsByPath();
    final selectedFiles = <String, File>{};
    for (final entry in filesByFilename.entries) {
      final candidates = entry.value..sort((a, b) => a.path.compareTo(b.path));
      selectedFiles[entry.key] = candidates.firstWhere(
        (candidate) => knownIds.containsKey(candidate.path),
        orElse: () => candidates.first,
      );
    }
    final knownIdsByFilename = await _mergeDuplicateFilenameTracks(
      knownIds,
      filesByFilename,
      selectedFiles,
    );

    final total = selectedFiles.length;
    var scanned = 0;
    final seenPaths = files.map((file) => file.path).toSet();
    var pending = <_ScannedTrack>[];

    for (final entry in selectedFiles.entries) {
      final filename = entry.key;
      final file = entry.value;
      yield ScanProgress(
        scanned: scanned,
        total: total,
        currentFile: file.path,
      );

      final meta = await _metadata.read(file.path);
      pending.add(
        _ScannedTrack(
          path: file.path,
          meta: meta,
          artHash: _metadata.hashAlbumArt(meta.albumArt),
          existingId: knownIdsByFilename[filename],
        ),
      );

      if (pending.length >= _writeBatchSize) {
        await _writeBatch(pending);
        pending = [];
      }

      scanned++;
      yield ScanProgress(
        scanned: scanned,
        total: total,
        currentFile: file.path,
      );
    }

    if (pending.isNotEmpty) await _writeBatch(pending);
    await _removeVanishedTracks(knownIds, resolvedPaths, seenPaths);
    await _mergeDuplicateMetadataTracks(resolvedPaths);

    yield ScanProgress(scanned: scanned, total: total, done: true);
  }

  Future<Map<String, int>> _trackIdsByPath() async {
    final rows = await _db
        .customSelect(
          'SELECT id, file_path FROM tracks',
          readsFrom: {_db.tracks},
        )
        .get();
    final idsByPath = <String, List<int>>{};
    for (final row in rows) {
      final id = row.read<int>('id');
      final path = await _canonicalPath(row.read<String>('file_path'));
      idsByPath.putIfAbsent(path, () => []).add(id);
    }

    final result = <String, int>{};
    for (final entry in idsByPath.entries) {
      final ids = entry.value;
      final survivorId = ids.first;
      if (ids.length > 1) {
        await _mergeDuplicateTracks(survivorId, ids.skip(1).toList());
      }
      await (_db.update(_db.tracks)..where((t) => t.id.equals(survivorId)))
          .write(TracksCompanion(filePath: Value(entry.key)));
      result[entry.key] = survivorId;
    }
    return result;
  }

  String _filenameKey(String path) =>
      p.basenameWithoutExtension(path).toLowerCase();

  bool _isInFolders(String path, List<String> resolvedPaths) {
    return resolvedPaths.any((folder) {
      final prefix = folder.endsWith('/') ? folder : '$folder/';
      return path.startsWith(prefix);
    });
  }

  Future<Map<String, int>> _mergeDuplicateFilenameTracks(
    Map<String, int> knownIds,
    Map<String, List<File>> filesByFilename,
    Map<String, File> selectedFiles,
  ) async {
    final result = <String, int>{};
    for (final entry in filesByFilename.entries) {
      final filePaths = entry.value.map((file) => file.path).toSet();
      final ids = [
        for (final path in filePaths) ?knownIds[path],
      ].whereType<int>().toList();
      if (ids.isEmpty) continue;

      final survivorPath = selectedFiles[entry.key]!.path;
      final survivorId = knownIds[survivorPath];
      if (survivorId == null) continue;
      final duplicateIds = ids.where((id) => id != survivorId).toList();
      if (duplicateIds.isNotEmpty) {
        await _mergeDuplicateTracks(survivorId, duplicateIds);
        knownIds.removeWhere(
          (path, id) => filePaths.contains(path) && id != survivorId,
        );
      }
      result[entry.key] = survivorId;
    }
    return result;
  }

  String _normalizeMetadataValue(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<void> _mergeDuplicateMetadataTracks(List<String> resolvedPaths) async {
    final tracks = await _db.select(_db.tracks).get();
    final idsByMetadata = <(String, String, int), List<int>>{};
    for (final track in tracks) {
      if (!_isInFolders(track.filePath, resolvedPaths)) continue;
      final duration = track.durationMs;
      if (duration == null) continue;
      final key = (
        _normalizeMetadataValue(track.title),
        _normalizeMetadataValue(track.artist),
        duration,
      );
      idsByMetadata.putIfAbsent(key, () => []).add(track.id);
    }

    for (final ids in idsByMetadata.values) {
      if (ids.length > 1) {
        await _mergeDuplicateTracks(ids.first, ids.skip(1).toList());
      }
    }
  }

  Future<void> _mergeDuplicateTracks(int survivorId, List<int> duplicateIds) {
    return _db.transaction(() async {
      for (final duplicateId in duplicateIds) {
        await _db.customStatement(
          '''
          INSERT OR IGNORE INTO likes (track_id, liked_at)
          SELECT ?, liked_at FROM likes WHERE track_id = ?
          ''',
          [survivorId, duplicateId],
        );
        await _db.customStatement(
          '''
          UPDATE likes
          SET liked_at = (
            SELECT MAX(liked_at) FROM likes WHERE track_id IN (?, ?)
          )
          WHERE track_id = ?
          ''',
          [survivorId, duplicateId, survivorId],
        );
        await _db.customStatement(
          '''
          INSERT INTO playlist_tracks (playlist_id, track_id, position)
          SELECT source.playlist_id, ?, source.position
          FROM playlist_tracks source
          WHERE source.track_id = ?
            AND NOT EXISTS (
              SELECT 1 FROM playlist_tracks existing
              WHERE existing.playlist_id = source.playlist_id
                AND existing.track_id = ?
            )
          ''',
          [survivorId, duplicateId, survivorId],
        );
        await _db.customStatement(
          'DELETE FROM playlist_tracks WHERE track_id = ?',
          [duplicateId],
        );
        await _db.customStatement(
          '''
          INSERT OR IGNORE INTO track_moods (track_id, mood)
          SELECT ?, mood FROM track_moods WHERE track_id = ?
          ''',
          [survivorId, duplicateId],
        );
        await _db.customStatement(
          '''
          INSERT OR IGNORE INTO track_mood_analysis (track_id, metadata_hash)
          SELECT ?, metadata_hash FROM track_mood_analysis WHERE track_id = ?
          ''',
          [survivorId, duplicateId],
        );
        await (_db.delete(
          _db.tracks,
        )..where((t) => t.id.equals(duplicateId))).go();
      }

      final session = await (_db.select(
        _db.playbackSessions,
      )..where((s) => s.id.equals(0))).getSingleOrNull();
      if (session != null) {
        final duplicateIdSet = duplicateIds.toSet();
        final queueIds = session.queueTrackIds
            .split(',')
            .map((value) => int.tryParse(value.trim()))
            .whereType<int>()
            .map((id) => duplicateIdSet.contains(id) ? survivorId : id)
            .toList();
        await _db
            .update(_db.playbackSessions)
            .write(
              PlaybackSessionsCompanion(
                queueTrackIds: Value(queueIds.join(',')),
              ),
            );
      }
    });
  }

  Future<void> _writeBatch(List<_ScannedTrack> batch) {
    return _db.transaction(() async {
      await _db.batch((b) {
        for (final track in batch) {
          final art = track.meta.albumArt;
          final hash = track.artHash;
          if (hash != null && art != null) {
            b.insert(
              _db.albumArt,
              AlbumArtCompanion.insert(hash: hash, bytes: art),
              mode: InsertMode.insertOrReplace,
            );
          }

          if (track.existingId == null) {
            b.insert(
              _db.tracks,
              track.toInsert(),
              mode: InsertMode.insertOrIgnore,
            );
          } else {
            b.update(
              _db.tracks,
              track.toUpdate(),
              where: (t) => t.id.equals(track.existingId!),
            );
          }
        }
      });
    });
  }

  /// Drops tracks whose folder is still in the scan set but whose file is gone.
  /// Tracks outside the scanned folders are left alone.
  Future<void> _removeVanishedTracks(
    Map<String, int> knownIds,
    List<String> resolvedPaths,
    Set<String> seenPaths,
  ) async {
    final stale = <int>[];
    knownIds.forEach((path, id) {
      if (!_isInFolders(path, resolvedPaths)) return;
      if (!seenPaths.contains(path) || !File(path).existsSync()) {
        stale.add(id);
      }
    });
    if (stale.isEmpty) return;

    // One delete rather than one per track.
    await (_db.delete(_db.tracks)..where((t) => t.id.isIn(stale))).go();
  }

  Future<int> addScanFolder(String path) {
    return _db
        .into(_db.scanFolders)
        .insert(
          ScanFoldersCompanion.insert(path: path),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> removeScanFolder(int id) async {
    await (_db.delete(_db.scanFolders)..where((f) => f.id.equals(id))).go();
  }

  Future<List<ScanFolder>> getScanFolders() {
    return _db.select(_db.scanFolders).get();
  }
}

/// One file's tags, resolved and waiting to be written.
class _ScannedTrack {
  const _ScannedTrack({
    required this.path,
    required this.meta,
    required this.artHash,
    required this.existingId,
  });

  final String path;
  final TrackMetadata meta;
  final String? artHash;

  /// The row this file already has, or null if it is new to the library.
  final int? existingId;

  TracksCompanion toInsert() => TracksCompanion.insert(
    filePath: path,
    title: meta.title,
    artist: Value(meta.artist),
    album: Value(meta.album),
    year: Value(meta.year),
    durationMs: Value(meta.durationMs),
    trackNumber: Value(meta.trackNumber),
    albumArtHash: Value(artHash),
  );

  TracksCompanion toUpdate() => TracksCompanion(
    title: Value(meta.title),
    artist: Value(meta.artist),
    album: Value(meta.album),
    year: Value(meta.year),
    durationMs: Value(meta.durationMs),
    trackNumber: Value(meta.trackNumber),
    albumArtHash: Value(artHash),
  );
}
