import 'package:flutter/material.dart';

/// What the user picked in Settings › Appearance.
///
/// [system] defers to the platform's light/dark setting; the dark side of that
/// pairing is whichever [AppDarkVariant] the user prefers, so following the
/// system doesn't force anyone onto a dark flavour they dislike.
enum AppThemeChoice { system, light, amoled, midnight }

/// Which dark palette to use, both when picked outright and as the dark half
/// of [AppThemeChoice.system].
enum AppDarkVariant { amoled, midnight }

extension AppThemeChoiceX on AppThemeChoice {
  /// Stable string for the database. These are persisted, so never change them.
  String get storageKey => name;

  static AppThemeChoice fromStorage(String? value) {
    return AppThemeChoice.values.firstWhere(
      (c) => c.storageKey == value,
      orElse: () => AppThemeChoice.amoled,
    );
  }

  String get label => switch (this) {
    AppThemeChoice.system => 'Follow system',
    AppThemeChoice.light => 'Light',
    AppThemeChoice.amoled => 'Dark · AMOLED',
    AppThemeChoice.midnight => 'Dark · Midnight',
  };

  String get description => switch (this) {
    AppThemeChoice.system => 'Match your device setting',
    AppThemeChoice.light => 'Bright and high contrast',
    AppThemeChoice.amoled => 'True black, saves battery',
    AppThemeChoice.midnight => 'Deep teal-blue',
  };
}

extension AppDarkVariantX on AppDarkVariant {
  String get storageKey => name;

  static AppDarkVariant fromStorage(String? value) {
    return AppDarkVariant.values.firstWhere(
      (v) => v.storageKey == value,
      orElse: () => AppDarkVariant.amoled,
    );
  }

  String get label => switch (this) {
    AppDarkVariant.amoled => 'AMOLED',
    AppDarkVariant.midnight => 'Midnight',
  };

  AppPalette get palette => switch (this) {
    AppDarkVariant.amoled => AppPalette.amoled,
    AppDarkVariant.midnight => AppPalette.midnight,
  };
}

/// The app's semantic colour tokens, carried on [ThemeData] as a
/// [ThemeExtension] so every widget resolves them from its own `BuildContext`
/// and rebuilds automatically when the theme changes.
///
/// Read these via `AppColors.of(context)` rather than referencing a palette
/// constant directly; a direct reference pins a widget to one theme.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceHighlight,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.miniPlayer,
    required this.miniPlayerFg,
    required this.miniPlayerButton,
    required this.miniPlayerButtonFg,
    required this.pillOutline,
    required this.glowFallback,
    required this.accent,
    required this.onAccent,
    required this.waveformInactive,
    required this.navGlow,
    required this.scrim,
  });

  /// Whether this palette reads as light or dark. Drives status-bar icon
  /// brightness and Material's own light/dark defaults.
  final Brightness brightness;

  /// Page background, the furthest-back surface.
  final Color background;

  /// Raised panels: bottom sheets, cards, dialogs.
  final Color surface;

  /// Selected/pressed row backgrounds and art placeholders.
  final Color surfaceHighlight;

  /// A hair above [background]; for surfaces that need separation without the
  /// full contrast of [surface].
  final Color surfaceElevated;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// The floating mini-player pill, which sits on its own tinted surface so it
  /// reads as detached from the page behind it.
  final Color miniPlayer;
  final Color miniPlayerFg;

  /// The circular play/pause button inside the mini player, which inverts
  /// against the pill rather than against the page.
  final Color miniPlayerButton;
  final Color miniPlayerButtonFg;

  /// Hairline border for outlined pill buttons.
  final Color pillOutline;

  /// Album-art glow used when no colour can be extracted from the artwork.
  final Color glowFallback;

  /// Primary action fill (filled buttons, the big play button, the played
  /// portion of the waveform) and the colour that sits legibly on top of it.
  final Color accent;
  final Color onAccent;

  /// Unplayed portion of the seek bar.
  final Color waveformInactive;

  /// Halo behind the selected bottom-nav icon.
  final Color navGlow;

  /// Modal barrier behind sheets and the expanded player.
  final Color scrim;

  /// The current palette, or the AMOLED default if no theme has been installed
  /// (which only happens in bare `MaterialApp`s such as the startup error page).
  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? amoled;
  }

  /// Pure black. The app's original look, kept byte-for-byte so existing users
  /// see no change after this setting shipped.
  static const amoled = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    surface: Color(0xFF1A1A1A),
    surfaceHighlight: Color(0xFF2A2A2A),
    surfaceElevated: Color(0xFF1E1E1E),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF888888),
    textTertiary: Color(0xFF9E9E9E),
    miniPlayer: Color(0xFF181C26),
    miniPlayerFg: Color(0xFFFFFFFF),
    miniPlayerButton: Color(0xFF000000),
    miniPlayerButtonFg: Color(0xFFFFFFFF),
    pillOutline: Color(0xFF3A3A3A),
    glowFallback: Color(0x33FFFFFF),
    accent: Color(0xFFFFFFFF),
    onAccent: Color(0xFF000000),
    waveformInactive: Color(0xFF4A4A4A),
    navGlow: Color(0x2EFFFFFF),
    scrim: Color(0x8A000000),
  );

  /// Deep teal-blue built as a single-hue ramp off #06202B (H198°), so every
  /// surface tint stays in the same family instead of drifting toward grey.
  static const midnight = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF06202B),
    surface: Color(0xFF12303D),
    surfaceHighlight: Color(0xFF1C404F),
    surfaceElevated: Color(0xFF0D2833),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8A9FA8),
    textTertiary: Color(0xFFA0B3BB),
    miniPlayer: Color(0xFF163644),
    miniPlayerFg: Color(0xFFFFFFFF),
    miniPlayerButton: Color(0xFF06202B),
    miniPlayerButtonFg: Color(0xFFFFFFFF),
    pillOutline: Color(0xFF284D5C),
    glowFallback: Color(0x33FFFFFF),
    accent: Color(0xFFFFFFFF),
    onAccent: Color(0xFF06202B),
    waveformInactive: Color(0xFF355664),
    navGlow: Color(0x2EFFFFFF),
    scrim: Color(0x8A000000),
  );

  /// Light. Text tokens are tuned to clear WCAG AA against every surface they
  /// land on, which plain greys don't manage on a white background.
  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF1F3F5),
    surfaceHighlight: Color(0xFFE3E7EB),
    surfaceElevated: Color(0xFFF7F9FA),
    textPrimary: Color(0xFF0B1417),
    textSecondary: Color(0xFF5F6C73),
    textTertiary: Color(0xFF6C787F),
    miniPlayer: Color(0xFFEBEFF2),
    miniPlayerFg: Color(0xFF0B1417),
    miniPlayerButton: Color(0xFF0B1417),
    miniPlayerButtonFg: Color(0xFFFFFFFF),
    pillOutline: Color(0xFFD5DBE0),
    glowFallback: Color(0x240B1417),
    accent: Color(0xFF0B1417),
    onAccent: Color(0xFFFFFFFF),
    waveformInactive: Color(0xFFC7CFD4),
    navGlow: Color(0x1A0B1417),
    scrim: Color(0x660B1417),
  );

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? surfaceHighlight,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? miniPlayer,
    Color? miniPlayerFg,
    Color? miniPlayerButton,
    Color? miniPlayerButtonFg,
    Color? pillOutline,
    Color? glowFallback,
    Color? accent,
    Color? onAccent,
    Color? waveformInactive,
    Color? navGlow,
    Color? scrim,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHighlight: surfaceHighlight ?? this.surfaceHighlight,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      miniPlayer: miniPlayer ?? this.miniPlayer,
      miniPlayerFg: miniPlayerFg ?? this.miniPlayerFg,
      miniPlayerButton: miniPlayerButton ?? this.miniPlayerButton,
      miniPlayerButtonFg: miniPlayerButtonFg ?? this.miniPlayerButtonFg,
      pillOutline: pillOutline ?? this.pillOutline,
      glowFallback: glowFallback ?? this.glowFallback,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      waveformInactive: waveformInactive ?? this.waveformInactive,
      navGlow: navGlow ?? this.navGlow,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      // Brightness is a discrete choice, so it flips at the halfway point
      // rather than interpolating.
      brightness: t < 0.5 ? brightness : other.brightness,
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceHighlight: mix(surfaceHighlight, other.surfaceHighlight),
      surfaceElevated: mix(surfaceElevated, other.surfaceElevated),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textTertiary: mix(textTertiary, other.textTertiary),
      miniPlayer: mix(miniPlayer, other.miniPlayer),
      miniPlayerFg: mix(miniPlayerFg, other.miniPlayerFg),
      miniPlayerButton: mix(miniPlayerButton, other.miniPlayerButton),
      miniPlayerButtonFg: mix(miniPlayerButtonFg, other.miniPlayerButtonFg),
      pillOutline: mix(pillOutline, other.pillOutline),
      glowFallback: mix(glowFallback, other.glowFallback),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      waveformInactive: mix(waveformInactive, other.waveformInactive),
      navGlow: mix(navGlow, other.navGlow),
      scrim: mix(scrim, other.scrim),
    );
  }
}
