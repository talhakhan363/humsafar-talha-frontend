// Task 5.6 — TC-5.6-27..31. Doctor links: the empty state, listing an
// active link with its opened-count, creating a link (shares the full
// URL via ShareSource rather than just displaying it), the
// SHARE_LIMIT error mapping, and cancelling an active link.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/core/files/file_providers.dart';
import 'package:humsafar_frontend/features/records/screens/doctor_links_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/fake_file_sources.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes() => [
      GoRoute(path: '/doctor-links-under-test', builder: (_, __) => const DoctorLinksScreen(dependentId: 'dep-1')),
    ];

final _activeLink = {
  'share_id': 'share-1',
  'status': 'active',
  'categories': ['prescription', 'lab_report'],
  'open_count': 3,
};

void main() {
  testWidgets('TC-5.6-27: an empty list shows the empty state', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': []});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/doctor-links-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('No doctor links yet.'), findsOneWidget);
  });

  testWidgets('TC-5.6-28: an active link shows its categories and opened count', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [_activeLink]});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/doctor-links-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Active'), findsOneWidget);
    expect(find.textContaining('Prescription, Lab Report'), findsOneWidget);
    expect(find.textContaining('Opened 3 time(s)'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel Link'), findsOneWidget);
  });

  testWidgets('TC-5.6-29: creating a link POSTs the chosen hours/vitals and shares the url', (tester) async {
    final fakeShare = FakeShareSource();
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': []},
      postHandler: (_) => {'url': 'https://humsafar.app/s/abc123'},
    );
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/doctor-links-under-test',
      routes: _routes(),
      extraOverrides: [shareSourceProvider.overrideWithValue(fakeShare)],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Link'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(fakeClient.lastPostPath, '/dependents/dep-1/records/share');
    expect(fakeClient.lastPostData, {'hours': 72, 'include_vitals': false});
    expect(fakeShare.shareTextCalls, 1);
    expect(fakeShare.lastSharedText, contains('https://humsafar.app/s/abc123'));
  });

  testWidgets('TC-5.6-30: SHARE_LIMIT on create shows the mapped message', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': []},
      postError: const ApiException(code: 'SHARE_LIMIT', message: 'raw'),
    );
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/doctor-links-under-test',
      routes: _routes(),
      extraOverrides: [shareSourceProvider.overrideWithValue(FakeShareSource())],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Link'));
    await tester.pumpAndSettle();

    expect(find.text("You've reached the limit of active doctor links."), findsOneWidget);
  });

  testWidgets('TC-5.6-31: cancelling an active link DELETEs and refreshes', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [Map<String, dynamic>.from(_activeLink)]},
      deleteHandler: (_) => <String, dynamic>{},
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/doctor-links-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancel Link'));
    await tester.pumpAndSettle();

    expect(fakeClient.deleteCalls, 1);
    expect(fakeClient.lastDeletePath, '/dependents/dep-1/records/share/share-1');
  });
}
