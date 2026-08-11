import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/player_ui_provider.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/track_list_view.dart';
import 'widgets/library_search_scaffold.dart';

class SongsListScreen extends ConsumerWidget {
  const SongsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(allTracksProvider).valueOrNull ?? const [];

    return LibrarySearchScaffold<Track>(
      title: 'Songs',
      items: tracks,
      searchText: (track) => '${track.title} ${track.artist} ${track.album}',
      hintText: 'Search songs',
      noMatchesMessage: 'No songs match',
      actions: (filtered) => [
        IconButton(
          onPressed: filtered.isEmpty ? null : () => shuffleAll(ref, filtered),
          icon: const Icon(Icons.shuffle_rounded),
        ),
      ],
      builder: (context, filtered) => TrackListView(
        tracks: filtered,
        emptyMessage: 'No songs yet. Add a folder in Settings.',
      ),
    );
  }
}
