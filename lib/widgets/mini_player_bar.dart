import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/format.dart';
import '../data/repositories/providers.dart';
import 'album_art_with_glow.dart';
import 'mini_player_progress_button.dart';

/// The floating bar above the bottom nav.
///
/// Deliberately built from several small consumers rather than one: only the
/// timestamp and the progress ring follow the playhead, so only those two
/// rebuild as the track plays. The artwork, title and artist change once per
/// track.
class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final item = ref.watch(currentMediaItemProvider);
    if (item == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Material(
        color: palette.miniPlayer,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.only(left: 6, right: 8),
              child: Row(
                children: [
                  AlbumArtWithGlow(
                    artHash: item.extras?['albumArtHash'] as String?,
                    size: 44,
                    // Fully rounded (circular) art in the floating player.
                    borderRadius: 22,
                    showGlow: false,
                    heroTag: 'mini-art-${item.id}',
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Line(
                          text: item.title,
                          color: palette.miniPlayerFg,
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                        _Line(
                          text: item.artist ?? '',
                          color: palette.miniPlayerFg.withValues(alpha: 0.55),
                          size: 12,
                          weight: FontWeight.w500,
                        ),
                        const SizedBox(height: 3),
                        const _Elapsed(),
                      ],
                    ),
                  ),
                  _LikeButton(trackId: int.tryParse(item.id)),
                  const SizedBox(width: 4),
                  const MiniPlayerProgressButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.text,
    required this.color,
    required this.size,
    required this.weight,
  });

  final String text;
  final Color color;
  final double size;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontWeight: weight,
        fontSize: size,
        height: 1.1,
      ),
    );
  }
}

/// The only text in the bar that ticks.
class _Elapsed extends ConsumerWidget {
  const _Elapsed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playbackPositionProvider);
    final duration = ref.watch(playbackDurationProvider);
    final palette = AppColors.of(context);

    return Text(
      '${formatDuration(position)} / ${formatDuration(duration)}',
      maxLines: 1,
      style: TextStyle(
        color: palette.miniPlayerFg.withValues(alpha: 0.45),
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.1,
        // Keeps the row from twitching as the digits tick.
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _LikeButton extends ConsumerWidget {
  const _LikeButton({required this.trackId});

  final int? trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = trackId;
    final liked = id != null && ref.watch(isLikedProvider(id));

    return GestureDetector(
      onTap: id == null
          ? null
          : () => ref.read(databaseProvider).toggleLike(id),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: AppColors.of(context).miniPlayerFg,
          size: 20,
        ),
      ),
    );
  }
}
