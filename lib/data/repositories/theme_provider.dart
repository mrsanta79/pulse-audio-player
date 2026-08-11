import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import 'database_provider.dart';

/// Preference keys. These strings are persisted, so renaming one silently
/// resets the user's choice back to the default.
const _kThemeChoiceKey = 'theme_choice';
const _kDarkVariantKey = 'theme_dark_variant';

/// The user's appearance preferences.
@immutable
class ThemeSettings {
  const ThemeSettings({
    this.choice = AppThemeChoice.amoled,
    this.darkVariant = AppDarkVariant.amoled,
  });

  final AppThemeChoice choice;

  /// Which dark palette to pair with [AppThemeChoice.system]. Kept separate
  /// from [choice] so switching to "follow system" and back doesn't lose the
  /// user's preferred dark flavour.
  final AppDarkVariant darkVariant;

  /// The dark palette this configuration implies. An explicit dark choice wins
  /// over [darkVariant]; otherwise the stored variant decides.
  AppPalette get darkPalette => switch (choice) {
    AppThemeChoice.amoled => AppPalette.amoled,
    AppThemeChoice.midnight => AppPalette.midnight,
    AppThemeChoice.system || AppThemeChoice.light => darkVariant.palette,
  };

  AppPalette get lightPalette => AppPalette.light;

  ThemeMode get themeMode => switch (choice) {
    AppThemeChoice.system => ThemeMode.system,
    AppThemeChoice.light => ThemeMode.light,
    AppThemeChoice.amoled || AppThemeChoice.midnight => ThemeMode.dark,
  };

  /// The palette that will actually be shown, given the platform's current
  /// light/dark setting. Used for the system bars, which are painted outside
  /// the widget tree that `MaterialApp` themes.
  AppPalette resolve(Brightness platformBrightness) {
    return switch (themeMode) {
      ThemeMode.light => lightPalette,
      ThemeMode.dark => darkPalette,
      ThemeMode.system =>
        platformBrightness == Brightness.dark ? darkPalette : lightPalette,
    };
  }

  ThemeSettings copyWith({
    AppThemeChoice? choice,
    AppDarkVariant? darkVariant,
  }) {
    return ThemeSettings(
      choice: choice ?? this.choice,
      darkVariant: darkVariant ?? this.darkVariant,
    );
  }

  /// Reads the stored preferences. Call this before `runApp` and feed the
  /// result into [initialThemeSettingsProvider] so the first frame already has
  /// the right theme. Loading it afterwards flashes the default palette.
  static Future<ThemeSettings> load(AppDatabase db) async {
    try {
      final choice = await db.getPreference(_kThemeChoiceKey);
      final variant = await db.getPreference(_kDarkVariantKey);
      return ThemeSettings(
        choice: AppThemeChoiceX.fromStorage(choice),
        darkVariant: AppDarkVariantX.fromStorage(variant),
      );
    } catch (e, st) {
      debugPrint('Failed to load theme settings: $e\n$st');
      return const ThemeSettings();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeSettings &&
      other.choice == choice &&
      other.darkVariant == darkVariant;

  @override
  int get hashCode => Object.hash(choice, darkVariant);
}

/// The settings as they were at startup. Overridden in `main` with the value
/// read from the database; the default here is what a fresh install gets.
final initialThemeSettingsProvider = Provider<ThemeSettings>(
  (ref) => const ThemeSettings(),
);

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
      ThemeSettingsNotifier.new,
    );

class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() => ref.read(initialThemeSettingsProvider);

  /// Applies the choice immediately and persists in the background, so the
  /// theme never lags behind the tap. Picking a specific dark palette also
  /// updates the remembered variant, so a later switch to "follow system"
  /// keeps the flavour the user just chose.
  Future<void> setChoice(AppThemeChoice choice) async {
    final variant = switch (choice) {
      AppThemeChoice.amoled => AppDarkVariant.amoled,
      AppThemeChoice.midnight => AppDarkVariant.midnight,
      AppThemeChoice.system || AppThemeChoice.light => state.darkVariant,
    };

    if (state.choice == choice && state.darkVariant == variant) return;
    state = state.copyWith(choice: choice, darkVariant: variant);
    await _persist();
  }

  Future<void> setDarkVariant(AppDarkVariant variant) async {
    if (state.darkVariant == variant) return;
    state = state.copyWith(darkVariant: variant);
    await _persist();
  }

  Future<void> _persist() async {
    final settings = state;
    try {
      final db = ref.read(databaseProvider);
      await db.setPreference(_kThemeChoiceKey, settings.choice.storageKey);
      await db.setPreference(_kDarkVariantKey, settings.darkVariant.storageKey);
    } catch (e, st) {
      // The in-memory choice still applies for this session; only persistence
      // failed, so don't disrupt the user with an error.
      debugPrint('Failed to save theme settings: $e\n$st');
    }
  }
}
