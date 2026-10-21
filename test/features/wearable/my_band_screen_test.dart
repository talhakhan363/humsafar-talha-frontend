// Task 5.8 — TC-5.8-05..10. My band: the not-paired state with its
// Connect Band button, a receiving-data status card, the no_data
// warning banner, unpair (with confirm), and generate demo data.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/features/wearable/screens/my_band_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes() => [
      GoRoute(path: '/my-band-under-test', builder: (_, __) => const MyBandScreen(dependentId: 'dep-1')),
      GoRoute(path: '/wearable/connect', builder: (_, __) => stubScreen('CONNECT_BAND_STUB')),
    ];

void main() {
  testWidgets('TC-5.8-05: not_paired status shows the Connect Band button', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'status': 'not_paired'});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/my-band-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Not paired'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Connect Band'), findsOneWidget);
  });

  testWidgets('TC-5.8-06: tapping Connect Band navigates there', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'status': 'not_paired'});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/my-band-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Connect Band'));
    await tester.pumpAndSettle();

    expect(find.text('CONNECT_BAND_STUB'), findsOneWidget);
  });

  testWidgets('TC-5.8-07: receiving status shows the device, status and latest heart rate', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {
          'status': 'receiving',
          'device': {'name': 'Humsafar Band', 'ble_address': 'C4:5B:BE:12:34:56'},
          'latest_heart_rate': {'value': 76},
        });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/my-band-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Humsafar Band'), findsOneWidget);
    expect(find.textContaining('Receiving data'), findsOneWidget);
    expect(find.textContaining('76 bpm'), findsOneWidget);
    expect(find.text('No readings have come in recently. Check that the band is powered on and nearby.'), findsNothing);
  });

  testWidgets('TC-5.8-08: no_data status shows the warning banner', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {
          'status': 'no_data',
          'device': {'name': 'Humsafar Band', 'ble_address': 'C4:5B:BE:12:34:56'},
        });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/my-band-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('No readings have come in recently. Check that the band is powered on and nearby.'), findsOneWidget);
  });

  testWidgets('TC-5.8-09: Unpair asks for confirmation, then DELETEs', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {
        'status': 'receiving',
        'device': {'name': 'Humsafar Band', 'ble_address': 'C4:5B:BE:12:34:56'},
      },
      deleteHandler: (_) => <String, dynamic>{},
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/my-band-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Unpair'));
    await tester.pumpAndSettle();
    expect(fakeClient.deleteCalls, 0); // confirm dialog first

    await tester.tap(find.widgetWithText(TextButton, 'Unpair'));
    await tester.pumpAndSettle();

    expect(fakeClient.deleteCalls, 1);
    expect(fakeClient.lastDeletePath, '/dependents/dep-1/wearable');
  });

  testWidgets('TC-5.8-10: Generate demo data POSTs to /wearable/mock and refreshes', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {
        'status': 'receiving',
        'device': {'name': 'Humsafar Band', 'ble_address': 'C4:5B:BE:12:34:56'},
      },
      postHandler: (_) => <String, dynamic>{},
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/my-band-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Generate Demo Data'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(fakeClient.lastPostPath, '/dependents/dep-1/wearable/mock');
  });
}
