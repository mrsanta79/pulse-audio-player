import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/track_list_view.dart';

class YearDetailScreen extends ConsumerWidget {
  const YearDetailScreen({super.key, required this.year});

  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(yearTracksProvider(year)).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text('$year')),
      body: TrackListView(
        tracks: tracks,
        subtitle: (track) => '${track.artist} • ${track.album}',
        emptyMessage: 'No songs from this year',
      ),
    );
  }
}
