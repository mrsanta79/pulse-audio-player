import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/providers.dart';
import '../../../widgets/album_list_tile.dart';
import '../../../widgets/artist_list_tile.dart';
import '../../../widgets/track_list_view.dart';
import '../search_results.dart';

enum SearchFilter {
  songs('Songs'),
  albums('Albums'),
  artists('Artists');

  const SearchFilter(this.label);

  final String label;
}

class SearchResultsList extends StatelessWidget {
  const SearchResultsList({
    super.key,
    required this.query,
    required this.filter,
    required this.results,
  });

  final String query;
  final SearchFilter filter;
  final SearchResults results;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return const _Message('Find anything in your library');
    }

    return switch (filter) {
      SearchFilter.songs => TrackListView(
        tracks: results.tracks,
        subtitle: (track) => '${track.artist} • ${track.album}',
        emptyMessage: 'No results',
      ),
      SearchFilter.albums => _AlbumResults(albums: results.albums),
      SearchFilter.artists => _ArtistResults(artists: results.artists),
    };
  }
}

class _AlbumResults extends StatelessWidget {
  const _AlbumResults({required this.albums});

  final List<AlbumSummary> albums;

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) return const _Message('No results');

    return ListView.builder(
      padding: AppSpacing.listPadding,
      itemCount: albums.length,
      itemBuilder: (context, index) => AlbumListTile(album: albums[index]),
    );
  }
}

class _ArtistResults extends StatelessWidget {
  const _ArtistResults({required this.artists});

  final List<String> artists;

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) return const _Message('No results');

    return ListView.builder(
      padding: AppSpacing.listPadding,
      itemCount: artists.length,
      itemBuilder: (context, index) => ArtistListTile(artist: artists[index]),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(color: AppColors.of(context).textSecondary),
      ),
    );
  }
}
