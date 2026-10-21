// Task 5.6 — TC-5.6-22..26. Record access: the not-granted note, the
// per-category switches, a successful PUT toggle, and a failed toggle
// reverting optimistically. (TC-5.6-20..21 are the Medical
// records/Appointments button tests in
// `dependent_detail_screen_test.dart`.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/records/screens/record_access_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes() => [
      GoRoute(path: '/record-access-under-test', builder: (_, __) => const RecordAccessScreen(dependentId: 'dep-1')),
    ];

Map<String, dynamic> _secondary({required bool granted}) => {
      'guardian_id': 'g-2',
      'email': 'sec@example.com',
      'health_records_granted': granted,
      'categories': {'prescription': true, 'lab_report': true, 'xray': true, 'other': true},
    };

void main() {
  testWidgets('TC-5.6-22: a Secondary without health_records_granted shows the note and disables switches', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'secondaries': [_secondary(granted: false)]});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/record-access-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text("Health records access isn't granted yet."), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).onChanged, isNull);
  });

  testWidgets('TC-5.6-23: a granted Secondary shows four category switches, all enabled', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'secondaries': [_secondary(granted: true)]});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/record-access-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.byType(SwitchListTile), findsNWidgets(4));
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).onChanged, isNotNull);
  });

  testWidgets('TC-5.6-24: toggling a category PUTs the right path and body', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'secondaries': [_secondary(granted: true)]},
      putHandler: (_) => <String, dynamic>{},
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/record-access-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();

    expect(fakeClient.putCalls, 1);
    expect(fakeClient.lastPutPath, '/dependents/dep-1/records/access/prescription');
    expect(fakeClient.lastPutData, {'guardian_id': 'g-2', 'visible': false});
  });

  testWidgets('TC-5.6-25: a failed toggle reverts the switch and shows the error', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'secondaries': [_secondary(granted: true)]},
      putError: const ApiException(code: 'SOME_ERROR', message: 'could not update'),
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/record-access-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value, isTrue);
    expect(find.text('could not update'), findsOneWidget);
  });

  testWidgets('TC-5.6-26: NOT_PRIMARY_GUARDIAN on load maps to notPrimaryGuardianMessage', (tester) async {
    final fakeClient = FakeApiClient(getError: const ApiException(code: 'NOT_PRIMARY_GUARDIAN', message: 'raw'));
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/record-access-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Only the Primary Guardian can do this.'), findsOneWidget);
  });
}
