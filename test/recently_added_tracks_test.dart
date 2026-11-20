import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_audio_player/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('recently added tracks are newest-first and limited to 50', () async {
    final baseTime = DateTime(2026, 1, 1);
    for (var index = 0; index < 55; index++) {
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              filePath: '/music/$index.mp3',
              title: 'Song $index',
              addedAt: Value(baseTime.add(Duration(minutes: index))),
            ),
          );
    }

    final tracks = await db.watchRecentlyAddedTracks().first;

    expect(tracks, hasLength(50));
    expect(tracks.first.title, 'Song 54');
    expect(tracks.last.title, 'Song 5');
  });
}
