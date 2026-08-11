import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/name_prompt_dialog.dart';
import '../../widgets/page_header.dart';
import 'widgets/hotlist_tile.dart';

class HotlistScreen extends ConsumerWidget {
  const HotlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final likeCount = ref.watch(likedTrackIdsProvider).length;
    final playlists = ref.watch(playlistsProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageH,
            AppSpacing.pageTop,
            AppSpacing.pageH,
            AppSpacing.bottomGap,
          ),
          children: [
            PageHeader(
              title: 'Hotlist',
              action: IconButton(
                onPressed: () => _createPlaylist(context, ref),
                icon: const Icon(Icons.add_rounded),
              ),
            ),
            const SizedBox(height: 12),
            HotlistTile(
              icon: Icons.favorite_rounded,
              background: palette.surfaceHighlight,
              title: 'Liked songs',
              subtitle: '$likeCount songs',
              bold: true,
              onTap: () => context.push(Routes.likes),
            ),
            const SizedBox(height: 20),
            const Text('Playlists', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 8),
            if (playlists.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Create a playlist to organize your favorites.',
                  style: TextStyle(color: palette.textSecondary),
                ),
              )
            else
              for (final playlist in playlists)
                HotlistTile(
                  icon: Icons.queue_music_rounded,
                  background: palette.surface,
                  title: playlist.name,
                  onTap: () => context.push(playlistRoute(playlist.id)),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: palette.textSecondary,
                    ),
                    onPressed: () =>
                        ref.read(databaseProvider).deletePlaylist(playlist.id),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
    final name = await promptForName(
      context,
      title: 'New playlist',
      hint: 'Playlist name',
    );
    if (name == null) return;
    await ref.read(databaseProvider).createPlaylist(name);
  }
}
