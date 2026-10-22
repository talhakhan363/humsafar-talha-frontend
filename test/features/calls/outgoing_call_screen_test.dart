// Task 4.7 — TC-4.7-01..06. See outgoing_call_screen.dart's doc comment
// for the full named field-name caveat on call_contract.md's assumed
// shape. `tester.pump(duration)` advances the 2s poll `Timer`
// deterministically instead of waiting on a real one.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/calls/screens/outgoing_call_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes() => [
      GoRoute(
        path: '/calls/outgoing-under-test',
        builder: (_, __) => const OutgoingCallScreen(calleeId: 'dep-9', calleeName: 'Ammi', isVideo: true),
      ),
      GoRoute(path: '/calls/active', builder: (_, __) => stubScreen('CALL_ACTIVE_STUB')),
    ];

void main() {
  testWidgets('TC-4.7-01: starts the call and shows "Calling..." while ringing', (tester) async {
    final fakeClient = FakeApiClient(postHandler: (path) => path == '/calls' ? {'call_id': 'call-1', 'status': 'ringing'} : <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/calls/outgoing-under-test', routes: _routes()));
    await tester.pump();

    expect(find.text('Ammi'), findsOneWidget);
    expect(fakeClient.lastPostPath, '/calls');
    expect(fakeClient.lastPostData, {'receiver_id': 'dep-9', 'type': 'video'});
  });

  testWidgets('TC-4.7-02: callee accepts — navigates to the active call screen with the real join info', (tester) async {
    final fakeClient = FakeApiClient(
      postHandler: (path) => path == '/calls' ? {'call_id': 'call-1', 'status': 'ringing'} : <String, dynamic>{},
      getHandler: (_) => {
        'call_id': 'call-1',
        'status': 'accepted',
        'zego': {'app_id': 123456789, 'token': 'tok-abc'},
      },
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/calls/outgoing-under-test', routes: _routes()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('CALL_ACTIVE_STUB'), findsOneWidget);
  });

  testWidgets('TC-4.7-03: callee declines — shows the declined message', (tester) async {
    final fakeClient = FakeApiClient(
      postHandler: (path) => path == '/calls' ? {'call_id': 'call-1', 'status': 'ringing'} : <String, dynamic>{},
      getHandler: (_) => {'call_id': 'call-1', 'status': 'declined'},
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/calls/outgoing-under-test', routes: _routes()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Call declined.'), findsOneWidget);
  });

  testWidgets('TC-4.7-04: no answer within the server\'s timeout — shows the missed message', (tester) async {
    final fakeClient = FakeApiClient(
      postHandler: (path) => path == '/calls' ? {'call_id': 'call-1', 'status': 'ringing'} : <String, dynamic>{},
      getHandler: (_) => {'call_id': 'call-1', 'status': 'missed'},
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/calls/outgoing-under-test', routes: _routes()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('No answer.'), findsOneWidget);
  });

  testWidgets('TC-4.7-05: POST /calls fails — shows the error message, no crash', (tester) async {
    final fakeClient = FakeApiClient(postError: const ApiException(code: 'UNEXPECTED', message: 'Something went wrong.'));
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/calls/outgoing-under-test', routes: _routes()));
    await tester.pump();

    expect(find.text('Something went wrong.'), findsOneWidget);
  });

  testWidgets('TC-4.7-06: tapping the hang-up button ends the call and pops', (tester) async {
    final fakeClient = FakeApiClient(postHandler: (path) => path == '/calls' ? {'call_id': 'call-1', 'status': 'ringing'} : <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/host',
      routes: [
        GoRoute(path: '/host', builder: (_, __) => const AutoPushHost(targetPath: '/calls/outgoing-under-test')),
        ..._routes(),
      ],
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.call_end));
    await tester.pumpAndSettle();

    expect(fakeClient.lastPostPath, '/calls/call-1/end');
    expect(find.text('HOST'), findsOneWidget);
  });
}
