import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Music library actions, disabled while a scan or mood pass is running.
class ScanButtons extends StatelessWidget {
  const ScanButtons({
    super.key,
    required this.scanning,
    required this.onAddFolder,
    required this.onRescan,
    required this.onCategorizeMoods,
  });

  final bool scanning;
  final VoidCallback onAddFolder;
  final VoidCallback onRescan;
  final VoidCallback onCategorizeMoods;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    const verticalPadding = EdgeInsets.symmetric(vertical: 14);
    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.pill),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final addFolder = FilledButton.icon(
          onPressed: scanning ? null : onAddFolder,
          icon: const Icon(Icons.create_new_folder_rounded),
          label: const Text('Add folder'),
          style: FilledButton.styleFrom(
            backgroundColor: palette.accent,
            foregroundColor: palette.onAccent,
            padding: verticalPadding,
            shape: pill,
          ),
        );
        final rescan = OutlinedButton.icon(
          onPressed: scanning ? null : onRescan,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Rescan'),
          style: OutlinedButton.styleFrom(
            foregroundColor: palette.textPrimary,
            padding: verticalPadding,
            side: BorderSide(color: palette.pillOutline),
            shape: pill,
          ),
        );
        final categorize = OutlinedButton.icon(
          onPressed: scanning ? null : onCategorizeMoods,
          icon: const Icon(Icons.mood_rounded),
          label: const Text('Categorize moods'),
          style: OutlinedButton.styleFrom(
            foregroundColor: palette.textPrimary,
            padding: verticalPadding,
            side: BorderSide(color: palette.pillOutline),
            shape: pill,
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: addFolder),
                  const SizedBox(width: 12),
                  Expanded(child: rescan),
                ],
              ),
              const SizedBox(height: 10),
              categorize,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: addFolder),
            const SizedBox(width: 10),
            Expanded(child: rescan),
            const SizedBox(width: 10),
            Expanded(child: categorize),
          ],
        );
      },
    );
  }
}
