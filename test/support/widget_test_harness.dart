// test/support/widget_test_harness.dart
//
// Shared widget-pump scaffolding for screens that navigate with
// GoRouter's context.go/push/pop (which throw without a real GoRouter
// ancestor — a plain MaterialApp isn't enough). Pulled out of
// panic_screen_test.dart and wellness_check_screen_test.dart (Tasks
// 3.11/3.12), which had each hand-rolled an almost-identical `_wrap`
// function.
//
// Extended for Task 4.6/4.8 (2026-10-22): added `extraOverrides`, so
// `chat_screen_test.dart` can also override
// `audioRecorderSourceProvider`/`audioPlayerSourceProvider` with fakes
// without hand-rolling its own copy of this whole function just to add
// two more overrides. Purely additive — every existing caller (which
// only needs `fakeClient`/`user`) is unaffected by the new, optional,
// empty-by-default parameter.

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

/// A standard logged-in Primary Guardian, for the messaging tests
/// (Task 4.6/4.8) that need to assert on Guardian-only UI (the mic
/// button) the default Dependent user above wouldn't show.
const kTestGuardianUser = AppUser(
  userId: 'g-1',
  email: 'guardian@example.com',
  phone: '03009999999',
  fullName: 'Test Guardian',
  role: 'guardian',
  guardianRole: 'primary',
);

/// Wraps [routes] in a GoRouter + ProviderScope + MaterialApp.router,
/// with [fakeClient] overriding `apiClientProvider` and [user]
/// overriding `currentUserProvider`. [routes] must include the route
/// the test actually lands on first (named by [initialLocation]) plus a
/// stub route (see [stubScreen]) for every destination the screen under
/// test might navigate to. [extraOverrides] adds any further provider
/// overrides a given screen's test needs on top of those two.
Widget wrapWithRouter({
  required ApiClient fakeClient,
  required String initialLocation,
  required List<GoRoute> routes,
  AppUser user = kTestDependentUser,
  List<Override> extraOverrides = const [],
}) {
  final router = GoRouter(initialLocation: initialLocation, routes: routes);
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(fakeClient),
      currentUserProvider.overrideWith((ref) => user),
      ...extraOverrides,
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
/// `GoRoute(path: '/dependent', builder: (_, __) => stubScreen('DEPENDENT_HOME_STUB')).`
/// Just a named Text widget — exists so every test spells this pattern
/// the same way instead of writing `const Text('...')` inline everywhere.
Widget stubScreen(String label) => Text(label);

/// A route stub that pushes [targetPath] onto the stack as soon as it's
/// mounted, so a test can reach the screen under test via `context.push`
/// (as it's always reached in the real app) instead of making it
/// GoRouter's sole/initial route.
///
/// Why this matters: several screens (`add_record_screen.dart`,
/// `add_vital_reading_screen.dart`, `connect_band_screen.dart`, …) call
/// `Navigator.of(context).pop(true)` on save success. That's always
/// safe in the real app, where these screens are only ever reached via
/// `context.push(...)` from a list screen — there's always a route
/// underneath to land on. But if a test makes the screen under test
/// GoRouter's *only* route (as `initialLocation` normally does), that
/// `pop()` empties go_router's match list and trips its
/// `'currentConfiguration.isNotEmpty'` assertion. Routing through this
/// host first — `initialLocation: '/host'`, with `/host` and the real
/// target both in `routes` — gives the stack a second entry so the
/// pop behaves exactly as it does in production.
///
/// Usage:
/// ```dart
/// List<GoRoute> _hostedRoutes() => [
///       GoRoute(path: '/host', builder: (_, __) => const AutoPushHost(targetPath: '/add-record-under-test')),
///       ..._routes(),
///     ];
/// // then: initialLocation: '/host', routes: _hostedRoutes()
/// ```
class AutoPushHost extends StatefulWidget {
  const AutoPushHost({super.key, required this.targetPath, this.extra, this.hostLabel = 'HOST'});

  final String targetPath;
  final Object? extra;
  final String hostLabel;

  @override
  State<AutoPushHost> createState() => _AutoPushHostState();
}

class _AutoPushHostState extends State<AutoPushHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.push(widget.targetPath, extra: widget.extra);
    });
  }

  @override
  Widget build(BuildContext context) => Text(widget.hostLabel);
}
