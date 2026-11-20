import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pulse_audio_player/core/theme/app_theme.dart';
import 'package:pulse_audio_player/data/repositories/database_provider.dart';
import 'package:pulse_audio_player/features/library/mood_detail_screen.dart';
import 'package:pulse_audio_player/features/library/moods_list_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Track> insertTrack(String title) async {
    final id = await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(filePath: '/music/$title.mp3', title: title),
        );
    return (await (db.select(
      db.tracks,
    )..where((track) => track.id.equals(id))).getSingle());
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  }

  test(
    'mood assignments persist and update their grouped song lists',
    () async {
      final happy = await insertTrack('Sunny');
      final chill = await insertTrack('Quiet');
      await db.saveTrackMoods(happy.id, 'one', ['happy', 'cheerful']);
      await db.saveTrackMoods(chill.id, 'two', ['chill']);

      expect(await db.getMoodCounts(), [
        const MoodCount('cheerful', 1),
        const MoodCount('chill', 1),
        const MoodCount('happy', 1),
      ]);

      await db.saveTrackMoods(happy.id, 'updated', ['sad']);
      expect(await db.getTrackMoodHashes(), {
        happy.id: 'updated',
        chill.id: 'two',
      });
      expect(await db.watchTracksByMood('happy').first, isEmpty);
      expect((await db.watchTracksByMood('sad').first).single.title, 'Sunny');
    },
  );

  testWidgets('mood catalog shows colored options and opens song lists', (
    tester,
  ) async {
    final song = await insertTrack('Bright Day');
    await db.saveTrackMoods(song.id, 'hash', ['happy']);
    final router = GoRouter(
      initialLocation: '/moods',
      routes: [
        GoRoute(path: '/moods', builder: (_, _) => const MoodsListScreen()),
        GoRoute(
          path: '/mood',
          builder: (_, state) => MoodDetailScreen(
            moodId: state.uri.queryParameters['value'] ?? '',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(
          theme: AppTheme.from(AppPalette.amoled),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Happy'), findsOneWidget);
    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      3,
    );
    await tester.tap(find.text('Happy'));
    await tester.pumpAndSettle();
    expect(find.text('Bright Day'), findsOneWidget);

    await close(tester);
  });
}
