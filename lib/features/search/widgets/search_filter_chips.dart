import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'search_results_list.dart';

class SearchFilterChips extends StatelessWidget {
  const SearchFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final SearchFilter selected;
  final ValueChanged<SearchFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
      child: Row(
        children: [
          for (final filter in SearchFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter.label),
                selected: selected == filter,
                onSelected: (_) => onSelected(filter),
                selectedColor: palette.accent,
                labelStyle: TextStyle(
                  color: selected == filter
                      ? palette.onAccent
                      : palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: palette.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                side: BorderSide.none,
              ),
            ),
        ],
      ),
    );
  }
}
