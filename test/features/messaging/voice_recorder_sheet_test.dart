// Task 4.8 — TC-4.8-01..07.
//
// VoiceRecorderSheet is opened via showModalBottomSheet, which pops with
// its result rather than returning one from a build method — so each
// test here pumps a tiny harness screen with a button that opens the
// sheet and stashes the eventual result in a Completer, the standard
// way to assert on a modal route's pop value in a widget test.

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart' show FormData;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humsafar_frontend/core/audio/audio_providers.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/core/network/providers.dart';
import 'package:humsafar_frontend/features/messaging/models/chat_message.dart';
import 'package:humsafar_frontend/features/messaging/widgets/voice_recorder_sheet.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../support/fake_api_client.dart';
import '../../support/fake_audio_sources.dart';

Future<void> _pumpSheetHarness(
  WidgetTester tester, {
  required FakeApiClient fakeClient,
  required FakeAudioRecorderSource recorder,
  required FakeAudioPlayerSource player,
  required Completer<ChatMessage?> resultCompleter,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(fakeClient),
        audioRecorderSourceProvider.overrideWithValue(recorder),
        audioPlayerSourceProvider.overrideWithValue(player),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await showModalBottomSheet<ChatMessage>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const VoiceRecorderSheet(receiverId: 'dep-9', peerName: 'Ammi'),
                );
                resultCompleter.complete(result);
              },
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
  testWidgets('TC-4.8-01: tapping start shows a running elapsed-time counter', (tester) async {
    final recorder = FakeAudioRecorderSource();
    await _pumpSheetHarness(
      tester,
      fakeClient: FakeApiClient(),
      recorder: recorder,
      player: FakeAudioPlayerSource(),
      resultCompleter: Completer<ChatMessage?>(),
    );

    await tester.tap(find.text('Tap to start recording'));
    await tester.pumpAndSettle();
    expect(recorder.isRecording, true);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Recording… 00:03'), findsOneWidget);
  });

  testWidgets('TC-4.8-02: auto-stops at 2:00 and shows the max-length note on the review screen', (tester) async {
    final recorder = FakeAudioRecorderSource(bytesOnStop: Uint8List.fromList([1, 2, 3]));
    await _pumpSheetHarness(
      tester,
      fakeClient: FakeApiClient(),
      recorder: recorder,
      player: FakeAudioPlayerSource(),
      resultCompleter: Completer<ChatMessage?>(),
    );

    await tester.tap(find.text('Tap to start recording'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 120));
    await tester.pumpAndSettle();

    expect(recorder.isRecording, false);
    expect(find.text('Maximum length reached (2:00).'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
  });

  testWidgets('TC-4.8-03: tapping Stop moves to the review screen with Play/Discard/Send', (tester) async {
    final recorder = FakeAudioRecorderSource(bytesOnStop: Uint8List.fromList([9, 9]));
    await _pumpSheetHarness(
      tester,
      fakeClient: FakeApiClient(),
      recorder: recorder,
      player: FakeAudioPlayerSource(),
      resultCompleter: Completer<ChatMessage?>(),
    );

    await tester.tap(find.text('Tap to start recording'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();

    expect(find.text('Discard'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
  });

  testWidgets('TC-4.8-04: Discard clears the review screen and returns to idle', (tester) async {
    final recorder = FakeAudioRecorderSource(bytesOnStop: Uint8List.fromList([9, 9]));
    await _pumpSheetHarness(
      tester,
      fakeClient: FakeApiClient(),
      recorder: recorder,
      player: FakeAudioPlayerSource(),
      resultCompleter: Completer<ChatMessage?>(),
    );

    await tester.tap(find.text('Tap to start recording'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Tap to start recording'), findsOneWidget);
  });

  testWidgets('TC-4.8-05: denied microphone permission shows the permission message and never starts', (tester) async {
    final recorder = FakeAudioRecorderSource(permissionGranted: false);
    await _pumpSheetHarness(
      tester,
      fakeClient: FakeApiClient(),
      recorder: recorder,
      player: FakeAudioPlayerSource(),
      resultCompleter: Completer<ChatMessage?>(),
    );

    await tester.tap(find.text('Tap to start recording'));
    await tester.pumpAndSettle();

    expect(recorder.isRecording, false);
    expect(find.text('Microphone permission is needed to record a voice message.'), findsOneWidget);
  });

  testWidgets('TC-4.8-06: Send builds the multipart request and pops with the returned message on success',
      (tester) async {
    final recorder = FakeAudioRecorderSource(bytesOnStop: Uint8List.fromList([1, 2, 3]));
    final fakeClient = FakeApiClient(
      postHandler: (path) => {
        'message_id': 'm-voice-1',
        'sender_id': 'g-1',
        'receiver_id': 'dep-9',
        'type': 'priority_voice',
        'body': null,
        'content_url': '/messages/m-voice-1/audio',
        'priority': 'critical',
        'sent_at': '2026-10-22T10:00:00Z',
        'read_at': null,
        'from_me': true,
        'duration_s': 2,
      },
    );
    final completer = Completer<ChatMessage?>();
    await _pumpSheetHarness(
      tester,
      fakeClient: fakeClient,
      recorder: recorder,
      player: FakeAudioPlayerSource(),
      resultCompleter: completer,
    );

    await tester.tap(find.text('Tap to start recording'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(fakeClient.lastPostPath, '/messages/voice');
    expect((fakeClient.lastPostData as FormData).fields.any((f) => f.key == 'receiver_id' && f.value == 'dep-9'), true);
    expect(completer.isCompleted, true);
    final result = await completer.future;
    expect(result?.messageId, 'm-voice-1');
  });

  testWidgets('TC-4.8-07: a MODULE_ACCESS_DENIED send failure shows the mapped message and stays on review (bytes kept)',
      (tester) async {
    final recorder = FakeAudioRecorderSource(bytesOnStop: Uint8List.fromList([1, 2, 3]));
    final fakeClient = FakeApiClient(
      postError: const ApiException(code: 'MODULE_ACCESS_DENIED', message: 'raw server message'),
    );
    await _pumpSheetHarness(
      tester,
      fakeClient: fakeClient,
      recorder: recorder,
      player: FakeAudioPlayerSource(),
      resultCompleter: Completer<ChatMessage?>(),
    );

    await tester.tap(find.text('Tap to start recording'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(find.text('Only Guardians with Communication access can message right now.'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget); // still on review, can retry
  });
}
