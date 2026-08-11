import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/providers.dart';

/// Shows what's queued up, with the playing track marked.
Future<void> showQueueSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => const _QueueSheet(),
  );
}

class _QueueSheet extends ConsumerWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final queue = ref.watch(playerQueueProvider);
    final currentId = ref.watch(currentMediaItemProvider)?.id;

    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        itemCount: queue.length,
        itemBuilder: (context, index) {
          final item = queue[index];
          final current = currentId == item.id;

          return ListTile(
            tileColor: current ? palette.surfaceHighlight : null,
            leading: SizedBox(
              width: 24,
              child: Center(
                child: current
                    ? Icon(
                        Icons.graphic_eq_rounded,
                        size: 20,
                        color: palette.textPrimary,
                      )
                    : Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            title: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: current ? palette.textPrimary : palette.textSecondary,
                fontWeight: current ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            subtitle: Text(
              item.artist ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              ref.read(audioHandlerProvider).skipToQueueItem(index);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
