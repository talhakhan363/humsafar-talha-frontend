// test/support/widget_test_harness.dart
//
// Shared widget-pump scaffolding for screens that navigate with
// GoRouter's context.go/push/pop (which throw without a real GoRouter
// ancestor — a plain MaterialApp isn't enough). Pulled out of
// panic_screen_test.dart and wellness_check_screen_test.dart (Tasks
// 3.11/3.12), which had each hand-rolled an almost-identical `_wrap`
// function.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/auth/app_user.dart';
import 'package:humsafar_frontend/core/auth/current_user_provider.dart';
import 'package:humsafar_frontend/core/network/api_client.dart';
import 'package:humsafar_frontend/core/network/providers.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

/// A standard logged-in Dependent, reused across every screen test that
/// needs *some* current user but doesn't care about the exact details.
/// For a test that genuinely needs a different value, build a fresh
/// `AppUser(...)` directly and pass it as [wrapWithRouter]'s `user`.
const kTestDependentUser = AppUser(
  userId: 'dep-1',
  email: 'dep@example.com',
  phone: '03001234567',
  fullName: 'Test Dependent',
  role: 'dependent',
  guardianRole: null,
);

/// Wraps [routes] in a GoRouter + ProviderScope + MaterialApp.router,
/// with [fakeClient] overriding `apiClientProvider` and [user]
/// overriding `currentUserProvider`. [routes] must include the route
/// the test actually lands on first (named by [initialLocation]) plus a
/// stub route (see [stubScreen]) for every destination the screen under
/// test might navigate to.
Widget wrapWithRouter({
  required ApiClient fakeClient,
  required String initialLocation,
  required List<GoRoute> routes,
  AppUser user = kTestDependentUser,
}) {
  final router = GoRouter(initialLocation: initialLocation, routes: routes);
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(fakeClient),
      currentUserProvider.overrideWith((ref) => user),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// A stub destination screen for navigation assertions, e.g.
/// `GoRoute(path: '/dependent', builder: (_, __) => stubScreen('DEPENDENT_HOME_STUB'))`.
/// Just a named Text widget — exists so every test spells this pattern
/// the same way instead of writing `const Text('...')` inline everywhere.
Widget stubScreen(String label) => Text(label);
