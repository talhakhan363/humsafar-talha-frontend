import 'package:flutter/material.dart';

import 'accessibility_mode.dart';
import 'humsafar_colors.dart';

/// Task 1.9 — the two ThemeData sets the app switches between.
///
/// Kept as plain static builders (not one parameterized theme) so each
/// mode's numbers stay easy to read and tune independently — accessibility
/// tuning tends to happen by trial with real Dependent/Guardian testers,
/// so these are meant to be easy to come back and adjust later.
class AppTheme {
  AppTheme._();

  static ThemeData themeFor(AccessibilityMode mode) {
    switch (mode) {
      case AccessibilityMode.standard:
        return _standard;
      case AccessibilityMode.highContrast:
        return _highContrast;
    }
  }

  /// Fixed 2026-10-25 — Design Handoff v1.0 fix #1 (section 3): this used
  /// to generate its whole palette from one green seed colour
  /// (`0xFF2E7D32`), which is why the app still looked green everywhere
  /// instead of Sarim's teal brand. Now built from [HumsafarColors]
  /// instead, with `fromSeed`'s override parameters pinning the roles the
  /// handoff actually specifies (primary/secondary/surface/error/outline)
  /// rather than letting Material 3 derive them from a seed guess. This is
  /// the foundational piece of the handoff's 8-item fix list — the other 7
  /// (37 raw-Colors.* screens, Panic button sizing/contrast, the location
  /// banner, Inter font, etc.) are a separate follow-up pass.
  static final ThemeData _standard = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: HumsafarColors.primary,
      primary: HumsafarColors.primary,
      onPrimary: Colors.white,
      primaryContainer: HumsafarColors.primaryTint,
      onPrimaryContainer: HumsafarColors.primaryDark,
      secondary: HumsafarColors.primaryDark,
      onSecondary: Colors.white,
      secondaryContainer: HumsafarColors.primarySoft,
      onSecondaryContainer: HumsafarColors.primaryDark,
      surface: HumsafarColors.surface,
      onSurface: HumsafarColors.text,
      error: HumsafarColors.danger,
      onError: Colors.white,
      errorContainer: HumsafarColors.dangerTint,
      onErrorContainer: HumsafarColors.danger,
      outline: HumsafarColors.border,
    ),
    scaffoldBackgroundColor: HumsafarColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: HumsafarColors.surface,
      foregroundColor: HumsafarColors.text,
      elevation: 0,
    ),
    textTheme: _baseTextTheme,
  );

  // FR-P2: large-text + high-contrast mode.
  // - Text sizes scaled up ~25% over the standard theme.
  // - Colors pinned to a fixed black/white/amber palette instead of a
  //   generated Material 3 seed scheme, so contrast ratios stay predictable
  //   and don't drift if the seed color ever changes later (NFR-08).
  static final ThemeData _highContrast = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.highContrastLight(
      primary: Colors.black,
      onPrimary: Colors.white,
      secondary: Color(0xFFB45309), // amber-800: dark enough for 4.5:1 on white
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      error: Color(0xFFB00020),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    textTheme: _scaledTextTheme(_baseTextTheme, 1.25),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(64, 56), // bigger tap targets alongside bigger text
        // Bug fix (2026-08-12): deliberately NOT setting a raw `textStyle:`
        // here anymore. Every ElevatedButton internally re-wraps itself in
        // its own AnimatedTheme (Flutter's ButtonStyleButton, not ours),
        // which lerps the FULL ambient ThemeData on every accessibility
        // toggle — including this field. A bare `const TextStyle(...)`
        // defaults to `inherit: true` and never passes through
        // ThemeData's own textTheme-merge pipeline, so it stayed inherit
        // TRUE while everything else (bodyLarge, titleLarge, and the
        // button's own default label style in the standard theme) gets
        // forced to inherit FALSE by that pipeline. That mismatch is what
        // "Failed to interpolate TextStyles with different inherit
        // values" was actually pointing at. Fixed below by driving the
        // bold weight through textTheme.labelLarge instead, so it goes
        // through the same safe merge as every other role.
      ),
    ),
  );

  static const TextTheme _baseTextTheme = TextTheme(
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
  );

  static TextTheme _scaledTextTheme(TextTheme base, double factor) {
    TextStyle? scale(TextStyle? style) => style?.copyWith(fontSize: (style.fontSize ?? 14) * factor);
    return base.copyWith(
      bodyLarge: scale(base.bodyLarge),
      bodyMedium: scale(base.bodyMedium),
      titleLarge: scale(base.titleLarge),
      // Bold button/label text in high-contrast mode. This role feeds
      // ElevatedButton's default label style (Material 3 uses labelLarge
      // for button text) and, unlike the old elevatedButtonTheme.textStyle
      // override, it flows through ThemeData's textTheme-merge pipeline —
      // same safe path as bodyLarge/titleLarge above — so its `inherit`
      // flag stays consistent with the standard theme's fallback instead
      // of clashing with it.
      labelLarge: const TextStyle(fontWeight: FontWeight.w700),
    );
  }
}
