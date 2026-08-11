import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/album_list_tile.dart';
import '../../widgets/page_header.dart';
import 'widgets/library_tile.dart';

/// How many albums the Library landing page previews before "Albums".
const _recentAlbumCount = 8;

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final albums = ref.watch(albumsProvider).valueOrNull ?? const [];
    final artists = ref.watch(artistsProvider).valueOrNull ?? const [];
    final years = ref.watch(yearsProvider).valueOrNull ?? const [];
    final tracks = ref.watch(allTracksProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: ListView(
          // List rows are inset by `listH`; the theme's ListTile contentPadding
          // then gives each row's tap highlight breathing room from the edge.
          // Page headers get an extra `pageH - listH` nudge so their text still
          // lines up flush at the standard page margin.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.listH,
            AppSpacing.pageTop,
            AppSpacing.listH,
            AppSpacing.bottomGap,
          ),
          children: [
            const _LibraryHeader(),
            const SizedBox(height: 16),
            LibraryTile(
              icon: Icons.person_rounded,
              title: 'Artists',
              subtitle: '${artists.length}',
              onTap: () => context.push(Routes.artists),
            ),
            LibraryTile(
              icon: Icons.album_rounded,
              title: 'Albums',
              subtitle: '${albums.length}',
              onTap: () => context.push(Routes.albums),
            ),
            LibraryTile(
              icon: Icons.calendar_today_rounded,
              title: 'Years',
              subtitle: '${years.length}',
              onTap: () => context.push(Routes.years),
            ),
            LibraryTile(
              icon: Icons.music_note_rounded,
              title: 'Songs',
              subtitle: '${tracks.length}',
              onTap: () => context.push(Routes.songs),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.pageH - AppSpacing.listH,
              ),
              child: Text('Recent albums', style: AppTextStyles.sectionTitle),
            ),
            const SizedBox(height: 12),
            for (final album in albums.take(_recentAlbumCount))
              AlbumListTile(album: album),
          ],
        ),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader();

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      title: 'Library',
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageH - AppSpacing.listH,
      ),
      action: IconButton(
        onPressed: () => context.push(Routes.settings),
        icon: const Icon(Icons.settings_rounded),
      ),
    );
  }
}
