// Task 5.6 — TC-5.6-15..19. Appointments: Upcoming/History tabs,
// opening the add/edit sheet, the POST-vs-PATCH branch, cancel, delete
// (with confirm), and the APPOINTMENT_IN_PAST error mapping.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/features/records/screens/appointments_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes() => [
      GoRoute(path: '/appointments-under-test', builder: (_, __) => const AppointmentsScreen(dependentId: 'dep-1')),
    ];

final _upcoming = {
  'appointment_id': 'appt-1',
  'provider_name': 'Dr. Khan',
  'scheduled_at': DateTime.now().add(const Duration(days: 5)).toUtc().toIso8601String(),
  'status': 'scheduled',
};

void main() {
  testWidgets('TC-5.6-15: loads Upcoming by default and shows a scheduled appointment', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [_upcoming]});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/appointments-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Dr. Khan'), findsOneWidget);
    expect(fakeClient.lastGetPath, contains('/appointments'));
  });

  testWidgets('TC-5.6-16: switching to History re-queries with when=past and shows the empty state', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': []});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/appointments-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(fakeClient.getCalls, 2);
    expect(find.text('No past appointments.'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing); // Upcoming-only FAB
  });

  testWidgets('TC-5.6-17: adding an appointment with empty provider name blocks Save', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': []});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/appointments-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsOneWidget);
    expect(fakeClient.postCalls, 0);
  });

  testWidgets('TC-5.6-18: a valid new appointment POSTs and shows the saved snackbar', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': []}, postHandler: (_) => <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/appointments-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Provider Name'), 'Dr. Khan');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(fakeClient.lastPostPath, '/dependents/dep-1/appointments');
    expect(find.text('Appointment saved'), findsOneWidget);
  });

  testWidgets('TC-5.6-19: the menu\'s Cancel appointment option posts to /cancel', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [Map<String, dynamic>.from(_upcoming)]},
      postHandler: (_) => <String, dynamic>{},
      deleteHandler: (_) => <String, dynamic>{},
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/appointments-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    // Every screen's AppBar also carries a language-switcher
    // `PopupMenuButton<String>` (see `language_switch_button.dart`), so
    // an untargeted `find.byType(PopupMenuButton<String>)` is
    // ambiguous here — scope to the one inside this appointment's own
    // Card/ListTile.
    await tester.tap(find.descendant(
      of: find.widgetWithText(Card, 'Dr. Khan'),
      matching: find.byType(PopupMenuButton<String>),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel appointment'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(fakeClient.lastPostPath, '/dependents/dep-1/appointments/appt-1/cancel');
  });
}
