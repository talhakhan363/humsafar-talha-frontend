import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Task 4.8 — wraps the `record` plugin behind a bytes-in/bytes-out
/// interface, the same seam shape as `DeviceLocationSource` (Task 2.7)
/// and the `launchUrlOverride` parameter (Task 3.14): a thin real
/// implementation wraps the plugin, and tests inject a fake that needs
/// no real microphone/device at all.
///
/// Deliberately bytes, not a file path: the plugin has to write to a
/// temp file either way (that's how `record` works), so the real
/// implementation reads that file into memory and deletes it itself —
/// nothing above this interface (the recorder sheet, the eventual
/// multipart upload) ever needs to know a file was involved.
abstract class AudioRecorderSource {
  /// Checks (and, per the plugin's own default, requests) microphone
  /// permission. Returns false if denied — the caller should show
  /// `micPermissionDeniedMessage` rather than calling [start] anyway.
  Future<bool> hasPermission();

  /// Starts recording to a fresh temp file.
  Future<void> start();

  /// Stops recording and returns the recorded audio bytes (AAC/m4a), or
  /// null if nothing was captured.
  Future<Uint8List?> stop();

  /// Stops (if still recording) and discards the temp file — used when
  /// the sheet is dismissed mid-recording, see
  /// `voice_recorder_sheet.dart`'s `dispose()`.
  Future<void> cancel();
}

class RecordPluginAudioRecorderSource implements AudioRecorderSource {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/humsafar_urgent_voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: _path!);
  }

  @override
  Future<Uint8List?> stop() async {
    final stoppedPath = await _recorder.stop() ?? _path;
    if (stoppedPath == null) return null;
    final file = File(stoppedPath);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    unawaited(file.delete().catchError((_) => file));
    return bytes;
  }

  @override
  Future<void> cancel() async {
    await _recorder.cancel();
    final path = _path;
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      unawaited(file.delete().catchError((_) => file));
    }
  }
}
