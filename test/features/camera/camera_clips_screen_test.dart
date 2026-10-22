// Task 6.9 — TC-6.9-13..16. Saved clips list (mockup 19b): empty state,
// a saved clip's trigger/status, download (byte-fetch + OS share sheet,
// same pattern as medical_vault_screen.dart's export), and delete with
// its confirm dialog. Fixture updated 2026-10-22 to the real field
// names (`trigger_type`/`stored`) per camera_clips_screen.dart's own
// field-name fix.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/files/file_providers.dart';
import 'package:humsafar_frontend/features/camera/screens/camera_clips_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/fake_file_sources.dart';
import '../../support/widget_test_harness.dart';

const _clip = {
  'clip_id': 'clip-1',
  'trigger_type': 'panic',
  'status': 'stored',
  'captured_at': '2026-10-22T10:00:00Z',
  'uploaded_at': '2026-10-22T10:00:20Z',
};

List<GoRoute> _routes() => [
      GoRoute(path: '/clips-under-test', builder: (_, __) => const CameraClipsScreen(dependentId: 'dep-1')),
    ];

void main() {
  testWidgets('TC-6.9-13: an empty clips list shows the empty state', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': <dynamic>[]});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/clips-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('No saved clips yet.'), findsOneWidget);
  });

  testWidgets('TC-6.9-14: a saved clip shows its trigger and status, with download/delete actions', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [_clip]});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/clips-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Panic Mode'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.byTooltip('Download'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);
  });

  testWidgets('TC-6.9-15: Download fetches the clip bytes and shares them', (tester) async {
    final fakeShare = FakeShareSource();
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path.endsWith('/file')) return <int>[1, 2, 3];
      return {'items': [_clip]};
    });
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/clips-under-test',
      routes: _routes(),
      extraOverrides: [shareSourceProvider.overrideWithValue(fakeShare)],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Download'));
    await tester.pumpAndSettle();

    expect(fakeClient.lastGetPath, '/dependents/dep-1/camera/clips/clip-1/file');
    expect(fakeShare.shareBytesCalls, 1);
    expect(fakeShare.lastSharedFileName, 'humsafar_clip_clip-1.mp4');
    expect(fakeShare.lastSharedBytes, Uint8List.fromList([1, 2, 3]));
  });

  testWidgets('TC-6.9-16: Delete asks to confirm, then DELETEs and removes the row', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [_clip]});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/clips-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this clip?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(fakeClient.deleteCalls, 1);
    expect(fakeClient.lastDeletePath, '/dependents/dep-1/camera/clips/clip-1');
    expect(find.text('Panic Mode'), findsNothing);
    expect(find.text('Clip deleted'), findsOneWidget);
  });
}
