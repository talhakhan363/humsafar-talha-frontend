import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sharing/share_source.dart';
import 'file_picker_source.dart';

/// Tasks 5.6/5.7 — one shared instance per app run, same shape as
/// `apiClientProvider`/`audioRecorderSourceProvider`. Overridden in
/// widget tests with fakes (test/support/fake_file_sources.dart)
/// exactly like those providers are.
final filePickerSourceProvider = Provider<FilePickerSource>((ref) => PlatformFilePickerSource());

final shareSourceProvider = Provider<ShareSource>((ref) => PlatformShareSource());
