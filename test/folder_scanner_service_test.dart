import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pulse_audio_player/data/database/app_database.dart';
import 'package:pulse_audio_player/data/services/folder_scanner_service.dart';
import 'package:pulse_audio_player/data/services/metadata_service.dart';

class _FixedMetadataService extends MetadataService {
  _FixedMetadataService(this._metadataByPath);

  final Map<String, TrackMetadata> _metadataByPath;

  @override
  Future<TrackMetadata> read(String filePath) async {
    final canonicalPath = File(filePath).resolveSymbolicLinksSync();
    for (final entry in _metadataByPath.entries) {
      if (File(entry.key).resolveSymbolicLinksSync() == canonicalPath) {
        return entry.value;
      }
    }
    return TrackMetadata(
      title: p.basenameWithoutExtension(filePath),
      artist: 'Unknown Artist',
      album: 'Unknown Album',
    );
  }
}

void main() {
  late Directory tempDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('folder_scanner_test');
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('overlapping physical and symlinked folders store one track', () async {
    final music = Directory('${tempDir.path}/music');
    await music.create();
    final song = File('${music.path}/song.mp3');
    await song.writeAsBytes([0, 1, 2]);

    final alias = Link('${tempDir.path}/music-alias');
    await alias.create(music.path);

    final scanner = FolderScannerService(db, MetadataService());
    await scanner.scanFolders([music.path, alias.path]).drain<void>();
    await scanner.scanFolders([music.path]).drain<void>();

    final tracks = await db.getAllTracks();
    expect(tracks, hasLength(1));
    expect(tracks.single.filePath, await song.resolveSymbolicLinks());
  });

  test(
    'merges matching basenames across folders and extensions without deleting files',
    () async {
      final firstFolder = Directory('${tempDir.path}/a');
      final secondFolder = Directory('${tempDir.path}/b');
      await firstFolder.create();
      await secondFolder.create();
      final firstSong = File('${firstFolder.path}/Song.mp3');
      final secondSong = File('${secondFolder.path}/song.flac');
      await firstSong.writeAsBytes([0, 1, 2]);
      await secondSong.writeAsBytes([3, 4, 5]);

      final scanner = FolderScannerService(db, MetadataService());
      await scanner.scanFolders([
        firstFolder.path,
        secondFolder.path,
      ]).drain<void>();

      expect(await db.getAllTracks(), hasLength(1));
      expect(await firstSong.exists(), isTrue);
      expect(await secondSong.exists(), isTrue);
    },
  );

  test(
    'merges metadata duplicates across different filenames and albums',
    () async {
      final firstFolder = Directory('${tempDir.path}/a');
      final secondFolder = Directory('${tempDir.path}/b');
      await firstFolder.create();
      await secondFolder.create();
      final firstSong = File('${firstFolder.path}/copy-one.mp3');
      final secondSong = File('${secondFolder.path}/copy-two.flac');
      await firstSong.writeAsBytes([0, 1, 2]);
      await secondSong.writeAsBytes([3, 4, 5]);

      final survivorId = await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              filePath: firstSong.path,
              title: 'Aadat 2.0',
              artist: const Value('Artist'),
              album: const Value('Album One'),
              durationMs: const Value(180000),
            ),
          );
      final duplicateId = await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              filePath: secondSong.path,
              title: ' aadat   2.0 ',
              artist: const Value('ARTIST'),
              album: const Value('Album Two'),
              durationMs: const Value(180000),
            ),
          );
      await db.setLikes([duplicateId], liked: true);
      final playlistId = await db.createPlaylist('Favourites');
      await db.addTrackToPlaylist(playlistId, duplicateId);

      final scanner = FolderScannerService(
        db,
        _FixedMetadataService({
          firstSong.path: const TrackMetadata(
            title: 'Aadat 2.0',
            artist: 'Artist',
            album: 'Album One',
            durationMs: 180000,
          ),
          secondSong.path: const TrackMetadata(
            title: ' aadat   2.0 ',
            artist: 'ARTIST',
            album: 'Album Two',
            durationMs: 180000,
          ),
        }),
      );
      await scanner.scanFolders([
        firstFolder.path,
        secondFolder.path,
      ]).drain<void>();

      expect(await db.getAllTracks(), hasLength(1));
      expect((await db.watchLikedTracks().first).single.id, survivorId);
      expect((await db.getPlaylistTracks(playlistId)).single.id, survivorId);
      expect(await firstSong.exists(), isTrue);
      expect(await secondSong.exists(), isTrue);
    },
  );

  test('does not metadata-merge tracks with different durations', () async {
    final firstFolder = Directory('${tempDir.path}/a');
    final secondFolder = Directory('${tempDir.path}/b');
    await firstFolder.create();
    await secondFolder.create();
    final firstSong = File('${firstFolder.path}/copy-one.mp3');
    final secondSong = File('${secondFolder.path}/copy-two.mp3');
    await firstSong.writeAsBytes([0, 1, 2]);
    await secondSong.writeAsBytes([3, 4, 5]);

    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            filePath: firstSong.path,
            title: 'Song',
            artist: const Value('Artist'),
            durationMs: const Value(180000),
          ),
        );
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            filePath: secondSong.path,
            title: 'Song',
            artist: const Value('Artist'),
            durationMs: const Value(181000),
          ),
        );

    final scanner = FolderScannerService(
      db,
      _FixedMetadataService({
        firstSong.path: const TrackMetadata(
          title: 'Song',
          artist: 'Artist',
          album: 'Album',
          durationMs: 180000,
        ),
        secondSong.path: const TrackMetadata(
          title: 'Song',
          artist: 'Artist',
          album: 'Album',
          durationMs: 181000,
        ),
      }),
    );
    await scanner.scanFolders([
      firstFolder.path,
      secondFolder.path,
    ]).drain<void>();

    expect(await db.getAllTracks(), hasLength(2));
  });

  test('merges filename duplicates and keeps playlist membership', () async {
    final firstFolder = Directory('${tempDir.path}/a');
    final secondFolder = Directory('${tempDir.path}/b');
    await firstFolder.create();
    await secondFolder.create();
    final firstSong = File('${firstFolder.path}/song.mp3');
    final secondSong = File('${secondFolder.path}/song.flac');
    await firstSong.writeAsBytes([0, 1, 2]);
    await secondSong.writeAsBytes([3, 4, 5]);

    final survivorId = await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(filePath: firstSong.path, title: 'Song'),
        );
    final duplicateId = await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(filePath: secondSong.path, title: 'Song'),
        );
    await db.setLikes([duplicateId], liked: true);
    final playlistId = await db.createPlaylist('Favourites');
    await db.addTrackToPlaylist(playlistId, duplicateId);

    final scanner = FolderScannerService(db, MetadataService());
    await scanner.scanFolders([
      firstFolder.path,
      secondFolder.path,
    ]).drain<void>();

    expect(await db.getAllTracks(), hasLength(1));
    expect((await db.watchLikedTracks().first).single.id, survivorId);
    expect((await db.getPlaylistTracks(playlistId)).single.id, survivorId);
    expect(await secondSong.exists(), isTrue);
  });

  test(
    'merges previously indexed path aliases and keeps playlist membership',
    () async {
      final music = Directory('${tempDir.path}/music');
      await music.create();
      final song = File('${music.path}/song.mp3');
      await song.writeAsBytes([0, 1, 2]);

      final alias = Link('${tempDir.path}/music-alias');
      await alias.create(music.path);
      final canonicalPath = await song.resolveSymbolicLinks();
      final aliasPath = '${alias.path}/song.mp3';
      final survivorId = await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(filePath: canonicalPath, title: 'Song'),
          );
      final duplicateId = await db
          .into(db.tracks)
          .insert(TracksCompanion.insert(filePath: aliasPath, title: 'Song'));
      await db.setLikes([duplicateId], liked: true);
      final playlistId = await db.createPlaylist('Favourites');
      await db.addTrackToPlaylist(playlistId, duplicateId);

      final scanner = FolderScannerService(db, MetadataService());
      await scanner.scanFolders([music.path]).drain<void>();

      expect(await db.getAllTracks(), hasLength(1));
      expect((await db.watchLikedTracks().first).single.id, survivorId);
      expect((await db.getPlaylistTracks(playlistId)).single.id, survivorId);
    },
  );
}
