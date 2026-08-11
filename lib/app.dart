import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/theme_provider.dart';

class PulseApp extends ConsumerWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(themeSettingsProvider);

    return MaterialApp.router(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.from(settings.lightPalette),
      darkTheme: AppTheme.from(settings.darkPalette),
      themeMode: settings.themeMode,
      routerConfig: router,
      // This builder sits *below* the resolved Theme, so when the mode is
      // "follow system" it sees the palette the platform actually picked,
      // which the widget above can't know.
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemOverlayStyleFor(AppColors.of(context)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
