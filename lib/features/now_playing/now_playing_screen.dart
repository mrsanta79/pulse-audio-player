import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/player_ui_provider.dart';
import '../../data/repositories/providers.dart';
import 'widgets/now_playing_body.dart';
import 'widgets/now_playing_header.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({
    super.key,
    this.embedded = false,
    this.showHeader = true,
    this.onDismiss,
  });

  /// True when this sits in the wide shell's split view rather than over the
  /// page as a sheet.
  final bool embedded;
  final bool showHeader;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    // Only the track identity, not the playhead: the pieces that tick watch
    // the position themselves.
    final hasMedia = ref.watch(hasMediaProvider);

    void dismiss() {
      if (onDismiss != null) {
        onDismiss!();
      } else if (embedded) {
        ref.read(playerExpandedProvider.notifier).collapse();
      } else {
        context.pop();
      }
    }

    // Always provide a Material ancestor. In the wide/embedded layout this
    // screen is placed directly in a Row (no Scaffold), so without this its
    // text would render with the "missing Material" yellow underlines.
    return Material(
      color: palette.background,
      child: hasMedia
          ? NowPlayingBody(
              embedded: embedded,
              showHeader: showHeader,
              onDismiss: dismiss,
            )
          : _NothingPlaying(showHeader: showHeader, onDismiss: dismiss),
    );
  }
}

class _NothingPlaying extends StatelessWidget {
  const _NothingPlaying({required this.showHeader, required this.onDismiss});

  final bool showHeader;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final message = Center(
      child: Text(
        'Nothing playing',
        style: TextStyle(color: AppColors.of(context).textSecondary),
      ),
    );

    if (!showHeader) return message;
    return Column(
      children: [
        NowPlayingHeader(onDismiss: onDismiss, onQueue: null),
        Expanded(child: message),
      ],
    );
  }
}
