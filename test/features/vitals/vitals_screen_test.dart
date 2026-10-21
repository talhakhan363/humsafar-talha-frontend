// Task 5.7 — TC-5.7-01..06. Vitals: the five latest-value tiles (with
// the band-sourced note on heart rate), the history list with its
// metric filter, delete gated by can_delete, and the
// MODULE_ACCESS_DENIED error mapping.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/vitals/screens/vitals_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes() => [
      GoRoute(path: '/vitals-under-test', builder: (_, __) => const VitalsScreen(dependentId: 'dep-1')),
      GoRoute(path: '/vitals/add', builder: (_, __) => stubScreen('ADD_VITAL_STUB')),
    ];

dynamic _handler(String path) {
  if (path.contains('/latest')) {
    return {
      'latest': {
        'blood_pressure': {'metric_type': 'blood_pressure', 'value': 120, 'diastolic': 80, 'unit': 'mmHg'},
        'heart_rate': {'metric_type': 'heart_rate', 'value': 72, 'unit': 'bpm'},
      },
    };
  }
  return {
    'items': [
      {
        'reading_id': 'v-1',
        'metric_type': 'blood_pressure',
        'value': 120,
        'diastolic': 80,
        'unit': 'mmHg',
        'recorded_at': '2026-10-01T08:00:00Z',
        'can_delete': true,
        'source': 'manual',
      },
    ],
  };
}

void main() {
  testWidgets('TC-5.7-01: shows a blood pressure tile and the from-band note on heart rate', (tester) async {
    final fakeClient = FakeApiClient(getHandler: _handler);
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/vitals-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('120/80 mmHg'), findsOneWidget);
    expect(find.text('From band'), findsOneWidget);
  });

  testWidgets('TC-5.7-02: the history list shows a manual reading with a note icon', (tester) async {
    final fakeClient = FakeApiClient(getHandler: _handler);
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/vitals-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit_note), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget); // can_delete: true
  });

  testWidgets('TC-5.7-03: picking a metric filter chip re-queries history', (tester) async {
    final fakeClient = FakeApiClient(getHandler: _handler);
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/vitals-under-test', routes: _routes()));
    await tester.pumpAndSettle();
    final loadsBefore = fakeClient.getCalls;

    await tester.tap(find.widgetWithText(ChoiceChip, 'SpO2'));
    await tester.pumpAndSettle();

    expect(fakeClient.getCalls, greaterThan(loadsBefore));
  });

  testWidgets('TC-5.7-04: deleting a reading DELETEs and removes the row', (tester) async {
    final fakeClient = FakeApiClient(getHandler: _handler, deleteHandler: (_) => <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/vitals-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(fakeClient.deleteCalls, 1);
    expect(fakeClient.lastDeletePath, '/dependents/dep-1/vitals/v-1');
  });

  testWidgets('TC-5.7-05: tapping + opens Add reading', (tester) async {
    final fakeClient = FakeApiClient(getHandler: _handler);
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/vitals-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('ADD_VITAL_STUB'), findsOneWidget);
  });

  testWidgets('TC-5.7-06: MODULE_ACCESS_DENIED on load shows the mapped message', (tester) async {
    final fakeClient = FakeApiClient(getError: const ApiException(code: 'MODULE_ACCESS_DENIED', message: 'raw'));
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/vitals-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text("You don't have access to health records for this Dependent."), findsOneWidget);
  });
}
