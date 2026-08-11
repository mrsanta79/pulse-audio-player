import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/providers.dart';
import 'data/repositories/theme_provider.dart';
import 'data/services/audio_player_service.dart';
import 'data/services/playback_session_store.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();

  // Read the saved theme before the first frame so the app doesn't paint a
  // default palette and then snap to the user's choice.
  final themeSettings = await ThemeSettings.load(db);
  SystemChrome.setSystemUIOverlayStyle(
    systemOverlayStyleFor(
      themeSettings.resolve(binding.platformDispatcher.platformBrightness),
    ),
  );

  AppAudioHandler? handler;
  try {
    handler = await initAudioService(
      artLoader: (hash) => db.getAlbumArtBytes(hash),
      sessionStore: DatabasePlaybackSessionStore(db),
    );
  } catch (e, st) {
    debugPrint('Audio service init failed: $e\n$st');
  }

  if (handler == null) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Failed to start audio engine. Please restart the app.',
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        audioHandlerProvider.overrideWithValue(handler),
        initialThemeSettingsProvider.overrideWithValue(themeSettings),
      ],
      child: const PulseApp(),
    ),
  );

  // Restore the last session after the first frame so startup isn't blocked by
  // the queue read; the mini player fills in as soon as it lands.
  unawaited(_restoreLastSession(db, handler));
}

Future<void> _restoreLastSession(
  AppDatabase db,
  AppAudioHandler handler,
) async {
  try {
    final session = await db.getPlaybackSession();
    if (session == null) return;
    await handler.restoreSession(session);
  } catch (e, st) {
    debugPrint('Failed to restore last session: $e\n$st');
  }
}
