import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/player_ui_provider.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/track_options_sheet.dart';

/// Likes or unlikes a whole album.
///
/// One statement for the lot: this used to read and write per track, so a
/// twenty-track album meant forty serial round trips before the heart filled in.
Future<void> toggleAlbumLike(
  BuildContext context,
  WidgetRef ref,
  List<Track> tracks, {
  required bool allLiked,
}) async {
  if (tracks.isEmpty) return;

  await ref.read(databaseProvider).setLikes([
    for (final track in tracks) track.id,
  ], liked: !allLiked);

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        allLiked ? 'Removed from liked songs' : 'Added to liked songs',
      ),
    ),
  );
}

Future<void> showAlbumOptionsSheet(
  BuildContext context,
  WidgetRef ref, {
  required String album,
  required List<Track> tracks,
  required bool allLiked,
}) {
  if (tracks.isEmpty) return Future.value();

  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(
            album,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.play_arrow_rounded),
            title: const Text('Play album'),
            onTap: () {
              Navigator.pop(sheetContext);
              playAndMaybeOpenPlayer(
                ref,
                () => ref.read(audioHandlerProvider).loadQueue(tracks),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add_rounded),
            title: const Text('Add to playlist'),
            onTap: () {
              Navigator.pop(sheetContext);
              showAddTracksToPlaylistSheet(context, ref, tracks);
            },
          ),
          ListTile(
            leading: Icon(
              allLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            ),
            title: Text(
              allLiked ? 'Remove from liked songs' : 'Add to liked songs',
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              toggleAlbumLike(context, ref, tracks, allLiked: allLiked);
            },
          ),
        ],
      ),
    ),
  );
}
