import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/theme_provider.dart';
import 'dark_variant_selector.dart';
import 'palette_preview.dart';

/// Theme picker: the four choices, plus a dark-variant selector that only
/// matters (and so only appears) when the choice is "follow system".
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final controller = ref.read(themeSettingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final choice in AppThemeChoice.values) ...[
          _ThemeOptionTile(
            choice: choice,
            selected: settings.choice == choice,
            preview: _previewFor(choice, settings),
            onTap: () => controller.setChoice(choice),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: settings.choice == AppThemeChoice.system
              ? DarkVariantSelector(
                  value: settings.darkVariant,
                  onChanged: controller.setDarkVariant,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  /// The palette(s) an option produces. "Follow system" has no palette of its
  /// own, so it previews whichever pair it would actually produce; the others
  /// return a single palette and are drawn as one swatch.
  static (AppPalette, AppPalette?) _previewFor(
    AppThemeChoice choice,
    ThemeSettings settings,
  ) {
    return switch (choice) {
      AppThemeChoice.system => (AppPalette.light, settings.darkVariant.palette),
      AppThemeChoice.light => (AppPalette.light, null),
      AppThemeChoice.amoled => (AppPalette.amoled, null),
      AppThemeChoice.midnight => (AppPalette.midnight, null),
    };
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.choice,
    required this.selected,
    required this.preview,
    required this.onTap,
  });

  final AppThemeChoice choice;
  final bool selected;
  final (AppPalette, AppPalette?) preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      label: choice.label,
      child: Material(
        color: selected ? palette.surfaceHighlight : palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.trackRow),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.trackRow),
              border: Border.all(
                color: selected ? palette.accent : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                PalettePreview(light: preview.$1, dark: preview.$2),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        choice.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        choice.description,
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _SelectionMark(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A fixed-size box either way, so rows don't shift width as the selection
/// moves between them.
class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return SizedBox(
      width: 22,
      height: 22,
      child: selected
          ? Icon(Icons.check_circle_rounded, size: 22, color: palette.accent)
          : DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: palette.pillOutline),
              ),
            ),
    );
  }
}
