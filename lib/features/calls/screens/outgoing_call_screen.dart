import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/auth/current_user_provider.dart';

/// Task 4.7 — mockup 17e "Calling...". Shown to the caller immediately
/// after they tap Call, while the callee's device is ringing. This is
/// this app's first native-SDK feature (ZegoCloud's prebuilt Call
/// UIKit, used only by `call_screen.dart` once a call is actually
/// joined) — kept its own isolated delivery/commit per the standing
/// multi-task-batch convention, same reasoning 3.14/4.7 itself were
/// already being kept isolated from earlier batches.
///
/// **Deliberately does NOT use ZegoCloud's own Call Invitation feature**
/// for this waiting state. Per this project's standing decision
/// (`Humsafar_Progress_Tracker.md`, Abdullah's "Contracts ready for
/// Talha" note): our own critical `incoming_call` push is what actually
/// rings the callee's phone, so Zego's parallel invitation/ringing
/// system would be a second, redundant signaling path that could
/// disagree with our own `call_contract.md` state. This screen is a
/// plain polling UI instead — `POST /calls` starts the call, then
/// `GET /calls/{id}` is polled every 2s until the callee answers,
/// declines, or the call is auto-marked missed by the backend's own
/// 30s timeout job.
///
/// **Named field-name caveat:** `call_contract.md` itself hasn't been
/// read fresh in this sandbox — it lives in the backend repo, not
/// available here. Built from the Progress Tracker's written summary
/// for Task 4.4 ("start / ring / accept / decline / end, 30s missed
/// timeout, one open call per person, mock join token, history,
/// background job") — same contract-grounding convention, and the same
/// caveat, as Tasks 6.9/7.3. Assumed shapes:
/// - `POST /calls` body `{"receiver_id": ..., "type": "video"|"voice"}`
///   → `{"call_id": ..., "status": "ringing", ...}`.
/// - `GET /calls/{id}` → `{"call_id": ..., "status": "ringing"|
///   "accepted"|"declined"|"missed"|"ended", "zego": {"app_id": <int>,
///   "token": <string>} | null}` — `zego` is assumed present once
///   `status` is `"accepted"`, carrying everything `CallScreen` needs to
///   join. The ZegoCloud App ID and the per-call token both come from
///   the backend (which already has to generate the real token per Task
///   4.4b, `CALL_PROVIDER=zego`) — this Flutter app never embeds the
///   ZegoCloud App ID or Server Secret itself, only what the backend
///   hands back per call.
/// - The call's own `call_id` is reused as ZegoCloud's `callID` (the
///   room/channel identifier) rather than inventing a separate field.
///
/// If the real contract differs, only this screen's polling logic and
/// `IncomingCallScreen`/`CallScreen`'s matching assumptions need
/// adjusting — flagged for Abdullah/Talha to confirm against the real
/// `call_contract.md`.
class OutgoingCallScreen extends ConsumerStatefulWidget {
  const OutgoingCallScreen({super.key, required this.calleeId, required this.calleeName, required this.isVideo});

  final String calleeId;
  final String calleeName;
  final bool isVideo;

  @override
  ConsumerState<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

enum _OutgoingCallState { starting, ringing, failed, declined, missed, ended }

class _OutgoingCallScreenState extends ConsumerState<OutgoingCallScreen> {
  _OutgoingCallState _state = _OutgoingCallState.starting;
  String? _callId;
  String? _errorMessage;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startCall() async {
    try {
      final response = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
            '/calls',
            data: {'receiver_id': widget.calleeId, 'type': widget.isVideo ? 'video' : 'voice'},
          );
      final data = response.data!;
      if (!mounted) return;
      setState(() {
        _callId = data['call_id'] as String;
        _state = _OutgoingCallState.ringing;
      });
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _OutgoingCallState.failed;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _poll() async {
    final callId = _callId;
    if (callId == null) return;
    try {
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/calls/$callId');
      final status = response.data?['status'] as String?;
      if (!mounted) return;
      switch (status) {
        case 'accepted':
          _pollTimer?.cancel();
          final zego = response.data?['zego'] as Map<String, dynamic>?;
          if (zego == null) {
            setState(() => _state = _OutgoingCallState.failed);
            return;
          }
          _goToCallScreen(callId, zego);
        case 'declined':
          _pollTimer?.cancel();
          setState(() => _state = _OutgoingCallState.declined);
        case 'missed':
          _pollTimer?.cancel();
          setState(() => _state = _OutgoingCallState.missed);
        case 'ended':
          _pollTimer?.cancel();
          setState(() => _state = _OutgoingCallState.ended);
        case 'ringing':
          break; // keep waiting, next tick polls again
      }
    } on ApiException {
      // A single failed poll is not fatal — the next tick tries again.
      // Matches this app's established best-effort-polling pattern
      // (e.g. PanicScreen's own 15s refresh while a panic is active).
    }
  }

  void _goToCallScreen(String callId, Map<String, dynamic> zego) {
    final me = ref.read(currentUserProvider);
    context.pushReplacement(
      '/calls/active',
      extra: {
        'callId': callId,
        'appId': zego['app_id'] as int,
        'token': zego['token'] as String,
        'isVideo': widget.isVideo,
        'userId': me?.userId ?? '',
        'userName': me?.fullName ?? '',
      },
    );
  }

  Future<void> _cancelCall() async {
    final callId = _callId;
    _pollTimer?.cancel();
    if (callId != null) {
      try {
        await ref.read(apiClientProvider).post('/calls/$callId/end');
      } on ApiException {
        // best-effort — the backend's own 30s missed-timeout job is the
        // fallback if this doesn't land, same reasoning as every other
        // best-effort call in this app.
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 48,
                  child: Text(widget.calleeName.isNotEmpty ? widget.calleeName[0].toUpperCase() : '?'),
                ),
                const SizedBox(height: 16),
                Text(widget.calleeName, style: const TextStyle(color: Colors.white, fontSize: 22)),
                const SizedBox(height: 8),
                Text(_statusLabel(l10n), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 32),
                if (_state == _OutgoingCallState.starting || _state == _OutgoingCallState.ringing)
                  IconButton(
                    onPressed: _cancelCall,
                    icon: const Icon(Icons.call_end, color: Colors.white),
                    iconSize: 56,
                    style: IconButton.styleFrom(backgroundColor: Colors.red, shape: const CircleBorder()),
                  )
                else
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.callScreenOkButton),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (_state) {
      case _OutgoingCallState.starting:
        return l10n.callStartingLabel;
      case _OutgoingCallState.ringing:
        return l10n.callRingingLabel;
      case _OutgoingCallState.failed:
        return _errorMessage ?? l10n.callFailedMessage;
      case _OutgoingCallState.declined:
        return l10n.callDeclinedMessage;
      case _OutgoingCallState.missed:
        return l10n.callNoAnswerMessage;
      case _OutgoingCallState.ended:
        return l10n.callEndedMessage;
    }
  }
}
