import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/moods/mood_catalog.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/player_ui_provider.dart';
import '../../widgets/track_list_view.dart';

class MoodDetailScreen extends ConsumerWidget {
  const MoodDetailScreen({super.key, required this.moodId});

  final String moodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = moodById(moodId);
    final tracks =
        ref.watch(moodTracksProvider(moodId)).valueOrNull ?? const [];

    if (mood == null) {
      return Scaffold(
        backgroundColor: AppColors.of(context).background,
        appBar: AppBar(title: const Text('Mood')),
        body: const Center(child: Text('This mood is not available.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(mood.label),
        actions: [
          IconButton(
            tooltip: 'Shuffle songs',
            onPressed: tracks.isEmpty ? null : () => shuffleAll(ref, tracks),
            icon: const Icon(Icons.shuffle_rounded),
          ),
        ],
      ),
      body: TrackListView(
        tracks: tracks,
        subtitle: (track) => '${track.artist} • ${track.album}',
        emptyMessage:
            'No ${mood.label.toLowerCase()} songs yet. Rescan your library in Settings.',
      ),
    );
  }
}
