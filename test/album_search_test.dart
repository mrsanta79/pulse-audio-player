import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_audio_player/data/repositories/providers.dart';
import 'package:pulse_audio_player/features/album/album_detail_screen.dart';

/// The album page's search icon used to jump to the global Search tab. It now
/// filters the album's own song list.
///
/// Note the deliberate absence of `pumpAndSettle` once the field is open: a
/// focused text field blinks its caret forever, so nothing ever settles.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> insertAlbum() async {
    const titles = ['Airbag', 'Karma Police', 'No Surprises'];
    for (var i = 0; i < titles.length; i++) {
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              filePath: '/music/$i.mp3',
              title: titles[i],
              artist: const Value('Radiohead'),
              album: const Value('OK Computer'),
              trackNumber: Value(i + 1),
            ),
          );
    }
  }

  Future<void> openAlbum(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          // Stand in for the audio handler, which the rows consult for the
          // playing-row highlight and which has no test double.
          currentTrackIdProvider.overrideWithValue(null),
          isPlayingProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: AlbumDetailScreen(album: 'OK Computer', artist: 'Radiohead'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSearch(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump();
  }

  Future<void> type(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump();
  }

  /// Tears the tree down inside the test so drift's stream-close timer, which
  /// riverpod fires when the scope disposes, runs before the framework checks
  /// for pending timers.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets('the album list filters as the query is typed', (tester) async {
    await insertAlbum();
    await openAlbum(tester);

    expect(find.text('Karma Police'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await openSearch(tester);
    await type(tester, 'karma');

    expect(find.text('Karma Police'), findsOneWidget);
    expect(find.text('Airbag'), findsNothing);
    expect(find.text('No Surprises'), findsNothing);

    await close(tester);
  });

  testWidgets('a query with no hits says so, and closing restores the album', (
    tester,
  ) async {
    await insertAlbum();
    await openAlbum(tester);

    await openSearch(tester);
    await type(tester, 'creep');

    expect(find.text('No songs match'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Airbag'), findsOneWidget);
    expect(find.text('No Surprises'), findsOneWidget);

    await close(tester);
  });
}
