import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/player_ui_provider.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/track_list_view.dart';

class LikesScreen extends ConsumerWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likes = ref.watch(likedTracksProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: const Text('Liked songs'),
        actions: [
          IconButton(
            onPressed: likes.isEmpty
                ? null
                : () => playAndMaybeOpenPlayer(
                    ref,
                    () => ref.read(audioHandlerProvider).loadQueue(likes),
                  ),
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ],
      ),
      body: TrackListView(
        tracks: likes,
        emptyMessage: 'Songs you like will show up here',
        // Unliking drops the row from the liked-tracks stream, so the list
        // updates itself.
        trailing: (track) => IconButton(
          icon: const Icon(Icons.favorite_rounded),
          onPressed: () => ref.read(databaseProvider).toggleLike(track.id),
        ),
      ),
    );
  }
}
