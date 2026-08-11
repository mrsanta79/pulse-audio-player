import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/providers.dart';

/// Play/pause button with the track's progress drawn as a ring around it,
/// sweeping clockwise from 12 o'clock.
class MiniPlayerProgressButton extends ConsumerWidget {
  const MiniPlayerProgressButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final playing = ref.watch(isPlayingProvider);
    final position = ref.watch(playbackPositionProvider);
    final duration = ref.watch(playbackDurationProvider);

    final total = duration.inMilliseconds;
    final progress = total <= 0
        ? 0.0
        : (position.inMilliseconds / total).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => ref.read(audioHandlerProvider).playPause(),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.5,
                strokeCap: StrokeCap.round,
                backgroundColor: palette.miniPlayerFg.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation<Color>(palette.miniPlayerFg),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.miniPlayerButton,
                shape: BoxShape.circle,
              ),
              child: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: palette.miniPlayerButtonFg,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
