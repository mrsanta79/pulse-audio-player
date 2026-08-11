import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// An icon button in the player, boxed to a fixed 40px so the header's buttons
/// and the actions row below line up. Material's own 48px tap-target padding
/// would otherwise drive each row's width independently.
class NowPlayingIconButton extends StatelessWidget {
  const NowPlayingIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size,
  });

  final IconData icon;
  final VoidCallback? onTap;

  /// Icon size. Defaults to Material's, for icons that already read at the
  /// right weight.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return SizedBox(
      width: 40,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: palette.textPrimary, size: size),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }
}
