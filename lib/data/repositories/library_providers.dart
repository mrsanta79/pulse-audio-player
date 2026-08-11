import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_provider.dart';
import 'service_providers.dart';

/// Identifies one album. A record so it works as a family key: Riverpod caches
/// per argument, which needs value equality.
typedef AlbumKey = ({String album, String artist});

final allTracksProvider = StreamProvider<List<Track>>((ref) {
  return ref.watch(databaseProvider).watchAllTracks();
});

final likedTracksProvider = StreamProvider<List<Track>>((ref) {
  return ref.watch(databaseProvider).watchLikedTracks();
});

final playlistsProvider = StreamProvider<List<Playlist>>((ref) {
  return ref.watch(databaseProvider).watchPlaylists();
});

final scanFoldersProvider = StreamProvider<List<ScanFolder>>((ref) {
  return ref.watch(databaseProvider).watchScanFolders();
});

// The groupings the Library tab is built from. Each re-runs when the track
// table changes, which is the only thing that can move them.
final artistsProvider = FutureProvider<List<String>>((ref) async {
  ref.watch(allTracksProvider);
  return ref.watch(databaseProvider).getArtists();
});

final albumsProvider = FutureProvider<List<AlbumSummary>>((ref) async {
  ref.watch(allTracksProvider);
  return ref.watch(databaseProvider).getAlbums();
});

final yearsProvider = FutureProvider<List<int>>((ref) async {
  ref.watch(allTracksProvider);
  return ref.watch(databaseProvider).getYears();
});

// Detail-screen track lists.
//
// These are streams rather than futures started from `build`: a `FutureBuilder`
// fed by a query call in a build method re-runs that query on every rebuild,
// and these screens rebuild whenever playback or likes change. Streams are
// subscribed once and re-emit only when the rows actually change, which also
// means edits (a like, a playlist removal) show up without a manual refresh.
final albumTracksProvider = StreamProvider.autoDispose
    .family<List<Track>, AlbumKey>((ref, key) {
      return ref
          .watch(databaseProvider)
          .watchTracksByAlbum(key.album, key.artist);
    });

final artistTracksProvider = StreamProvider.autoDispose
    .family<List<Track>, String>((ref, artist) {
      return ref.watch(databaseProvider).watchTracksByArtist(artist);
    });

final yearTracksProvider = StreamProvider.autoDispose.family<List<Track>, int>((
  ref,
  year,
) {
  return ref.watch(databaseProvider).watchTracksByYear(year);
});

final playlistTracksProvider = StreamProvider.autoDispose
    .family<List<Track>, int>((ref, playlistId) {
      return ref.watch(databaseProvider).watchPlaylistTracks(playlistId);
    });

/// Raw artwork bytes for one hash.
///
/// `autoDispose` matters here: these are the biggest objects in the app, and
/// without it every cover the user has scrolled past stays in memory for the
/// life of the process. Riverpod keeps each one alive as long as something is
/// showing it, which is exactly how long it is wanted.
final albumArtProvider = FutureProvider.autoDispose.family<Uint8List?, String?>(
  (ref, hash) {
    return ref.watch(databaseProvider).getAlbumArtBytes(hash);
  },
);

/// Whether a track is liked, derived from the liked-tracks stream rather than
/// queried per track: the stream is already in memory, so this costs a set
/// lookup instead of a database round trip per heart icon on screen.
final isLikedProvider = Provider.family<bool, int>((ref, trackId) {
  final liked = ref.watch(likedTrackIdsProvider);
  return liked.contains(trackId);
});

final likedTrackIdsProvider = Provider<Set<int>>((ref) {
  final tracks = ref.watch(likedTracksProvider).valueOrNull;
  if (tracks == null || tracks.isEmpty) return const {};
  return {for (final track in tracks) track.id};
});

/// The artwork-derived glow colour.
///
/// Also `autoDispose`, so it doesn't pin [albumArtProvider]'s bytes in memory.
/// Recomputing is cheap on the second look: `PaletteService` keeps a bounded
/// cache of the colours themselves, which are a few bytes each.
final glowColorProvider = FutureProvider.autoDispose.family<Color?, String?>((
  ref,
  hash,
) async {
  if (hash == null) return null;
  final bytes = await ref.watch(albumArtProvider(hash).future);
  return ref.watch(paletteServiceProvider).glowColorFor(bytes, cacheKey: hash);
});
