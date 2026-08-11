import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class PlayerUiNotifier extends StateNotifier<bool> {
  PlayerUiNotifier() : super(false);

  void expand() => state = true;
  void collapse() => state = false;
  void toggle() => state = !state;
}

final playerExpandedProvider = StateNotifierProvider<PlayerUiNotifier, bool>(
  (ref) => PlayerUiNotifier(),
);

/// Runs [play], then opens the full player only if nothing was loaded before,
/// i.e. the mini player wasn't on screen to begin with. Once the mini player is
/// up, starting another track leaves the user on the screen they're browsing.
///
/// The idle check has to happen before [play] loads the queue, which is why
/// this takes a callback instead of being called after the fact.
Future<void> playAndMaybeOpenPlayer(
  WidgetRef ref,
  FutureOr<void> Function() play,
) async {
  final wasIdle = ref.read(currentMediaItemProvider) == null;
  await play();
  if (wasIdle) ref.read(playerExpandedProvider.notifier).expand();
}

/// Plays [tracks] shuffled. Shuffle is turned on only if it wasn't already, so
/// a listener who likes it on doesn't get it toggled off by a "shuffle" button.
Future<void> shuffleAll(WidgetRef ref, List<Track> tracks) {
  if (tracks.isEmpty) return Future.value();
  return playAndMaybeOpenPlayer(ref, () async {
    final handler = ref.read(audioHandlerProvider);
    await handler.loadQueue(tracks);
    if (!handler.shuffleEnabled) await handler.toggleShuffle();
  });
}
