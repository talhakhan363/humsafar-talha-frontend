// Task 3.14 — TC-3.14-33..37. GuardianHomeScreen had no test coverage at
// all before this task (confirmed: no test file existed for it even for
// its original Task 2.5 dependent-list behavior), so this file covers
// both the pre-existing list rendering and the new panic banner / Needs
// attention preview together, rather than leaving the old behavior
// untested while only adding tests for the new piece.
//
// Extended for Task 4.6 (2026-10-22) — TC-4.6-18..20, for the new
// Messages icon + unread badge. The pre-existing TC-3.14-33..37 tests
// above are untouched and still pass unmodified: none of them mock
// `/messages/conversations`, which the screen now also calls on load,
// but `FakeApiClient`'s default (an empty map when no handler branch
// matches) already makes `_loadUnreadMessages()` resolve to 0 silently —
// no crash, no behavior change for those tests to re-assert.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/guardian/screens/guardian_home_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

const _oneDependent = [
  {
    'dependent_id': 'dep-9',
    'email': 'ammi@example.com',
    'phone': '03001234567',
    'my_role': 'primary',
    'kyc_status': 'verified',
    'account_active': true,
  },
];

const _panicAlert = {
  'notification_id': 'n-panic',
  'type': 'panic',
  'priority': 'critical',
  'title': 'Panic alert',
  'body': 'Test Dependent pressed panic.',
  'dependent_id': 'dep-9',
  'event_id': 'ev-1',
  'data': <String, dynamic>{},
  'sent_at': '2026-10-21T09:42:00Z',
  'acknowledged_at': null,
  'is_acknowledged': false,
};

const _missedDoseAlert = {
  'notification_id': 'n-dose',
  'type': 'missed_dose',
  'priority': 'critical',
  'title': 'Missed medication',
  'body': 'Test Dependent has not taken Metformin.',
  'dependent_id': 'dep-9',
  'event_id': 'ev-2',
  'data': {'tier': 'primary'},
  'sent_at': '2026-10-21T14:00:00Z',
  'acknowledged_at': null,
  'is_acknowledged': false,
};

List<GoRoute> _routes() => [
      GoRoute(path: '/guardian', builder: (_, __) => const GuardianHomeScreen()),
      GoRoute(path: '/guardian/alerts', builder: (_, __) => stubScreen('ALERTS_STUB')),
      GoRoute(path: '/guardian/dependent-detail', builder: (_, __) => stubScreen('DETAIL_STUB')),
      GoRoute(path: '/messages', builder: (_, __) => stubScreen('MESSAGES_STUB')),
    ];

void main() {
  testWidgets('TC-3.14-33: the Dependent list still renders normally with no alerts', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/guardians/me/dependents') return _oneDependent;
      if (path == '/notifications') return {'items': <dynamic>[]};
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('ammi@example.com'), findsOneWidget);
    expect(find.text('Needs attention'), findsNothing);
  });

  testWidgets('TC-3.14-34: a panic alert shows the red banner with Open navigating to Alerts', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/guardians/me/dependents') return _oneDependent;
      if (path == '/notifications') return {'items': [_panicAlert]};
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('PANIC ALERT'), findsOneWidget);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('ALERTS_STUB'), findsOneWidget);
  });

  testWidgets('TC-3.14-35: a non-panic critical alert shows in "Needs attention"', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/guardians/me/dependents') return _oneDependent;
      if (path == '/notifications') return {'items': [_missedDoseAlert]};
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('Missed dose'), findsOneWidget);
    expect(find.text('PANIC ALERT'), findsNothing);
  });

  testWidgets('TC-3.14-36: "See all" navigates to Alerts', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/guardians/me/dependents') return _oneDependent;
      if (path == '/notifications') return {'items': [_missedDoseAlert]};
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
    expect(find.text('ALERTS_STUB'), findsOneWidget);
  });

  testWidgets('TC-3.14-37: a failed alerts preview load is silent — the Dependent list still shows', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/guardians/me/dependents') return _oneDependent;
      if (path == '/notifications') throw const ApiException(code: 'unexpected_error', message: 'offline');
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('ammi@example.com'), findsOneWidget);
    expect(find.text('Needs attention'), findsNothing);
  });

  testWidgets('TC-4.6-18: an unread total shows as a badge next to the Messages icon', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/guardians/me/dependents') return _oneDependent;
      if (path == '/messages/conversations') return {'items': <dynamic>[], 'total_unread': 3};
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('TC-4.6-19: zero unread shows no badge', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/guardians/me/dependents') return _oneDependent;
      if (path == '/messages/conversations') return {'items': <dynamic>[], 'total_unread': 0};
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsNothing);
  });

  testWidgets('TC-4.6-20: tapping the Messages icon navigates to the inbox', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/guardians/me/dependents') return _oneDependent;
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pumpAndSettle();

    expect(find.text('MESSAGES_STUB'), findsOneWidget);
  });
}
