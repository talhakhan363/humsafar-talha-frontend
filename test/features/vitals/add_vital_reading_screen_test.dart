// Task 5.7 — TC-5.7-07..11. Add reading: heart_rate is never offered
// (band-only, per the contract), per-metric field validation, a
// successful blood-pressure POST body, the blood-sugar unit/context
// fields, and the VITAL_OUT_OF_RANGE error mapping. Also guards the
// DropdownButtonFormField `value:` (not `initialValue:`) fix needed for
// Flutter 3.32.1 by simply exercising the sugar-context dropdown.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/vitals/screens/add_vital_reading_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes() => [
      GoRoute(path: '/add-vital-under-test', builder: (_, __) => const AddVitalReadingScreen(dependentId: 'dep-1')),
    ];

// Adds a `/host` route in front of the screen under test — needed for
// any test that reaches `_save()`'s `Navigator.of(context).pop(true)`.
// See `AutoPushHost`'s doc comment in widget_test_harness.dart.
List<GoRoute> _hostedRoutes() => [
      GoRoute(path: '/host', builder: (_, __) => const AutoPushHost(targetPath: '/add-vital-under-test')),
      ..._routes(),
    ];

void main() {
  testWidgets('TC-5.7-07: heart rate is never offered as a metric choice', (tester) async {
    final fakeClient = FakeApiClient();
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/add-vital-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ChoiceChip, 'Heart Rate'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Blood Pressure'), findsOneWidget);
  });

  testWidgets('TC-5.7-08: blood pressure with empty fields blocks Save, no POST', (tester) async {
    final fakeClient = FakeApiClient();
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/add-vital-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsOneWidget);
    expect(fakeClient.postCalls, 0);
  });

  testWidgets('TC-5.7-09: a valid blood pressure reading POSTs top/bottom as value/diastolic', (tester) async {
    final fakeClient = FakeApiClient(postHandler: (_) => <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/host', routes: _hostedRoutes()));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Systolic'), '120');
    await tester.enterText(find.widgetWithText(TextField, 'Diastolic'), '80');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    final body = fakeClient.lastPostData as Map;
    expect(body['metric_type'], 'blood_pressure');
    expect(body['value'], 120.0);
    expect(body['diastolic'], 80.0);
  });

  testWidgets('TC-5.7-10: switching to blood sugar shows unit and context dropdowns, sent in the body', (tester) async {
    final fakeClient = FakeApiClient(postHandler: (_) => <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/host', routes: _hostedRoutes()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Blood Sugar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Blood Sugar'), '110');
    // DropdownButtonFormField<String?>'s currently-selected value ("None")
    // is what's tappable to open the menu; Fasting then appears in the
    // overlay — same open-then-select two-step every Flutter dropdown
    // test needs.
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fasting').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    final body = fakeClient.lastPostData as Map;
    expect(body['metric_type'], 'blood_sugar');
    expect(body['unit'], 'mg/dL');
    expect(body['context'], 'fasting');
  });

  testWidgets('TC-5.7-11: VITAL_OUT_OF_RANGE on save shows the mapped message', (tester) async {
    final fakeClient = FakeApiClient(postError: const ApiException(code: 'VITAL_OUT_OF_RANGE', message: 'raw'));
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/add-vital-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'SpO2'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'SpO2 (%)'), '95');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('This value looks out of range. Please check it.'), findsOneWidget);
  });
}
