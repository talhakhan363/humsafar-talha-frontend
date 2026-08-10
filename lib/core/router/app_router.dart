import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/screens/role_select_screen.dart';
import '../../features/guardian/screens/guardian_home_screen.dart';
import '../../features/dependent/screens/dependent_home_screen.dart';

// Task 1.8 — Navigation shell: Guardian app + Dependent app routing.
//
//   /             -> SplashScreen        boot state; later checks a stored JWT
//   /role-select  -> RoleSelectScreen     TEMPORARY dev-only picker — gets
//                                         deleted once real auth (Task 1.3 +
//                                         2.5 wiring) exists
//   /guardian     -> GuardianHomeScreen   entry point into the Guardian app
//   /dependent    -> DependentHomeScreen  entry point into the Dependent app
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/role-select',
        name: 'role-select',
        builder: (context, state) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: '/guardian',
        name: 'guardian-home',
        builder: (context, state) => const GuardianHomeScreen(),
      ),
      GoRoute(
        path: '/dependent',
        name: 'dependent-home',
        builder: (context, state) => const DependentHomeScreen(),
      ),
    ],
  );
});
