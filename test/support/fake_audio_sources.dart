// test/support/fake_audio_sources.dart
//
// Task 4.8 — fakes for AudioRecorderSource/AudioPlayerSource, same
// reasoning as FakeApiClient: VoiceRecorderSheet and ChatScreen's voice
// playback are tested against these instead of the real `record`/
// `audioplayers` plugins, which have no platform channel under
// `flutter test` (same category as DeviceLocationSource's fake in
// Task 2.7's tests).

import 'dart:async';
import 'dart:typed_data';

import 'package:humsafar_frontend/core/audio/audio_player_source.dart';
import 'package:humsafar_frontend/core/audio/audio_recorder_source.dart';

class FakeAudioRecorderSource implements AudioRecorderSource {
  FakeAudioRecorderSource({this.permissionGranted = true, this.bytesOnStop});

  /// What [hasPermission] returns.
  bool permissionGranted;

  /// What [stop] returns — deliberately no default fallback, so a test
  /// that wants the "nothing was recorded" (null) path doesn't have to
  /// fight an implicit non-null default to get it.
  Uint8List? bytesOnStop;

  bool isRecording = false;
  bool wasCancelled = false;
  int startCalls = 0;

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<void> start() async {
    startCalls++;
    isRecording = true;
  }

  @override
  Future<Uint8List?> stop() async {
    isRecording = false;
    return bytesOnStop;
  }

  @override
  Future<void> cancel() async {
    isRecording = false;
    wasCancelled = true;
  }
}

class FakeAudioPlayerSource implements AudioPlayerSource {
  Uint8List? lastPlayedBytes;
  int playCalls = 0;
  int stopCalls = 0;
  final StreamController<void> _completeController = StreamController<void>.broadcast();

  @override
  Future<void> playBytes(Uint8List bytes) async {
    playCalls++;
    lastPlayedBytes = bytes;
  }

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Stream<void> get onComplete => _completeController.stream;

  /// Test helper — simulates the current playback finishing on its own.
  void fireComplete() => _completeController.add(null);

  @override
  void dispose() => _completeController.close();
}
