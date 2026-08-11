import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';

class MusicFoldersSection extends ConsumerWidget {
  const MusicFoldersSection({
    super.key,
    required this.foldersAsync,
    required this.onRemove,
  });

  final AsyncValue<List<ScanFolder>> foldersAsync;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    return foldersAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('$e'),
      data: (folders) {
        if (folders.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'No folders selected yet.',
              style: TextStyle(color: palette.textSecondary),
            ),
          );
        }
        return Column(
          children: folders
              .map(
                (folder) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_rounded),
                  title: Text(
                    folder.path,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => onRemove(folder.id),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
