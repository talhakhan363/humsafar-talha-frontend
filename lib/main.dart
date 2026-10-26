import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import 'core/auth/current_user_provider.dart';
import 'core/localization/app_locale_provider.dart';
import 'core/push/push_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/accessibility_mode.dart';
import 'core/theme/accessibility_mode_provider.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  // Task 3.14 — Firebase must be initialized before anything touches
  // FirebaseMessaging, and the background message handler must be
  // registered before runApp (it has to be in place even if the app is
  // killed moments later — that's the whole point of a background
  // handler). See push_service.dart's doc comments for why both of these
  // are otherwise minimal.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: HumsafarApp(),
    ),
  );
}

class HumsafarApp extends ConsumerStatefulWidget {
  const HumsafarApp({super.key});

  @override
  ConsumerState<HumsafarApp> createState() => _HumsafarAppState();
}

class _HumsafarAppState extends ConsumerState<HumsafarApp> {
  @override
  void initState() {
    super.initState();
    // Task 3.14 — one-time push wiring. Done here (not in SplashScreen)
    // because a notification tap can cold-start the app straight into
    // this widget before SplashScreen's own session check has run, and
    // the channels/permission-request need to exist regardless of which
    // screen ends up on top.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializePush());
  }

  /// Wrapped in a try/catch for the same "push must never break core app
  /// flows" reasoning as `registerPushToken`/`unregisterPushToken` (see
  /// push_service.dart's doc comments) — if `Firebase.initializeApp()`
  /// hasn't run (or the platform has no Google Play Services), the rest
  /// of the app must still work. This is also what keeps
  /// `test/widget_test.dart`'s plain `pumpWidget(HumsafarApp())` smoke
  /// test passing: that test never bootstraps Firebase at all (nor does
  /// it override `apiClientProvider` the way the real screens' own
  /// tests do), so without this catch, every widget test that pumps
  /// `HumsafarApp` itself (not just push-specific tests) would crash on
  /// `FirebaseMessaging.instance` with "No Firebase App '[DEFAULT]' has
  /// been created".
  Future<void> _initializePush() async {
    try {
      final pushService = ref.read(pushServiceProvider);
      await pushService.initializeChannelsAndHandlers(onMessageTapped: _handleNotificationTap);
      // "Whenever Firebase gives the app a new token" (notification_contract.md)
      // — only re-register while someone is actually signed in; a token
      // refresh with nobody logged in has nothing to register it against.
      pushService.onTokenRefresh.listen((_) {
        if (ref.read(currentUserProvider) != null) {
          registerPushToken(ref.read);
        }
      });
    } catch (_) {
      // best-effort, see doc comment above
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    // Task 4.7 — incoming_call needs more than a route string (see
    // push_service.dart's incomingCallPushData doc comment), so it's
    // checked first, ahead of the generic route-string mapper below.
    final callData = incomingCallPushData(message.data);
    if (callData != null) {
      GoRouter.of(context).push('/calls/incoming', extra: callData);
      return;
    }
    final route = routeForNotificationType(message.data['type'] as String?);
    if (route == null) return;
    GoRouter.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
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
      // Fix #8 (2026-10-25): languageCode is hardcoded 'en' here on
      // purpose, NOT Localizations.localeOf(context) or chosenLocale —
      // see the comment block above. This value must stay IDENTICAL
      // across rebuilds (same reasoning as AccessibilityMode.standard
      // being hardcoded here already); the real, locale-aware font swap
      // happens below in `builder`, through the plain (non-animated)
      // Theme widget this comment block already set up for exactly this
      // kind of safe, reactive swap.
      theme: AppTheme.themeFor(AccessibilityMode.standard, 'en'),
      routerConfig: router,
      locale: chosenLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // The REAL, live theme swap happens here instead: a plain (non-
      // animated) Theme widget wrapping the router's content. Toggling
      // accessibilityMode now just replaces the ThemeData outright on the
      // next frame — no lerp, no interpolation, no assertion to trip.
      builder: (context, child) {
        // Fix #8 (2026-10-25): this is the safe spot for the font to vary
        // by language — plain Theme, not AnimatedTheme, so switching
        // languages just replaces the ThemeData outright on the next
        // frame, same "no lerp, no interpolation" reasoning as the
        // accessibility-mode swap this builder already existed for.
        return Theme(
          data: AppTheme.themeFor(accessibilityMode, Localizations.localeOf(context).languageCode),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
