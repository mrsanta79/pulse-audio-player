import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/providers.dart';
import '../../../widgets/album_art_with_glow.dart';

/// Horizontally scrolling album covers on Home.
class AlbumShelf extends StatelessWidget {
  const AlbumShelf({super.key, required this.albums, this.maxAlbums = 12});

  final List<AlbumSummary> albums;
  final int maxAlbums;

  @override
  Widget build(BuildContext context) {
    final count = albums.length < maxAlbums ? albums.length : maxAlbums;

    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) => _AlbumCard(album: albums[index]),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album});

  final AlbumSummary album;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return GestureDetector(
      onTap: () => context.push(albumRoute(album.album, album.artist)),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AlbumArtWithGlow(
              artHash: album.albumArtHash,
              size: 130,
              showGlow: false,
            ),
            const SizedBox(height: 8),
            Text(
              album.album,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              album.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
