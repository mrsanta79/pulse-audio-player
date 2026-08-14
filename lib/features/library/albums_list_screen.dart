import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/album_art_with_glow.dart';
import 'widgets/library_search_scaffold.dart';

class AlbumsListScreen extends ConsumerWidget {
  const AlbumsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(albumsProvider).valueOrNull ?? const [];
    // Landscape is short and wide: two columns there would put a single row of
    // tall tiles on screen, both of them cut off. Four narrower columns fit a
    // full row with the next one peeking, which also reads as scrollable.
    final columns =
        MediaQuery.orientationOf(context) == Orientation.landscape ? 4 : 2;

    return LibrarySearchScaffold<AlbumSummary>(
      title: 'Albums',
      items: albums,
      searchText: (album) => '${album.album} ${album.artist}',
      hintText: 'Search albums',
      noMatchesMessage: 'No albums match',
      builder: (context, filtered) => GridView.builder(
        padding: AppSpacing.listPaddingBelowHeader,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.78,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _AlbumGridItem(album: filtered[index]),
      ),
    );
  }
}

class _AlbumGridItem extends StatelessWidget {
  const _AlbumGridItem({required this.album});

  final AlbumSummary album;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return GestureDetector(
      onTap: () => context.push(albumRoute(album.album, album.artist)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AlbumArtWithGlow(
              artHash: album.albumArtHash,
              showGlow: false,
            ),
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
    );
  }
}
