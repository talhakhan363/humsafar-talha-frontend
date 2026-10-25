// Task 4.7 — TC-4.7-07..12. See outgoing_call_screen.dart's doc comment
// for the full named field-name caveat on call_contract.md's assumed
// shape (shared by this screen).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/calls/screens/incoming_call_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes() => [
      GoRoute(
        path: '/calls/incoming-under-test',
        builder: (_, __) => const IncomingCallScreen(callId: 'call-1', callerName: 'Abdullah', isVideo: false),
      ),
      GoRoute(path: '/calls/active', builder: (_, __) => stubScreen('CALL_ACTIVE_STUB')),
    ];

List<GoRoute> _hostedRoutes() => [
      GoRoute(path: '/host', builder: (_, __) => const AutoPushHost(targetPath: '/calls/incoming-under-test')),
      ..._routes(),
    ];

void main() {
  testWidgets('TC-4.7-07: still ringing — shows the caller name and Accept/Decline', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'call_id': 'call-1', 'status': 'ringing'});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/calls/incoming-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Abdullah'), findsOneWidget);
    expect(find.byIcon(Icons.call), findsOneWidget);
    expect(find.byIcon(Icons.call_end), findsOneWidget);
  });

  testWidgets('TC-4.7-08: already over by the time it loads — shows the message, no Accept/Decline', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'call_id': 'call-1', 'status': 'missed'});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/calls/incoming-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('This call has already ended.'), findsOneWidget);
    expect(find.byIcon(Icons.call), findsNothing);
  });

  testWidgets('TC-4.7-09: tap Accept — posts accept and navigates to the active call screen', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'call_id': 'call-1', 'status': 'ringing'},
      postHandler: (path) => path == '/calls/call-1/accept'
          ? {
              'join': {'provider': 'zego', 'app_id': '123456789', 'room_id': 'room-1', 'user_id': 'user-1', 'token': 'tok-abc'},
            }
          : <String, dynamic>{},
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/calls/incoming-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.call));
    await tester.pumpAndSettle();

    expect(find.text('CALL_ACTIVE_STUB'), findsOneWidget);
  });

  testWidgets('TC-4.7-10: tap Decline — posts decline and pops back', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'call_id': 'call-1', 'status': 'ringing'});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/host', routes: _hostedRoutes()));
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.call_end));
    await tester.pumpAndSettle();

    expect(fakeClient.lastPostPath, '/calls/call-1/decline');
    expect(find.text('HOST'), findsOneWidget);
  });

  testWidgets('TC-4.7-11: initial GET fails — shows the error message', (tester) async {
    final fakeClient = FakeApiClient(getError: const ApiException(code: 'UNEXPECTED', message: 'Something went wrong.'));
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/calls/incoming-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong.'), findsOneWidget);
  });

  testWidgets('TC-4.7-12: the video flag is honored in the subtitle', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'call_id': 'call-2', 'status': 'ringing'});
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/calls/incoming-video-under-test',
      routes: [
        GoRoute(
          path: '/calls/incoming-video-under-test',
          builder: (_, __) => const IncomingCallScreen(callId: 'call-2', callerName: 'Abdullah', isVideo: true),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Incoming video call'), findsOneWidget);
  });
}
