import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/openrouter_mood_service.dart';

class MoodCategorizationProgressBar extends StatelessWidget {
  const MoodCategorizationProgressBar({super.key, required this.progress});

  final MoodCategorizationProgress? progress;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final completed = progress?.completed ?? 0;
    final total = progress?.total ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        LinearProgressIndicator(
          value: progress?.done == true
              ? 1
              : total == 0
              ? null
              : (completed / total).clamp(0.0, 1.0),
          color: const Color(0xFFAB86D7),
          backgroundColor: palette.surfaceHighlight,
        ),
        const SizedBox(height: 8),
        Text(
          total == 0
              ? 'Preparing mood categorization…'
              : progress?.done == true
              ? 'Mood categorization complete'
              : 'Categorizing songs by mood $completed / $total',
          style: TextStyle(color: palette.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
