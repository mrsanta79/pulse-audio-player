import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/player_ui_provider.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/page_header.dart';
import '../../widgets/track_tile.dart';
import 'widgets/album_shelf.dart';
import 'widgets/empty_home_state.dart';
import 'widgets/section_heading.dart';

/// How many recently added songs the Home page lists before "Songs" takes over.
const _recentSongCount = 20;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final tracksAsync = ref.watch(allTracksProvider);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: tracksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (tracks) => tracks.isEmpty
              ? EmptyHomeState(onScan: () => context.push(Routes.settings))
              : _HomeContent(tracks: tracks),
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.tracks});

  final List<Track> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(albumsProvider).valueOrNull ?? const [];
    final recentCount = tracks.length < _recentSongCount
        ? tracks.length
        : _recentSongCount;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _HomeHeader()),
        if (albums.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeading(
              title: 'Albums',
              actionLabel: 'See all',
              onAction: () => context.go(Routes.library),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageH,
                8,
                AppSpacing.pageH,
                12,
              ),
            ),
          ),
          SliverToBoxAdapter(child: AlbumShelf(albums: albums)),
        ],
        SliverToBoxAdapter(
          child: SectionHeading(
            title: 'Songs',
            actionLabel: 'Shuffle all',
            onAction: () => shuffleAll(ref, tracks),
          ),
        ),
        SliverPadding(
          padding: AppSpacing.listPadding,
          sliver: SliverList.builder(
            itemCount: recentCount,
            // `tracks` is the queue and `index` indexes straight into it, so
            // starting playback doesn't need to search the list for the row.
            itemBuilder: (context, index) =>
                TrackTile(tracks: tracks, index: index),
          ),
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      title: 'Pulse',
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        AppSpacing.pageTop,
        AppSpacing.pageH,
        8,
      ),
      action: IconButton(
        onPressed: () => context.push(Routes.settings),
        icon: const Icon(Icons.settings_rounded),
      ),
    );
  }
}
