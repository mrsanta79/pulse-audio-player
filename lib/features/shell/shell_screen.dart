import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../now_playing/now_playing_screen.dart';

/// From this width up, the player sits beside the browsing pane rather than
/// over it. Matches the breakpoint `PlayerOverlay` uses to hide the mini
/// player, so the two can't disagree about which layout is showing.
const shellSplitBreakpoint = 600.0;

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < shellSplitBreakpoint) {
          return navigationShell;
        }

        return Row(
          children: [
            Expanded(flex: 45, child: navigationShell),
            VerticalDivider(width: 1, color: AppColors.of(context).surface),
            const Expanded(
              flex: 55,
              child: NowPlayingScreen(embedded: true, showHeader: false),
            ),
          ],
        );
      },
    );
  }
}
