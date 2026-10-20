import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/screens/role_select_screen.dart';
import '../../features/guardian/screens/guardian_home_screen.dart';
import '../../features/guardian/screens/link_dependent_screen.dart';
import '../../features/guardian/screens/dependent_detail_screen.dart';
import '../../features/guardian/screens/invite_secondary_screen.dart';
import '../../features/guardian/screens/permissions_dashboard_screen.dart';
import '../../features/guardian/screens/my_access_screen.dart';
import '../../features/guardian/screens/live_map_screen.dart';
import '../../features/dependent/screens/dependent_home_screen.dart';
import '../../features/dependent/screens/coming_soon_screen.dart';
import '../../features/dependent/screens/panic_screen.dart';
import '../../features/dependent/screens/wellness_check_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/accept_invite_screen.dart';
import '../../features/kyc/screens/guardian_verification_screen.dart';
import '../../features/kyc/screens/dependent_kyc_screen.dart';
import '../guardian/dependent_summary.dart';

// Task 1.8 — Navigation shell. Task 1.11 — added auth/KYC routes. Task 2.5
// Step E — added the linkage/permissions routes below. These all use
// `extra` rather than path params to pass data forward (a dependent
// summary or a dependent id) - consistent with how the rest of this
// router already works, and this app doesn't do real deep-linking yet so
// static paths are enough; no need for :id segments.
//
// Fix (post-1.11): switched every route from `builder:` to `pageBuilder:`
// with `NoTransitionPage`. Reason: the default page-transition animation
// keeps the outgoing AND incoming screen mounted at once for its
// duration. Toggling the accessibility theme rebuilds the whole app
// (theme: lives on MaterialApp.router, the root), and if that rebuild
// landed while two screens' Material widgets were both alive mid-
// transition, it triggered a "GlobalKey used multiple times" crash in
// Flutter's internal ink-rendering code. Removing the transition removes
// the overlap window entirely.
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
        path: '/invitations/accept',
        name: 'accept-invite',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const AcceptInviteScreen()),
      ),
      GoRoute(
        path: '/kyc/guardian',
        name: 'kyc-guardian',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const GuardianVerificationScreen()),
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
        path: '/guardian/link-dependent',
        name: 'link-dependent',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const LinkDependentScreen()),
      ),
      GoRoute(
        path: '/guardian/dependent-detail',
        name: 'dependent-detail',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: DependentDetailScreen(summary: state.extra as DependentSummary),
        ),
      ),
      GoRoute(
        path: '/guardian/invite-secondary',
        name: 'invite-secondary',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: InviteSecondaryScreen(dependentId: state.extra as String),
        ),
      ),
      GoRoute(
        path: '/guardian/permissions',
        name: 'permissions-dashboard',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: PermissionsDashboardScreen(dependentId: state.extra as String),
        ),
      ),
      GoRoute(
        path: '/guardian/my-access',
        name: 'my-access',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: MyAccessScreen(dependentId: state.extra as String),
        ),
      ),
      GoRoute(
        path: '/guardian/live-map',
        name: 'live-map',
        pageBuilder: (context, state) {
          final summary = state.extra as DependentSummary;
          return NoTransitionPage(
            key: state.pageKey,
            child: LiveMapScreen(dependentId: summary.dependentId, dependentLabel: summary.email),
          );
        },
      ),
      GoRoute(
        path: '/dependent',
        name: 'dependent-home',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const DependentHomeScreen()),
      ),
      // Task 3.10 named these as real destinations with a placeholder
      // screen each, to be swapped for the real thing task by task.
      // Task 3.11 (2026-10-20) swapped Panic in; Task 3.12 (same day)
      // swapped Wellness Check in. Medication (3.13) is still the
      // placeholder — not a silent gap, see ComingSoonScreen's doc
      // comment.
      GoRoute(
        path: '/dependent/panic',
        name: 'dependent-panic',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const PanicScreen()),
      ),
      GoRoute(
        path: '/dependent/wellness-check',
        name: 'dependent-wellness-check',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const WellnessCheckScreen()),
      ),
      GoRoute(
        path: '/dependent/medication',
        name: 'dependent-medication',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const ComingSoonScreen(kind: ComingSoonKind.medication)),
      ),
    ],
  );
});
