import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/now_playing/now_playing_screen.dart';

/// The full-screen player, slid up over whatever page is underneath.
///
/// It is an overlay rather than a route, which is why it handles the system
/// back gesture itself.
class ExpandedPlayer extends StatefulWidget {
  const ExpandedPlayer({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  State<ExpandedPlayer> createState() => _ExpandedPlayerState();
}

class _ExpandedPlayerState extends State<ExpandedPlayer>
    with SingleTickerProviderStateMixin {
  /// How far down the sheet must be dragged before it closes.
  static const _dismissDragDistance = 80.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  double _dragDy = 0;

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0) _dragDy += details.delta.dy;
  }

  void _onDragEnd(DragEndDetails _) {
    if (_dragDy > _dismissDragDistance) _dismiss();
    _dragDy = 0;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return PopScope(
      canPop: false,
      // Collapse the player instead of popping the route beneath it, which
      // would navigate away (or exit the app) unexpectedly.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _dismiss();
      },
      child: Material(
        color: palette.scrim,
        child: SlideTransition(
          position: _slide,
          child: GestureDetector(
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: ColoredBox(
              color: palette.background,
              child: SafeArea(child: NowPlayingScreen(onDismiss: _dismiss)),
            ),
          ),
        ),
      ),
    );
  }
}
