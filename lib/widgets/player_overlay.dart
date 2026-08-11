import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/routes.dart';
import '../data/repositories/player_ui_provider.dart';
import '../data/repositories/providers.dart';
import '../features/shell/shell_screen.dart';
import 'app_bottom_nav.dart';
import 'expanded_player.dart';
import 'mini_player_bar.dart';

const _bottomNavHeight = 64.0;

/// Wraps the routed page with the mini player, the expanded player and the
/// bottom nav.
///
/// This sits above every screen in the app, so it must not follow the playhead:
/// it watches only whether *something* is loaded, which changes when a track
/// starts or the queue empties. Watching the full player state here rebuilt the
/// entire app shell several times a second.
class PlayerOverlay extends ConsumerWidget {
  const PlayerOverlay({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMedia = ref.watch(hasMediaProvider);
    final expanded = ref.watch(playerExpandedProvider);

    final onShellRoute = Routes.shellRoutes.contains(location);
    final wideShell =
        onShellRoute &&
        MediaQuery.sizeOf(context).width >= shellSplitBreakpoint;

    // The bottom nav is `SizedBox(height: 64)` inside a `SafeArea`, so its real
    // height includes the system gesture inset. Offset the mini-player by both
    // so it sits above the nav instead of being clipped behind it.
    final bottomOffset = onShellRoute
        ? _bottomNavHeight + MediaQuery.paddingOf(context).bottom
        : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (hasMedia && !expanded && !wideShell)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomOffset,
            child: MiniPlayerBar(
              onTap: () => ref.read(playerExpandedProvider.notifier).expand(),
            ),
          ),
        if (hasMedia && expanded && !wideShell)
          Positioned.fill(
            child: ExpandedPlayer(
              onDismiss: () =>
                  ref.read(playerExpandedProvider.notifier).collapse(),
            ),
          ),
        // On the wide shell the expanded player is never rendered (the split
        // view already shows it), so the nav must ignore `expanded` there.
        // Otherwise a stale expand would hide the nav and show nothing.
        if (onShellRoute && (!expanded || wideShell))
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ShellBottomNav(location: location),
          ),
      ],
    );
  }
}

class _ShellBottomNav extends StatelessWidget {
  const _ShellBottomNav({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final index = Routes.shellRoutes.indexOf(location);
    return AppBottomNav(
      currentIndex: index < 0 ? 0 : index,
      onTap: (i) => context.go(Routes.shellRoutes[i]),
    );
  }
}
