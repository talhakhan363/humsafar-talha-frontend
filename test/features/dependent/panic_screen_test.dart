import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/dependent/screens/panic_screen.dart';
import 'package:humsafar_frontend/features/dependent/widgets/panic_hold_button.dart';

import '../../support/fake_api_client.dart';
import '../../support/gesture_test_helpers.dart';
import '../../support/widget_test_harness.dart';

/// TC-3.11-04..09 — soft test cases for Task 3.11's Panic screen. Widget
/// tests against a fake ApiClient (same "soft test" convention as
/// live_map_screen_test.dart) — no login, no device. Unlike
/// DependentHomeScreen, this screen never touches a real plugin
/// (geolocator etc.), so the whole screen is testable end to end,
/// including navigation, via the shared test/support/ harness
/// (`FakeApiClient`, `wrapWithRouter`, `startHoldGesture`) instead of a
/// one-off `_FakeApiClient`/`_wrap` pair living in this file.
void main() {
  testWidgets('TC-3.11-04: no panic open — shows the hold-to-confirm screen', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'active': false, 'panic': null});

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/panic-under-test',
      routes: [
        GoRoute(path: '/panic-under-test', builder: (context, state) => const PanicScreen()),
        GoRoute(path: '/dependent', builder: (context, state) => stubScreen('DEPENDENT_HOME_STUB')),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Need help?'), findsOneWidget);
    expect(find.text('HOLD'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.11-05: a panic already open on arrival shows "Help is coming" directly, no hold UI', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {
          'active': true,
          'panic': {
            'event_id': 'evt-1',
            'status': 'open',
            'tier': 'primary',
            'triggered_at': '2026-10-20T08:00:00Z',
            'acknowledged_at': null,
            'resolved_at': null,
            'notified': 2,
            'already_active': true,
          },
        });

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/panic-under-test',
      routes: [
        GoRoute(path: '/panic-under-test', builder: (context, state) => const PanicScreen()),
        GoRoute(path: '/dependent', builder: (context, state) => stubScreen('DEPENDENT_HOME_STUB')),
      ],
    ));
    await tester.pumpAndSettle();

    // "Help is coming" legitimately appears twice — the AppBar title and
    // the body heading both show it, matching the mockup's own AppBar.
    expect(find.text('Help is coming'), findsNWidgets(2));
    expect(find.text('We told 2 Guardian(s)'), findsOneWidget);
    expect(find.text('Waiting for a Guardian to see this'), findsOneWidget);
    expect(find.text('I am safe now'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.11-06: holding the button POSTs /panic and switches to "Help is coming"', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'active': false, 'panic': null},
      postHandler: (path) => {
        'event_id': 'evt-2',
        'status': 'open',
        'tier': 'primary',
        'triggered_at': '2026-10-20T08:00:00Z',
        'acknowledged_at': null,
        'resolved_at': null,
        'notified': 3,
        'already_active': false,
      },
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/panic-under-test',
      routes: [
        GoRoute(path: '/panic-under-test', builder: (context, state) => const PanicScreen()),
        GoRoute(path: '/dependent', builder: (context, state) => stubScreen('DEPENDENT_HOME_STUB')),
      ],
    ));
    await tester.pumpAndSettle();

    final gesture = await startHoldGesture(tester, find.byType(PanicHoldButton));
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(find.text('Help is coming'), findsNWidgets(2)); // AppBar title + body heading
    expect(find.text('We told 3 Guardian(s)'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.11-07: a failed trigger shows an error and stays on the hold screen', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'active': false, 'panic': null},
      postError: const ApiException(code: 'unexpected_error', message: 'boom'),
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/panic-under-test',
      routes: [
        GoRoute(path: '/panic-under-test', builder: (context, state) => const PanicScreen()),
        GoRoute(path: '/dependent', builder: (context, state) => stubScreen('DEPENDENT_HOME_STUB')),
      ],
    ));
    await tester.pumpAndSettle();

    final gesture = await startHoldGesture(tester, find.byType(PanicHoldButton));
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Need help?'), findsOneWidget);
    expect(find.text("Couldn't send the alert. Check your connection and try again."), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.11-08: an escalated tier shows the emergency-contact note', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {
          'active': true,
          'panic': {
            'event_id': 'evt-3',
            'status': 'open',
            'tier': 'external_contact',
            'triggered_at': '2026-10-20T08:00:00Z',
            'acknowledged_at': null,
            'resolved_at': null,
            'notified': 1,
            'already_active': true,
          },
        });

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/panic-under-test',
      routes: [
        GoRoute(path: '/panic-under-test', builder: (context, state) => const PanicScreen()),
        GoRoute(path: '/dependent', builder: (context, state) => stubScreen('DEPENDENT_HOME_STUB')),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('This has reached your emergency contact.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.11-09: "I am safe now" calls resolve and leaves the Panic screen', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {
        'active': true,
        'panic': {
          'event_id': 'evt-4',
          'status': 'open',
          'tier': 'primary',
          'triggered_at': '2026-10-20T08:00:00Z',
          'acknowledged_at': '2026-10-20T08:01:00Z',
          'resolved_at': null,
          'notified': 2,
          'already_active': true,
        },
      },
      postHandler: (path) => {'event_id': 'evt-4', 'status': 'resolved'},
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/panic-under-test',
      routes: [
        GoRoute(path: '/panic-under-test', builder: (context, state) => const PanicScreen()),
        GoRoute(path: '/dependent', builder: (context, state) => stubScreen('DEPENDENT_HOME_STUB')),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('I am safe now'), findsOneWidget);
    await tester.tap(find.text('I am safe now'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(find.text('DEPENDENT_HOME_STUB'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
