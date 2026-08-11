import '../../data/repositories/providers.dart';

/// What one search turned up, across all three tabs.
class SearchResults {
  const SearchResults({
    required this.tracks,
    required this.albums,
    required this.artists,
  });

  static const empty = SearchResults(tracks: [], albums: [], artists: []);

  final List<Track> tracks;
  final List<AlbumSummary> albums;
  final List<String> artists;

  bool get isEmpty => tracks.isEmpty && albums.isEmpty && artists.isEmpty;
}

/// Matches [query] against the library.
///
/// Songs are matched in SQL (there can be tens of thousands); albums and
/// artists are filtered in memory from lists the app already holds, so typing
/// doesn't re-run an aggregate query over every track per keystroke.
Future<SearchResults> searchLibrary(
  String query, {
  required Future<List<Track>> tracks,
  required List<AlbumSummary> albums,
  required List<String> artists,
}) async {
  // Lowercased once, not once per candidate per field.
  final needle = query.toLowerCase();

  return SearchResults(
    tracks: await tracks,
    albums: [
      for (final album in albums)
        if (album.album.toLowerCase().contains(needle) ||
            album.artist.toLowerCase().contains(needle))
          album,
    ],
    artists: [
      for (final artist in artists)
        if (artist.toLowerCase().contains(needle)) artist,
    ],
  );
}
