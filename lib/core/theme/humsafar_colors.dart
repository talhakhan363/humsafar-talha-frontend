import 'package:flutter/material.dart';

/// Design tokens from Sarim's Design Handoff v1.0 (section 2.1, style guide
/// v0.2 — docs/design/handoff/ in the team repo). These are the single
/// source of truth for every themed colour in the app. [AppTheme]'s
/// standard theme is built from these; individual screens should reference
/// these constants too instead of raw `Colors.*` values — that gap (37
/// files still on Material's default palette) is section 3 of the handoff
/// and is being fixed screen-by-screen as a separate follow-up pass, not
/// all at once in this file.
///
/// Every text/background pair here passes WCAG AA (4.5:1) per the
/// handoff's contrast check (docs/qa/Humsafar_QA_NFR-08_Contrast_Check).
class HumsafarColors {
  HumsafarColors._();

  static const Color primary = Color(0xFF0E7490);
  static const Color primaryDark = Color(0xFF155E75);
  static const Color primaryTint = Color(0xFFECFEFF);
  static const Color primarySoft = Color(0xFFCFFAFE);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color text = Color(0xFF0F172A);
  static const Color muted = Color(0xFF475569);
  static const Color border = Color(0xFFCBD5E1);
  static const Color tabTrack = Color(0xFFE2E8F0);

  /// Verified / inside safe zone / dose taken.
  static const Color success = Color(0xFF15803D);
  static const Color successTint = Color(0xFFDCFCE7);

  /// Missed dose, left zone, urgent voice, band no-data, load errors on
  /// Dependent screens. NOT for Panic or other critical alerts — see
  /// [danger]. Handoff section 2.5: "Warnings and errors on Dependent
  /// screens are amber or grey, never red."
  static const Color warning = Color(0xFFB45309);
  static const Color warningTint = Color(0xFFFEF3C7);

  /// PANIC and critical alerts ONLY. Handoff section 2.5: "Red only for
  /// Panic and critical alerts."
  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerTint = Color(0xFFFEE2E2);
}
