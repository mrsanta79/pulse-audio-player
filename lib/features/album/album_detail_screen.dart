import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/search_filter.dart';
import '../../data/repositories/player_ui_provider.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/search_field.dart';
import '../../widgets/track_list_tile.dart';
import '../../widgets/track_options_sheet.dart';
import 'widgets/album_action_pill.dart';
import 'widgets/album_header.dart';

class AlbumDetailScreen extends ConsumerStatefulWidget {
  const AlbumDetailScreen({
    super.key,
    required this.album,
    required this.artist,
  });

  final String album;
  final String artist;

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  bool _searching = false;
  String _query = '';

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      // Closing drops the query along with the field, so no filter can outlive
      // the input that explains it.
      if (!_searching) _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    // A database *stream*, not a query kicked off from build: this screen
    // rebuilds whenever the playing track or the likes change, and a future
    // created here would re-run the query every one of those times.
    final tracksAsync = ref.watch(
      albumTracksProvider((album: widget.album, artist: widget.artist)),
    );
    final tracks = tracksAsync.valueOrNull ?? const <Track>[];

    final likedIds = ref.watch(likedTrackIdsProvider);
    final allLiked =
        tracks.isNotEmpty && tracks.every((t) => likedIds.contains(t.id));

    // The header and its like-all button stay about the album as a whole; the
    // song list and the play buttons follow the query.
    final filtered = filterBySearchQuery(
      tracks,
      _query,
      (track) => '${track.title} ${track.artist}',
    );

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        // The back button is the theme's (a chevron, see AppTheme._actionIcon).
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            tooltip: _searching ? 'Close search' : 'Search this album',
            onPressed: tracks.isEmpty ? null : _toggleSearch,
          ),
        ],
      ),
      body: tracks.isEmpty && tracksAsync.hasValue
          ? Center(
              child: Text(
                'No tracks',
                style: TextStyle(color: palette.textSecondary),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: AlbumHeader(
                    album: widget.album,
                    artist: widget.artist,
                    tracks: tracks,
                    allLiked: allLiked,
                  ),
                ),
                SliverToBoxAdapter(child: _PlayActions(tracks: filtered)),
                if (_searching)
                  SliverToBoxAdapter(
                    child: SearchField(
                      autofocus: true,
                      hintText: 'Search this album',
                      onChanged: (value) =>
                          setState(() => _query = value.trim()),
                    ),
                  ),
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Text(
                        'No songs match',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    ),
                  )
                else
                  _AlbumTrackList(tracks: filtered),
              ],
            ),
    );
  }
}

class _PlayActions extends ConsumerWidget {
  const _PlayActions({required this.tracks});

  final List<Track> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        20,
        AppSpacing.pageH,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: AlbumActionPill(
              filled: true,
              icon: Icons.play_arrow_rounded,
              label: 'Play',
              onTap: tracks.isEmpty
                  ? null
                  : () => playAndMaybeOpenPlayer(
                      ref,
                      () => ref.read(audioHandlerProvider).loadQueue(tracks),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AlbumActionPill(
              filled: false,
              icon: Icons.shuffle_rounded,
              label: 'Shuffle',
              onTap: tracks.isEmpty ? null : () => shuffleAll(ref, tracks),
            ),
          ),
        ],
      ),
    );
  }
}

/// The album's songs. Watches only the playing track's id and the play/pause
/// flag, so the position ticks underneath don't rebuild the list.
class _AlbumTrackList extends ConsumerWidget {
  const _AlbumTrackList({required this.tracks});

  final List<Track> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentId = ref.watch(currentTrackIdProvider);
    final isPlayingNow = ref.watch(isPlayingProvider);

    return SliverPadding(
      padding: AppSpacing.listPaddingBelowHeader,
      sliver: SliverList.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return TrackListTile(
            track: track,
            index: index,
            isPlaying: currentId == track.id && isPlayingNow,
            onTap: () => playAndMaybeOpenPlayer(
              ref,
              () => ref
                  .read(audioHandlerProvider)
                  .loadQueue(tracks, startIndex: index),
            ),
            onMore: () => showTrackOptionsSheet(context, ref, track),
          );
        },
      ),
    );
  }
}
