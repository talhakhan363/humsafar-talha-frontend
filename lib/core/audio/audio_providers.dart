import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_player_source.dart';
import 'audio_recorder_source.dart';

/// Task 4.8 — one shared instance per app run, same shape as
/// `apiClientProvider` (lib/core/network/providers.dart). Overridden in
/// widget tests with `FakeAudioRecorderSource`/`FakeAudioPlayerSource`
/// (test/support/fake_audio_sources.dart) exactly like `apiClientProvider`
/// is overridden with `FakeApiClient`.
final audioRecorderSourceProvider = Provider<AudioRecorderSource>((ref) => RecordPluginAudioRecorderSource());

final audioPlayerSourceProvider = Provider<AudioPlayerSource>((ref) {
  final player = AudioplayersSource();
  ref.onDispose(player.dispose);
  return player;
});
