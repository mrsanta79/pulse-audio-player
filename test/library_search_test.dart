import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_audio_player/core/theme/app_theme.dart';
import 'package:pulse_audio_player/features/library/widgets/library_search_scaffold.dart';

void main() {
  const items = ['Radiohead', 'Ride', 'Slowdive', 'The Cure'];

  Widget harness({List<Widget> Function(List<String>)? actions}) {
    return MaterialApp(
      theme: AppTheme.from(AppPalette.amoled),
      home: LibrarySearchScaffold<String>(
        title: 'Artists',
        items: items,
        searchText: (artist) => artist,
        hintText: 'Search artists',
        noMatchesMessage: 'No artists match',
        actions: actions,
        builder: (context, filtered) =>
            ListView(children: [for (final artist in filtered) Text(artist)]),
      ),
    );
  }

  Future<void> openSearch(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
  }

  testWidgets('the field is hidden until the search icon is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Slowdive'), findsOneWidget);

    await openSearch(tester);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('typing filters the list case-insensitively', (tester) async {
    await tester.pumpWidget(harness());
    await openSearch(tester);

    await tester.enterText(find.byType(TextField), 'ri');
    await tester.pumpAndSettle();

    expect(find.text('Ride'), findsOneWidget);
    expect(find.text('Slowdive'), findsNothing);
    expect(find.text('Radiohead'), findsNothing);
  });

  testWidgets('every term has to match, in any order', (tester) async {
    await tester.pumpWidget(harness());
    await openSearch(tester);

    await tester.enterText(find.byType(TextField), 'cure the');
    await tester.pumpAndSettle();

    expect(find.text('The Cure'), findsOneWidget);
    expect(find.text('Ride'), findsNothing);
  });

  testWidgets('a query with no hits says so', (tester) async {
    await tester.pumpWidget(harness());
    await openSearch(tester);

    await tester.enterText(find.byType(TextField), 'oasis');
    await tester.pumpAndSettle();

    expect(find.text('No artists match'), findsOneWidget);
  });

  testWidgets('closing search restores the full list', (tester) async {
    await tester.pumpWidget(harness());
    await openSearch(tester);

    await tester.enterText(find.byType(TextField), 'ride');
    await tester.pumpAndSettle();
    expect(find.text('Slowdive'), findsNothing);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Slowdive'), findsOneWidget);
  });

  testWidgets('app bar actions see the filtered items, not all of them', (
    tester,
  ) async {
    late List<String> seen;
    await tester.pumpWidget(
      harness(
        actions: (filtered) {
          seen = filtered;
          return [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.shuffle_rounded),
            ),
          ];
        },
      ),
    );
    await openSearch(tester);

    await tester.enterText(find.byType(TextField), 'r');
    await tester.pumpAndSettle();

    expect(seen, ['Radiohead', 'Ride', 'The Cure']);
  });
}
