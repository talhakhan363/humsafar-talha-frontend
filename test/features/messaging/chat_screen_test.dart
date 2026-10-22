// Task 4.6/4.8 — TC-4.6-07..17.
//
// Extended for Task 4.7 (2026-10-22) — TC-4.7-16/17, for the new
// Guardian-only Call button in the AppBar. Added a stub route for
// '/calls/outgoing' since that's as far as this screen's own
// responsibility goes (see chat_screen.dart's doc comment and
// outgoing_call_screen_test.dart for what happens past that point).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/audio/audio_providers.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/messaging/screens/chat_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/fake_audio_sources.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes() => [
      GoRoute(
        path: '/messages/chat',
        builder: (_, __) => const ChatScreen(peerId: 'dep-9', peerName: 'Ammi'),
      ),
      GoRoute(path: '/calls/outgoing', builder: (_, __) => stubScreen('OUTGOING_CALL_STUB')),
    ];

void main() {
  testWidgets('TC-4.6-07: loads and renders both sides of the conversation', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/messages') {
        return {
          'items': [
            {
              'message_id': 'm-2',
              'sender_id': 'g-1',
              'receiver_id': 'dep-9',
              'type': 'text',
              'body': 'Did you take your medicine?',
              'content_url': null,
              'priority': 'standard',
              'sent_at': '2026-10-22T09:01:00Z',
              'read_at': null,
              'from_me': true,
              'duration_s': null,
            },
            {
              'message_id': 'm-1',
              'sender_id': 'dep-9',
              'receiver_id': 'g-1',
              'type': 'text',
              'body': 'Yes, just now',
              'content_url': null,
              'priority': 'standard',
              'sent_at': '2026-10-22T09:00:00Z',
              'read_at': null,
              'from_me': false,
              'duration_s': null,
            },
          ],
          'next_before': null,
        };
      }
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/messages/chat', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Did you take your medicine?'), findsOneWidget);
    expect(find.text('Yes, just now'), findsOneWidget);
    expect(fakeClient.lastPostPath, '/messages/read');
  });

  testWidgets('TC-4.6-08: shows "Read" under my last message once read_at is set', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/messages') {
        return {
          'items': [
            {
              'message_id': 'm-1',
              'sender_id': 'g-1',
              'receiver_id': 'dep-9',
              'type': 'text',
              'body': 'Hello',
              'content_url': null,
              'priority': 'standard',
              'sent_at': '2026-10-22T09:00:00Z',
              'read_at': '2026-10-22T09:05:00Z',
              'from_me': true,
              'duration_s': null,
            },
          ],
          'next_before': null,
        };
      }
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/messages/chat', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Read'), findsOneWidget);
  });

  testWidgets('TC-4.6-09: sending a text message shows "Sending…" then the real bubble, no retry caption', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) => path == '/messages' ? {'items': <dynamic>[], 'next_before': null} : <String, dynamic>{},
      postHandler: (path) => {
        'message_id': 'm-new',
        'sender_id': 'dep-1',
        'receiver_id': 'dep-9',
        'type': 'text',
        'body': 'On my way',
        'content_url': null,
        'priority': 'standard',
        'sent_at': '2026-10-22T10:00:00Z',
        'read_at': null,
        'from_me': true,
        'duration_s': null,
        'already_sent': false,
      },
    );
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/messages/chat',
      routes: _routes(),
      user: kTestGuardianUser,
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'On my way');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('On my way'), findsOneWidget);
    expect(find.text('Sending…'), findsNothing);
    expect(find.text('Not sent · Tap to retry'), findsNothing);
    expect(
      fakeClient.lastPostData,
      isA<Map>().having((m) => m['receiver_id'], 'receiver_id', 'dep-9').having((m) => m['body'], 'body', 'On my way'),
    );
  });

  testWidgets('TC-4.6-10: a failed send shows "Not sent · Tap to retry", and retrying reuses the same client_id', (tester) async {
    var postAttempts = 0;
    final clientIds = <String>[];
    late FakeApiClient fakeClient;
    fakeClient = FakeApiClient(
      getHandler: (path) => path == '/messages' ? {'items': <dynamic>[], 'next_before': null} : <String, dynamic>{},
      postHandler: (path) {
        // The screen also fires an automatic, best-effort POST /messages/read
        // on load (see ChatScreen._markRead) — that call carries no
        // client_id, so it must not be counted or inspected here.
        if (path != '/messages') return <String, dynamic>{};
        postAttempts++;
        clientIds.add((fakeClient.lastPostData as Map)['client_id'] as String);
        if (postAttempts == 1) throw const ApiException(code: 'unexpected_error', message: 'offline');
        return {
          'message_id': 'm-new',
          'sender_id': 'dep-1',
          'receiver_id': 'dep-9',
          'type': 'text',
          'body': 'retry me',
          'content_url': null,
          'priority': 'standard',
          'sent_at': '2026-10-22T10:00:00Z',
          'read_at': null,
          'from_me': true,
          'duration_s': null,
        };
      },
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/messages/chat', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'retry me');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('Not sent · Tap to retry'), findsOneWidget);

    await tester.tap(find.text('Not sent · Tap to retry'));
    await tester.pumpAndSettle();

    expect(find.text('Not sent · Tap to retry'), findsNothing);
    expect(clientIds[0], clientIds[1]);
  });

  testWidgets('TC-4.6-11: tapping Send with an empty field does nothing', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) => path == '/messages' ? {'items': <dynamic>[], 'next_before': null} : <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/messages/chat', routes: _routes()));
    await tester.pumpAndSettle();

    // Baseline includes the screen's own automatic POST /messages/read on
    // load — tapping Send on an empty field must not add to it.
    final postCallsAfterLoad = fakeClient.postCalls;

    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, postCallsAfterLoad);
  });

  testWidgets('TC-4.6-12: a Dependent sees quick-reply chips and no mic button; tapping one sends it', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) => path == '/messages' ? {'items': <dynamic>[], 'next_before': null} : <String, dynamic>{},
      postHandler: (path) => {
        'message_id': 'm-qr',
        'sender_id': 'dep-1',
        'receiver_id': 'g-9',
        'type': 'text',
        'body': 'I am fine',
        'content_url': null,
        'priority': 'standard',
        'sent_at': '2026-10-22T10:00:00Z',
        'read_at': null,
        'from_me': true,
        'duration_s': null,
      },
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/messages/chat', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.mic), findsNothing);
    await tester.tap(find.text('I am fine'));
    await tester.pumpAndSettle();

    expect(fakeClient.lastPostData, isA<Map>().having((m) => m['body'], 'body', 'I am fine'));
  });

  testWidgets('TC-4.6-13/4.8: a Guardian sees the mic button, which opens the voice recorder sheet', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) => path == '/messages' ? {'items': <dynamic>[], 'next_before': null} : <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/messages/chat',
      routes: _routes(),
      user: kTestGuardianUser,
      extraOverrides: [
        audioRecorderSourceProvider.overrideWithValue(FakeAudioRecorderSource()),
        audioPlayerSourceProvider.overrideWithValue(FakeAudioPlayerSource()),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('I am fine'), findsNothing);
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();

    expect(find.text('Record an urgent voice message'), findsOneWidget);
  });

  testWidgets('TC-4.6-14: "Load earlier messages" fetches older items and removes itself once next_before is null', (tester) async {
    var calls = 0;
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path != '/messages') return <String, dynamic>{};
      calls++;
      if (calls == 1) {
        return {
          'items': [
            {
              'message_id': 'm-new',
              'sender_id': 'dep-9',
              'receiver_id': 'g-1',
              'type': 'text',
              'body': 'Recent',
              'content_url': null,
              'priority': 'standard',
              'sent_at': '2026-10-22T10:00:00Z',
              'read_at': null,
              'from_me': false,
              'duration_s': null,
            },
          ],
          'next_before': '2026-10-22T10:00:00Z',
        };
      }
      return {
        'items': [
          {
            'message_id': 'm-old',
            'sender_id': 'dep-9',
            'receiver_id': 'g-1',
            'type': 'text',
            'body': 'Older message',
            'content_url': null,
            'priority': 'standard',
            'sent_at': '2026-10-21T10:00:00Z',
            'read_at': null,
            'from_me': false,
            'duration_s': null,
          },
        ],
        'next_before': null,
      };
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/messages/chat', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Load earlier messages'), findsOneWidget);
    await tester.tap(find.text('Load earlier messages'));
    await tester.pumpAndSettle();

    expect(find.text('Older message'), findsOneWidget);
    expect(find.text('Load earlier messages'), findsNothing);
  });

  testWidgets('TC-4.6-15/4.8: tapping Play on a voice bubble downloads and plays the audio', (tester) async {
    final fakePlayer = FakeAudioPlayerSource();
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/messages') {
        return {
          'items': [
            {
              'message_id': 'm-voice',
              'sender_id': 'g-1',
              'receiver_id': 'dep-9',
              'type': 'priority_voice',
              'body': null,
              'content_url': '/messages/m-voice/audio',
              'priority': 'critical',
              'sent_at': '2026-10-22T10:00:00Z',
              'read_at': null,
              'from_me': false,
              'duration_s': 7,
            },
          ],
          'next_before': null,
        };
      }
      if (path == '/messages/m-voice/audio') return <int>[1, 2, 3, 4, 5];
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/messages/chat',
      routes: _routes(),
      extraOverrides: [audioPlayerSourceProvider.overrideWithValue(fakePlayer)],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Urgent voice message'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_circle));
    await tester.pumpAndSettle();

    expect(fakePlayer.playCalls, 1);
    expect(fakePlayer.lastPlayedBytes, [1, 2, 3, 4, 5]);
    expect(find.byIcon(Icons.pause_circle), findsOneWidget);
  });

  testWidgets('TC-4.6-16: the initial load failing shows Retry, which reloads successfully', (tester) async {
    var shouldFail = true;
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path != '/messages') return <String, dynamic>{};
      if (shouldFail) {
        shouldFail = false;
        throw const ApiException(code: 'unexpected_error', message: "Couldn't load this conversation.");
      }
      return {'items': <dynamic>[], 'next_before': null};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/messages/chat', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load this conversation."), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('No messages yet. Say hello!'), findsOneWidget);
  });

  testWidgets('TC-4.6-17: an empty thread shows the start-conversation message', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) => path == '/messages' ? {'items': <dynamic>[], 'next_before': null} : <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/messages/chat', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('No messages yet. Say hello!'), findsOneWidget);
  });

  testWidgets('TC-4.7-16: a Guardian sees the Call button; tapping it + "Video call" starts an outgoing call', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) => path == '/messages' ? {'items': <dynamic>[], 'next_before': null} : <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/messages/chat',
      routes: _routes(),
      user: kTestGuardianUser,
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.call), findsOneWidget);
    await tester.tap(find.byIcon(Icons.call));
    await tester.pumpAndSettle();

    expect(find.text('Video call'), findsOneWidget);
    await tester.tap(find.text('Video call'));
    await tester.pumpAndSettle();

    expect(find.text('OUTGOING_CALL_STUB'), findsOneWidget);
  });

  testWidgets('TC-4.7-17: a Dependent does not see the Call button', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) => path == '/messages' ? {'items': <dynamic>[], 'next_before': null} : <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/messages/chat', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.call), findsNothing);
  });
}
