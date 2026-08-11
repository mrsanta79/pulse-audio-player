import 'package:drift/drift.dart';

import '../app_database.dart';

/// Reads over the scanned library: tracks, the album/artist/year groupings the
/// Library tab is built from, likes, and album artwork.
///
/// The `watch*` variants are what screens should use. A `Future` query started
/// from a `build` method re-runs on every rebuild; a stream is subscribed once
/// and re-emits only when the underlying tables actually change.
extension LibraryQueries on AppDatabase {
  Future<List<Track>> getAllTracks() => _allTracks().get();

  Stream<List<Track>> watchAllTracks() => _allTracks().watch();

  SimpleSelectStatement<$TracksTable, Track> _allTracks() {
    return select(tracks)..orderBy([(t) => OrderingTerm.asc(t.title)]);
  }

  Stream<List<Track>> watchTracksByAlbum(String album, String artist) =>
      _byAlbum(album, artist).watch();

  SimpleSelectStatement<$TracksTable, Track> _byAlbum(
    String album,
    String artist,
  ) {
    return select(tracks)
      ..where((t) => t.album.equals(album) & t.artist.equals(artist))
      ..orderBy([
        (t) => OrderingTerm.asc(t.trackNumber),
        (t) => OrderingTerm.asc(t.title),
      ]);
  }

  Stream<List<Track>> watchTracksByArtist(String artist) =>
      _byArtist(artist).watch();

  SimpleSelectStatement<$TracksTable, Track> _byArtist(String artist) {
    return select(tracks)
      ..where((t) => t.artist.equals(artist))
      ..orderBy([
        (t) => OrderingTerm.asc(t.album),
        (t) => OrderingTerm.asc(t.trackNumber),
      ]);
  }

  Stream<List<Track>> watchTracksByYear(int year) => _byYear(year).watch();

  SimpleSelectStatement<$TracksTable, Track> _byYear(int year) {
    return select(tracks)
      ..where((t) => t.year.equals(year))
      ..orderBy([
        (t) => OrderingTerm.asc(t.album),
        (t) => OrderingTerm.asc(t.trackNumber),
      ]);
  }

  Future<List<Track>> searchTracks(String query) {
    final q = '%${query.toLowerCase()}%';
    return customSelect(
      '''
      SELECT * FROM tracks
      WHERE lower(title) LIKE ? OR lower(artist) LIKE ? OR lower(album) LIKE ?
      ORDER BY title ASC
      ''',
      variables: [
        Variable.withString(q),
        Variable.withString(q),
        Variable.withString(q),
      ],
      readsFrom: {tracks},
    ).map((row) => tracks.map(row.data)).get();
  }

  Future<List<String>> getArtists() async {
    final rows = await customSelect(
      'SELECT DISTINCT artist FROM tracks ORDER BY lower(artist) ASC',
      readsFrom: {tracks},
    ).get();
    return rows.map((r) => r.read<String>('artist')).toList();
  }

  Future<List<AlbumSummary>> getAlbums() async {
    final rows = await customSelect(
      '''
      SELECT album, artist, COUNT(*) AS song_count, MAX(year) AS year, MAX(album_art_hash) AS art_hash
      FROM tracks
      GROUP BY album, artist
      ORDER BY lower(album) ASC
      ''',
      readsFrom: {tracks},
    ).get();
    return [
      for (final r in rows)
        AlbumSummary(
          album: r.read<String>('album'),
          artist: r.read<String>('artist'),
          songCount: r.read<int>('song_count'),
          year: r.readNullable<int>('year'),
          albumArtHash: r.readNullable<String>('art_hash'),
        ),
    ];
  }

  Future<List<int>> getYears() async {
    final rows = await customSelect(
      'SELECT DISTINCT year FROM tracks WHERE year IS NOT NULL ORDER BY year DESC',
      readsFrom: {tracks},
    ).get();
    return rows.map((r) => r.read<int>('year')).toList();
  }

  Stream<List<Track>> watchLikedTracks() => _likedTracks().watch();

  Selectable<Track> _likedTracks() {
    return customSelect(
      '''
      SELECT t.* FROM tracks t
      INNER JOIN likes l ON l.track_id = t.id
      ORDER BY l.liked_at DESC
      ''',
      readsFrom: {tracks, likes},
    ).map((row) => tracks.map(row.data));
  }

  Future<bool> isLiked(int trackId) async {
    final row =
        await (select(likes)
              ..where((l) => l.trackId.equals(trackId))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<void> toggleLike(int trackId) async {
    final liked = await isLiked(trackId);
    await setLikes([trackId], liked: !liked);
  }

  /// Likes or unlikes many tracks in one round trip. Liking is idempotent, so
  /// tracks that are already liked keep their original `likedAt` (and so their
  /// place in the Liked Songs list) instead of jumping to the top.
  Future<void> setLikes(List<int> trackIds, {required bool liked}) async {
    if (trackIds.isEmpty) return;
    if (!liked) {
      await (delete(likes)..where((l) => l.trackId.isIn(trackIds))).go();
      return;
    }
    await batch(
      (b) => b.insertAll(likes, [
        for (final id in trackIds) LikesCompanion.insert(trackId: Value(id)),
      ], mode: InsertMode.insertOrIgnore),
    );
  }

  Future<Uint8List?> getAlbumArtBytes(String? hash) async {
    if (hash == null) return null;
    final row = await (select(
      albumArt,
    )..where((a) => a.hash.equals(hash))).getSingleOrNull();
    return row?.bytes;
  }

  Stream<List<ScanFolder>> watchScanFolders() {
    return (select(
      scanFolders,
    )..orderBy([(f) => OrderingTerm.desc(f.addedAt)])).watch();
  }
}
