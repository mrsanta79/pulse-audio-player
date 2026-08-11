import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/services/audio_player_service.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.playing,
    required this.shuffleEnabled,
    required this.repeatMode,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onShuffle,
    required this.onRepeat,
    this.compact = false,
  });

  final bool playing;
  final bool shuffleEnabled;
  final RepeatMode repeatMode;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final playSize = compact ? 56.0 : 72.0;
    final sideSize = compact ? 28.0 : 32.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onShuffle,
          icon: Icon(
            Icons.shuffle_rounded,
            color: shuffleEnabled ? palette.textPrimary : palette.textSecondary,
            size: sideSize,
          ),
        ),
        IconButton(
          onPressed: onPrevious,
          icon: Icon(
            Icons.skip_previous_rounded,
            color: palette.textPrimary,
            size: sideSize + 4,
          ),
        ),
        GestureDetector(
          onTap: onPlayPause,
          child: Container(
            width: playSize,
            height: playSize,
            decoration: BoxDecoration(
              color: palette.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: palette.onAccent,
              size: playSize * 0.55,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(
            Icons.skip_next_rounded,
            color: palette.textPrimary,
            size: sideSize + 4,
          ),
        ),
        IconButton(
          onPressed: onRepeat,
          icon: Icon(
            repeatMode == RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: repeatMode == RepeatMode.off
                ? palette.textSecondary
                : palette.textPrimary,
            size: sideSize,
          ),
        ),
      ],
    );
  }
}
