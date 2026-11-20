import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_audio_player/core/theme/app_theme.dart';
import 'package:pulse_audio_player/features/settings/widgets/scan_buttons.dart';

void main() {
  testWidgets('shows separate add, rescan and categorize actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.from(AppPalette.amoled),
        home: Scaffold(
          body: ScanButtons(
            scanning: false,
            onAddFolder: () {},
            onRescan: () {},
            onCategorizeMoods: () {},
          ),
        ),
      ),
    );

    expect(find.text('Add folder'), findsOneWidget);
    expect(find.text('Rescan'), findsOneWidget);
    expect(find.text('Categorize moods'), findsOneWidget);
  });

  testWidgets('disables all actions while a mood run is active', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.from(AppPalette.amoled),
        home: Scaffold(
          body: ScanButtons(
            scanning: true,
            onAddFolder: () {},
            onRescan: () {},
            onCategorizeMoods: () {},
          ),
        ),
      ),
    );

    final addFolder = tester.widget<FilledButton>(find.byType(FilledButton));
    final actions = tester.widgetList<OutlinedButton>(
      find.byType(OutlinedButton),
    );
    expect(addFolder.onPressed, isNull);
    expect(actions.every((button) => button.onPressed == null), isTrue);
  });
}
