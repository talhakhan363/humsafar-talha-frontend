// Task 6.8 — TC-6.8-12..16. Activity log: a non-booking entry (no
// detail sheet), opening a booking's detail sheet, the pending/
// confirmed action buttons, the Call-to-arrange button, and the
// BOOKING_STATUS_CONFLICT mapping on a stale action.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/directory/screens/activity_log_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes() => [
      GoRoute(path: '/activity-log-under-test', builder: (_, __) => const ActivityLogScreen(dependentId: 'dep-1')),
    ];

// `find.widgetWithText(OutlinedButton, ...)` matches by *exact* runtime
// type, but "Call to Arrange" is built with `OutlinedButton.icon(...)`,
// which returns a private subclass — so that finder always comes back
// empty. This matches by `is OutlinedButton`, which covers the `.icon`
// factory too.
Finder _outlinedButtonWithText(String text) =>
    find.ancestor(of: find.text(text), matching: find.byWidgetPredicate((widget) => widget is OutlinedButton));

final _contactEntry = {
  'type': 'org_contact',
  'subject_name': 'City Hospital',
  'initiated_by': {'full_name': 'Ammi'},
  'occurred_at': '2026-10-01T09:00:00Z',
};

final _bookingEntry = {
  'type': 'booking_requested',
  'reference_id': 'req-1',
  'subject_name': 'Nurse Amina',
  'initiated_by': {'full_name': 'Ammi'},
  'occurred_at': '2026-10-02T09:00:00Z',
};

final _pendingBooking = {
  'request_id': 'req-1',
  'provider_name': 'Nurse Amina',
  'status': 'pending',
  'requested_by_name': 'Ammi',
  'note': '',
  'contact': '03001234567',
};

void main() {
  testWidgets('TC-6.8-12: an empty log shows the empty state', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': []});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/activity-log-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('No activity yet.'), findsOneWidget);
  });

  testWidgets('TC-6.8-13: a non-booking entry is not tappable (no chevron, no detail sheet)', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [_contactEntry]});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/activity-log-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Called organization · City Hospital'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('TC-6.8-14: tapping a booking entry opens its detail sheet with Confirm and Cancel', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) => path.contains('/bookings/req-1') ? _pendingBooking : {'items': [_bookingEntry]},
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/activity-log-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Visit requested · Nurse Amina'));
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Confirm'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
    expect(_outlinedButtonWithText('Call to Arrange'), findsOneWidget);
  });

  testWidgets('TC-6.8-15: Confirm posts to /confirm and closes the sheet', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) => path.contains('/bookings/req-1') ? _pendingBooking : {'items': [_bookingEntry]},
      postHandler: (_) => <String, dynamic>{},
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/activity-log-under-test', routes: _routes()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visit requested · Nurse Amina'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(fakeClient.lastPostPath, '/dependents/dep-1/bookings/req-1/confirm');
    expect(find.text('Pending'), findsNothing); // sheet closed
  });

  testWidgets('TC-6.8-16: BOOKING_STATUS_CONFLICT on an action shows the conflict message', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) => path.contains('/bookings/req-1') ? _pendingBooking : {'items': [_bookingEntry]},
      postError: const ApiException(code: 'BOOKING_STATUS_CONFLICT', message: 'raw'),
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/activity-log-under-test', routes: _routes()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visit requested · Nurse Amina'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await tester.pumpAndSettle();

    expect(find.text("This booking's status has already changed."), findsOneWidget);
  });
}
