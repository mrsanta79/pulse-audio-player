import 'app_database.dart';

/// One row of the album list: a `(album, artist)` pair with its aggregates.
class AlbumSummary {
  final String album;
  final String artist;
  final int songCount;
  final int? year;
  final String? albumArtHash;

  const AlbumSummary({
    required this.album,
    required this.artist,
    required this.songCount,
    this.year,
    this.albumArtHash,
  });
}

/// A restored playback session, with the queue already resolved to tracks that
/// still exist in the library.
class SavedPlaybackSession {
  final List<Track> tracks;
  final int currentIndex;
  final Duration position;
  final int repeatModeIndex;
  final bool shuffleEnabled;

  const SavedPlaybackSession({
    required this.tracks,
    required this.currentIndex,
    required this.position,
    required this.repeatModeIndex,
    required this.shuffleEnabled,
  });
}
