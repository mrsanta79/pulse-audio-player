import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/providers.dart';
import '../../../widgets/track_options_sheet.dart';
import 'now_playing_icon_button.dart';

/// Like and overflow, under the transport controls.
class NowPlayingActions extends ConsumerWidget {
  const NowPlayingActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackId = ref.watch(currentTrackIdProvider);
    final liked = trackId != null && ref.watch(isLikedProvider(trackId));
    // The queue's own copy of the row, so the options sheet gets real track
    // data rather than the media item's subset of it.
    final track = ref
        .watch(audioHandlerProvider)
        .trackForMediaItem(ref.watch(currentMediaItemProvider));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        NowPlayingIconButton(
          icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          onTap: trackId == null
              ? null
              : () => ref.read(databaseProvider).toggleLike(trackId),
        ),
        NowPlayingIconButton(
          icon: Icons.more_horiz_rounded,
          onTap: track == null
              ? null
              : () => showTrackOptionsSheet(context, ref, track),
        ),
      ],
    );
  }
}
