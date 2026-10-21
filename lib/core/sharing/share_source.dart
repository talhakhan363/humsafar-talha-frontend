import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Tasks 5.6/5.7 — wraps the `share_plus` plugin behind a plain
/// interface, same seam shape as `FilePickerSource`
/// (lib/core/files/file_picker_source.dart) and every other native
/// plugin in this app: a thin real implementation, and a fake for
/// widget tests that asserts on *what* was shared without needing a
/// real OS share sheet (which has no platform channel under `flutter
/// test`, same reasoning as `DeviceLocationSource`).
///
/// Used for: the exported records/vitals PDF (downloaded as bytes via
/// `ApiClient.get(..., responseType: ResponseType.bytes)`, same
/// pattern as Task 4.8's voice-message download, then handed to the
/// OS share sheet instead of opened in an in-app viewer — see
/// `medical_vault_screen.dart`'s doc comment for why no in-app viewer
/// was built this batch) and the doctor-link URL (plain text share).
abstract class ShareSource {
  /// Shares a file's raw bytes (a PDF export, or a medical record's own
  /// file) via the OS share sheet. [fileName] should keep its real
  /// extension so the receiving app picks the right viewer.
  Future<void> shareBytes({required Uint8List bytes, required String fileName});

  /// Shares plain text (the doctor-link URL, with its own short
  /// explanation) — e.g. so it can be pasted into WhatsApp or SMS, per
  /// `records_contract.md`'s own suggestion.
  Future<void> shareText(String text);
}

class PlatformShareSource implements ShareSource {
  @override
  Future<void> shareBytes({required Uint8List bytes, required String fileName}) async {
    // `XFile.fromData`'s own `name` is ignored on most platforms (per
    // share_plus's own README) — `fileNameOverrides` is what actually
    // names the shared file, so both are set to the same value.
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: _mimeTypeFor(fileName), name: fileName)],
        fileNameOverrides: [fileName],
      ),
    );
  }

  @override
  Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }

  String _mimeTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }
}
