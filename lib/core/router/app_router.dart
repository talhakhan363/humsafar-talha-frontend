import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/screens/role_select_screen.dart';
import '../../features/guardian/screens/guardian_home_screen.dart';
import '../../features/dependent/screens/dependent_home_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/kyc/screens/guardian_verification_screen.dart';
import '../../features/kyc/screens/dependent_kyc_screen.dart';

// Task 1.8 — Navigation shell. Task 1.11 — added auth/KYC routes.
//
// Fix (post-1.11): switched every route from `builder:` to `pageBuilder:`
// with `NoTransitionPage`. Reason: the default page-transition animation
// keeps the outgoing AND incoming screen mounted at once for its
// duration. Toggling the accessibility theme rebuilds the whole app
// (theme: lives on MaterialApp.router, the root), and if that rebuild
// landed while two screens' Material widgets were both alive mid-
// transition, it triggered a "GlobalKey used multiple times" crash in
// Flutter's internal ink-rendering code. Removing the transition removes
// the overlap window entirely. These are temporary placeholder screens
// (Task 2.5 rebuilds this whole flow against real auth) — trading away
// transition polish here is a reasonable, cheap fix, not a compromise
// worth agonizing over at this stage.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/role-select',
        name: 'role-select',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const RoleSelectScreen()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const RegisterScreen()),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/kyc/guardian',
        name: 'kyc-guardian',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const GuardianVerificationScreen()),
      ),
      GoRoute(
        path: '/kyc/dependent',
        name: 'kyc-dependent',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const DependentKycScreen()),
      ),
      GoRoute(
        path: '/guardian',
        name: 'guardian-home',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const GuardianHomeScreen()),
      ),
      GoRoute(
        path: '/dependent',
        name: 'dependent-home',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const DependentHomeScreen()),
      ),
    ],
  );
});
