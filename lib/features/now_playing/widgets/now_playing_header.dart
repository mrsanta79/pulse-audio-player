import 'package:flutter/material.dart';

import 'now_playing_icon_button.dart';

class NowPlayingHeader extends StatelessWidget {
  const NowPlayingHeader({super.key, required this.onDismiss, this.onQueue});

  final VoidCallback onDismiss;
  final VoidCallback? onQueue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          NowPlayingIconButton(
            icon: Icons.keyboard_arrow_down_rounded,
            size: 28,
            onTap: onDismiss,
          ),
          const Expanded(
            child: Text(
              'Now Playing',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          NowPlayingIconButton(icon: Icons.queue_music_rounded, onTap: onQueue),
        ],
      ),
    );
  }
}
