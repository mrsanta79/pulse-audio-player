import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/providers.dart';
import 'widgets/library_search_scaffold.dart';

class YearsListScreen extends ConsumerWidget {
  const YearsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final years = ref.watch(yearsProvider).valueOrNull ?? const [];

    return LibrarySearchScaffold<int>(
      title: 'Years',
      items: years,
      searchText: (year) => '$year',
      hintText: 'Search years',
      noMatchesMessage: 'No years match',
      builder: (context, filtered) => ListView.builder(
        padding: AppSpacing.listPadding,
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final year = filtered[index];
          return ListTile(
            leading: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$year',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text('$year'),
            onTap: () => context.push(yearRoute(year)),
          );
        },
      ),
    );
  }
}
