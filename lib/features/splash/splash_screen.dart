import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/app_user.dart';
import '../../core/auth/current_user_provider.dart';
import '../../core/auth/pending_dependent_registration_provider.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/providers.dart';
import '../../core/push/push_service.dart';
import '../../core/theme/humsafar_colors.dart';

/// Task 1.8 built a dummy 600ms delay then a hardcoded /role-select. Task
/// 2.5 Step D wires this to an actual "are we already logged in" check.
///
/// If no refresh token is stored, we skip the network entirely and go
/// straight to /welcome - no point calling the backend for a brand
/// new install. If one IS stored, GET /auth/me is the check: the shared
/// ApiClient already refreshes-and-retries transparently on an expired
/// access token (Step A), so this one call covers both "access token
/// still good" and "it expired but the refresh token still works."
///
/// Any failure from that call - no valid session left, refresh token also
/// expired/invalid - means "not logged in": tokens are cleared and we go
/// to /welcome, same as a first run, rather than retry forever.
///
/// Bug fix (UI-01/F-07, Sarim's 22 Nov design-vs-app report): this used to
/// send a signed-out user to /role-select, a dev-only screen (see
/// role_select_screen.dart's own "TEMPORARY, DEV-ONLY" comment) with no
/// splash, logo or Welcome branding at all. /welcome is the real,
/// designed screen (mockup 01) a real user should land on; /role-select
/// still exists and still works, just isn't reachable from here anymore
/// — it's a quick manual way to jump straight into Guardian/Dependent
/// mode for testing, reached by typing the route directly.
///
/// Task 3.14 (2026-10-21): a restored session also (re-)registers this
/// device's push token (`registerPushToken`, best-effort) — covers the
/// case where the app was killed and reopened days later with a rotated
/// FCM token that was never sent while the app wasn't running.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

/// Task 1.12/PR #106 (Sarim's 8 Nov spec, docs/design/1.12_identity_access/
/// README.md's "Splash and launch" section) — this is "00b Launch": the
/// first Flutter screen shown while the session check above runs, teal
/// background matching the native "00 Splash" screen (see pubspec.yaml's
/// `flutter_native_splash:` config) so the transition between the two
/// reads as one continuous screen instead of a visible swap.
class _SplashScreenState extends ConsumerState<SplashScreen> {
  // Spec: "symbol moves up and shrinks (128 -> 112 px) ... 0.6s ease
  // in-out", triggered one frame in via the post-frame callback below so
  // it's actually visible instead of starting mid-build.
  double _symbolSize = 128;
  bool _showWordmark = false;
  // Spec: "white loader 28 px ... shown only if the check takes longer
  // than about 300ms" — starts false, flips true only if _checkSession()
  // is still running when this fires.
  bool _showLoader = false;
  Timer? _loaderDelayTimer;

  // Bug fix (UI-14, Sarim's 1.9.5 retest: "the splash only shows ~0.5s"):
  // `_checkSession()` has no floor on how long it takes — a brand new
  // install with no refresh token stored skips the network call entirely
  // (see that method's own doc comment) and a signed-in session can
  // resolve `GET /auth/me` in well under a second against the deployed
  // backend. Either way, `context.go(...)` could fire before the symbol's
  // own 600ms shrink/wordmark-fade animation above had any real chance to
  // play, cutting the branded moment this screen exists for down to
  // whatever the network/storage happened to take — not a fixed, designed
  // duration. Every `context.go(...)` call in `_checkSession` now awaits
  // this shared minimum first; the delay runs concurrently with the real
  // session check (both start at the same moment in `initState`), so a
  // slow network still takes exactly as long as it takes — this only
  // stops a FAST path from cutting the splash short.
  //
  // Bug fix (`flutter test` regression caught right after the above): a
  // bare `Future.delayed(...)` field was a real `Timer` under the hood
  // with nothing ever cancelling it — `widget_test.dart`'s plain
  // `pumpWidget(HumsafarApp())` smoke test disposes this screen well
  // before 900ms of fake-async time elapses, and flutter_test's own
  // `AutomatedTestWidgetsFlutterBinding` asserts no Timer is left pending
  // after disposal ("A Timer is still pending even after the widget tree
  // was disposed"). Same shape as `_loaderDelayTimer` right above, which
  // already gets cancelled in `dispose()` for exactly this reason — this
  // minimum-display gate now does too, via an explicit `Timer` driving a
  // `Completer` instead of a bare `Future.delayed`.
  final Completer<void> _minimumDisplayCompleter = Completer<void>();
  Timer? _minimumDisplayTimer;

  @override
  void initState() {
    super.initState();
    _minimumDisplayTimer = Timer(const Duration(milliseconds: 900), () {
      if (!_minimumDisplayCompleter.isCompleted) _minimumDisplayCompleter.complete();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Bug fix (Talha's 22 Nov real-device test): hands off from the
      // native "00 Splash" to this screen at exactly this moment — see
      // main.dart's `FlutterNativeSplash.preserve()` call for the other
      // half of this fix. This is the first frame this screen's own
      // content is actually on screen and ready to be seen, so it's the
      // right moment to remove the native one instead of letting Android
      // decide on its own schedule.
      FlutterNativeSplash.remove();
      if (!mounted) return;
      setState(() {
        _symbolSize = 112;
        _showWordmark = true;
      });
    });
    _loaderDelayTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showLoader = true);
    });
    _checkSession();
  }

  @override
  void dispose() {
    _loaderDelayTimer?.cancel();
    _minimumDisplayTimer?.cancel();
    // Lets anything still awaiting `_minimumDisplayCompleter.future` (every
    // `!mounted` check right after it already guards against acting on a
    // disposed screen) resolve immediately instead of hanging — mirrors
    // cancelling the Timer itself, just for the Completer side of the pair.
    if (!_minimumDisplayCompleter.isCompleted) _minimumDisplayCompleter.complete();
    super.dispose();
  }

  Future<void> _checkSession() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final refreshToken = await tokenStorage.readRefreshToken();

    if (refreshToken == null) {
      // Bug fix (2026-10-30): resume path for an interrupted Dependent
      // KYC — see pending_dependent_registration_provider.dart's doc
      // comment. A Dependent never gets tokens until kyc-verify succeeds,
      // so this is exactly the branch where an unfinished KYC
      // registration would otherwise strand someone at /welcome with
      // no way back in.
      final pending = await ref.read(pendingDependentRegistrationStorageProvider).read();
      if (!mounted) return;
      if (pending != null) {
        ref.read(pendingDependentRegistrationProvider.notifier).state = pending;
        await _minimumDisplayCompleter.future;
        if (!mounted) return;
        context.go('/kyc/dependent');
        return;
      }
      await _minimumDisplayCompleter.future;
      if (!mounted) return;
      context.go('/welcome');
      return;
    }

    try {
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/auth/me');
      final user = AppUser.fromJson(response.data!);
      ref.read(currentUserProvider.notifier).state = user;
      await registerPushToken(ref.read);
      if (!mounted) return;

      bool goToGuardian = false;
      bool verified = false;
      if (user.isGuardian) {
        goToGuardian = true;
        try {
          final verification = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/guardians/me/verification');
          verified = (verification.data?['verified'] as bool?) ?? false;
        } on ApiException {
          verified = false;
        }
        if (!mounted) return;
      }
      // Bug fix (UI-14): the session check (and, for a Guardian, the
      // extra verification check above) already ran concurrently with
      // `_minimumDisplayCompleter.future` since both started in `initState` — this only
      // waits out whatever's left of it, it never adds real network time
      // on top.
      await _minimumDisplayCompleter.future;
      if (!mounted) return;
      if (goToGuardian) {
        context.go(verified ? '/guardian' : '/kyc/guardian');
      } else {
        context.go('/dependent');
      }
      // Bug fix (F-24, Sarim's 9 Nov report): applies a cold-start
      // notification tap only now, AFTER the context.go(...) above has
      // already resolved the app's real home route — see
      // pendingColdStartNotificationProvider's doc comment in
      // push_service.dart for the race this fixes. Deliberately not
      // called on the KYC-incomplete/no-session paths above and below —
      // a notification deep link doesn't make sense ahead of an
      // unfinished KYC or with no valid session to show it in.
      _applyPendingColdStartNotification();
    } on ApiException {
      await tokenStorage.clear();
      if (!mounted) return;
      await _minimumDisplayCompleter.future;
      if (!mounted) return;
      context.go('/welcome');
    }
  }

  void _applyPendingColdStartNotification() {
    final message = ref.read(pendingColdStartNotificationProvider);
    if (message == null) return;
    ref.read(pendingColdStartNotificationProvider.notifier).state = null;
    if (!mounted) return;
    navigateForNotificationTap(context, message);
  }

  @override
  Widget build(BuildContext context) {
    // Spec: "Teal background, white status-bar icons."
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: HumsafarColors.primary,
        body: SafeArea(
          // Spec: 'Screen-reader label: "Humsafar, loading".' — a fixed,
          // non-localized phrase per the design spec itself (same
          // "brand name doesn't translate" reasoning as the wordmark
          // image below being a fixed English asset regardless of the
          // chosen app language).
          child: Semantics(
            label: 'Humsafar, loading',
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  /// **Unverified approximation, flagged rather than assumed exact** — the
  /// design spec gives absolute pixel y-coordinates (symbol centred at y
  /// 300, wordmark top at y 384, loader at y 678) measured against a
  /// specific Figma frame height that isn't recorded anywhere this fix
  /// could read it from. Hard-coding those pixels against an assumed
  /// frame size would only be right on one exact screen size and wrong on
  /// every other phone. Using proportional `Spacer` weights instead keeps
  /// the same relative layout (symbol upper-middle, wordmark just below
  /// it, loader well below that) across screen sizes, but the exact
  /// *vertical* spacing has NOT been checked side-by-side against the real
  /// Figma frame ("Splash → Launch" prototype) — do that before treating
  /// this as pixel-accurate.
  ///
  /// Bug fix (UI-14, Sarim's report on debug-apk-1.9.2): the symbol showed
  /// small and top-left and the loader bottom-left, instead of centred.
  /// Root cause confirmed by reading this method, not guessed — `Column`'s
  /// default `crossAxisAlignment.center` only centres children WITHIN the
  /// Column's own width, and a bare `Column` (no `width`/stretch applied
  /// by a parent) sizes itself to its widest child rather than filling the
  /// screen; with nothing to fill or centre that narrower box itself
  /// within the Scaffold, it — and every child inside it — sat flush
  /// against the left edge. Wrapping it in a `SizedBox(width:
  /// double.infinity)` gives the Column the full screen width to centre
  /// its children within, which is the only change this fix makes; the
  /// vertical Spacer proportions below are unchanged.
  Widget _buildBody() {
    return SizedBox(
      width: double.infinity,
      child: Column(
      children: [
        const Spacer(flex: 3),
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          width: _symbolSize,
          height: _symbolSize,
          // Brand v2.0 (Sarim's 22 Nov handoff, assets/brand/README.md):
          // "Splash and launch (00/00b): icon splash/
          // Humsafar_Splash_Icon_v2.0_1152.png" — 00b reuses the exact
          // same file as the native 00 splash (not a separate "symbol"
          // asset) so the handoff is pixel-identical, not just similar.
          child: Image.asset(
            'assets/brand/splash/Humsafar_Splash_Icon_v2.0_1152.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 24),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          opacity: _showWordmark ? 1 : 0,
          // Spec: "wordmark ... visible part 230 px wide" — `width: 230`
          // on the SvgPicture itself (not a wrapping SizedBox) auto-
          // computes height preserving the source's real aspect ratio.
          // Brand v2.0: the wordmark now ships as an SVG, not a PNG
          // (assets/brand/README.md), spec names this exact file:
          // "Humsafar_Wordmark_v2.0_white.svg ... visible part 230 px
          // wide".
          child: SvgPicture.asset(
            'assets/brand/logo/exports/wordmark/Humsafar_Wordmark_v2.0_white.svg',
            width: 230,
          ),
        ),
        const Spacer(flex: 4),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _showLoader ? 1 : 0,
          child: const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              // Spec: "30% white track" — the ring's unfilled portion.
              backgroundColor: Color(0x4DFFFFFF),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        const Spacer(flex: 2),
      ],
      ),
    );
  }
}
