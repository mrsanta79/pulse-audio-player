import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

export 'app_palette.dart';

/// Status-bar and navigation-bar styling for a palette.
///
/// The system bars are painted by the OS, outside the tree `MaterialApp`
/// themes, so they have to be told about the theme explicitly. Otherwise a
/// light theme gets white icons on a white status bar.
SystemUiOverlayStyle systemOverlayStyleFor(AppPalette palette) {
  final isDark = palette.brightness == Brightness.dark;
  // `statusBarIconBrightness` is the Android knob and takes the colour the
  // icons should be drawn in; `statusBarBrightness` is the iOS knob and takes
  // the brightness of the background behind them. They are deliberately
  // opposites here.
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: palette.background,
    systemNavigationBarIconBrightness: isDark
        ? Brightness.light
        : Brightness.dark,
  );
}

/// Entry point for the app's colour tokens.
///
/// `AppColors.of(context)` returns the [AppPalette] installed on the current
/// theme, so a widget re-reads its colours whenever the user switches themes.
/// There are deliberately no colour constants here: a `const` colour would
/// silently ignore the user's choice.
class AppColors {
  const AppColors._();

  static AppPalette of(BuildContext context) => AppPalette.of(context);
}

class AppRadii {
  static const albumArt = 20.0;
  static const pill = 28.0;
  static const playButton = 40.0;
  static const trackRow = 16.0;
  static const iconPill = 20.0;

  /// Top corners of a modal bottom sheet. Applied by the theme, so no sheet
  /// has to pass a shape of its own.
  static const sheet = 24.0;
}

/// Single source of truth for layout spacing so screens don't each pick their
/// own paddings. `pageH`/`pageTop` frame full-page content (titles, headers);
/// `listH` insets scrolling lists so each row's rounded tap highlight (see the
/// ListTile theme below) sits the same distance from the edge everywhere.
class AppSpacing {
  /// Horizontal inset for page content aligned to the screen edge.
  static const pageH = 20.0;

  /// Top inset for the first item on a page.
  static const pageTop = 16.0;

  /// Horizontal inset for scrolling lists of rows.
  static const listH = 12.0;

  /// Bottom padding so the last row clears the floating nav + mini player.
  static const bottomGap = 120.0;

  /// Gap between major sections within a page.
  static const section = 24.0;

  /// Padding for a scrolling list of rows: [listH] at the sides, and enough
  /// room at the bottom for the last row to clear the floating nav and mini
  /// player. Every list in the app uses this, so rows line up across screens.
  static const listPadding = EdgeInsets.fromLTRB(listH, 0, listH, bottomGap);

  /// As [listPadding], but for a list that sits under something (a header, a
  /// row of buttons) and needs a gap before its first row.
  static const listPaddingBelowHeader = EdgeInsets.fromLTRB(
    listH,
    8,
    listH,
    bottomGap,
  );
}

/// The two headings that appear on more than one page. Colour comes from the
/// theme's text colour, so these stay palette-agnostic.
class AppTextStyles {
  const AppTextStyles._();

  /// The big title at the top of a top-level page (Home, Library, Hotlist).
  static const pageTitle = TextStyle(fontSize: 28, fontWeight: FontWeight.w800);

  /// A section title within a page ("Albums", "Playlists", "Appearance").
  static const sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
}

class AppTheme {
  /// Builds the full [ThemeData] for a palette and attaches the palette itself
  /// as a theme extension, which is what `AppColors.of(context)` reads back.
  ///
  /// The per-component themes are split out below: this used to be one long
  /// literal in which a change to, say, dialogs meant scrolling past every
  /// other widget's styling to find it.
  static ThemeData from(AppPalette palette) {
    final base = _base(palette);

    return base.copyWith(
      extensions: [palette],
      canvasColor: palette.background,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      dividerColor: palette.surfaceHighlight,
      dividerTheme: DividerThemeData(color: palette.surfaceHighlight),
      iconTheme: IconThemeData(color: palette.textPrimary),
      actionIconTheme: _actionIcon(),
      appBarTheme: _appBar(palette),
      listTileTheme: _listTile(palette),
      bottomNavigationBarTheme: _bottomNav(palette),
      bottomSheetTheme: _bottomSheet(palette),
      dialogTheme: _dialog(palette),
      progressIndicatorTheme: _progressIndicator(palette),
      snackBarTheme: _snackBar(palette),
      textSelectionTheme: _textSelection(palette),
      inputDecorationTheme: _inputDecoration(palette),
      popupMenuTheme: _popupMenu(palette),
      sliderTheme: _slider(palette),
      switchTheme: _switch(palette),
    );
  }

  static ThemeData _base(AppPalette palette) {
    final isDark = palette.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme:
          (isDark ? const ColorScheme.dark() : const ColorScheme.light())
              .copyWith(
                brightness: palette.brightness,
                surface: palette.background,
                onSurface: palette.textPrimary,
                surfaceContainerHighest: palette.surfaceHighlight,
                primary: palette.accent,
                onPrimary: palette.onAccent,
                secondary: palette.textSecondary,
                outline: palette.pillOutline,
                scrim: palette.scrim,
              ),
    );
  }

  /// A chevron reads lighter than the platform's back arrow. The larger size
  /// compensates for the chevron's smaller drawn area, so it lands at the same
  /// optical weight as the other app bar icons.
  static ActionIconThemeData _actionIcon() {
    return ActionIconThemeData(
      backButtonIconBuilder: (context) =>
          const Icon(Icons.chevron_left_rounded, size: 32),
    );
  }

  static AppBarTheme _appBar(AppPalette palette) {
    return AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        color: palette.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: palette.textPrimary),
      // Scaffolds with an AppBar apply this to the status bar, overriding the
      // app-level AnnotatedRegion, so it has to agree with it.
      systemOverlayStyle: systemOverlayStyleFor(palette),
    );
  }

  /// Without an explicit subtitle style, `textTheme.apply(bodyColor: ...)`
  /// forces ListTile subtitles to the primary text colour, making titles and
  /// artist names indistinguishable.
  ///
  /// The `shape` + `contentPadding` are what make every row's tap highlight
  /// consistent: rounded corners, inset from the row edge with vertical
  /// breathing room, instead of a full-bleed square that hugs the screen edges.
  /// Screens should not override these unless a row needs to sit flush with
  /// page content (e.g. under a big page title).
  static ListTileThemeData _listTile(AppPalette palette) {
    return ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      minVerticalPadding: 10,
      iconColor: palette.textPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.trackRow),
      ),
      titleTextStyle: GoogleFonts.inter(
        color: palette.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: GoogleFonts.inter(
        color: palette.textSecondary,
        fontSize: 13,
      ),
    );
  }

  static BottomNavigationBarThemeData _bottomNav(AppPalette palette) {
    return BottomNavigationBarThemeData(
      backgroundColor: palette.background,
      selectedItemColor: palette.textPrimary,
      unselectedItemColor: palette.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    );
  }

  /// Modal sheets read `backgroundColor` and `shape` from here, so
  /// `showModalBottomSheet` call sites pass neither.
  static BottomSheetThemeData _bottomSheet(AppPalette palette) {
    return BottomSheetThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: palette.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
    );
  }

  static DialogThemeData _dialog(AppPalette palette) {
    return DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        color: palette.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: GoogleFonts.inter(
        color: palette.textSecondary,
        fontSize: 14,
      ),
    );
  }

  static ProgressIndicatorThemeData _progressIndicator(AppPalette palette) {
    return ProgressIndicatorThemeData(
      color: palette.accent,
      linearTrackColor: palette.surfaceHighlight,
      circularTrackColor: palette.surfaceHighlight,
    );
  }

  /// Snackbars invert against the page so they read as an overlay rather than
  /// as more page content.
  static SnackBarThemeData _snackBar(AppPalette palette) {
    return SnackBarThemeData(
      backgroundColor: palette.accent,
      contentTextStyle: GoogleFonts.inter(color: palette.onAccent),
      actionTextColor: palette.onAccent,
      behavior: SnackBarBehavior.floating,
    );
  }

  static TextSelectionThemeData _textSelection(AppPalette palette) {
    return TextSelectionThemeData(
      cursorColor: palette.textPrimary,
      selectionColor: palette.textPrimary.withValues(alpha: 0.25),
      selectionHandleColor: palette.textPrimary,
    );
  }

  static InputDecorationTheme _inputDecoration(AppPalette palette) {
    return InputDecorationTheme(
      hintStyle: TextStyle(color: palette.textSecondary),
      iconColor: palette.textSecondary,
      prefixIconColor: palette.textSecondary,
      suffixIconColor: palette.textSecondary,
    );
  }

  static PopupMenuThemeData _popupMenu(AppPalette palette) {
    return PopupMenuThemeData(
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      textStyle: GoogleFonts.inter(color: palette.textPrimary, fontSize: 14),
    );
  }

  static SliderThemeData _slider(AppPalette palette) {
    return SliderThemeData(
      activeTrackColor: palette.accent,
      inactiveTrackColor: palette.waveformInactive,
      thumbColor: palette.accent,
    );
  }

  static SwitchThemeData _switch(AppPalette palette) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.onAccent
            : palette.textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.accent
            : palette.surfaceHighlight,
      ),
    );
  }
}
