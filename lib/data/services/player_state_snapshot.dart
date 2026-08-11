import 'package:audio_service/audio_service.dart';

enum RepeatMode { off, all, one }

/// Everything the UI needs about the player, as of one instant.
///
/// Re-emitted on every position tick, so widgets should watch the narrow
/// providers derived from it rather than the whole thing.
class PlayerStateSnapshot {
  final List<MediaItem> queue;
  final MediaItem? mediaItem;
  final PlaybackState playbackState;
  final Duration position;
  final Duration duration;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;

  const PlayerStateSnapshot({
    required this.queue,
    required this.mediaItem,
    required this.playbackState,
    required this.position,
    required this.duration,
    required this.repeatMode,
    required this.shuffleEnabled,
  });

  bool get playing => playbackState.playing;
}

extension RepeatModeX on RepeatMode {
  RepeatMode get next => switch (this) {
    RepeatMode.off => RepeatMode.all,
    RepeatMode.all => RepeatMode.one,
    RepeatMode.one => RepeatMode.off,
  };

  AudioServiceRepeatMode get asServiceMode => switch (this) {
    RepeatMode.off => AudioServiceRepeatMode.none,
    RepeatMode.all => AudioServiceRepeatMode.all,
    RepeatMode.one => AudioServiceRepeatMode.one,
  };
}
