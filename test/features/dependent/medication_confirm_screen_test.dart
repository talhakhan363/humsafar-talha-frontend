import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/dependent/screens/medication_confirm_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

/// TC-3.13-01..08 — Task 3.13's Medication Confirmation screen
/// (mockups 23/23b). Uses the shared test/support/ harness
/// (`FakeApiClient`, `wrapWithRouter`) rather than a one-off fake, per
/// the Task 3.13+3.15 batch's test-folder-cleanup prep step.
void main() {
  final pendingDose = {
    'confirmation_id': 'conf-1',
    'schedule_id': 'sch-1',
    'drug_name': 'Panadol',
    'dosage': '500mg',
    'scheduled_for': '2026-10-21T08:00:00Z',
    'status': 'pending',
    'confirmed_at': null,
    'window_ends_at': '2026-10-21T08:30:00Z',
    'open_alert_tier': null,
  };

  List<GoRoute> routesFor(Widget screen) => [
        GoRoute(path: '/dependent/medication-under-test', builder: (context, state) => screen),
        GoRoute(path: '/dependent', builder: (context, state) => stubScreen('DEPENDENT_HOME_STUB')),
      ];

  testWidgets('TC-3.13-01: no dose due — shows the empty state, no prompt/confirm UI', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': []});

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/dependent/medication-under-test',
      routes: routesFor(const MedicationConfirmScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text("There's no medicine due right now."), findsOneWidget);
    expect(find.text("It's time for your medicine"), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.13-02: a load failure shows the error and Retry re-fetches', (tester) async {
    final fakeClient = FakeApiClient(
      getError: const ApiException(code: 'unexpected_error', message: 'Could not load your medicine schedule.'),
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/dependent/medication-under-test',
      routes: routesFor(const MedicationConfirmScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Could not load your medicine schedule.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(fakeClient.getCalls, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(fakeClient.getCalls, 2);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.13-03: a dose due shows the step-1 prompt, and "I took it" moves to step 2', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [pendingDose]},
      postHandler: (path) => path.endsWith('confirm-request')
          ? {
              'confirmation_id': 'conf-1',
              'drug_name': 'Panadol',
              'dosage': '500mg',
              'scheduled_for': '2026-10-21T08:00:00Z',
              'confirm_token': 'tok-1',
              'expires_in_s': 120,
            }
          : <String, dynamic>{},
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/dependent/medication-under-test',
      routes: routesFor(const MedicationConfirmScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text("It's time for your medicine"), findsOneWidget);
    expect(find.text('Panadol (500mg) — did you take it?'), findsOneWidget);

    await tester.tap(find.text('I took it'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(fakeClient.lastPostPath, '/medications/sch-1/confirm-request');
    expect(fakeClient.lastPostData, {'confirmation_id': 'conf-1'});
    expect(find.text('Confirm you took it'), findsOneWidget);
    expect(find.text('Please confirm: Panadol (500mg)'), findsOneWidget);
    expect(find.textContaining('This confirmation expires in'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.13-04: skipPrompt true (opened from Home with a dose already due) skips straight to step 2',
      (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [pendingDose]},
      postHandler: (path) =>
          path.endsWith('confirm-request') ? {'confirm_token': 'tok-1', 'expires_in_s': 120} : <String, dynamic>{},
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/dependent/medication-under-test',
      routes: routesFor(const MedicationConfirmScreen(skipPrompt: true)),
    ));
    await tester.pumpAndSettle();

    expect(find.text("It's time for your medicine"), findsNothing);
    expect(find.text('Confirm you took it'), findsOneWidget);
    expect(fakeClient.postCalls, 1);
    expect(fakeClient.lastPostPath, '/medications/sch-1/confirm-request');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.13-05: full happy path — step 2 confirm marks it taken, Done returns to Home', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [pendingDose]},
      postHandler: (path) {
        if (path.endsWith('confirm-request')) return {'confirm_token': 'tok-1', 'expires_in_s': 120};
        return {
          'confirmation_id': 'conf-1',
          'drug_name': 'Panadol',
          'dosage': '500mg',
          'status': 'taken',
          'confirmed_at': '2026-10-21T08:01:00Z',
          'already_confirmed': false,
        };
      },
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/dependent/medication-under-test',
      routes: routesFor(const MedicationConfirmScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I took it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, I took it'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 2);
    expect(fakeClient.lastPostPath, '/medications/sch-1/confirm');
    expect(fakeClient.lastPostData, {'confirm_token': 'tok-1'});
    expect(find.text('Marked as taken'), findsOneWidget);
    expect(find.text('Panadol is marked as taken.'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('DEPENDENT_HOME_STUB'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.13-06: an expired confirmation window offers Try again, which re-requests a token',
      (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [pendingDose]},
      // expires_in_s: -5 forces the screen straight into the "already
      // expired" branch the instant it lands on step 2, without
      // depending on wall-clock time passing during the test.
      postHandler: (path) =>
          path.endsWith('confirm-request') ? {'confirm_token': 'tok-1', 'expires_in_s': -5} : <String, dynamic>{},
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/dependent/medication-under-test',
      routes: routesFor(const MedicationConfirmScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I took it'));
    await tester.pumpAndSettle();

    expect(find.text('This confirmation window expired.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Yes, I took it'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 2);
    expect(fakeClient.lastPostPath, '/medications/sch-1/confirm-request');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.13-07: a failed step-1 request keeps the prompt and shows a snackbar', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [pendingDose]},
      postError: const ApiException(code: 'unexpected_error', message: 'boom'),
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/dependent/medication-under-test',
      routes: routesFor(const MedicationConfirmScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I took it'));
    await tester.pumpAndSettle();

    expect(find.text("It's time for your medicine"), findsOneWidget);
    expect(find.text("Couldn't start the confirmation. Try again."), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.13-08: a failed step-2 confirm keeps step 2 and shows a snackbar', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [pendingDose]},
      postHandler: (path) {
        if (path.endsWith('confirm-request')) return {'confirm_token': 'tok-1', 'expires_in_s': 120};
        throw const ApiException(code: 'unexpected_error', message: 'boom');
      },
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/dependent/medication-under-test',
      routes: routesFor(const MedicationConfirmScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I took it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, I took it'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm you took it'), findsOneWidget);
    expect(find.text("Couldn't confirm. Try again."), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
