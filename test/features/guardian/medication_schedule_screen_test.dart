import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/guardian/dependent_summary.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/guardian/screens/medication_schedule_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

/// TC-3.15-03..11 — Task 3.15's Guardian-side Medication schedule
/// screen. See wellness_schedule_screen_test.dart (TC-3.15-12 onward)
/// for the other half of this task.
void main() {
  const primarySummary = DependentSummary(
    dependentId: 'dep-1',
    email: 'dep@example.com',
    phone: '03001234567',
    myRole: 'primary',
    kycStatus: 'verified',
    accountActive: true,
  );
  const secondarySummary = DependentSummary(
    dependentId: 'dep-1',
    email: 'dep@example.com',
    phone: '03001234567',
    myRole: 'secondary',
    kycStatus: 'verified',
    accountActive: true,
  );

  final dailySchedule = {
    'schedule_id': 'ms-1',
    'drug_name': 'Panadol',
    'dosage': '500mg',
    'time': '08:00',
    'frequency': 'daily',
    'active': true,
  };

  final weeklySchedule = {
    'schedule_id': 'ms-2',
    'drug_name': 'Vitamin D',
    'dosage': '1 tablet',
    'time': '20:00',
    'frequency': 'weekly',
    'days': ['mon', 'wed', 'fri'],
    'active': true,
  };

  testWidgets('TC-3.15-03: Primary sees a daily schedule formatted as "time · Daily"', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [dailySchedule]});

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/medication-schedule-under-test',
      routes: [
        GoRoute(
          path: '/guardian/medication-schedule-under-test',
          builder: (context, state) => const MedicationScheduleScreen(summary: primarySummary),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Panadol · 500mg'), findsOneWidget);
    expect(find.text('8:00 AM · Daily'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.15-04: a weekly schedule shows its days, abbreviated and localized', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [weeklySchedule]});

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/medication-schedule-under-test',
      routes: [
        GoRoute(
          path: '/guardian/medication-schedule-under-test',
          builder: (context, state) => const MedicationScheduleScreen(summary: primarySummary),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Vitamin D · 1 tablet'), findsOneWidget);
    expect(find.text('8:00 PM · Weekly (Mon, Wed, Fri)'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.15-05: a Secondary without medication_management sees a read-only screen', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) => path.contains('permissions/me')
          ? {'guardian_role': 'secondary', 'modules': {'medication_management': false}}
          : {'items': [dailySchedule]},
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/medication-schedule-under-test',
      routes: [
        GoRoute(
          path: '/guardian/medication-schedule-under-test',
          builder: (context, state) => const MedicationScheduleScreen(summary: secondarySummary),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text("You don't have permission to manage medicines. Ask the Primary Guardian."), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.15-06: a Secondary WITH medication_management can add and toggle', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) => path.contains('permissions/me')
          ? {'guardian_role': 'secondary', 'modules': {'medication_management': true}}
          : {'items': [dailySchedule]},
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/medication-schedule-under-test',
      routes: [
        GoRoute(
          path: '/guardian/medication-schedule-under-test',
          builder: (context, state) => const MedicationScheduleScreen(summary: secondarySummary),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text("You don't have permission to manage medicines. Ask the Primary Guardian."), findsNothing);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.15-07: toggling a schedule off PUTs active:false and keeps the new value', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [Map<String, dynamic>.from(dailySchedule)]},
      putHandler: (_) => <String, dynamic>{},
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/medication-schedule-under-test',
      routes: [
        GoRoute(
          path: '/guardian/medication-schedule-under-test',
          builder: (context, state) => const MedicationScheduleScreen(summary: primarySummary),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(fakeClient.putCalls, 1);
    expect(fakeClient.lastPutPath, '/dependents/dep-1/medications/ms-1');
    expect(fakeClient.lastPutData, {'active': false});
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.15-08: a failed toggle reverts the switch and shows the mapped message', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [Map<String, dynamic>.from(dailySchedule)]},
      putError: const ApiException(code: 'MODULE_ACCESS_DENIED', message: 'raw message should not show'),
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/medication-schedule-under-test',
      routes: [
        GoRoute(
          path: '/guardian/medication-schedule-under-test',
          builder: (context, state) => const MedicationScheduleScreen(summary: primarySummary),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text("You don't have permission to manage medicines. Ask the Primary Guardian."), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.15-09: Add form — empty required fields block Save with an inline error, no POST',
      (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': []});

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/medication-schedule-under-test',
      routes: [
        GoRoute(
          path: '/guardian/medication-schedule-under-test',
          builder: (context, state) => const MedicationScheduleScreen(summary: primarySummary),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsOneWidget);
    expect(fakeClient.postCalls, 0);
    expect(find.text('Add medicine'), findsOneWidget); // sheet is still open

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.15-10: Add form — weekly with no day selected blocks Save, no POST', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': []});

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/medication-schedule-under-test',
      routes: [
        GoRoute(
          path: '/guardian/medication-schedule-under-test',
          builder: (context, state) => const MedicationScheduleScreen(summary: primarySummary),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Medicine name'), 'Aspirin');
    await tester.enterText(find.widgetWithText(TextField, 'Dosage'), '100mg');
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Pick at least one day for a weekly schedule.'), findsOneWidget);
    expect(fakeClient.postCalls, 0);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.15-11: Add form — a valid daily entry POSTs the right body and refreshes the list',
      (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': []},
      postHandler: (_) => <String, dynamic>{},
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/medication-schedule-under-test',
      routes: [
        GoRoute(
          path: '/guardian/medication-schedule-under-test',
          builder: (context, state) => const MedicationScheduleScreen(summary: primarySummary),
        ),
      ],
    ));
    await tester.pumpAndSettle();
    expect(fakeClient.getCalls, 1);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Medicine name'), 'Aspirin');
    await tester.enterText(find.widgetWithText(TextField, 'Dosage'), '100mg');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(fakeClient.lastPostPath, '/dependents/dep-1/medications');
    // Bug fix (2026-10-30, Sarim's N-01): this test was asserting the
    // OLD, broken POST body shape as correct — 'time': a bare string,
    // which is what made every real add-medicine attempt 422 against
    // the actual backend. Updated to the fixed shape
    // (medication_schedule_screen.dart's `_openForm`): POST wraps the
    // single time picked in this form into 'times': [...], matching the
    // create-takes-a-list / update-takes-one-value split this contract
    // family already uses for wellness schedules.
    expect(fakeClient.lastPostData, {'drug_name': 'Aspirin', 'dosage': '100mg', 'frequency': 'daily', 'times': ['08:00']});
    expect(find.text('Saved.'), findsOneWidget);
    expect(fakeClient.getCalls, 2); // _load() ran again after the save

    await tester.pumpWidget(const SizedBox());
  });
}
