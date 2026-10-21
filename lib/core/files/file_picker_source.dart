import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Tasks 5.6/5.7 — wraps the `file_picker` plugin behind a bytes-out
/// interface, the same seam shape as `DeviceLocationSource` (Task 2.7)
/// and `AudioRecorderSource` (Task 4.8): a thin real implementation
/// wraps the plugin, and tests inject a fake that needs no real file
/// chooser at all.
///
/// Deliberately bytes (`withData: true`), not a file path — consistent
/// with `records_contract.md`'s multipart upload needing the raw bytes
/// anyway, and it keeps everything above this interface (the Add
/// record form, the multipart upload itself) free of any `dart:io`
/// file handling.
class PickedFileData {
  const PickedFileData({required this.bytes, required this.fileName, required this.sizeBytes});

  final Uint8List bytes;
  final String fileName;
  final int sizeBytes;
}

abstract class FilePickerSource {
  /// Opens the system file chooser restricted to [allowedExtensions]
  /// (no dot, e.g. `['pdf', 'jpg', 'jpeg', 'png']` — matching
  /// `records_contract.md`'s "PDF, JPEG or PNG" rule). Returns null if
  /// the person cancelled, or if the plugin returned no bytes (can
  /// happen on some platforms for a very large file — the caller
  /// should show a generic "couldn't read that file" message, not
  /// crash on a null check).
  Future<PickedFileData?> pickFile({required List<String> allowedExtensions});
}

class PlatformFilePickerSource implements FilePickerSource {
  @override
  Future<PickedFileData?> pickFile({required List<String> allowedExtensions}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;
    return PickedFileData(bytes: bytes, fileName: file.name, sizeBytes: bytes.length);
  }
}
