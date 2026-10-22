// Screen 05 fix — TC-2.5-16..18. The dedicated "Share my ID" screen
// (QR code, Copy ID, Share) that replaces the old plain `SelectableText`
// in the KYC outcome view. Pure, API-free widget — a `FakeApiClient` is
// still supplied because `wrapWithRouter` requires one, but nothing
// here ever calls it.
//
// Fix, 2026-10-22 (post-delivery, Talha's real `flutter test` run):
// `Clipboard.setData`/`getData` do NOT resolve on their own under
// `flutter_test` on this Flutter version — with no mock handler
// registered for the `flutter/platform` channel, the call never
// receives a reply and just hangs until the test runner's own 10-minute
// per-test timeout kills it (`TimeoutException after 0:10:00`), rather
// than failing fast. (An earlier, unverified assumption in this file's
// comment claimed otherwise — wrong, now corrected here with the real
// fix instead of just removing the wrong claim.) `setUp`/`tearDown`
// below register an in-memory fake for exactly the two methods this
// screen uses, same "give the platform channel a real handler" idea as
// every other native plugin in this app, just done inline here rather
// than via a separate fake-source class since only this one file needs
// it.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/files/file_providers.dart';
import 'package:humsafar_frontend/features/dependent/screens/share_id_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/fake_file_sources.dart';
import '../../support/widget_test_harness.dart';

const _dependentId = 'dep-123';

List<GoRoute> _routes() => [
      GoRoute(path: '/share-id-under-test', builder: (_, __) => const ShareIdScreen(dependentId: _dependentId)),
    ];

// In-memory fake for the `flutter/platform` channel's Clipboard methods
// — see the fix note above for why this is needed at all.
String? _fakeClipboardText;

Future<Object?> _fakeClipboardHandler(MethodCall call) async {
  switch (call.method) {
    case 'Clipboard.setData':
      _fakeClipboardText = (call.arguments as Map)['text'] as String?;
      return null;
    case 'Clipboard.getData':
      return _fakeClipboardText == null ? null : <String, dynamic>{'text': _fakeClipboardText};
    case 'Clipboard.hasStrings':
      return <String, dynamic>{'value': _fakeClipboardText != null};
    default:
      return null;
  }
}

// Same reasoning as my_band_screen_test.dart's helpers: every button on
// this screen is built with the `.icon(...)` factory constructor, which
// `find.widgetWithText` can't match by exact runtime type.
Finder _outlinedButtonWithText(String text) =>
    find.ancestor(of: find.text(text), matching: find.byWidgetPredicate((widget) => widget is OutlinedButton));

Finder _elevatedButtonWithText(String text) =>
    find.ancestor(of: find.text(text), matching: find.byWidgetPredicate((widget) => widget is ElevatedButton));

void main() {
  setUp(() {
    _fakeClipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, _fakeClipboardHandler);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('TC-2.5-16: shows the QR code and the dependent ID as selectable text', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/share-id-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text(_dependentId), findsOneWidget);
    expect(_outlinedButtonWithText('Copy ID'), findsOneWidget);
    expect(_elevatedButtonWithText('Share'), findsOneWidget);
  });

  testWidgets('TC-2.5-17: Copy ID copies the dependent ID to the clipboard and confirms it', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/share-id-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(_outlinedButtonWithText('Copy ID'));
    // Deliberately NOT pumpAndSettle here — a SnackBar's own auto-
    // dismiss timer counts as pending work, so pumpAndSettle would run
    // the clock all the way past its 4s display duration and dismiss
    // it before the assertion below ever sees it (a well-known
    // SnackBar-testing gotcha). Two short pumps are enough to let the
    // tap's onPressed run, the now-mocked `Clipboard.setData` resolve
    // (a microtask hop, not a real delay), and the SnackBar's entrance
    // animation start, while staying well inside its display window.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    expect(clipboardData?.text, _dependentId);
    expect(find.text('ID copied'), findsOneWidget);
  });

  testWidgets('TC-2.5-18: Share hands the OS share sheet text containing the dependent ID', (tester) async {
    final fakeShare = FakeShareSource();
    final fakeClient = FakeApiClient(getHandler: (_) => <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/share-id-under-test',
      routes: _routes(),
      extraOverrides: [shareSourceProvider.overrideWithValue(fakeShare)],
    ));
    await tester.pumpAndSettle();

    await tester.tap(_elevatedButtonWithText('Share'));
    await tester.pumpAndSettle();

    expect(fakeShare.shareTextCalls, 1);
    expect(fakeShare.lastSharedText, contains(_dependentId));
  });
}
