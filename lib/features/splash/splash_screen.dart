import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
/// straight to /role-select - no point calling the backend for a brand
/// new install. If one IS stored, GET /auth/me is the check: the shared
/// ApiClient already refreshes-and-retries transparently on an expired
/// access token (Step A), so this one call covers both "access token
/// still good" and "it expired but the refresh token still works."
///
/// Any failure from that call - no valid session left, refresh token also
/// expired/invalid - means "not logged in": tokens are cleared and we go
/// to /role-select, same as a first run, rather than retry forever.
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

  @override
  void initState() {
    super.initState();
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
      // registration would otherwise strand someone at /role-select with
      // no way back in.
      final pending = await ref.read(pendingDependentRegistrationStorageProvider).read();
      if (!mounted) return;
      if (pending != null) {
        ref.read(pendingDependentRegistrationProvider.notifier).state = pending;
        context.go('/kyc/dependent');
        return;
      }
      context.go('/role-select');
      return;
    }

    try {
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/auth/me');
      final user = AppUser.fromJson(response.data!);
      ref.read(currentUserProvider.notifier).state = user;
      await registerPushToken(ref.read);
      if (!mounted) return;

      if (user.isGuardian) {
        bool verified = false;
        try {
          final verification = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/guardians/me/verification');
          verified = (verification.data?['verified'] as bool?) ?? false;
        } on ApiException {
          verified = false;
        }
        if (!mounted) return;
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
      context.go('/role-select');
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
  /// spacing has NOT been checked side-by-side against the real Figma
  /// frame ("Splash → Launch" prototype) — do that before treating this
  /// as pixel-accurate.
  Widget _buildBody() {
    return Column(
      children: [
        const Spacer(flex: 3),
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          width: _symbolSize,
          height: _symbolSize,
          child: Image.asset(
            'assets/brand/logo/symbol/Humsafar_Symbol_v1.0_white-amber_1024.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 24),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          opacity: _showWordmark ? 1 : 0,
          // Spec: "wordmark ... visible part 230 px wide" — `width: 230`
          // on Image itself (not a wrapping SizedBox) is what makes it
          // auto-compute height preserving the source PNG's real aspect
          // ratio (1024x512, 2:1) instead of needing both dimensions
          // spelled out.
          child: const Image(
            image: AssetImage('assets/brand/logo/wordmark/Humsafar_Wordmark_v1.0_white_1024.png'),
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
    );
  }
}
