import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/dependent/screens/wellness_check_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

/// TC-3.12-04..09 — soft test cases for Task 3.12's Wellness Check
/// screen. Same shared test/support/ harness (`FakeApiClient`,
/// `wrapWithRouter`) as panic_screen_test.dart, instead of a one-off
/// `_FakeApiClient`/`_wrap` pair living in this file.
void main() {
  testWidgets('TC-3.12-04: no pending check — shows the empty state, "I need help" still offered', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': []});

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/wellness-under-test',
      routes: [
        GoRoute(path: '/wellness-under-test', builder: (context, state) => const WellnessCheckScreen()),
        GoRoute(path: '/dependent', builder: (context, state) => stubScreen('DEPENDENT_HOME_STUB')),
        GoRoute(path: '/dependent/panic', builder: (context, state) => stubScreen('PANIC_SCREEN_STUB')),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text("There's no wellness check waiting for a response right now."), findsOneWidget);
    expect(find.text('I need help'), findsOneWidget);
    expect(find.text('Yes, I am OK'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.12-05: a pending check shows the countdown and "Yes, I am OK"', (tester) async {
    final deadline = DateTime.now().toUtc().add(const Duration(minutes: 10));
    final fakeClient = FakeApiClient(getHandler: (_) => {
          'items': [
            {
              'response_id': 'wcr-1',
              'wc_id': 'wc-1',
              'prompted_at': DateTime.now().toUtc().toIso8601String(),
              'deadline': deadline.toIso8601String(),
              'status': 'pending',
              'responded_at': null,
              'open_alert_tier': null,
            }
          ]
        });

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/wellness-under-test',
      routes: [
        GoRoute(path: '/wellness-under-test', builder: (context, state) => const WellnessCheckScreen()),
        GoRoute(path: '/dependent', builder: (context, state) => stubScreen('DEPENDENT_HOME_STUB')),
        GoRoute(path: '/dependent/panic', builder: (context, state) => stubScreen('PANIC_SCREEN_STUB')),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Are you OK?'), findsOneWidget);
    expect(find.text('Yes, I am OK'), findsOneWidget);
    expect(find.textContaining('Answer within'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.12-06: picks the soonest deadline when more than one is pending', (tester) async {
    final soon = DateTime.now().toUtc().add(const Duration(minutes: 2));
    final later = DateTime.now().toUtc().add(const Duration(minutes: 20));
    final fakeClient = FakeApiClient(
      getHandler: (_) => {
        'items': [
          {
            'response_id': 'wcr-later',
            'wc_id': 'wc-2',
            'prompted_at': '2026-10-20T08:00:00Z',
            'deadline': later.toIso8601String(),
            'status': 'pending',
            'responded_at': null,
            'open_alert_tier': null,
          },
          {
            'response_id': 'wcr-soon',
            'wc_id': 'wc-1',
            'prompted_at': '2026-10-20T08:00:00Z',
            'deadline': soon.toIso8601String(),
            'status': 'pending',
            'responded_at': null,
            'open_alert_tier': null,
          },
        ]
      },
      postHandler: (_) => {'response_id': 'wcr-soon', 'status': 'responded', 'already_responded': false},
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/wellness-under-test',
      routes: [
        GoRoute(path: '/wellness-under-test', builder: (context, state) => const WellnessCheckScreen()),
        GoRoute(path: '/dependent', builder: (context, state) => stubScreen('DEPENDENT_HOME_STUB')),
        GoRoute(path: '/dependent/panic', builder: (context, state) => stubScreen('PANIC_SCREEN_STUB')),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yes, I am OK'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(fakeClient.lastPostPath, '/wellness-checks/wcr-soon/respond');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.12-07: answering "Yes, I am OK" posts to /respond and leaves the screen', (tester) async {
    final deadline = DateTime.now().toUtc().add(const Duration(minutes: 10));
    final fakeClient = FakeApiClient(
      getHandler: (_) => {
        'items': [
          {
            'response_id': 'wcr-1',
            'wc_id': 'wc-1',
            'prompted_at': '2026-10-20T08:00:00Z',
            'deadline': deadline.toIso8601String(),
            'status': 'pending',
            'responded_at': null,
            'open_alert_tier': null,
          }
        ]
      },
      postHandler: (_) => {'response_id': 'wcr-1', 'status': 'responded', 'already_responded': false},
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/wellness-under-test',
      routes: [
        GoRoute(path: '/wellness-under-test', builder: (context, state) => const WellnessCheckScreen()),
        GoRoute(path: '/dependent', builder: (context, state) => stubScreen('DEPENDENT_HOME_STUB')),
        GoRoute(path: '/dependent/panic', builder: (context, state) => stubScreen('PANIC_SCREEN_STUB')),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yes, I am OK'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(find.text('DEPENDENT_HOME_STUB'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.12-08: "I need help" opens the Panic screen', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': []});

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/wellness-under-test',
      routes: [
        GoRoute(path: '/wellness-under-test', builder: (context, state) => const WellnessCheckScreen()),
        GoRoute(path: '/dependent', builder: (context, state) => stubScreen('DEPENDENT_HOME_STUB')),
        GoRoute(path: '/dependent/panic', builder: (context, state) => stubScreen('PANIC_SCREEN_STUB')),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I need help'));
    await tester.pumpAndSettle();

    expect(find.text('PANIC_SCREEN_STUB'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.12-09: a failed respond keeps the screen and shows an error', (tester) async {
    final deadline = DateTime.now().toUtc().add(const Duration(minutes: 10));
    final fakeClient = FakeApiClient(
      getHandler: (_) => {
        'items': [
          {
            'response_id': 'wcr-1',
            'wc_id': 'wc-1',
            'prompted_at': '2026-10-20T08:00:00Z',
            'deadline': deadline.toIso8601String(),
            'status': 'pending',
            'responded_at': null,
            'open_alert_tier': null,
          }
        ]
      },
      postError: const ApiException(code: 'unexpected_error', message: 'boom'),
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/wellness-under-test',
      routes: [
        GoRoute(path: '/wellness-under-test', builder: (context, state) => const WellnessCheckScreen()),
        GoRoute(path: '/dependent', builder: (context, state) => stubScreen('DEPENDENT_HOME_STUB')),
        GoRoute(path: '/dependent/panic', builder: (context, state) => stubScreen('PANIC_SCREEN_STUB')),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yes, I am OK'));
    await tester.pumpAndSettle();

    expect(find.text('Are you OK?'), findsOneWidget);
    expect(find.text("Couldn't send your answer. Try again."), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
