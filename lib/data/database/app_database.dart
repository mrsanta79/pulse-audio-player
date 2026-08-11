import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

export 'models.dart';
// Query methods live in extensions so this file stays about schema. Re-exported
// so `import 'app_database.dart'` still brings every query into scope.
export 'queries/library_queries.dart';
export 'queries/playlist_queries.dart';
export 'queries/session_queries.dart';

part 'app_database.g.dart';

// The library is browsed by album, artist and year, and listed by title. Every
// one of those is a full scan + sort without an index, which is what makes a
// few-thousand-track library feel slow on a phone.
@TableIndex(name: 'tracks_album_artist', columns: {#album, #artist})
@TableIndex(name: 'tracks_artist', columns: {#artist})
@TableIndex(name: 'tracks_year', columns: {#year})
@TableIndex(name: 'tracks_title', columns: {#title})
class Tracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text().unique()();
  TextColumn get title => text()();
  TextColumn get artist =>
      text().withDefault(const Constant('Unknown Artist'))();
  TextColumn get album => text().withDefault(const Constant('Unknown Album'))();
  IntColumn get year => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  TextColumn get albumArtHash => text().nullable()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

class AlbumArt extends Table {
  TextColumn get hash => text()();
  BlobColumn get bytes => blob()();

  @override
  Set<Column> get primaryKey => {hash};
}

class ScanFolders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().unique()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'likes_liked_at', columns: {#likedAt})
class Likes extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get likedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {trackId};
}

class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'playlist_tracks_playlist', columns: {#playlistId, #position})
@TableIndex(name: 'playlist_tracks_track', columns: {#trackId})
class PlaylistTracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
}

/// Single-row table (id is always 0) holding the last playback session so the
/// app can resume where the listener left off, even days later.
class PlaybackSessions extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get queueTrackIds => text()();
  IntColumn get currentIndex => integer().withDefault(const Constant(0))();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  IntColumn get repeatMode => integer().withDefault(const Constant(0))();
  BoolColumn get shuffleEnabled =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Generic key/value store for small user settings (theme choice, and whatever
/// comes next). Kept generic so a new preference doesn't need a schema bump.
class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Tracks,
    AlbumArt,
    ScanFolders,
    Likes,
    Playlists,
    PlaylistTracks,
    PlaybackSessions,
    Preferences,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(playbackSessions);
      }
      if (from < 3) {
        await m.createTable(preferences);
      }
      if (from < 4) {
        await _createIndexes(m);
      }
    },
    beforeOpen: (details) async {
      // Cascading deletes (likes/playlist entries of a removed track) are
      // declared on the schema but SQLite ignores them unless this is on,
      // and it is off by default on every new connection.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Adds every declared index that isn't there yet.
  ///
  /// Indexes carry no data, so creating them is safe to re-run: an upgrade that
  /// died half way, or a database already carrying some of them, must not leave
  /// the app unable to open. `m.create` would throw on the first duplicate.
  Future<void> _createIndexes(Migrator m) async {
    for (final index in allSchemaEntities.whereType<Index>()) {
      final sql = index.createStatementsByDialect[SqlDialect.sqlite];
      if (sql == null) continue;
      await m.database.customStatement(
        sql.replaceFirst('CREATE INDEX ', 'CREATE INDEX IF NOT EXISTS '),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pulse_music.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
