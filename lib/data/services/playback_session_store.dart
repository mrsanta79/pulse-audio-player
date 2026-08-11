import '../database/app_database.dart';

/// Persistence hook for the "resume where I left off" session. Kept as an
/// interface so the audio handler does not depend on the database directly
/// (and so tests can supply a fake).
abstract class PlaybackSessionStore {
  Future<void> save({
    required List<int> queueTrackIds,
    required int currentIndex,
    required Duration position,
    required int repeatModeIndex,
    required bool shuffleEnabled,
  });

  Future<void> clear();
}

class DatabasePlaybackSessionStore implements PlaybackSessionStore {
  DatabasePlaybackSessionStore(this._db);

  final AppDatabase _db;

  @override
  Future<void> save({
    required List<int> queueTrackIds,
    required int currentIndex,
    required Duration position,
    required int repeatModeIndex,
    required bool shuffleEnabled,
  }) {
    return _db.savePlaybackSession(
      queueTrackIds: queueTrackIds,
      currentIndex: currentIndex,
      position: position,
      repeatModeIndex: repeatModeIndex,
      shuffleEnabled: shuffleEnabled,
    );
  }

  @override
  Future<void> clear() => _db.clearPlaybackSession();
}
