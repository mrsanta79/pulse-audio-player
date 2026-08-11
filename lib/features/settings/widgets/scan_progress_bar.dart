import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/folder_scanner_service.dart';

/// Progress while a folder scan is running.
class ScanProgressBar extends StatelessWidget {
  const ScanProgressBar({super.key, required this.progress});

  final ScanProgress? progress;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final scanned = progress?.scanned ?? 0;
    final total = progress?.total ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        LinearProgressIndicator(
          // Indeterminate until the file count is known.
          value: total == 0 ? null : (scanned / total).clamp(0.0, 1.0),
          color: palette.accent,
          backgroundColor: palette.surfaceHighlight,
        ),
        const SizedBox(height: 8),
        Text(
          'Scanning $scanned / $total',
          style: TextStyle(color: palette.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
