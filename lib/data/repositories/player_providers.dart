import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio_player_service.dart';

final audioHandlerProvider = Provider<AppAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main');
});

/// The full player state. This re-emits on **every position tick** (several
/// times a second), so watching it directly rebuilds the watcher at that rate.
///
/// Only widgets that genuinely draw the playhead should use it. Everything else
/// should watch one of the narrow providers below, each of which re-emits only
/// when that particular value changes: a screen that shows the track title has
/// no business rebuilding 5 times a second.
final playerSnapshotProvider = StreamProvider<PlayerStateSnapshot>((ref) {
  return ref.watch(audioHandlerProvider).playerSnapshotStream;
});

/// The playing track, or null when nothing is loaded. Stable across position
/// ticks: the handler hands out the same instance until the track changes.
final currentMediaItemProvider = Provider<MediaItem?>((ref) {
  return ref.watch(
    playerSnapshotProvider.select((s) => s.valueOrNull?.mediaItem),
  );
});

/// Whether anything is loaded at all. Drives the mini player's presence.
final hasMediaProvider = Provider<bool>((ref) {
  return ref.watch(currentMediaItemProvider) != null;
});

final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(
    playerSnapshotProvider.select((s) => s.valueOrNull?.playing ?? false),
  );
});

/// The playing track's library id, or null when nothing is loaded (or the id
/// isn't parseable, which shouldn't happen for queues we built ourselves).
final currentTrackIdProvider = Provider<int?>((ref) {
  final id = ref.watch(currentMediaItemProvider)?.id;
  return id == null ? null : int.tryParse(id);
});

final currentArtHashProvider = Provider<String?>((ref) {
  return ref.watch(currentMediaItemProvider)?.extras?['albumArtHash']
      as String?;
});

/// The playhead. Watching this *does* rebuild on every tick, by design.
final playbackPositionProvider = Provider<Duration>((ref) {
  return ref.watch(
    playerSnapshotProvider.select(
      (s) => s.valueOrNull?.position ?? Duration.zero,
    ),
  );
});

/// The playing track's length. Falls back to the duration stored on the media
/// item until the player has decoded the file and reported the real one.
final playbackDurationProvider = Provider<Duration>((ref) {
  final decoded = ref.watch(
    playerSnapshotProvider.select(
      (s) => s.valueOrNull?.duration ?? Duration.zero,
    ),
  );
  if (decoded > Duration.zero) return decoded;
  return ref.watch(currentMediaItemProvider)?.duration ?? Duration.zero;
});

final repeatModeProvider = Provider<RepeatMode>((ref) {
  return ref.watch(
    playerSnapshotProvider.select(
      (s) => s.valueOrNull?.repeatMode ?? RepeatMode.off,
    ),
  );
});

final shuffleEnabledProvider = Provider<bool>((ref) {
  return ref.watch(
    playerSnapshotProvider.select(
      (s) => s.valueOrNull?.shuffleEnabled ?? false,
    ),
  );
});

/// The queue, for the queue sheet. Stable across position ticks.
final playerQueueProvider = Provider<List<MediaItem>>((ref) {
  return ref.watch(
    playerSnapshotProvider.select((s) => s.valueOrNull?.queue ?? const []),
  );
});
