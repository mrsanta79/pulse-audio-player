import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/providers.dart';
import 'playlist_picker_sheet.dart';

/// The per-track overflow menu: like, and add to a playlist.
Future<void> showTrackOptionsSheet(
  BuildContext context,
  WidgetRef ref,
  Track track,
) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => _TrackOptions(
      track: track,
      // Closes over the *opening* context, not the sheet's: by the time this
      // runs the sheet is on its way out and its own context is going away.
      onAddToPlaylist: () {
        Navigator.pop(sheetContext);
        showAddToPlaylistSheet(context, ref, track);
      },
    ),
  );
}

class _TrackOptions extends ConsumerWidget {
  const _TrackOptions({required this.track, required this.onAddToPlaylist});

  final Track track;
  final VoidCallback onAddToPlaylist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final liked = ref.watch(isLikedProvider(track.id));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.surfaceHighlight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              track.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Text(
              track.artist,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              ),
              title: Text(liked ? 'Remove from likes' : 'Add to likes'),
              onTap: () async {
                await ref.read(databaseProvider).toggleLike(track.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Add to playlist'),
              onTap: onAddToPlaylist,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showAddToPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  Track track,
) {
  return showAddTracksToPlaylistSheet(context, ref, [track]);
}

/// Adds every track in [tracks] to a chosen (or freshly created) playlist.
/// Used for both single-track and whole-album "add to playlist" actions.
///
/// Playlists that already hold the tracks are marked as such, and tapping one
/// removes them again rather than silently doing nothing. The sheet stays open
/// and flips the row as you go, so a tap's effect is visible immediately.
Future<void> showAddTracksToPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  List<Track> tracks,
) async {
  if (tracks.isEmpty) return;

  final db = ref.read(databaseProvider);
  final playlists = await db.select(db.playlists).get();
  // Read alongside the playlists so the first frame already knows which ones
  // hold these tracks; the sheet keeps this up to date itself from then on.
  final memberCounts = await db.countTracksInPlaylists([
    for (final track in tracks) track.id,
  ]);

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    builder: (_) => PlaylistPickerSheet(
      db: db,
      tracks: tracks,
      playlists: playlists,
      memberCounts: memberCounts,
    ),
  );
}
