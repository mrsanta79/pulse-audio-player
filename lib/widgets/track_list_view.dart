import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/providers.dart';
import 'track_tile.dart';

/// The standard "here are some songs" list, shared by every screen that shows
/// one (likes, playlists, an artist, a year, search results, all songs).
///
/// Tapping a row plays the list from that row, which is why the whole list is
/// passed rather than rows being wired up individually: the queue is the list
/// the user is looking at.
class TrackListView extends StatelessWidget {
  const TrackListView({
    super.key,
    required this.tracks,
    this.subtitle,
    this.trailing,
    this.emptyMessage = 'No songs here',
    this.showArtwork = true,
  });

  final List<Track> tracks;

  /// Second line of each row. Defaults to the artist.
  final String Function(Track track)? subtitle;

  /// Optional row action, e.g. unlike or remove-from-playlist.
  final Widget Function(Track track)? trailing;

  final String emptyMessage;
  final bool showArtwork;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
      );
    }

    // Sides only: the pages using this list have an app bar for the top, and
    // `listPadding` ends with `bottomGap`. The sides matter in landscape,
    // where the gesture bar sits on one of them.
    return SafeArea(
      top: false,
      bottom: false,
      child: ListView.builder(
        padding: AppSpacing.listPadding,
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return TrackTile(
            tracks: tracks,
            index: index,
            subtitle: subtitle?.call(track),
            trailing: trailing?.call(track),
            showArtwork: showArtwork,
          );
        },
      ),
    );
  }
}
