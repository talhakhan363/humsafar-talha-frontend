import 'package:flutter/material.dart';

import 'accessibility_mode.dart';

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

  static final ThemeData _standard = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
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
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );

  static const TextTheme _baseTextTheme = TextTheme(
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
  );

  static TextTheme _scaledTextTheme(TextTheme base, double factor) {
    TextStyle? scale(TextStyle? style) =>
        style?.copyWith(fontSize: (style.fontSize ?? 14) * factor);
    return base.copyWith(
      bodyLarge: scale(base.bodyLarge),
      bodyMedium: scale(base.bodyMedium),
      titleLarge: scale(base.titleLarge),
    );
  }
}
