import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/player_ui_provider.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/track_list_view.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final int playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks =
        ref.watch(playlistTracksProvider(playlistId)).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: const Text('Playlist'),
        actions: [
          IconButton(
            onPressed: tracks.isEmpty
                ? null
                : () => playAndMaybeOpenPlayer(
                    ref,
                    () => ref.read(audioHandlerProvider).loadQueue(tracks),
                  ),
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ],
      ),
      // Removing a track used to need a manual `markNeedsBuild`; the row list
      // is a database stream now, so the write itself refreshes the screen.
      body: TrackListView(
        tracks: tracks,
        emptyMessage: 'No songs in this playlist',
        trailing: (track) => IconButton(
          icon: const Icon(Icons.remove_circle_outline_rounded),
          onPressed: () => ref
              .read(databaseProvider)
              .removeTrackFromPlaylist(playlistId, track.id),
        ),
      ),
    );
  }
}
