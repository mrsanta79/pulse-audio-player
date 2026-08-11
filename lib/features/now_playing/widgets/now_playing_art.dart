import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/providers.dart';
import '../../../data/services/audio_player_service.dart';
import '../../../widgets/spinning_disc_art.dart';

/// The spinning disc, with the gestures that act on it: swipe across for
/// prev/next, double-tap to pause or resume.
///
/// This one *does* take the position, because the disc uses it to tell a fresh
/// start from a resume. The disc keeps its own cached raster, so the rebuild
/// costs a transform rather than a repaint of the artwork.
class NowPlayingArt extends ConsumerStatefulWidget {
  const NowPlayingArt({super.key, required this.width});

  final double width;

  @override
  ConsumerState<NowPlayingArt> createState() => _NowPlayingArtState();
}

class _NowPlayingArtState extends ConsumerState<NowPlayingArt> {
  /// How far across the disc must be dragged to count as a skip.
  static const _skipDragDistance = 60.0;

  double _dragDx = 0;

  void _onDragEnd(AppAudioHandler handler) {
    if (_dragDx < -_skipDragDistance) {
      handler.skipToNext();
    } else if (_dragDx > _skipDragDistance) {
      handler.skipToPrevious();
    }
    _dragDx = 0;
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(audioHandlerProvider);
    final item = ref.watch(currentMediaItemProvider);
    if (item == null) return const SizedBox.shrink();

    return Center(
      child: GestureDetector(
        onDoubleTap: handler.playPause,
        onHorizontalDragUpdate: (details) => _dragDx += details.delta.dx,
        onHorizontalDragEnd: (_) => _onDragEnd(handler),
        child: SizedBox(
          width: widget.width,
          child: SpinningDiscArt(
            artHash: ref.watch(currentArtHashProvider),
            spinning: ref.watch(isPlayingProvider),
            trackKey: item.id,
            position: ref.watch(playbackPositionProvider),
            heroTag: 'now-playing-art-${item.id}',
          ),
        ),
      ),
    );
  }
}
