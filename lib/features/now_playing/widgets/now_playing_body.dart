import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/providers.dart';
import '../../../widgets/marquee_text.dart';
import 'now_playing_actions.dart';
import 'now_playing_art.dart';
import 'now_playing_header.dart';
import 'now_playing_progress.dart';
import 'now_playing_transport.dart';
import 'queue_sheet.dart';

/// Layout metrics for the player, derived from the space it was given.
///
/// Pulled out of the build so the sizing rules read as one small table instead
/// of a dozen inline ternaries.
class _Metrics {
  _Metrics(
    BoxConstraints constraints, {
    required bool embedded,
    required double bottomInset,
  }) : compact = constraints.maxHeight < 640,
       artWidth = constraints.maxWidth < 420
           ? constraints.maxWidth * 0.72
           : 300.0,
       pageInset = constraints.maxWidth < 500 ? AppSpacing.pageH : 32.0,
       // Embedded in the wide split view, the shell's bottom nav overlays the
       // bottom of this panel, so add clearance to keep the controls visible.
       bottomClearance =
           (constraints.maxHeight < 640 ? 12.0 : 20.0) +
           (embedded ? 76 + bottomInset : 0.0);

  final bool compact;
  final double artWidth;
  final double pageInset;
  final double bottomClearance;
}

/// The player's contents, for when something is actually loaded.
class NowPlayingBody extends ConsumerStatefulWidget {
  const NowPlayingBody({
    super.key,
    required this.embedded,
    required this.showHeader,
    required this.onDismiss,
  });

  final bool embedded;
  final bool showHeader;
  final VoidCallback onDismiss;

  @override
  ConsumerState<NowPlayingBody> createState() => _NowPlayingBodyState();
}

class _NowPlayingBodyState extends ConsumerState<NowPlayingBody> {
  /// How far down the page must be dragged before it closes.
  static const _dismissDragDistance = 72.0;

  double _dragDy = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final m = _Metrics(
          constraints,
          embedded: widget.embedded,
          bottomInset: MediaQuery.paddingOf(context).bottom,
        );

        return GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 0) _dragDy += details.delta.dy;
          },
          onVerticalDragEnd: (_) {
            if (_dragDy > _dismissDragDistance) widget.onDismiss();
            _dragDy = 0;
          },
          child: SingleChildScrollView(
            // Only the vertical insets live here: the header runs edge to edge,
            // so the horizontal page inset is applied to the content below it.
            padding: EdgeInsets.fromLTRB(
              6,
              m.compact ? 4 : 8,
              6,
              m.bottomClearance,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showHeader)
                  NowPlayingHeader(
                    onDismiss: widget.onDismiss,
                    onQueue: () => showQueueSheet(context),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: m.pageInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: m.compact ? 8 : 12),
                      NowPlayingArt(width: m.artWidth),
                      SizedBox(height: m.compact ? 20 : 26),
                      _TitleBlock(compact: m.compact),
                      SizedBox(height: m.compact ? 18 : 24),
                      const NowPlayingProgress(),
                      SizedBox(height: m.compact ? 12 : 18),
                      NowPlayingTransport(compact: m.compact),
                      // Secondary actions live below the transport controls so
                      // the title/artist can stay centered above the progress
                      // bar.
                      SizedBox(height: m.compact ? 14 : 22),
                      const NowPlayingActions(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TitleBlock extends ConsumerWidget {
  const _TitleBlock({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final item = ref.watch(currentMediaItemProvider);
    if (item == null) return const SizedBox.shrink();

    return Column(
      children: [
        MarqueeText(
          text: item.title,
          style: TextStyle(
            fontSize: compact ? 22 : 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.artist ?? '',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: palette.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
