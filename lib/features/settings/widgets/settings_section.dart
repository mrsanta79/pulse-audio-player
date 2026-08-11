import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A titled block on the Settings page: heading, one line of explanation, and
/// optionally the control it introduces.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.description,
    this.child,
  });

  final String title;
  final String description;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        const SizedBox(height: 6),
        Text(
          description,
          style: TextStyle(color: palette.textSecondary, fontSize: 13),
        ),
        if (child != null) ...[const SizedBox(height: 16), child!],
      ],
    );
  }
}
