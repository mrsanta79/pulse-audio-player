import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// "Add folder" and "Rescan", disabled while a scan is running.
class ScanButtons extends StatelessWidget {
  const ScanButtons({
    super.key,
    required this.scanning,
    required this.onAddFolder,
    required this.onRescan,
  });

  final bool scanning;
  final VoidCallback onAddFolder;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    const verticalPadding = EdgeInsets.symmetric(vertical: 14);
    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.pill),
    );

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: scanning ? null : onAddFolder,
            icon: const Icon(Icons.create_new_folder_rounded),
            label: const Text('Add folder'),
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.onAccent,
              padding: verticalPadding,
              shape: pill,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: scanning ? null : onRescan,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Rescan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.textPrimary,
              padding: verticalPadding,
              side: BorderSide(color: palette.pillOutline),
              shape: pill,
            ),
          ),
        ),
      ],
    );
  }
}
