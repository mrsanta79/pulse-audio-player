import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/providers.dart';
import '../../../widgets/player_controls.dart';

/// Shuffle / previous / play-pause / next / repeat.
///
/// Watches only the three flags it draws, none of which move with the playhead.
class NowPlayingTransport extends ConsumerWidget {
  const NowPlayingTransport({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);

    return PlayerControls(
      playing: ref.watch(isPlayingProvider),
      shuffleEnabled: ref.watch(shuffleEnabledProvider),
      repeatMode: ref.watch(repeatModeProvider),
      compact: compact,
      onPlayPause: handler.playPause,
      onPrevious: handler.skipToPrevious,
      onNext: handler.skipToNext,
      onShuffle: handler.toggleShuffle,
      onRepeat: handler.cycleRepeatMode,
    );
  }
}
