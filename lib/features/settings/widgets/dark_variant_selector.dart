import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Segmented control for the dark half of "follow system".
class DarkVariantSelector extends StatelessWidget {
  const DarkVariantSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AppDarkVariant value;
  final ValueChanged<AppDarkVariant> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dark variant',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final variant in AppDarkVariant.values) ...[
                Expanded(
                  child: _VariantChip(
                    variant: variant,
                    selected: value == variant,
                    onTap: () => onChanged(variant),
                  ),
                ),
                if (variant != AppDarkVariant.values.last)
                  const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _VariantChip extends StatelessWidget {
  const _VariantChip({
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  final AppDarkVariant variant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      label: '${variant.label} dark theme',
      child: Material(
        color: selected ? palette.accent : palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: variant.palette.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? palette.onAccent : palette.pillOutline,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  variant.label,
                  style: TextStyle(
                    color: selected ? palette.onAccent : palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
