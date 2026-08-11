import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import 'core/localization/app_locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/accessibility_mode.dart';
import 'core/theme/accessibility_mode_provider.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: HumsafarApp(),
    ),
  );
}

class HumsafarApp extends ConsumerWidget {
  const HumsafarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final accessibilityMode = ref.watch(accessibilityModeProvider);
    final chosenLocale = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      title: 'Humsafar',
      debugShowCheckedModeBanner: false,
      // Bug fix (2026-08-11): DO NOT pass a mode-dependent theme here.
      // MaterialApp wraps `theme:` in its own internal AnimatedTheme, which
      // *animates* between the old and new ThemeData on every change via
      // ThemeData.lerp -> TextTheme.lerp -> TextStyle.lerp. That lerp
      // asserts both sides have the same TextStyle.inherit flag, and our
      // _standard/_highContrast themes are structurally asymmetric enough
      // (highContrast alone sets appBarTheme/elevatedButtonTheme, and only
      // 3 of ~15 TextTheme roles are ever explicitly set) that the
      // assertion fails mid-interpolation. That's the real cause of the
      // "Failed to interpolate TextStyles with different inherit values"
      // crash (and the GlobalKey/ink-features errors downstream of it) —
      // not routing, not SegmentedButton.
      //
      // Keeping this value CONSTANT means MaterialApp's internal
      // AnimatedTheme always animates from a ThemeData to itself (a no-op,
      // and since AppTheme's fields are `static final`, it's even the same
      // identical instance every rebuild) — so it never actually
      // interpolates and the assertion never runs.
      theme: AppTheme.themeFor(AccessibilityMode.standard),
      routerConfig: router,
      locale: chosenLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // The REAL, live theme swap happens here instead: a plain (non-
      // animated) Theme widget wrapping the router's content. Toggling
      // accessibilityMode now just replaces the ThemeData outright on the
      // next frame — no lerp, no interpolation, no assertion to trip.
      builder: (context, child) {
        return Theme(
          data: AppTheme.themeFor(accessibilityMode),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
