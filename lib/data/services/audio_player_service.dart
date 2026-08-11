import 'dart:async';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../database/app_database.dart';
import 'notification_artwork.dart';
import 'playback_session_store.dart';
import 'player_state_snapshot.dart';
import 'session_checkpoint.dart';

export 'player_state_snapshot.dart';

Future<AppAudioHandler> initAudioService({
  required Future<Uint8List?> Function(String? hash) artLoader,
  PlaybackSessionStore? sessionStore,
}) {
  return AudioService.init(
    builder: () =>
        AppAudioHandler(artLoader: artLoader, sessionStore: sessionStore),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.pulse.audio_player.channel.audio',
      androidNotificationChannelName: 'Pulse Music',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class AppAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  AppAudioHandler({
    required Future<Uint8List?> Function(String? hash) artLoader,
    PlaybackSessionStore? sessionStore,
  }) : _artwork = NotificationArtwork(artLoader) {
    _checkpoint = SessionCheckpoint(
      store: sessionStore,
      read: _sessionSnapshot,
      isPlaying: () => _player.playing,
    );

    _subscriptions.addAll([
      _player.playbackEventStream.listen(_broadcastState),
      _player.currentIndexStream.listen(_onIndexChanged),
      _player.durationStream.listen((duration) {
        _updateCurrentMediaDuration(duration);
        _broadcastState(_player.playbackEvent);
      }),
      _player.playingStream.listen((_) => _checkpoint.save()),
      _player.processingStateStream
          .where((state) => state == ProcessingState.completed)
          .listen((_) => unawaited(_onQueueEnded())),
    ]);
  }

  /// Rewinding rather than skipping back, if the track is already this far in.
  static const _restartThreshold = Duration(seconds: 3);

  final NotificationArtwork _artwork;
  final AudioPlayer _player = AudioPlayer();
  final _subscriptions = <StreamSubscription<Object?>>[];

  final _repeatMode = BehaviorSubject.seeded(RepeatMode.off);
  final _shuffleEnabled = BehaviorSubject.seeded(false);
  final _duration = BehaviorSubject.seeded(Duration.zero);

  late final SessionCheckpoint _checkpoint;
  List<Track> _tracks = [];

  /// Guards [_onQueueEnded] against re-entering while its own seek settles.
  bool _rewinding = false;

  Stream<PlayerStateSnapshot> get playerSnapshotStream {
    return Rx.combineLatest6(
      queue,
      mediaItem,
      playbackState,
      _player.positionStream,
      _duration.stream,
      Rx.combineLatest2(
        _repeatMode.stream,
        _shuffleEnabled.stream,
        (RepeatMode repeat, bool shuffle) => (repeat, shuffle),
      ),
      (
        List<MediaItem> queue,
        MediaItem? item,
        PlaybackState state,
        Duration position,
        Duration duration,
        (RepeatMode, bool) modes,
      ) => PlayerStateSnapshot(
        queue: queue,
        mediaItem: item,
        playbackState: state,
        position: position,
        duration: duration,
        repeatMode: modes.$1,
        shuffleEnabled: modes.$2,
      ),
    );
  }

  bool get shuffleEnabled => _shuffleEnabled.value;

  void _onIndexChanged(int? index) {
    if (index == null || index < 0 || index >= queue.value.length) return;
    mediaItem.add(queue.value[index]);
    // Resolve notification artwork for the new track lazily (see loadQueue).
    unawaited(_resolveArtForIndex(index));
    _checkpoint.save();
  }

  void _updateCurrentMediaDuration(Duration? duration) {
    if (duration == null || duration <= Duration.zero) return;
    _duration.add(duration);

    final current = mediaItem.value;
    if (current == null || current.duration == duration) return;

    final updated = current.copyWith(duration: duration);
    mediaItem.add(updated);
    _replaceInQueue(current.id, updated);
  }

  void _replaceInQueue(String id, MediaItem updated) {
    final items = List<MediaItem>.from(queue.value);
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return;
    items[index] = updated;
    queue.add(items);
  }

  Future<void> loadQueue(
    List<Track> tracks, {
    int startIndex = 0,
    bool autoPlay = true,
    Duration initialPosition = Duration.zero,
  }) async {
    if (tracks.isEmpty) return;
    _tracks = List.of(tracks);

    // Build the queue without resolving notification artwork up front. Doing a
    // DB read + temp-file write per track here blocked playback for seconds on
    // large libraries; artwork is now filled in lazily per current track (the
    // in-app UI reads art straight from the DB, so this only affects the
    // system notification).
    final items = [for (final track in tracks) _mediaItemFor(track)];
    queue.add(items);

    final safeIndex = startIndex.clamp(0, items.length - 1);
    mediaItem.add(items[safeIndex]);

    await _player.setAudioSource(
      ConcatenatingAudioSource(
        children: [for (final t in tracks) AudioSource.file(t.filePath)],
      ),
      initialIndex: safeIndex,
      initialPosition: initialPosition,
    );
    await _player.setShuffleModeEnabled(_shuffleEnabled.value);
    await _applyLoopMode();

    _updateCurrentMediaDuration(_player.duration);
    if (autoPlay) await play();

    unawaited(_resolveArtForIndex(safeIndex));
    _checkpoint.save(immediate: true);
  }

  static MediaItem _mediaItemFor(Track track) {
    final ms = track.durationMs;
    return MediaItem(
      id: track.id.toString(),
      title: track.title,
      artist: track.artist,
      album: track.album,
      duration: ms != null ? Duration(milliseconds: ms) : null,
      extras: {
        'filePath': track.filePath,
        'albumArtHash': track.albumArtHash,
        'trackId': track.id,
      },
    );
  }

  /// Reloads the queue saved by a previous run, paused and seeked to where the
  /// listener stopped. Does nothing if something is already queued (the user
  /// started a song before the restore finished).
  Future<void> restoreSession(SavedPlaybackSession session) async {
    if (_tracks.isNotEmpty || session.tracks.isEmpty) return;

    _checkpoint.suspended = true;
    try {
      _repeatMode.add(
        RepeatMode.values[session.repeatModeIndex.clamp(
          0,
          RepeatMode.values.length - 1,
        )],
      );
      _shuffleEnabled.add(session.shuffleEnabled);
      await loadQueue(
        session.tracks,
        startIndex: session.currentIndex,
        autoPlay: false,
        initialPosition: session.position,
      );
    } finally {
      _checkpoint.suspended = false;
    }
  }

  /// Read at write time, so a debounced save records where playback actually
  /// got to rather than where it was when the save was asked for.
  ({
    List<int> queueTrackIds,
    int currentIndex,
    Duration position,
    int repeatModeIndex,
    bool shuffleEnabled,
  })?
  _sessionSnapshot() {
    if (_tracks.isEmpty) return null;
    return (
      queueTrackIds: [for (final track in _tracks) track.id],
      currentIndex: _player.currentIndex ?? 0,
      position: _player.position,
      repeatModeIndex: _repeatMode.value.index,
      shuffleEnabled: _shuffleEnabled.value,
    );
  }

  /// Resolves the notification artwork for a single queue entry in the
  /// background and patches it into the queue / current media item.
  Future<void> _resolveArtForIndex(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    final target = queue.value[index];
    if (target.artUri != null) return;

    final artUri = await _artwork.uriFor(
      target.extras?['albumArtHash'] as String?,
    );
    if (artUri == null) return;

    final updated = target.copyWith(artUri: artUri);
    _replaceInQueue(target.id, updated);
    if (mediaItem.value?.id == updated.id) mediaItem.add(updated);
  }

  Future<void> _applyLoopMode() {
    return _player.setLoopMode(switch (_repeatMode.value) {
      RepeatMode.off => LoopMode.off,
      RepeatMode.all => LoopMode.all,
      RepeatMode.one => LoopMode.one,
    });
  }

  /// The queue ran out with nothing left to repeat (only reachable on
  /// [RepeatMode.off]; the other modes loop instead of completing).
  ///
  /// just_audio leaves the player parked at the end of the last track with
  /// `playing` still true, which the UI reads as "paused at 100%" and the disc
  /// as "still spinning". Rewind to the top of the queue and stay stopped, so
  /// the next press of play starts the whole thing over from the first track.
  Future<void> _onQueueEnded() async {
    if (_rewinding) return;
    _rewinding = true;
    try {
      // Pause first: seeking while the player still considers itself playing
      // would start the first track over on its own.
      await _player.pause();
      final order = _player.effectiveIndices;
      await _player.seek(
        Duration.zero,
        index: order == null || order.isEmpty ? 0 : order.first,
      );
    } finally {
      _rewinding = false;
    }
    _broadcastState(_player.playbackEvent);
    _checkpoint.save(immediate: true);
  }

  Future<void> cycleRepeatMode() async {
    _repeatMode.add(_repeatMode.value.next);
    await _applyLoopMode();
    _broadcastState(_player.playbackEvent);
    _checkpoint.save();
  }

  Future<void> toggleShuffle() async {
    final enabled = !_shuffleEnabled.value;
    _shuffleEnabled.add(enabled);
    await _player.setShuffleModeEnabled(enabled);
    _broadcastState(_player.playbackEvent);
    _checkpoint.save();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  Future<void> playPause() => _player.playing ? pause() : play();

  @override
  Future<void> stop() async {
    // Save before stopping: the player resets its position on stop, and the
    // queue should still be resumable next launch.
    _checkpoint.save(immediate: true);
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _checkpoint.save();
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() async {
    // Well into the track, "previous" means "start this one again", which is
    // what every other player does.
    if (_player.position > _restartThreshold) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> onTaskRemoved() async {
    _checkpoint.save(immediate: true);
    await super.onTaskRemoved();
  }

  /// The library row behind a queue entry, for UI that needs more than the
  /// media item carries.
  Track? trackForMediaItem(MediaItem? item) {
    if (item == null) return null;
    final id = int.tryParse(item.id);
    if (id == null) return null;
    for (final track in _tracks) {
      if (track.id == id) return track;
    }
    return null;
  }

  Future<void> dispose() async {
    _checkpoint.dispose();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await Future.wait([
      _repeatMode.close(),
      _shuffleEnabled.close(),
      _duration.close(),
    ]);
    await _player.dispose();
  }

  static const _processingStates = {
    ProcessingState.idle: AudioProcessingState.idle,
    ProcessingState.loading: AudioProcessingState.loading,
    ProcessingState.buffering: AudioProcessingState.buffering,
    ProcessingState.ready: AudioProcessingState.ready,
    ProcessingState.completed: AudioProcessingState.completed,
  };

  void _broadcastState(PlaybackEvent event) {
    // A completed queue still reports `playing`, and _onQueueEnded takes a
    // moment to rewind it. Call it stopped from the first frame so the button
    // never flashes "pause" over a finished queue.
    final ended = _player.processingState == ProcessingState.completed;
    final playing = _player.playing && !ended;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _processingStates[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
        repeatMode: _repeatMode.value.asServiceMode,
        shuffleMode: _shuffleEnabled.value
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
      ),
    );
  }
}
