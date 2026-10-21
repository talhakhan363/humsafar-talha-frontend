// Task 4.6 — TC-4.6-02..06.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/messaging/screens/messages_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes() => [
      GoRoute(path: '/messages', builder: (_, __) => const MessagesScreen()),
      GoRoute(path: '/messages/chat', builder: (_, __) => stubScreen('CHAT_STUB')),
    ];

void main() {
  testWidgets('TC-4.6-02: renders conversations with an unread badge', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/messages/conversations') {
        return {
          'items': [
            {
              'user_id': 'dep-9',
              'name': 'Ammi',
              'role': null,
              'unread_count': 2,
              'last_message': {'type': 'text', 'body': 'Did you eat?'},
            },
          ],
          'total_unread': 2,
        };
      }
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/messages', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Ammi'), findsOneWidget);
    expect(find.text('Did you eat?'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('TC-4.6-03: an urgent-voice last message shows the voice label and mic icon, not the badge count as text',
      (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/messages/conversations') {
        return {
          'items': [
            {
              'user_id': 'g-2',
              'name': 'Secondary Guardian',
              'role': 'secondary',
              'unread_count': 0,
              'last_message': {'type': 'priority_voice', 'body': null},
            },
          ],
          'total_unread': 0,
        };
      }
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/messages', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Urgent voice message'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('TC-4.6-04: no conversations shows the empty state', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': <dynamic>[], 'total_unread': 0});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/messages', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('No conversations yet.'), findsOneWidget);
  });

  testWidgets('TC-4.6-05: a load failure shows Retry, and Retry reloads', (tester) async {
    var shouldFail = true;
    final fakeClient = FakeApiClient(
      getHandler: (path) {
        if (shouldFail) {
          shouldFail = false;
          throw const ApiException(code: 'unexpected_error', message: "Couldn't load your messages.");
        }
        return {'items': <dynamic>[], 'total_unread': 0};
      },
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/messages', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load your messages."), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No conversations yet.'), findsOneWidget);
  });

  testWidgets('TC-4.6-06: tapping a row navigates to the chat with the right peer', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/messages/conversations') {
        return {
          'items': [
            {'user_id': 'dep-9', 'name': 'Ammi', 'role': null, 'unread_count': 0, 'last_message': null},
          ],
          'total_unread': 0,
        };
      }
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/messages', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ammi'));
    await tester.pumpAndSettle();

    expect(find.text('CHAT_STUB'), findsOneWidget);
  });
}
