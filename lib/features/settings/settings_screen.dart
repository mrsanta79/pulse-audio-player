import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/storage_path.dart';
import '../../data/repositories/providers.dart';
import '../../data/services/folder_scanner_service.dart';
import 'widgets/appearance_section.dart';
import 'widgets/music_folders_section.dart';
import 'widgets/scan_buttons.dart';
import 'widgets/scan_progress_bar.dart';
import 'widgets/settings_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _scanning = false;
  ScanProgress? _progress;

  Future<bool> _ensurePermission() async {
    // Reading arbitrary folders by filesystem path on Android 11+ requires
    // "All files access" (MANAGE_EXTERNAL_STORAGE). Requesting it sends the
    // user to a system settings screen, so re-check after they return.
    if (await Permission.manageExternalStorage.isGranted) return true;
    if ((await Permission.manageExternalStorage.request()).isGranted) {
      return true;
    }

    // Fallbacks for older Android versions where scoped media access is enough.
    final audio = await Permission.audio.request();
    final storage = await Permission.storage.request();
    return audio.isGranted || storage.isGranted;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addFolder() async {
    // Stop here rather than opening the picker behind the message: without
    // read access the scan would find nothing in whatever folder was chosen,
    // which reads as "Pulse can't see my music" instead of "grant this".
    if (!await _ensurePermission()) {
      _showMessage(
        'Grant "All files access" so Pulse can read your music folders, '
        'then add the folder again.',
      );
      return;
    }

    final picked = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select music folder',
    );
    if (picked == null) return;

    // The Android picker returns a SAF content URI; convert it to a real path
    // that the file-based scanner can read.
    await ref
        .read(scannerServiceProvider)
        .addScanFolder(resolvePickedDirectoryPath(picked));
    await _rescan();
  }

  Future<void> _rescan() async {
    final scanner = ref.read(scannerServiceProvider);
    final folders = await scanner.getScanFolders();
    if (folders.isEmpty) {
      _showMessage('Add at least one folder to scan');
      return;
    }

    setState(() {
      _scanning = true;
      _progress = const ScanProgress(scanned: 0, total: 0);
    });

    final paths = [for (final folder in folders) folder.path];
    await for (final progress in scanner.scanFolders(paths)) {
      if (!mounted) return;
      setState(() => _progress = progress);
    }

    if (!mounted) return;
    setState(() => _scanning = false);
    _showMessage('Scan complete, ${_progress?.scanned ?? 0} files processed');
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          8,
          AppSpacing.pageH,
          40,
        ),
        children: [
          const SettingsSection(
            title: 'Appearance',
            description: 'Choose how Pulse looks.',
            child: AppearanceSection(),
          ),
          const SizedBox(height: AppSpacing.section + 8),
          SettingsSection(
            title: 'Music folders',
            description: 'Only tracks inside these folders are imported.',
            child: MusicFoldersSection(
              foldersAsync: ref.watch(scanFoldersProvider),
              onRemove: (id) =>
                  ref.read(scannerServiceProvider).removeScanFolder(id),
            ),
          ),
          const SizedBox(height: 16),
          ScanButtons(
            scanning: _scanning,
            onAddFolder: _addFolder,
            onRescan: _rescan,
          ),
          if (_scanning) ScanProgressBar(progress: _progress),
          const SizedBox(height: 32),
          const SettingsSection(
            title: 'About',
            description:
                'Pulse - A dead-simple fully vibe-coded completely free & offline audio player to break free from the shackles of streaming services and their algorithms.',
          ),
        ],
      ),
    );
  }
}
