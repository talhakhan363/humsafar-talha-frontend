// test/support/fake_file_sources.dart
//
// Tasks 5.6/5.7 — fakes for FilePickerSource/ShareSource, same
// reasoning as fake_audio_sources.dart: the Add record form and the
// export/share actions are tested against these instead of the real
// `file_picker`/`share_plus` plugins, which have no platform channel
// under `flutter test`.

import 'dart:typed_data';

import 'package:humsafar_frontend/core/files/file_picker_source.dart';
import 'package:humsafar_frontend/core/sharing/share_source.dart';

class FakeFilePickerSource implements FilePickerSource {
  FakeFilePickerSource({this.result});

  /// What [pickFile] returns — null simulates the person cancelling the
  /// chooser (or the plugin returning no bytes). Deliberately no
  /// default, same reasoning as FakeAudioRecorderSource.bytesOnStop.
  PickedFileData? result;

  List<String>? lastAllowedExtensions;
  int pickCalls = 0;

  @override
  Future<PickedFileData?> pickFile({required List<String> allowedExtensions}) async {
    pickCalls++;
    lastAllowedExtensions = allowedExtensions;
    return result;
  }
}

class FakeShareSource implements ShareSource {
  Uint8List? lastSharedBytes;
  String? lastSharedFileName;
  String? lastSharedText;
  int shareBytesCalls = 0;
  int shareTextCalls = 0;

  @override
  Future<void> shareBytes({required Uint8List bytes, required String fileName}) async {
    shareBytesCalls++;
    lastSharedBytes = bytes;
    lastSharedFileName = fileName;
  }

  @override
  Future<void> shareText(String text) async {
    shareTextCalls++;
    lastSharedText = text;
  }
}
