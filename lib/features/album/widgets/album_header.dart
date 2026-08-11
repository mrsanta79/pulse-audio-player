import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/providers.dart';
import '../../../widgets/album_art_with_glow.dart';
import '../../../widgets/track_options_sheet.dart';
import '../album_actions.dart';
import 'album_pill_icon.dart';

/// Artwork, title block and the three small pill actions at the top of an
/// album page.
class AlbumHeader extends ConsumerWidget {
  const AlbumHeader({
    super.key,
    required this.album,
    required this.artist,
    required this.tracks,
    required this.allLiked,
  });

  final String album;
  final String artist;
  final List<Track> tracks;
  final bool allLiked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final artHash = tracks.isNotEmpty ? tracks.first.albumArtHash : null;
    final year = _latestYear(tracks);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        8,
        AppSpacing.pageH,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlbumArtWithGlow(artHash: artHash, size: 110, showGlow: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Album  •  ${tracks.length} songs'
                  '${year != null ? '  •  $year' : ''}',
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  album,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  artist,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AlbumPillIcon(
                      icon: Icons.playlist_add_rounded,
                      onTap: () =>
                          showAddTracksToPlaylistSheet(context, ref, tracks),
                    ),
                    const SizedBox(width: 8),
                    AlbumPillIcon(
                      icon: allLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      onTap: () => toggleAlbumLike(
                        context,
                        ref,
                        tracks,
                        allLiked: allLiked,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AlbumPillIcon(
                      icon: Icons.more_horiz_rounded,
                      onTap: () => showAlbumOptionsSheet(
                        context,
                        ref,
                        album: album,
                        tracks: tracks,
                        allLiked: allLiked,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compilations can carry several years; the newest is the one shown.
  static int? _latestYear(List<Track> tracks) {
    int? latest;
    for (final track in tracks) {
      final year = track.year;
      if (year != null && (latest == null || year > latest)) latest = year;
    }
    return latest;
  }
}
