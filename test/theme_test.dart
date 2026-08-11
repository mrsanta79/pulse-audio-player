import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_audio_player/core/theme/app_theme.dart';
import 'package:pulse_audio_player/data/repositories/database_provider.dart';
import 'package:pulse_audio_player/data/repositories/theme_provider.dart';
import 'package:pulse_audio_player/features/settings/widgets/appearance_section.dart';

void main() {
  group('ThemeSettings resolution', () {
    test('defaults to AMOLED so existing installs look unchanged', () {
      const settings = ThemeSettings();
      expect(settings.choice, AppThemeChoice.amoled);
      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.darkPalette, AppPalette.amoled);
    });

    test('an explicit dark choice overrides the remembered variant', () {
      const settings = ThemeSettings(
        choice: AppThemeChoice.midnight,
        darkVariant: AppDarkVariant.amoled,
      );
      expect(settings.darkPalette, AppPalette.midnight);
      expect(settings.resolve(Brightness.light), AppPalette.midnight);
    });

    test('following the system honours the chosen dark variant', () {
      const settings = ThemeSettings(
        choice: AppThemeChoice.system,
        darkVariant: AppDarkVariant.midnight,
      );
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.resolve(Brightness.dark), AppPalette.midnight);
      expect(settings.resolve(Brightness.light), AppPalette.light);
    });

    test('light ignores the platform brightness', () {
      const settings = ThemeSettings(choice: AppThemeChoice.light);
      expect(settings.resolve(Brightness.dark), AppPalette.light);
      expect(settings.resolve(Brightness.light), AppPalette.light);
    });
  });

  group('storage keys', () {
    test('round-trip through their persisted form', () {
      for (final choice in AppThemeChoice.values) {
        expect(AppThemeChoiceX.fromStorage(choice.storageKey), choice);
      }
      for (final variant in AppDarkVariant.values) {
        expect(AppDarkVariantX.fromStorage(variant.storageKey), variant);
      }
    });

    test('unknown or missing values fall back to the default', () {
      expect(AppThemeChoiceX.fromStorage(null), AppThemeChoice.amoled);
      expect(AppThemeChoiceX.fromStorage('solarized'), AppThemeChoice.amoled);
      expect(AppDarkVariantX.fromStorage(null), AppDarkVariant.amoled);
    });
  });

  group('persistence', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('loads the default when nothing was ever saved', () async {
      expect(await ThemeSettings.load(db), const ThemeSettings());
    });

    test('a chosen theme survives a restart', () async {
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      await container
          .read(themeSettingsProvider.notifier)
          .setChoice(AppThemeChoice.midnight);

      // A fresh load stands in for the next app launch.
      final reloaded = await ThemeSettings.load(db);
      expect(reloaded.choice, AppThemeChoice.midnight);
      expect(reloaded.darkPalette, AppPalette.midnight);
    });

    test(
      'picking a dark palette is remembered when switching to system',
      () async {
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)],
        );
        addTearDown(container.dispose);

        final controller = container.read(themeSettingsProvider.notifier);
        await controller.setChoice(AppThemeChoice.midnight);
        await controller.setChoice(AppThemeChoice.system);

        final reloaded = await ThemeSettings.load(db);
        expect(reloaded.choice, AppThemeChoice.system);
        // Still midnight, rather than snapping back to the AMOLED default.
        expect(reloaded.darkVariant, AppDarkVariant.midnight);
        expect(reloaded.resolve(Brightness.dark), AppPalette.midnight);
      },
    );

    test('the dark variant can be changed on its own', () async {
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final controller = container.read(themeSettingsProvider.notifier);
      await controller.setChoice(AppThemeChoice.system);
      await controller.setDarkVariant(AppDarkVariant.midnight);

      expect(
        (await ThemeSettings.load(db)).darkVariant,
        AppDarkVariant.midnight,
      );
    });
  });

  group('AppTheme', () {
    // testWidgets, not test: building a theme kicks off google_fonts' async
    // font resolution, which fails without a network. Inside testWidgets that
    // future never gets to run, so it can't fail a test that already finished.
    testWidgets('carries its palette so AppColors.of can read it back', (
      tester,
    ) async {
      for (final palette in [
        AppPalette.light,
        AppPalette.amoled,
        AppPalette.midnight,
      ]) {
        final theme = AppTheme.from(palette);
        expect(theme.extension<AppPalette>(), same(palette));
        expect(theme.brightness, palette.brightness);
        expect(theme.scaffoldBackgroundColor, palette.background);
      }
    });

    testWidgets('AppColors.of returns the installed palette', (tester) async {
      late AppPalette seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.from(AppPalette.midnight),
          home: Builder(
            builder: (context) {
              seen = AppColors.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, AppPalette.midnight);
    });

    testWidgets('falls back to AMOLED when no palette is installed', (
      tester,
    ) async {
      late AppPalette seen;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              seen = AppColors.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, AppPalette.amoled);
    });
  });

  group('AppearanceSection', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Widget harness() {
      return ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(themeSettingsProvider);
            return MaterialApp(
              theme: AppTheme.from(settings.lightPalette),
              darkTheme: AppTheme.from(settings.darkPalette),
              themeMode: settings.themeMode,
              home: const Scaffold(
                body: SingleChildScrollView(child: AppearanceSection()),
              ),
            );
          },
        ),
      );
    }

    testWidgets('tapping an option repaints the app in that theme', (
      tester,
    ) async {
      await tester.pumpWidget(harness());

      final scaffold = find.byType(Scaffold);
      expect(
        Theme.of(tester.element(scaffold)).scaffoldBackgroundColor,
        AppPalette.amoled.background,
      );

      await tester.tap(find.text(AppThemeChoice.light.label));
      await tester.pumpAndSettle();

      expect(
        Theme.of(tester.element(scaffold)).scaffoldBackgroundColor,
        AppPalette.light.background,
      );
    });

    testWidgets('the dark variant selector appears only for system', (
      tester,
    ) async {
      await tester.pumpWidget(harness());
      expect(find.text('Dark variant'), findsNothing);

      await tester.tap(find.text(AppThemeChoice.system.label));
      await tester.pumpAndSettle();
      expect(find.text('Dark variant'), findsOneWidget);

      await tester.tap(find.text(AppThemeChoice.amoled.label));
      await tester.pumpAndSettle();
      expect(find.text('Dark variant'), findsNothing);
    });

    testWidgets('every theme option is listed', (tester) async {
      await tester.pumpWidget(harness());
      for (final choice in AppThemeChoice.values) {
        expect(find.text(choice.label), findsOneWidget);
      }
    });
  });
}
