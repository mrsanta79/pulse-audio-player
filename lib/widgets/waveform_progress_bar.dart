import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/format.dart';

/// The seek bar under the album art: a track, a filled portion and a thumb,
/// with the elapsed and total times beneath.
class WaveformProgressBar extends StatefulWidget {
  const WaveformProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  @override
  State<WaveformProgressBar> createState() => _WaveformProgressBarState();
}

class _WaveformProgressBarState extends State<WaveformProgressBar> {
  /// Where the finger is, while dragging. Non-null only during a drag, so the
  /// bar follows the touch instead of the (still unchanged) playhead.
  double? _dragRatio;

  double get _progress {
    final drag = _dragRatio;
    if (drag != null) return drag.clamp(0.0, 1.0);

    final total = widget.duration.inMilliseconds;
    if (total <= 0) return 0;
    return (widget.position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  Duration get _displayPosition {
    final total = widget.duration.inMilliseconds;
    if (_dragRatio == null || total <= 0) return widget.position;
    return Duration(milliseconds: (total * _progress).round());
  }

  void _scrubTo(double dx, double width) {
    setState(() => _dragRatio = (dx / width).clamp(0.0, 1.0));
  }

  void _commitSeek() {
    final total = widget.duration.inMilliseconds;
    if (total > 0) {
      widget.onSeek(Duration(milliseconds: (total * _progress).round()));
    }
    setState(() => _dragRatio = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _scrubTo(d.localPosition.dx, width),
              onTapUp: (_) => _commitSeek(),
              onHorizontalDragStart: (d) => _scrubTo(d.localPosition.dx, width),
              onHorizontalDragUpdate: (d) =>
                  _scrubTo(d.localPosition.dx, width),
              onHorizontalDragEnd: (_) => _commitSeek(),
              child: _Track(width: width, progress: _progress),
            );
          },
        ),
        const SizedBox(height: 8),
        _Timestamps(position: _displayPosition, duration: widget.duration),
      ],
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.width, required this.progress});

  static const _height = 3.0;
  static const _thumbSize = 12.0;

  final double width;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return SizedBox(
      height: 32,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _bar(width, palette.waveformInactive),
          _bar(width * progress, palette.accent),
          Positioned(
            left: (width * progress - _thumbSize / 2).clamp(
              0.0,
              width - _thumbSize,
            ),
            top: 10,
            child: _Thumb(color: palette.accent),
          ),
        ],
      ),
    );
  }

  Widget _bar(double barWidth, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: _height,
        width: barWidth,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _Track._thumbSize,
      height: _Track._thumbSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8),
        ],
      ),
    );
  }
}

class _Timestamps extends StatelessWidget {
  const _Timestamps({required this.position, required this.duration});

  final Duration position;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: AppColors.of(context).textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      // Keeps the row from twitching as the digits tick.
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(formatDuration(position), style: style),
        Text(formatDuration(duration), style: style),
      ],
    );
  }
}
