import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:path_provider/path_provider.dart';

/// Task 4.8 — wraps the `audioplayers` plugin behind a bytes-in
/// interface, same seam reasoning as [AudioRecorderSource]. A priority
/// voice message's audio needs the login token to download
/// (`GET /messages/{id}/audio` — messaging_contract.md is explicit that
/// "a plain audio player URL will not work"), so it's always fetched as
/// bytes through the normal `ApiClient` first, never handed to the
/// plugin as a bare URL.
abstract class AudioPlayerSource {
  /// Writes [bytes] to a temp file and starts playback from it.
  Future<void> playBytes(Uint8List bytes);

  Future<void> stop();

  /// Fires once when the current playback finishes on its own (not via
  /// [stop]).
  Stream<void> get onComplete;

  void dispose();
}

class AudioplayersSource implements AudioPlayerSource {
  final ap.AudioPlayer _player = ap.AudioPlayer();

  @override
  Future<void> playBytes(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/humsafar_playback_${DateTime.now().microsecondsSinceEpoch}.m4a';
    await File(path).writeAsBytes(bytes);
    await _player.play(ap.DeviceFileSource(path));
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Stream<void> get onComplete => _player.onPlayerComplete;

  @override
  void dispose() => _player.dispose();
}
