// Task 6.8 — TC-6.8-08..11. Request visit: the note-length guard,
// a successful save that POSTs the right body (no preferred_at when
// none was picked), the success view's Call-to-arrange button only
// appearing when the server returned a contact, and the
// TOO_MANY_OPEN_BOOKINGS error mapping.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/directory/screens/request_visit_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

const _provider = {'provider_id': 'prov-1', 'name': 'Nurse Amina', 'specialization': 'Home nursing', 'service_charge': 1500};

List<GoRoute> _routes() => [
      GoRoute(
        path: '/request-visit-under-test',
        builder: (_, __) => const RequestVisitScreen(dependentId: 'dep-1', provider: _provider),
      ),
    ];

void main() {
  testWidgets('TC-6.8-08: a note over 300 characters blocks Save, no POST', (tester) async {
    final fakeClient = FakeApiClient();
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/request-visit-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Note (optional)'), 'x' * 301);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Request'));
    await tester.pumpAndSettle();

    expect(find.text('The note is too long. Keep it under 300 characters.'), findsOneWidget);
    expect(fakeClient.postCalls, 0);
  });

  testWidgets('TC-6.8-09: saving with no preferred time POSTs without preferred_at', (tester) async {
    final fakeClient = FakeApiClient(postHandler: (_) => {'contact': null});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/request-visit-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Request'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(fakeClient.lastPostPath, '/dependents/dep-1/bookings');
    final body = fakeClient.lastPostData as Map;
    expect(body['provider_id'], 'prov-1');
    expect(body.containsKey('preferred_at'), isFalse);
    expect(find.text('Your visit request has been saved.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Call to Arrange'), findsNothing); // no contact returned
  });

  testWidgets('TC-6.8-10: when the server returns a contact, Call to Arrange appears', (tester) async {
    final fakeClient = FakeApiClient(postHandler: (_) => {'contact': '03001234567'});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/request-visit-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Request'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Call to Arrange'), findsOneWidget);
  });

  testWidgets('TC-6.8-11: TOO_MANY_OPEN_BOOKINGS on save shows the mapped message', (tester) async {
    final fakeClient = FakeApiClient(postError: const ApiException(code: 'TOO_MANY_OPEN_BOOKINGS', message: 'raw'));
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/request-visit-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Request'));
    await tester.pumpAndSettle();

    expect(find.text('You have too many open requests already. Cancel one first.'), findsOneWidget);
  });
}
