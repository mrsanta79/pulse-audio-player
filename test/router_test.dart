import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_audio_player/core/router/app_router.dart';

void main() {
  test(
    'router builds and resolves full-screen routes on the root navigator',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Previously this threw: "sub-route's parent navigator key must either be
      // null or has the same navigator key as parent's key" because /settings
      // etc. were ShellRoute children targeting the root navigator.
      final router = container.read(routerProvider);

      for (final path in [
        '/settings',
        '/album',
        '/library/artists',
        '/library/songs',
        '/artist',
        '/year',
        '/likes',
        '/playlist',
      ]) {
        final match = router.configuration.findMatch(Uri.parse(path));
        expect(match.routes, isNotEmpty, reason: 'no route matched $path');
      }
    },
  );
}
