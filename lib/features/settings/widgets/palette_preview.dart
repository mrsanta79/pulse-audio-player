import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A round chip showing what a theme looks like: its background, with a bar of
/// its surface and accent colours. When [dark] is given the chip is split down
/// the middle to show both halves of a system-following pair.
class PalettePreview extends StatelessWidget {
  const PalettePreview({super.key, required this.light, this.dark});

  final AppPalette light;
  final AppPalette? dark;

  static const _size = 40.0;

  @override
  Widget build(BuildContext context) {
    final darkPalette = dark;

    return Container(
      width: _size,
      height: _size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: darkPalette == null
          ? _Half(palette: light)
          : Row(
              children: [
                Expanded(child: _Half(palette: light)),
                Expanded(child: _Half(palette: darkPalette, alignRight: true)),
              ],
            ),
    );
  }
}

class _Half extends StatelessWidget {
  const _Half({required this.palette, this.alignRight = false});

  final AppPalette palette;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: palette.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignRight
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            _Bar(color: palette.accent, width: 12),
            const SizedBox(height: 3),
            _Bar(color: palette.textSecondary, width: 8),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
