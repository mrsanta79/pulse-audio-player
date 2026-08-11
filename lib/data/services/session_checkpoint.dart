import 'dart:async';

import 'playback_session_store.dart';

/// What to persist, read at the moment the write actually happens rather than
/// when it was requested, so a debounced save records the latest position.
typedef SessionSnapshotReader =
    ({
      List<int> queueTrackIds,
      int currentIndex,
      Duration position,
      int repeatModeIndex,
      bool shuffleEnabled,
    })?
    Function();

/// Keeps the "resume where I left off" record up to date.
///
/// Writes are debounced, because the events that should trigger one (track
/// change, play, the duration arriving) tend to land together, and a periodic
/// checkpoint runs while playing so a process kill loses at most a few seconds.
class SessionCheckpoint {
  SessionCheckpoint({
    required PlaybackSessionStore? store,
    required SessionSnapshotReader read,
    required bool Function() isPlaying,
  }) : _store = store,
       _read = read {
    if (store == null) return;
    _ticker = Timer.periodic(_checkpointInterval, (_) {
      if (isPlaying()) save();
    });
  }

  static const _checkpointInterval = Duration(seconds: 5);
  static const _debounce = Duration(milliseconds: 700);

  final PlaybackSessionStore? _store;
  final SessionSnapshotReader _read;

  Timer? _ticker;
  Timer? _debounceTimer;

  /// Set while the saved session is being reloaded, so restoring doesn't
  /// immediately overwrite what it is restoring from.
  bool suspended = false;

  void save({bool immediate = false}) {
    if (_store == null || suspended) return;

    _debounceTimer?.cancel();
    if (immediate) {
      unawaited(_write());
    } else {
      _debounceTimer = Timer(_debounce, () => unawaited(_write()));
    }
  }

  Future<void> _write() async {
    final snapshot = _read();
    if (snapshot == null) return;
    try {
      await _store!.save(
        queueTrackIds: snapshot.queueTrackIds,
        currentIndex: snapshot.currentIndex,
        position: snapshot.position,
        repeatModeIndex: snapshot.repeatModeIndex,
        shuffleEnabled: snapshot.shuffleEnabled,
      );
    } catch (_) {
      // Losing a resume point must never take playback down with it.
    }
  }

  void dispose() {
    _ticker?.cancel();
    _debounceTimer?.cancel();
  }
}
