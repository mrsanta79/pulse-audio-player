import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/moods/mood_catalog.dart';
import '../../data/repositories/providers.dart';

class MoodsListScreen extends ConsumerWidget {
  const MoodsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final counts = {
      for (final item in ref.watch(moodCountsProvider).valueOrNull ?? const [])
        item.mood: item.count,
    };
    final hasCategorizedSongs = counts.values.any((count) => count > 0);
    final status = ref.watch(moodCategorizationStatusProvider);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('Moods')),
      body: Column(
        children: [
          if (status != null || !hasCategorizedSongs)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageH,
                12,
                AppSpacing.pageH,
                0,
              ),
              child: Material(
                color: status?.isError == true
                    ? Theme.of(context).colorScheme.errorContainer
                    : palette.surface,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        status?.isError == true
                            ? Icons.error_outline_rounded
                            : Icons.info_outline_rounded,
                        color: status?.isError == true
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : palette.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          status?.message ??
                              'No songs have been categorized yet. Add an OpenRouter API key in Settings, then rescan.',
                          style: TextStyle(
                            color: status?.isError == true
                                ? Theme.of(context).colorScheme.onErrorContainer
                                : palette.textSecondary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(Routes.settings),
                        child: const Text('Settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageH,
                12,
                AppSpacing.pageH,
                AppSpacing.bottomGap,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 128,
              ),
              itemCount: moodCatalog.length,
              itemBuilder: (context, index) {
                final mood = moodCatalog[index];
                return _MoodCard(
                  mood: mood,
                  count: counts[mood.id] ?? 0,
                  onTap: () => context.push(moodRoute(mood.id)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({
    required this.mood,
    required this.count,
    required this.onTap,
  });

  final MoodDefinition mood;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: mood.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(mood.icon, color: mood.color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mood.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count ${count == 1 ? 'song' : 'songs'}',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
