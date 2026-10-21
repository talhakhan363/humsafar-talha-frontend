// Task 6.8 — TC-6.8-01..07. Directory: the Organizations/Home care
// tabs, the sample-entry Call-button rule, logging a contact before
// dialing, and the empty-results state. "Near me" isn't exercised here
// since it talks to the real `Geolocator` plugin, which has no
// platform channel under `flutter test` — `_useNearMe` already
// swallows any failure there, so the button simply isn't tapped in
// these tests rather than being stubbed out.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/features/directory/screens/directory_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes() => [
      GoRoute(path: '/directory-under-test', builder: (_, __) => const DirectoryScreen(dependentId: 'dep-1')),
      GoRoute(path: '/directory/activity', builder: (_, __) => stubScreen('ACTIVITY_LOG_STUB')),
      GoRoute(path: '/directory/request-visit', builder: (_, __) => stubScreen('REQUEST_VISIT_STUB')),
    ];

final _org = {'org_id': 'org-1', 'name': 'City Hospital', 'city': 'Lahore', 'phone': '04235000000', 'is_sample': false};
final _sampleOrg = {'org_id': 'org-2', 'name': 'Sample Clinic', 'city': 'Lahore', 'phone': '0420000000', 'is_sample': true};
final _provider = {
  'provider_id': 'prov-1',
  'name': 'Nurse Amina',
  'specialization': 'Home nursing',
  'service_charge': 1500,
  'is_sample': false,
};

void main() {
  testWidgets('TC-6.8-01: loads Organizations by default and shows a real org with its Call button', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [_org]});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/directory-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('City Hospital'), findsOneWidget);
    expect(find.byIcon(Icons.call), findsOneWidget);
  });

  testWidgets('TC-6.8-02: a sample org shows the Sample label and has no Call button', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [_sampleOrg]});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/directory-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sample'), findsOneWidget);
    expect(find.byIcon(Icons.call), findsNothing);
  });

  testWidgets('TC-6.8-03: calling a real org logs the contact before dialing', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [_org]}, postHandler: (_) => <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/directory-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.call));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(fakeClient.lastPostPath, '/dependents/dep-1/directory/contacts');
    expect(fakeClient.lastPostData, {'org_id': 'org-1'});
  });

  testWidgets('TC-6.8-04: an empty Organizations list shows the no-results message', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': []});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/directory-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('No results found.'), findsOneWidget);
  });

  testWidgets('TC-6.8-05: switching to Home care re-queries providers and shows Request Visit', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) => path.contains('/providers') ? {'items': [_provider]} : {'items': []});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/directory-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Home Care'));
    await tester.pumpAndSettle();

    expect(find.text('Nurse Amina'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Request Visit'), findsOneWidget);
  });

  testWidgets('TC-6.8-06: tapping Request Visit navigates with the provider payload', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) => path.contains('/providers') ? {'items': [_provider]} : {'items': []});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/directory-under-test', routes: _routes()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Home Care'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Request Visit'));
    await tester.pumpAndSettle();

    expect(find.text('REQUEST_VISIT_STUB'), findsOneWidget);
  });

  testWidgets('TC-6.8-07: the app-bar Activity log icon navigates there', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': []});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/directory-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();

    expect(find.text('ACTIVITY_LOG_STUB'), findsOneWidget);
  });
}
