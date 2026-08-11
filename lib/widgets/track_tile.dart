import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/player_ui_provider.dart';
import '../data/repositories/providers.dart';
import 'album_art_with_glow.dart';

/// One song in a list: artwork, title and a second line.
///
/// Takes the whole list rather than a single track because tapping a row plays
/// the list from that row: the queue is the list the user is looking at.
class TrackTile extends ConsumerWidget {
  const TrackTile({
    super.key,
    required this.tracks,
    required this.index,
    this.subtitle,
    this.trailing,
    this.showArtwork = true,
  });

  final List<Track> tracks;
  final int index;

  /// Second line of the row. Defaults to the artist.
  final String? subtitle;

  /// Optional row action, e.g. unlike or remove-from-playlist.
  final Widget? trailing;

  final bool showArtwork;

  /// Size and corner of the artwork on a list row, shared with the album rows
  /// so every list in the app lines its thumbnails up the same way.
  static const artSize = 48.0;
  static const artRadius = 10.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = tracks[index];

    return ListTile(
      leading: showArtwork
          ? AlbumArtWithGlow(
              artHash: track.albumArtHash,
              size: artSize,
              borderRadius: artRadius,
              showGlow: false,
            )
          : null,
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        subtitle ?? track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      onTap: () => playAndMaybeOpenPlayer(
        ref,
        () =>
            ref.read(audioHandlerProvider).loadQueue(tracks, startIndex: index),
      ),
    );
  }
}
