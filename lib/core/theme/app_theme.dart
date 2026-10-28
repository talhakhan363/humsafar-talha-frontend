import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  /// [languageCode] changes both themes' font (fix #8 below covers the
  /// standard theme; high-contrast was fixed 2026-10-27 — Sarim's ICP-1
  /// step 22 finding: it was skipping the Urdu font entirely and silently
  /// falling back to the phone's own Naskh font instead of Noto Nastaliq
  /// Urdu, because `_highContrast` never applied a GoogleFonts text theme
  /// at all. The "keep Talha's existing theme" handoff note this used to
  /// cite was about the fixed black/white/amber COLOR scheme below, not
  /// an instruction to skip the Urdu font swap too). Callers: see
  /// main.dart's doc comment on why one call site must pass a FIXED
  /// language code regardless of the real chosen one, and only the other
  /// is allowed to vary per rebuild — that reasoning is about
  /// AccessibilityMode.standard specifically, so it's unaffected by this.
  static ThemeData themeFor(AccessibilityMode mode, String languageCode) {
    switch (mode) {
      case AccessibilityMode.standard:
        return _standardFor(languageCode);
      case AccessibilityMode.highContrast:
        return _highContrast(languageCode);
    }
  }

  /// Fixed 2026-10-25 — Design Handoff v1.0 fix #1 (section 3): this used
  /// to generate its whole palette from one green seed colour
  /// (`0xFF2E7D32`), which is why the app still looked green everywhere
  /// instead of Sarim's teal brand. Now built from [HumsafarColors]
  /// instead, with `fromSeed`'s override parameters pinning the roles the
  /// handoff actually specifies (primary/secondary/surface/error/outline)
  /// rather than letting Material 3 derive them from a seed guess.
  ///
  /// Also fix #8 (section 2.3): Latin text uses Inter; Urdu falls back to
  /// Noto Nastaliq Urdu, since Inter has no Urdu letters and Android would
  /// otherwise silently substitute its own system font. Both come from
  /// google_fonts (see pubspec.yaml's comment on that dependency) keyed on
  /// [languageCode] — this is why [_standard] became a method instead of
  /// the single cached `static final` field it used to be; GoogleFonts'
  /// lookup is cheap (no network call itself — the actual glyph data is
  /// fetched/cached lazily by the rendering pipeline the first time it's
  /// actually drawn), so recomputing this on each relevant rebuild is not
  /// a real cost.
  static ThemeData _standardFor(String languageCode) {
    final fontTextTheme = languageCode == 'ur'
        ? GoogleFonts.getTextTheme('Noto Nastaliq Urdu', _baseTextTheme)
        : GoogleFonts.getTextTheme('Inter', _baseTextTheme);
    return ThemeData(
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
      textTheme: fontTextTheme,
    );
  }

  // FR-P2: large-text + high-contrast mode.
  // - Text sizes scaled up ~25% over the standard theme.
  // - Colors pinned to a fixed black/white/amber palette instead of a
  //   generated Material 3 seed scheme, so contrast ratios stay predictable
  //   and don't drift if the seed color ever changes later (NFR-08).
  //
  // Fixed 2026-10-27 (Sarim's ICP-1 step 22 finding): became a method
  // taking [languageCode], same reasoning as [_standardFor] — this was a
  // `static final` field, built once with [_baseTextTheme] directly, so
  // it could never pick up the Urdu GoogleFonts theme and silently fell
  // back to the phone's own Naskh font instead of Noto Nastaliq Urdu.
  static ThemeData _highContrast(String languageCode) {
    final fontTextTheme = languageCode == 'ur'
        ? GoogleFonts.getTextTheme('Noto Nastaliq Urdu', _baseTextTheme)
        : GoogleFonts.getTextTheme('Inter', _baseTextTheme);
    return ThemeData(
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
      textTheme: _scaledTextTheme(fontTextTheme, 1.25),
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
  }

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
      //
      // Bug fix (2026-10-28, Sarim's ICP-1 retest on debug-apk-1.7): this
      // used to be a bare `const TextStyle(fontWeight: FontWeight.w700)`,
      // which has no fontFamily and so REPLACED `base.labelLarge` (the
      // Nastaliq/Inter GoogleFonts style from fix above) instead of
      // building on it. Every button, FAB and TextButton uses labelLarge,
      // so every Urdu button label silently fell back to the phone's own
      // Naskh font in high-contrast mode, while normal body/title text
      // (bodyLarge/titleLarge above) correctly stayed Nastaliq — exactly
      // what Sarim found on screenshots of the Dependent home buttons.
      // Fixed by building on `base.labelLarge` via `copyWith` instead of
      // replacing it outright, so the font family survives and only the
      // weight changes — same pattern already used for bodyLarge/titleLarge.
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
