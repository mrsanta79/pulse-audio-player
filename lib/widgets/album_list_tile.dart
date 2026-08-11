import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/routes.dart';
import '../data/repositories/providers.dart';
import 'album_art_with_glow.dart';
import 'track_tile.dart';

/// One album as a list row (cover, name, artist and song count), as shown under
/// "Recent albums" and in album search results. The grid form on the Albums
/// page is a different shape and stays where it is.
class AlbumListTile extends StatelessWidget {
  const AlbumListTile({super.key, required this.album});

  final AlbumSummary album;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AlbumArtWithGlow(
        artHash: album.albumArtHash,
        size: TrackTile.artSize,
        borderRadius: TrackTile.artRadius,
        showGlow: false,
      ),
      title: Text(album.album, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${album.artist} • ${album.songCount} songs'),
      onTap: () => context.push(albumRoute(album.album, album.artist)),
    );
  }
}
