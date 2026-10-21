import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../core/auth/app_user.dart';
import '../../core/auth/current_user_provider.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/providers.dart';
import '../../core/push/push_service.dart';

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

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final refreshToken = await tokenStorage.readRefreshToken();

    if (refreshToken == null) {
      if (!mounted) return;
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
    } on ApiException {
      await tokenStorage.clear();
      if (!mounted) return;
      context.go('/role-select');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          AppLocalizations.of(context)!.appTitle,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
