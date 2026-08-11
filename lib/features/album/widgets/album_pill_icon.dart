import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AlbumPillIcon extends StatelessWidget {
  const AlbumPillIcon({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.iconPill),
      child: Container(
        width: 40,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.iconPill),
          border: Border.all(color: palette.pillOutline),
        ),
        child: Icon(icon, size: 18, color: palette.textPrimary),
      ),
    );
  }
}
