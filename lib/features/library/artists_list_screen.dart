import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/artist_list_tile.dart';
import 'widgets/library_search_scaffold.dart';

class ArtistsListScreen extends ConsumerWidget {
  const ArtistsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artists = ref.watch(artistsProvider).valueOrNull ?? const [];

    return LibrarySearchScaffold<String>(
      title: 'Artists',
      items: artists,
      searchText: (artist) => artist,
      hintText: 'Search artists',
      noMatchesMessage: 'No artists match',
      builder: (context, filtered) => ListView.builder(
        padding: AppSpacing.listPadding,
        itemCount: filtered.length,
        itemBuilder: (context, index) =>
            ArtistListTile(artist: filtered[index]),
      ),
    );
  }
}
