// Task 5.6 — TC-5.6-01..08. Covers the Medical Vault list: loading a
// record, the category filter re-querying the server, the app-bar menu
// gating Record access on `canManageAccess`, delete (with confirm), and
// the MODULE_ACCESS_DENIED error mapping. The Export item itself opens
// `showExportScopeSheet`, whose own download-then-share behaviour is
// covered once in `test/shared/widgets/export_scope_sheet_test.dart`
// rather than re-tested from every screen that triggers it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/records/screens/medical_vault_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes({bool canManageAccess = false}) => [
      GoRoute(
        path: '/records-under-test',
        builder: (_, __) => MedicalVaultScreen(dependentId: 'dep-1', canManageAccess: canManageAccess),
      ),
      GoRoute(path: '/records/add', builder: (_, __) => stubScreen('ADD_RECORD_STUB')),
      GoRoute(path: '/records/doctor-links', builder: (_, __) => stubScreen('DOCTOR_LINKS_STUB')),
      GoRoute(path: '/records/access', builder: (_, __) => stubScreen('RECORD_ACCESS_STUB')),
    ];

final _record = {
  'record_id': 'rec-1',
  'title': 'Blood test',
  'category': 'lab_report',
  'record_date': '2026-09-01',
  'has_file': true,
  'can_modify': true,
};

void main() {
  testWidgets('TC-5.6-01: loads and shows a record\'s title and category', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [_record], 'total': 1});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/records-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Blood test'), findsOneWidget);
    // The category filter row above the list also has a "Lab Report"
    // chip (same `categoryLabel()` text), so an untargeted
    // `find.textContaining('Lab Report')` matches both it and this
    // record's own subtitle — scope to the record's ListTile.
    expect(
      find.descendant(of: find.widgetWithText(ListTile, 'Blood test'), matching: find.textContaining('Lab Report')),
      findsOneWidget,
    );
  });

  testWidgets('TC-5.6-02: an empty vault shows the empty-state message', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [], 'total': 0});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/records-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('No records yet.'), findsOneWidget);
  });

  testWidgets('TC-5.6-03: picking a category chip re-queries with that category', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [_record], 'total': 1});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/records-under-test', routes: _routes()));
    await tester.pumpAndSettle();
    expect(fakeClient.getCalls, 1);

    await tester.tap(find.text('X-ray'));
    await tester.pumpAndSettle();

    expect(fakeClient.getCalls, 2);
  });

  testWidgets('TC-5.6-04: MODULE_ACCESS_DENIED on load shows the mapped message with a Retry button', (tester) async {
    final fakeClient = FakeApiClient(getError: const ApiException(code: 'MODULE_ACCESS_DENIED', message: 'raw'));
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/records-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text("You don't have access to health records for this Dependent."), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
  });

  testWidgets('TC-5.6-05: Record access menu item only shows when canManageAccess is true', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [], 'total': 0});
    await tester.pumpWidget(
      wrapWithRouter(fakeClient: fakeClient, initialLocation: '/records-under-test', routes: _routes(canManageAccess: false)),
    );
    await tester.pumpAndSettle();
    // The AppBar's language switcher is also a `PopupMenuButton<String>`
    // (see `language_switch_button.dart`), so an untargeted
    // `find.byType(PopupMenuButton<String>)` is ambiguous — this
    // screen's own menu keeps the default `more_vert` icon, the
    // language switcher uses `Icons.language`.
    await tester.tap(find.widgetWithIcon(PopupMenuButton<String>, Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Record access'), findsNothing);
    expect(find.text('Export records'), findsOneWidget);
    expect(find.text('Doctor links'), findsOneWidget);
  });

  testWidgets('TC-5.6-06: tapping Doctor links in the menu navigates there', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [], 'total': 0});
    await tester.pumpWidget(
      wrapWithRouter(fakeClient: fakeClient, initialLocation: '/records-under-test', routes: _routes(canManageAccess: true)),
    );
    await tester.pumpAndSettle();
    // Same language-switcher-collision reasoning as TC-5.6-05 above.
    await tester.tap(find.widgetWithIcon(PopupMenuButton<String>, Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Doctor links'));
    await tester.pumpAndSettle();

    expect(find.text('DOCTOR_LINKS_STUB'), findsOneWidget);
  });

  testWidgets('TC-5.6-07: Delete asks for confirmation, then DELETEs and removes the row', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [Map<String, dynamic>.from(_record)], 'total': 1});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/records-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(fakeClient.deleteCalls, 0); // confirmation dialog first, no DELETE yet

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(fakeClient.deleteCalls, 1);
    expect(fakeClient.lastDeletePath, '/dependents/dep-1/records/rec-1');
    expect(find.text('Blood test'), findsNothing);
  });

  testWidgets('TC-5.6-08: tapping + opens Add record', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [], 'total': 0});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/records-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('ADD_RECORD_STUB'), findsOneWidget);
  });
}
