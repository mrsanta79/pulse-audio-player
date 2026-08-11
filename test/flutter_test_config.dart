import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Runs before every test in this directory.
///
/// `AppTheme.from` builds its text theme with `GoogleFonts.interTextTheme`,
/// which by default downloads the font over the network. Tests have no network
/// and don't assert on the typeface, so turn fetching off. Otherwise every
/// theme-building test waits on a doomed HTTP request. Flutter's bundled font
/// stands in.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
