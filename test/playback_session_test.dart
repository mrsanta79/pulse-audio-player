import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_audio_player/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  Future<int> addTrack(String title, String path) {
    return db
        .into(db.tracks)
        .insert(TracksCompanion.insert(filePath: path, title: title));
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('returns null when nothing was ever saved', () async {
    expect(await db.getPlaybackSession(), isNull);
  });

  test('round-trips the queue, index, position and modes', () async {
    final a = await addTrack('A', '/music/a.mp3');
    final b = await addTrack('B', '/music/b.mp3');
    final c = await addTrack('C', '/music/c.mp3');

    await db.savePlaybackSession(
      queueTrackIds: [a, b, c],
      currentIndex: 1,
      position: const Duration(minutes: 1, seconds: 23),
      repeatModeIndex: 2,
      shuffleEnabled: true,
    );

    final session = await db.getPlaybackSession();
    expect(session, isNotNull);
    expect(session!.tracks.map((t) => t.title), ['A', 'B', 'C']);
    expect(session.currentIndex, 1);
    expect(session.position, const Duration(minutes: 1, seconds: 23));
    expect(session.repeatModeIndex, 2);
    expect(session.shuffleEnabled, isTrue);
  });

  test('saving twice replaces the previous session', () async {
    final a = await addTrack('A', '/music/a.mp3');
    final b = await addTrack('B', '/music/b.mp3');

    await db.savePlaybackSession(
      queueTrackIds: [a, b],
      currentIndex: 0,
      position: Duration.zero,
      repeatModeIndex: 0,
      shuffleEnabled: false,
    );
    await db.savePlaybackSession(
      queueTrackIds: [b],
      currentIndex: 0,
      position: const Duration(seconds: 5),
      repeatModeIndex: 0,
      shuffleEnabled: false,
    );

    final session = await db.getPlaybackSession();
    expect(session!.tracks.map((t) => t.title), ['B']);
    expect(session.position, const Duration(seconds: 5));
  });

  test(
    'drops tracks that left the library and keeps pointing at the same song',
    () async {
      final a = await addTrack('A', '/music/a.mp3');
      final b = await addTrack('B', '/music/b.mp3');
      final c = await addTrack('C', '/music/c.mp3');

      await db.savePlaybackSession(
        queueTrackIds: [a, b, c],
        currentIndex: 2,
        position: const Duration(seconds: 30),
        repeatModeIndex: 0,
        shuffleEnabled: false,
      );
      await (db.delete(db.tracks)..where((t) => t.id.equals(b))).go();

      final session = await db.getPlaybackSession();
      expect(session!.tracks.map((t) => t.title), ['A', 'C']);
      expect(session.currentIndex, 1);
      expect(session.position, const Duration(seconds: 30));
    },
  );

  test(
    'restarts the nearest surviving track when the saved one is gone',
    () async {
      final a = await addTrack('A', '/music/a.mp3');
      final b = await addTrack('B', '/music/b.mp3');

      await db.savePlaybackSession(
        queueTrackIds: [a, b],
        currentIndex: 1,
        position: const Duration(seconds: 30),
        repeatModeIndex: 0,
        shuffleEnabled: false,
      );
      await (db.delete(db.tracks)..where((t) => t.id.equals(b))).go();

      final session = await db.getPlaybackSession();
      expect(session!.tracks.map((t) => t.title), ['A']);
      expect(session.currentIndex, 0);
      expect(session.position, Duration.zero);
    },
  );

  test('returns null when the whole saved queue is gone', () async {
    final a = await addTrack('A', '/music/a.mp3');

    await db.savePlaybackSession(
      queueTrackIds: [a],
      currentIndex: 0,
      position: Duration.zero,
      repeatModeIndex: 0,
      shuffleEnabled: false,
    );
    await db.delete(db.tracks).go();

    expect(await db.getPlaybackSession(), isNull);
  });

  test('clearPlaybackSession removes the resume point', () async {
    final a = await addTrack('A', '/music/a.mp3');
    await db.savePlaybackSession(
      queueTrackIds: [a],
      currentIndex: 0,
      position: Duration.zero,
      repeatModeIndex: 0,
      shuffleEnabled: false,
    );

    await db.clearPlaybackSession();
    expect(await db.getPlaybackSession(), isNull);
  });
}
