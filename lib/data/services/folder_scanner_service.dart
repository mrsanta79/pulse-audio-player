import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/utils/storage_path.dart';
import '../database/app_database.dart';
import 'metadata_service.dart';

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
    final files = <File>[];
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
        if (audioExtensions.contains(p.extension(entity.path).toLowerCase())) {
          files.add(entity);
        }
      }
    }
    return files;
  }

  Stream<ScanProgress> scanFolders(List<String> folderPaths) async* {
    final resolvedPaths = folderPaths.map(resolvePickedDirectoryPath).toList();
    final files = await collectAudioFiles(resolvedPaths);
    final total = files.length;

    // One query instead of one per file: the old code asked the database
    // whether each path was already known, which is a round trip per track.
    // Only the two columns needed, so a large library doesn't pull every tag
    // it already has into memory.
    final knownIds = await _trackIdsByPath();

    var scanned = 0;
    final seenPaths = <String>{};
    var pending = <_ScannedTrack>[];

    for (final file in files) {
      seenPaths.add(file.path);
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
          existingId: knownIds[file.path],
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
    // `knownIds` is the library as it was before this scan; anything added
    // during it is in `seenPaths`, so it is the right set to check for files
    // that have gone away.
    await _removeVanishedTracks(knownIds, resolvedPaths, seenPaths);

    yield ScanProgress(scanned: scanned, total: total, done: true);
  }

  Future<Map<String, int>> _trackIdsByPath() async {
    final rows = await _db
        .customSelect(
          'SELECT id, file_path FROM tracks',
          readsFrom: {_db.tracks},
        )
        .get();
    return {
      for (final row in rows)
        row.read<String>('file_path'): row.read<int>('id'),
    };
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
    final prefixes = [
      for (final folder in resolvedPaths)
        folder.endsWith('/') ? folder : '$folder/',
    ];

    final stale = <int>[];
    knownIds.forEach((path, id) {
      if (!prefixes.any(path.startsWith)) return;
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
