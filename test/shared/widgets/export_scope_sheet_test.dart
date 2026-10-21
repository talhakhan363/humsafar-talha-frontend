// Tasks 5.6/5.7 — TC-5.6-32..35. `showExportScopeSheet` is a function
// that opens a sheet and then does the download+share itself, not a
// widget with a return value — so, same pattern as
// `voice_recorder_sheet_test.dart`, each test pumps a tiny harness
// screen with a button that calls it, and asserts on the fake API
// client/share source side effects instead of a pop value.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humsafar_frontend/core/files/file_providers.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/core/network/providers.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';
import 'package:humsafar_frontend/shared/widgets/export_scope_sheet.dart';

import '../../support/fake_api_client.dart';
import '../../support/fake_file_sources.dart';

Future<void> _pumpHarness(
  WidgetTester tester, {
  required FakeApiClient fakeClient,
  required FakeShareSource shareSource,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(fakeClient),
        shareSourceProvider.overrideWithValue(shareSource),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () => showExportScopeSheet(
                context: context,
                ref: ref,
                exportPath: '/dependents/dep-1/records/export',
                fileNamePrefix: 'medical_records',
              ),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-5.6-32: "Everything" downloads with scope=complete and shares with no suffix', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => [1, 2, 3]);
    final shareSource = FakeShareSource();
    await _pumpHarness(tester, fakeClient: fakeClient, shareSource: shareSource);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Export'));
    await tester.pumpAndSettle();

    expect(fakeClient.getCalls, 1);
    expect(fakeClient.lastGetPath, '/dependents/dep-1/records/export');
    expect(shareSource.shareBytesCalls, 1);
    expect(shareSource.lastSharedFileName, 'medical_records.pdf');
  });

  testWidgets('TC-5.6-33: "This year" suffixes the filename with the chosen year', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => [1, 2, 3]);
    final shareSource = FakeShareSource();
    await _pumpHarness(tester, fakeClient: fakeClient, shareSource: shareSource);

    await tester.tap(find.text('This year'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Export'));
    await tester.pumpAndSettle();

    expect(shareSource.lastSharedFileName, 'medical_records_${DateTime.now().year}.pdf');
  });

  testWidgets('TC-5.6-34: an empty byte response shows exportFailedMessage, no share', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => <int>[]);
    final shareSource = FakeShareSource();
    await _pumpHarness(tester, fakeClient: fakeClient, shareSource: shareSource);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Export'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't prepare the export. Please try again."), findsOneWidget);
    expect(shareSource.shareBytesCalls, 0);
  });

  testWidgets('TC-5.6-35: MODULE_ACCESS_DENIED maps to healthRecordsAccessDeniedMessage', (tester) async {
    final fakeClient = FakeApiClient(getError: const ApiException(code: 'MODULE_ACCESS_DENIED', message: 'raw'));
    final shareSource = FakeShareSource();
    await _pumpHarness(tester, fakeClient: fakeClient, shareSource: shareSource);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Export'));
    await tester.pumpAndSettle();

    expect(find.text("You don't have access to health records for this Dependent."), findsOneWidget);
  });
}
