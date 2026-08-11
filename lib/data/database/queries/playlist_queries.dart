import 'package:drift/drift.dart';

import '../app_database.dart';

/// Playlists and their membership.
///
/// The bulk `addTracksToPlaylist` / `removeTracksFromPlaylist` entry points
/// exist because the UI adds whole albums: doing that a track at a time meant
/// three statements per track, one of which loaded the entire playlist just to
/// count it.
extension PlaylistQueries on AppDatabase {
  Stream<List<Playlist>> watchPlaylists() {
    return (select(
      playlists,
    )..orderBy([(p) => OrderingTerm.desc(p.createdAt)])).watch();
  }

  Future<List<Track>> getPlaylistTracks(int playlistId) =>
      _playlistTracks(playlistId).get();

  Stream<List<Track>> watchPlaylistTracks(int playlistId) =>
      _playlistTracks(playlistId).watch();

  Selectable<Track> _playlistTracks(int playlistId) {
    return customSelect(
      '''
      SELECT t.* FROM tracks t
      INNER JOIN playlist_tracks pt ON pt.track_id = t.id
      WHERE pt.playlist_id = ?
      ORDER BY pt.position ASC
      ''',
      variables: [Variable.withInt(playlistId)],
      readsFrom: {tracks, playlistTracks},
    ).map((row) => tracks.map(row.data));
  }

  /// How many of [trackIds] each playlist already holds, keyed by playlist id.
  /// Playlists holding none of them are absent from the map.
  Future<Map<int, int>> countTracksInPlaylists(List<int> trackIds) async {
    final ids = trackIds.toSet().toList();
    if (ids.isEmpty) return {};
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await customSelect(
      '''
      SELECT playlist_id, COUNT(*) AS track_count FROM playlist_tracks
      WHERE track_id IN ($placeholders)
      GROUP BY playlist_id
      ''',
      variables: ids.map(Variable.withInt).toList(),
      readsFrom: {playlistTracks},
    ).get();
    return {
      for (final row in rows)
        row.read<int>('playlist_id'): row.read<int>('track_count'),
    };
  }

  Future<int> createPlaylist(String name) {
    return into(playlists).insert(PlaylistsCompanion.insert(name: name));
  }

  Future<void> deletePlaylist(int id) async {
    await (delete(playlists)..where((p) => p.id.equals(id))).go();
  }

  Future<void> addTrackToPlaylist(int playlistId, int trackId) {
    return addTracksToPlaylist(playlistId, [trackId]);
  }

  /// Appends every track in [trackIds] that isn't already in the playlist,
  /// keeping their given order. One read and one write, whatever the count.
  Future<void> addTracksToPlaylist(int playlistId, List<int> trackIds) async {
    if (trackIds.isEmpty) return;
    await transaction(() async {
      final existing = await (select(
        playlistTracks,
      )..where((pt) => pt.playlistId.equals(playlistId))).get();

      final present = {for (final row in existing) row.trackId};
      // Append after the highest position rather than at `length`: removing a
      // track leaves a gap, and counting rows would then reuse a position and
      // make the order ambiguous.
      var next =
          existing.fold(-1, (max, r) => r.position > max ? r.position : max) +
          1;

      final additions = <PlaylistTracksCompanion>[];
      for (final trackId in trackIds) {
        if (!present.add(trackId)) continue;
        additions.add(
          PlaylistTracksCompanion.insert(
            playlistId: playlistId,
            trackId: trackId,
            position: next++,
          ),
        );
      }
      if (additions.isEmpty) return;
      await batch((b) => b.insertAll(playlistTracks, additions));
    });
  }

  Future<void> removeTrackFromPlaylist(int playlistId, int trackId) {
    return removeTracksFromPlaylist(playlistId, [trackId]);
  }

  Future<void> removeTracksFromPlaylist(
    int playlistId,
    List<int> trackIds,
  ) async {
    if (trackIds.isEmpty) return;
    await (delete(playlistTracks)..where(
          (pt) => pt.playlistId.equals(playlistId) & pt.trackId.isIn(trackIds),
        ))
        .go();
  }
}
