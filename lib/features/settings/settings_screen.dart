import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/storage_path.dart';
import '../../data/repositories/providers.dart';
import '../../data/services/folder_scanner_service.dart';
import '../../data/services/openrouter_mood_service.dart';
import 'widgets/appearance_section.dart';
import 'widgets/mood_ai_section.dart';
import 'widgets/mood_categorization_progress_bar.dart';
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
  bool _categorizing = false;
  ScanProgress? _progress;
  MoodCategorizationProgress? _moodProgress;
  String? _moodStatus;
  bool _moodStatusIsError = false;
  static const _appVersion = String.fromEnvironment(
    'FLUTTER_BUILD_NAME',
    defaultValue: '1.2.0',
  );

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

  void _showMoodStatus(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _moodStatus = message;
      _moodStatusIsError = isError;
    });
    ref.read(moodCategorizationStatusProvider.notifier).state = (
      message: message,
      isError: isError,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 8)),
    );
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
    if (_scanning || _categorizing) return;
    final scanner = ref.read(scannerServiceProvider);
    final folders = await scanner.getScanFolders();
    if (folders.isEmpty) {
      _showMessage('Add at least one folder to scan');
      return;
    }

    _startMoodOperation(scanning: true);
    final paths = [for (final folder in folders) folder.path];
    try {
      await for (final progress in scanner.scanFolders(paths)) {
        if (!mounted) return;
        setState(() => _progress = progress);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _scanning = false);
      _showMessage('Library scan failed: $error');
      return;
    }

    await _categorizeMoods();
  }

  void _startMoodOperation({bool scanning = false}) {
    setState(() {
      _scanning = scanning;
      _categorizing = false;
      _progress = scanning ? const ScanProgress(scanned: 0, total: 0) : null;
      _moodProgress = const MoodCategorizationProgress(completed: 0, total: 0);
      _moodStatus = null;
      _moodStatusIsError = false;
    });
    ref.read(moodCategorizationStatusProvider.notifier).state = null;
  }

  Future<void> _categorizeMoodsOnly() async {
    if (_scanning || _categorizing) return;
    final tracks = await ref.read(allTracksProvider.future);
    if (tracks.isEmpty) {
      _showMoodStatus('There are no songs in your library to categorize.');
      return;
    }
    _startMoodOperation();
    await _categorizeMoods();
  }

  Future<void> _categorizeMoods() async {
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _categorizing = true;
      _moodProgress = const MoodCategorizationProgress(completed: 0, total: 0);
    });

    final scanner = ref.read(scannerServiceProvider);
    var skipped = false;
    try {
      await for (final progress in scanner.categorizePendingMoods()) {
        if (!mounted) return;
        skipped = progress.skipped;
        setState(() => _moodProgress = progress);
      }
      if (!mounted) return;
      final result = _moodProgress;
      setState(() {
        _categorizing = false;
        _moodProgress = null;
      });
      if (skipped) {
        _showMoodStatus(
          'Mood categorization skipped: add an OpenRouter API key below, then try again.',
          isError: true,
        );
      } else if (result?.total == 0) {
        _showMoodStatus(
          'Mood categorization complete: all songs are up to date.',
        );
      } else {
        _showMoodStatus(
          'Mood categorization complete: ${result?.completed ?? 0} songs categorized.',
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _categorizing = false;
        _moodProgress = null;
      });
      _showMoodStatus(
        'Mood categorization failed: $error. Save/check your OpenRouter settings, then try again.',
        isError: true,
      );
    }
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
            scanning: _scanning || _categorizing,
            onAddFolder: _addFolder,
            onRescan: _rescan,
            onCategorizeMoods: _categorizeMoodsOnly,
          ),
          if (_scanning) ScanProgressBar(progress: _progress),
          if (_categorizing)
            MoodCategorizationProgressBar(progress: _moodProgress),
          if (_moodStatus != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _moodStatusIsError
                    ? Theme.of(context).colorScheme.errorContainer
                    : palette.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _moodStatus!,
                      style: TextStyle(
                        color: _moodStatusIsError
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : palette.textPrimary,
                      ),
                    ),
                  ),
                  if (_moodStatusIsError)
                    TextButton(onPressed: _rescan, child: const Text('Retry')),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.section + 8),
          const SettingsSection(
            title: 'Mood categories',
            description:
                'Use OpenRouter to sort songs into moods after a library scan. Title, artist, album, year, duration, and track number are sent for categorization.',
            child: MoodAiSection(),
          ),
          const SizedBox(height: 32),
          SettingsSection(
            title: 'About',
            description:
                'Pulse keeps playback and library data on your device. Optional Mood AI uses OpenRouter to categorize song metadata.',
            child: Text(
              'Version $_appVersion',
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
