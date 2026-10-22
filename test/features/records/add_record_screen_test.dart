// Task 5.6 — TC-5.6-09..14. The Add/Edit record form: required-field
// validation, the "needs content" rule (no file AND no notes), the file
// picker + size-limit check, the add-vs-edit (POST multipart vs PATCH)
// branch, and the file-cannot-be-replaced note in edit mode.

import 'dart:typed_data';

import 'package:dio/dio.dart' show FormData;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/files/file_picker_source.dart';
import 'package:humsafar_frontend/core/files/file_providers.dart';
import 'package:humsafar_frontend/features/records/screens/add_record_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/fake_file_sources.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes({Map<String, dynamic>? existing}) => [
      GoRoute(
        path: '/add-record-under-test',
        builder: (_, __) => AddRecordScreen(dependentId: 'dep-1', existing: existing),
      ),
    ];

// Adds a `/host` route in front of the screen under test — see
// `AutoPushHost`'s doc comment in widget_test_harness.dart for why this
// is needed for any test that actually reaches `_save()`'s
// `Navigator.of(context).pop(true)`.
List<GoRoute> _hostedRoutes({Map<String, dynamic>? existing}) => [
      GoRoute(path: '/host', builder: (_, __) => const AutoPushHost(targetPath: '/add-record-under-test')),
      ..._routes(existing: existing),
    ];

// `find.widgetWithText(OutlinedButton, ...)` matches by *exact* runtime
// type, but `OutlinedButton.icon(...)` (used for "Attach File") returns
// a private subclass — so that finder always comes back empty. This
// matches by `is OutlinedButton`, which covers the `.icon` factory too.
Finder _outlinedButtonWithText(String text) =>
    find.ancestor(of: find.text(text), matching: find.byWidgetPredicate((widget) => widget is OutlinedButton));

void main() {
  testWidgets('TC-5.6-09: empty title blocks Save with an inline error, no POST', (tester) async {
    final fakeClient = FakeApiClient();
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/add-record-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsOneWidget);
    expect(fakeClient.postCalls, 0);
  });

  testWidgets('TC-5.6-10: a title with no file and no notes blocks Save with recordNeedsContentError', (tester) async {
    final fakeClient = FakeApiClient();
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/add-record-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Checkup notes');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Add a file or some notes before saving.'), findsOneWidget);
    expect(fakeClient.postCalls, 0);
  });

  testWidgets('TC-5.6-11: notes alone (no file) is enough content to save', (tester) async {
    final fakeClient = FakeApiClient(postHandler: (_) => <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/host', routes: _hostedRoutes()));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Checkup notes');
    await tester.enterText(find.widgetWithText(TextField, 'Notes'), 'Felt fine, BP normal.');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(fakeClient.lastPostPath, '/dependents/dep-1/records');
    expect(fakeClient.lastPostData, isA<FormData>());
  });

  testWidgets('TC-5.6-12: picking a file over the 10 MB limit shows fileTooLargeMessage and is not attached', (tester) async {
    final fakeClient = FakeApiClient();
    final fakeFilePicker = FakeFilePickerSource(
      result: PickedFileData(bytes: Uint8List(10), fileName: 'scan.pdf', sizeBytes: 11 * 1024 * 1024),
    );
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/add-record-under-test',
      routes: _routes(),
      extraOverrides: [filePickerSourceProvider.overrideWithValue(fakeFilePicker)],
    ));
    await tester.pumpAndSettle();

    await tester.tap(_outlinedButtonWithText('Attach File'));
    await tester.pumpAndSettle();

    expect(find.text('This file is too large. The limit is 10 MB.'), findsOneWidget);
    expect(find.text('scan.pdf'), findsNothing);
  });

  testWidgets('TC-5.6-13: a valid file attaches and is sent on save', (tester) async {
    final fakeClient = FakeApiClient(postHandler: (_) => <String, dynamic>{});
    final fakeFilePicker = FakeFilePickerSource(
      result: PickedFileData(bytes: Uint8List(10), fileName: 'scan.pdf', sizeBytes: 1024),
    );
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/host',
      routes: _hostedRoutes(),
      extraOverrides: [filePickerSourceProvider.overrideWithValue(fakeFilePicker)],
    ));
    await tester.pumpAndSettle();

    await tester.tap(_outlinedButtonWithText('Attach File'));
    await tester.pumpAndSettle();
    expect(find.text('scan.pdf'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Scan');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    final formData = fakeClient.lastPostData as FormData;
    expect(formData.files.first.key, 'file');
  });

  testWidgets('TC-5.6-14: edit mode hides the file picker, shows the cannot-replace note, and PATCHes', (tester) async {
    final existing = {
      'record_id': 'rec-9',
      'title': 'Old title',
      'category': 'prescription',
      'record_date': '2026-01-01',
      'notes': 'old notes',
    };
    final fakeClient = FakeApiClient(patchHandler: (_) => <String, dynamic>{});
    await tester.pumpWidget(
      wrapWithRouter(fakeClient: fakeClient, initialLocation: '/host', routes: _hostedRoutes(existing: existing)),
    );
    await tester.pumpAndSettle();

    expect(_outlinedButtonWithText('Attach File'), findsNothing);
    expect(find.text("The file can't be replaced. Delete this record and add a new one instead."), findsOneWidget);
    expect(find.text('Edit Record'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'New title');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(fakeClient.patchCalls, 1);
    expect(fakeClient.lastPatchPath, '/dependents/dep-1/records/rec-9');
    expect((fakeClient.lastPatchData as Map)['title'], 'New title');
  });
}
