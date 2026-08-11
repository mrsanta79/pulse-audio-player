import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/album/album_detail_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/hotlist/hotlist_screen.dart';
import '../../features/hotlist/likes_screen.dart';
import '../../features/hotlist/playlist_detail_screen.dart';
import '../../features/library/albums_list_screen.dart';
import '../../features/library/artist_detail_screen.dart';
import '../../features/library/artists_list_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/library/songs_list_screen.dart';
import '../../features/library/year_detail_screen.dart';
import '../../features/library/years_list_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/shell_screen.dart';
import '../../widgets/player_overlay.dart';
import 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.home,
    routes: [
      _shellRoute(),
      // Full-screen routes live on the root navigator (as siblings of the
      // ShellRoute), so they appear above the mini-player / bottom-nav overlay.
      // They must NOT be children of the ShellRoute: go_router forbids a shell
      // sub-route from targeting an ancestor (root) navigator.
      ..._fullScreenRoutes(),
    ],
  );
});

/// The four bottom-nav tabs, each keeping its own navigation stack, under the
/// mini-player / nav overlay.
RouteBase _shellRoute() {
  return ShellRoute(
    builder: (context, state, child) {
      return PlayerOverlay(location: state.uri.path, child: child);
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellScreen(navigationShell: navigationShell);
        },
        branches: [
          _branch(Routes.home, (_, __) => const HomeScreen()),
          _branch(Routes.search, (_, __) => const SearchScreen()),
          _branch(Routes.library, (_, __) => const LibraryScreen()),
          _branch(Routes.hotlist, (_, __) => const HotlistScreen()),
        ],
      ),
    ],
  );
}

StatefulShellBranch _branch(String path, GoRouterWidgetBuilder builder) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: builder)],
  );
}

List<RouteBase> _fullScreenRoutes() {
  return [
    GoRoute(
      // Legacy entry point: the player is an overlay now, not a route, so this
      // just returns wherever the caller came from.
      path: '/now-playing',
      redirect: (context, state) {
        final from = state.uri.queryParameters['from'];
        return (from != null && from.isNotEmpty) ? from : Routes.home;
      },
    ),
    GoRoute(path: Routes.settings, builder: (_, __) => const SettingsScreen()),
    GoRoute(path: Routes.likes, builder: (_, __) => const LikesScreen()),
    GoRoute(
      path: Routes.artists,
      builder: (_, __) => const ArtistsListScreen(),
    ),
    GoRoute(path: Routes.albums, builder: (_, __) => const AlbumsListScreen()),
    GoRoute(path: Routes.years, builder: (_, __) => const YearsListScreen()),
    GoRoute(path: Routes.songs, builder: (_, __) => const SongsListScreen()),
    GoRoute(
      path: '/album',
      builder: (context, state) => AlbumDetailScreen(
        album: state.uri.queryParameters['album'] ?? 'Unknown Album',
        artist: state.uri.queryParameters['artist'] ?? 'Unknown Artist',
      ),
    ),
    GoRoute(
      path: '/artist',
      builder: (context, state) => ArtistDetailScreen(
        artist: state.uri.queryParameters['name'] ?? 'Unknown Artist',
      ),
    ),
    GoRoute(
      path: '/year',
      builder: (context, state) => YearDetailScreen(
        year: int.tryParse(state.uri.queryParameters['value'] ?? '') ?? 0,
      ),
    ),
    GoRoute(
      path: '/playlist',
      builder: (context, state) => PlaylistDetailScreen(
        playlistId: int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0,
      ),
    ),
  ];
}
