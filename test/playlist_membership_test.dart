import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_audio_player/data/repositories/database_provider.dart';
import 'package:pulse_audio_player/widgets/track_options_sheet.dart';

/// The "add to playlist" sheet used to look identical whether or not the
/// playlist already held the songs, and adding an already-present song was a
/// silent no-op. It now reports membership, offers the reverse action, and
/// updates the row as soon as it is tapped instead of on the next open.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<List<Track>> insertTracks(int count) async {
    for (var i = 0; i < count; i++) {
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(filePath: '/music/$i.mp3', title: 'Song $i'),
          );
    }
    return db.select(db.tracks).get();
  }

  Future<List<int>> trackIdsIn(int playlistId) async {
    final rows = await db.getPlaylistTracks(playlistId);
    return rows.map((t) => t.id).toList();
  }

  /// Opens the sheet for [tracks] from a host that supplies the overridden
  /// database, and settles the modal route.
  Future<void> openSheet(WidgetTester tester, List<Track> tracks) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      showAddTracksToPlaylistSheet(context, ref, tracks),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  test('countTracksInPlaylists reports overlap per playlist', () async {
    final tracks = await insertTracks(3);
    final mixed = await db.createPlaylist('Mixed');
    final empty = await db.createPlaylist('Empty');
    await db.addTrackToPlaylist(mixed, tracks[0].id);
    await db.addTrackToPlaylist(mixed, tracks[1].id);

    final counts = await db.countTracksInPlaylists(
      tracks.map((t) => t.id).toList(),
    );

    expect(counts[mixed], 2);
    // Playlists holding none of the tracks aren't in the map at all.
    expect(counts.containsKey(empty), isFalse);
  });

  testWidgets('a song already in a playlist offers removal instead', (
    tester,
  ) async {
    final tracks = await insertTracks(1);
    final playlistId = await db.createPlaylist('Favourites');
    await db.addTrackToPlaylist(playlistId, tracks.single.id);

    await openSheet(tester, tracks);

    expect(find.text('Added. Tap to remove from playlist'), findsOneWidget);

    await tester.tap(find.text('Favourites'));
    await tester.pumpAndSettle();

    expect(await trackIdsIn(playlistId), isEmpty);
  });

  testWidgets('adding flips the row to "remove" without reopening', (
    tester,
  ) async {
    final tracks = await insertTracks(1);
    final playlistId = await db.createPlaylist('Favourites');

    await openSheet(tester, tracks);
    expect(find.textContaining('tap to remove'), findsNothing);

    await tester.tap(find.text('Favourites'));
    await tester.pumpAndSettle();

    // Same sheet, still open, now showing the opposite action.
    expect(find.text('Added. Tap to remove from playlist'), findsOneWidget);
    expect(await trackIdsIn(playlistId), [tracks.single.id]);

    // And tapping again takes it straight back out.
    await tester.tap(find.text('Favourites'));
    await tester.pumpAndSettle();

    expect(find.textContaining('tap to remove'), findsNothing);
    expect(await trackIdsIn(playlistId), isEmpty);
  });

  testWidgets('a playlist holding none of the songs still adds', (
    tester,
  ) async {
    final tracks = await insertTracks(2);
    final playlistId = await db.createPlaylist('Favourites');

    await openSheet(tester, tracks);

    expect(find.textContaining('tap to remove'), findsNothing);

    await tester.tap(find.text('Favourites'));
    await tester.pumpAndSettle();

    expect(await trackIdsIn(playlistId), tracks.map((t) => t.id));
    expect(find.text('All 2 songs added. Tap to remove them'), findsOneWidget);
  });

  testWidgets('a part-added album adds only the songs that are missing', (
    tester,
  ) async {
    final tracks = await insertTracks(3);
    final playlistId = await db.createPlaylist('Favourites');
    await db.addTrackToPlaylist(playlistId, tracks.first.id);

    await openSheet(tester, tracks);

    expect(
      find.text('1 of 3 already added. Tap to add the rest'),
      findsOneWidget,
    );

    await tester.tap(find.text('Favourites'));
    await tester.pumpAndSettle();

    // The song that was already there isn't duplicated.
    expect(await trackIdsIn(playlistId), tracks.map((t) => t.id));
    expect(find.text('All 3 songs added. Tap to remove them'), findsOneWidget);
  });

  testWidgets('a fully added album can be removed in one tap', (tester) async {
    final tracks = await insertTracks(3);
    final playlistId = await db.createPlaylist('Favourites');
    for (final track in tracks) {
      await db.addTrackToPlaylist(playlistId, track.id);
    }

    await openSheet(tester, tracks);

    expect(find.text('All 3 songs added. Tap to remove them'), findsOneWidget);

    await tester.tap(find.text('Favourites'));
    await tester.pumpAndSettle();

    expect(await trackIdsIn(playlistId), isEmpty);
    expect(find.textContaining('tap to remove'), findsNothing);
  });

  testWidgets('a freshly created playlist is listed as already added', (
    tester,
  ) async {
    final tracks = await insertTracks(2);

    await openSheet(tester, tracks);

    await tester.tap(find.text('New playlist'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Road trip');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Road trip'), findsOneWidget);
    expect(find.text('All 2 songs added. Tap to remove them'), findsOneWidget);

    final created = await db.select(db.playlists).getSingle();
    expect(await trackIdsIn(created.id), tracks.map((t) => t.id));
  });

  testWidgets('the sheet closes on Done', (tester) async {
    final tracks = await insertTracks(1);
    await db.createPlaylist('Favourites');

    await openSheet(tester, tracks);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Add to playlist'), findsNothing);
  });
}
