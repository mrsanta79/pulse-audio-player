import 'package:drift/drift.dart';

import '../app_database.dart';

/// The resume-where-you-left-off session and the generic preference store.
extension SessionQueries on AppDatabase {
  /// Reads a single preference, or null if it was never set.
  Future<String?> getPreference(String key) async {
    final row = await (select(
      preferences,
    )..where((p) => p.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setPreference(String key, String value) {
    return into(preferences).insertOnConflictUpdate(
      PreferencesCompanion.insert(key: key, value: value),
    );
  }

  Future<void> savePlaybackSession({
    required List<int> queueTrackIds,
    required int currentIndex,
    required Duration position,
    required int repeatModeIndex,
    required bool shuffleEnabled,
  }) async {
    await into(playbackSessions).insertOnConflictUpdate(
      PlaybackSessionsCompanion.insert(
        id: const Value(0),
        queueTrackIds: queueTrackIds.join(','),
        currentIndex: Value(currentIndex),
        positionMs: Value(position.inMilliseconds),
        repeatMode: Value(repeatModeIndex),
        shuffleEnabled: Value(shuffleEnabled),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> clearPlaybackSession() async {
    await (delete(playbackSessions)..where((s) => s.id.equals(0))).go();
  }

  /// Reads the last saved session. Queue entries whose track has since been
  /// removed from the library are dropped, and the saved index is shifted to
  /// keep pointing at the same song. Returns null when nothing is resumable.
  Future<SavedPlaybackSession?> getPlaybackSession() async {
    final row = await (select(
      playbackSessions,
    )..where((s) => s.id.equals(0))).getSingleOrNull();
    if (row == null) return null;

    final ids = row.queueTrackIds
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
    if (ids.isEmpty) return null;

    final rows = await (select(tracks)..where((t) => t.id.isIn(ids))).get();
    final byId = {for (final track in rows) track.id: track};

    final restored = <Track>[];
    var currentIndex = 0;
    for (var i = 0; i < ids.length; i++) {
      final track = byId[ids[i]];
      if (track == null) continue;
      if (i <= row.currentIndex) currentIndex = restored.length;
      restored.add(track);
    }
    if (restored.isEmpty) return null;

    // If the saved current track itself is gone we land on the nearest
    // surviving earlier track, so playback resumes from its start.
    final savedIndexInRange =
        row.currentIndex >= 0 && row.currentIndex < ids.length;
    final savedTrackSurvived =
        savedIndexInRange && byId.containsKey(ids[row.currentIndex]);

    return SavedPlaybackSession(
      tracks: restored,
      currentIndex: currentIndex.clamp(0, restored.length - 1),
      position: savedTrackSurvived
          ? Duration(milliseconds: row.positionMs)
          : Duration.zero,
      repeatModeIndex: row.repeatMode,
      shuffleEnabled: row.shuffleEnabled,
    );
  }
}
