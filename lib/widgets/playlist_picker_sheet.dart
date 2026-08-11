import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/providers.dart';
import 'name_prompt_dialog.dart';

/// The body of the "add to playlist" sheet.
///
/// Stateful because membership is the whole point of the sheet: adding or
/// removing has to redraw the row under the finger, not wait for the next time
/// the sheet is opened. It owns the counts rather than re-reading the database
/// on every change, since the writes it makes are the only thing that can move
/// them while the sheet is up.
class PlaylistPickerSheet extends StatefulWidget {
  const PlaylistPickerSheet({
    super.key,
    required this.db,
    required this.tracks,
    required this.playlists,
    required this.memberCounts,
  });

  final AppDatabase db;
  final List<Track> tracks;
  final List<Playlist> playlists;

  /// How many of [tracks] each playlist held when the sheet opened.
  final Map<int, int> memberCounts;

  @override
  State<PlaylistPickerSheet> createState() => _PlaylistPickerSheetState();
}

class _PlaylistPickerSheetState extends State<PlaylistPickerSheet> {
  late final List<Playlist> _playlists = List.of(widget.playlists);
  late final Map<int, int> _counts = Map.of(widget.memberCounts);

  /// Set while a write is in flight, so a second tap can't race the first one
  /// (double-tapping "remove" would otherwise re-add on the way back).
  bool _busy = false;

  List<int> get _trackIds => [for (final track in widget.tracks) track.id];

  Future<void> _toggle(Playlist playlist) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final allAdded = (_counts[playlist.id] ?? 0) == widget.tracks.length;
      // One statement for the whole album rather than one per track.
      if (allAdded) {
        await widget.db.removeTracksFromPlaylist(playlist.id, _trackIds);
      } else {
        await widget.db.addTracksToPlaylist(playlist.id, _trackIds);
      }
      if (!mounted) return;
      setState(() {
        if (allAdded) {
          _counts.remove(playlist.id);
        } else {
          _counts[playlist.id] = widget.tracks.length;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createAndAdd() async {
    if (_busy) return;
    final name = await promptForName(
      context,
      title: 'New playlist',
      hint: 'Playlist name',
    );
    if (name == null || !mounted) return;

    final id = await widget.db.createPlaylist(name);
    final playlist = await (widget.db.select(
      widget.db.playlists,
    )..where((p) => p.id.equals(id))).getSingle();
    if (!mounted) return;

    // Newest first, matching how playlists are listed elsewhere.
    setState(() => _playlists.insert(0, playlist));
    await _toggle(playlist);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Add to playlist',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: const Text('New playlist'),
              onTap: _createAndAdd,
            ),
            for (final playlist in _playlists)
              _PlaylistRow(
                playlist: playlist,
                already: _counts[playlist.id] ?? 0,
                total: widget.tracks.length,
                onTap: () => _toggle(playlist),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({
    required this.playlist,
    required this.already,
    required this.total,
    required this.onTap,
  });

  final Playlist playlist;

  /// How many of the sheet's tracks this playlist currently holds.
  final int already;
  final int total;
  final VoidCallback onTap;

  bool get _allAdded => already == total;

  /// Says what a tap will do, so the row's action is never a surprise.
  String? get _hint {
    if (_allAdded) {
      return total == 1
          ? 'Added. Tap to remove from playlist'
          : 'All $total songs added. Tap to remove them';
    }
    if (already > 0) {
      return '$already of $total already added. Tap to add the rest';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final hint = _hint;

    return ListTile(
      leading: Icon(
        _allAdded
            ? Icons.playlist_add_check_rounded
            : Icons.queue_music_rounded,
        color: _allAdded ? palette.accent : null,
      ),
      title: Text(playlist.name),
      subtitle: hint == null
          ? null
          : Text(
              hint,
              style: TextStyle(
                color: _allAdded ? palette.accent : palette.textSecondary,
                fontSize: 12,
              ),
            ),
      onTap: onTap,
    );
  }
}
