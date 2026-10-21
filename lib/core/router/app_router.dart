import 'package:flutter/widgets.dart';
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
import '../../features/guardian/screens/medication_schedule_screen.dart';
import '../../features/guardian/screens/wellness_schedule_screen.dart';
import '../../features/guardian/screens/alerts_screen.dart';
import '../../features/guardian/screens/missed_dose_screen.dart';
import '../../features/guardian/screens/emergency_settings_screen.dart';
import '../../features/dependent/screens/dependent_home_screen.dart';
import '../../features/dependent/screens/panic_screen.dart';
import '../../features/dependent/screens/wellness_check_screen.dart';
import '../../features/dependent/screens/medication_confirm_screen.dart';
import '../../features/dependent/screens/alarm_screen.dart';
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
//
// Task 3.13 (2026-10-21): `/dependent/medication` now opens the real
// MedicationConfirmScreen instead of ComingSoonScreen — the last of the
// three Task 3.10 placeholders is gone, so ComingSoonScreen itself (and
// its test) was deleted as dead code rather than left unused. `extra`
// here is a plain `bool?` ("did Home already establish a dose is due
// right now and skip straight to step 2?") - see
// dependent_home_screen.dart's doc comment and
// medication_confirm_screen.dart's `skipPrompt`.
//
// Task 3.15 (2026-10-21): added the two Guardian-side schedule
// configuration routes, following the same `extra: DependentSummary`
// pattern as `/guardian/live-map` (both need `dependentId` plus
// `isPrimary` for permission gating, not just the raw id string the
// permissions/my-access routes take).
//
// Task 3.14 (2026-10-21): added `rootNavigatorKey`, used by
// PushService's notification-tap handler (lib/core/push/push_service.dart
// + main.dart) to navigate from outside the widget tree — a push can be
// tapped from a background or cold-started app, where there's no
// existing BuildContext to call GoRouter.of(context) from. Also added:
// `/guardian/alerts` (mockup 08, the cross-Dependent notification inbox —
// deliberately NOT scoped to one DependentSummary like the routes above
// it, since `GET /notifications` itself is cross-Dependent, one list per
// Guardian covering every linked Dependent); `/guardian/missed-dose`
// (mockup 08b, reached by tapping a missed_dose row in Alerts, `extra` is
// a `{confirmationId, dependentId}` map taken straight from that
// notification's own `data`, not re-fetched); `/guardian/emergency-
// settings` (mockup 14, same `extra: DependentSummary` pattern as the
// 3.15 schedule screens, reached from DependentDetailScreen); and
// `/dependent/alarm` (mockup 24, self-resolving like panic/wellness-
// check/medication, reached only via a remote_alarm push tap for now —
// see alarm_screen.dart's doc comment for the named scope cut on waking
// a locked screen).
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
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
        path: '/guardian/medication-schedule',
        name: 'medication-schedule',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: MedicationScheduleScreen(summary: state.extra as DependentSummary),
        ),
      ),
      GoRoute(
        path: '/guardian/wellness-schedule',
        name: 'wellness-schedule',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: WellnessScheduleScreen(summary: state.extra as DependentSummary),
        ),
      ),
      GoRoute(
        path: '/guardian/alerts',
        name: 'guardian-alerts',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const AlertsScreen()),
      ),
      GoRoute(
        path: '/guardian/missed-dose',
        name: 'missed-dose',
        pageBuilder: (context, state) {
          final args = state.extra as Map<String, String>;
          return NoTransitionPage(
            key: state.pageKey,
            child: MissedDoseScreen(
              confirmationId: args['confirmationId']!,
              dependentId: args['dependentId']!,
              notificationId: args['notificationId'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/guardian/emergency-settings',
        name: 'emergency-settings',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: EmergencySettingsScreen(summary: state.extra as DependentSummary),
        ),
      ),
      GoRoute(
        path: '/dependent',
        name: 'dependent-home',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const DependentHomeScreen()),
      ),
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
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: MedicationConfirmScreen(skipPrompt: state.extra as bool? ?? false),
        ),
      ),
      GoRoute(
        path: '/dependent/alarm',
        name: 'dependent-alarm',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const AlarmScreen()),
      ),
    ],
  );
});
