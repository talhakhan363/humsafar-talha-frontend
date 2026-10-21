import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart' show FormData, MultipartFile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/audio/audio_providers.dart';
import '../../../core/audio/audio_recorder_source.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/scheduling/schedule_helpers.dart';
import '../models/chat_message.dart';

const _maxRecordingSeconds = 120;

enum _RecorderPhase { idle, recording, review, sending }

/// Task 4.8 — mockup 17c. Opened as a modal bottom sheet from
/// `ChatScreen`'s mic button (Guardian only — the mic button itself is
/// never shown to a Dependent; the backend would 403 anyway per
/// messaging_contract.md's "a Dependent cannot send one").
///
/// Returns the sent `ChatMessage` by popping with it
/// (`Navigator.of(context).pop(message)`) so `ChatScreen` can append it
/// to the thread immediately, without a second round-trip.
///
/// Named scope cut: no live waveform — would need an extra package
/// purely for the visual, with no functional value beyond the
/// elapsed-time counter already shown (same "flag it, don't silently
/// build a smaller thing" reasoning as every other named cut in this
/// project).
class VoiceRecorderSheet extends ConsumerStatefulWidget {
  const VoiceRecorderSheet({super.key, required this.receiverId, required this.peerName});

  final String receiverId;
  final String peerName;

  @override
  ConsumerState<VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends ConsumerState<VoiceRecorderSheet> {
  _RecorderPhase _phase = _RecorderPhase.idle;
  Timer? _ticker;
  int _elapsedSeconds = 0;
  bool _hitMaxLength = false;
  Uint8List? _recordedBytes;
  bool _isPlayingPreview = false;
  String? _errorMessage;
  final String _clientId = '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

  // Cached at the point recording starts, not re-read in dispose(): current
  // flutter_riverpod throws "Cannot use ref after the widget was disposed"
  // if dispose() itself calls ref.read — the element is already tearing
  // down by then. Caching the one provider dispose() needs sidesteps that.
  AudioRecorderSource? _recorder;

  @override
  void dispose() {
    _ticker?.cancel();
    // Safety net: the sheet can be dismissed (swipe down / back button)
    // mid-recording. Without this, the plugin keeps recording to a temp
    // file nobody will ever read or delete.
    if (_phase == _RecorderPhase.recording) {
      unawaited(_recorder?.cancel());
    }
    super.dispose();
  }

  Future<void> _startRecording() async {
    final l10n = AppLocalizations.of(context)!;
    final recorder = ref.read(audioRecorderSourceProvider);
    _recorder = recorder;
    final granted = await recorder.hasPermission();
    if (!granted) {
      if (!mounted) return;
      setState(() => _errorMessage = l10n.micPermissionDeniedMessage);
      return;
    }
    await recorder.start();
    if (!mounted) return;
    setState(() {
      _phase = _RecorderPhase.recording;
      _elapsedSeconds = 0;
      _hitMaxLength = false;
      _errorMessage = null;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= _maxRecordingSeconds) {
        _hitMaxLength = true;
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    _ticker?.cancel();
    final bytes = await ref.read(audioRecorderSourceProvider).stop();
    if (!mounted) return;
    setState(() {
      _recordedBytes = bytes;
      _phase = _RecorderPhase.review;
    });
  }

  Future<void> _playPreview() async {
    final bytes = _recordedBytes;
    if (bytes == null) return;
    final player = ref.read(audioPlayerSourceProvider);
    setState(() => _isPlayingPreview = true);
    await player.playBytes(bytes);
    unawaited(player.onComplete.first.then((_) {
      if (mounted) setState(() => _isPlayingPreview = false);
    }));
  }

  void _discard() {
    // Recording already stopped before this phase is reachable — only
    // local state (the bytes already read into memory) needs clearing,
    // no need to touch the recorder again.
    setState(() {
      _phase = _RecorderPhase.idle;
      _recordedBytes = null;
      _elapsedSeconds = 0;
      _hitMaxLength = false;
      _errorMessage = null;
    });
  }

  Future<void> _send() async {
    final bytes = _recordedBytes;
    final l10n = AppLocalizations.of(context)!;
    if (bytes == null || _elapsedSeconds < 1) return;
    setState(() {
      _phase = _RecorderPhase.sending;
      _errorMessage = null;
    });
    try {
      final formData = FormData.fromMap({
        'receiver_id': widget.receiverId,
        'duration_s': '$_elapsedSeconds',
        'client_id': _clientId,
        'audio': MultipartFile.fromBytes(bytes, filename: 'voice.m4a'),
      });
      final response = await ref.read(apiClientProvider).post<Map<String, dynamic>>('/messages/voice', data: formData);
      if (!mounted) return;
      Navigator.of(context).pop(ChatMessage.fromJson(response.data!));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _RecorderPhase.review;
        _errorMessage = _messageFor(l10n, e);
      });
    }
  }

  String _messageFor(AppLocalizations l10n, ApiException e) {
    switch (e.code) {
      case 'MODULE_ACCESS_DENIED':
        return l10n.communicationAccessDeniedMessage;
      case 'AUDIO_TOO_LARGE':
      case 'UNSUPPORTED_AUDIO':
      case 'VALIDATION_ERROR':
        return l10n.voiceSendFailedGenericMessage;
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.recordUrgentVoiceSheetTitle, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              l10n.urgentVoiceWarningMessage(widget.peerName),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.amber.shade900),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null) ...[
              Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700), textAlign: TextAlign.center),
              const SizedBox(height: 12),
            ],
            if (_hitMaxLength && _phase != _RecorderPhase.recording) ...[
              Text(l10n.maxLengthReachedMessage, style: TextStyle(color: Colors.orange.shade800), textAlign: TextAlign.center),
              const SizedBox(height: 12),
            ],
            ..._buildPhaseControls(l10n),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPhaseControls(AppLocalizations l10n) {
    switch (_phase) {
      case _RecorderPhase.idle:
        return [
          const Icon(Icons.mic_none, size: 48, color: Colors.teal),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _startRecording,
            icon: const Icon(Icons.mic),
            label: Text(l10n.tapToStartRecordingLabel),
          ),
        ];
      case _RecorderPhase.recording:
        return [
          const Icon(Icons.fiber_manual_record, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(l10n.recordingInProgressLabel(formatCountdown(Duration(seconds: _elapsedSeconds))), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _stopRecording, child: Text(l10n.stopRecordingButtonLabel)),
        ];
      case _RecorderPhase.review:
      case _RecorderPhase.sending:
        final sending = _phase == _RecorderPhase.sending;
        return [
          Text(formatCountdown(Duration(seconds: _elapsedSeconds)), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          IconButton(
            onPressed: sending ? null : _playPreview,
            icon: Icon(_isPlayingPreview ? Icons.pause_circle : Icons.play_circle, size: 40),
            tooltip: l10n.playPreviewButtonLabel,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: sending ? null : _discard,
                  child: Text(l10n.discardRecordingButtonLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: sending ? null : _send,
                  child: sending
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.sendUrgentVoiceButtonLabel),
                ),
              ),
            ],
          ),
        ];
    }
  }
}
