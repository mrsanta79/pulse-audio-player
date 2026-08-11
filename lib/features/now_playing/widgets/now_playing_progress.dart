import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/providers.dart';
import '../../../widgets/waveform_progress_bar.dart';

/// The seek bar and its timestamps.
///
/// The one part of the Now Playing screen that genuinely follows the playhead,
/// and so the only part that rebuilds as the track plays.
class NowPlayingProgress extends ConsumerWidget {
  const NowPlayingProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WaveformProgressBar(
      position: ref.watch(playbackPositionProvider),
      duration: ref.watch(playbackDurationProvider),
      onSeek: ref.read(audioHandlerProvider).seek,
    );
  }
}
