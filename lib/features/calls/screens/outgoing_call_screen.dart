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
/// **Fixed 2026-10-24 — real `call_contract.md` field names, confirmed
/// independently by both Abdullah and Sarim (reading straight from
/// `docs/api/call_contract.md`/`backend/app/schemas/call.py` on `dev`),
/// replacing this screen's earlier guessed/summarized shape:**
/// - `POST /calls` body `{"receiver_id": ..., "type": "video"|"voice"}`
///   → `{"call_id": ..., "status": "ringing", ...}` — unchanged, this
///   part was already correct.
/// - `GET /calls/{id}` → `{"call_id": ..., "status": "ringing"|
///   "accepted"|"declined"|"missed"|"ended"|"cancelled", "join": {
///   "provider", "app_id", "room_id", "user_id", "token", "expires_at"
///   } | null}`. The real key is **`join`, not `zego`**.
/// - `join['app_id']` is a **string**, not an int — must go through
///   `int.parse(...)` before reaching `CallScreen`'s `appID`, or it
///   throws.
/// - The ZegoCloud room/channel id and the joining user id are
///   `join['room_id']`/`join['user_id']` — **not** this app's own
///   `call_id`/current-user id. The token is signed for those exact
///   values; joining with this app's own ids instead gets refused by
///   ZegoCloud the moment a real (non-mock) token is used. See
///   `call_screen.dart`'s class doc comment for how `callId` (this
///   app's own id, for `POST /calls/{id}/end`) and the new `roomId`
///   (ZegoCloud's id, for the actual join) are now kept separate.
///
/// Everything else in this screen (the `/calls` POST, the 2s poll, the
/// `ringing`/`declined`/`missed`/`ended` status names) was already
/// correct and needed no change.
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
          final join = response.data?['join'] as Map<String, dynamic>?;
          if (join == null) {
            setState(() => _state = _OutgoingCallState.failed);
            return;
          }
          _goToCallScreen(callId, join);
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

  void _goToCallScreen(String callId, Map<String, dynamic> join) {
    final me = ref.read(currentUserProvider);
    context.pushReplacement(
      '/calls/active',
      extra: {
        'callId': callId,
        'roomId': join['room_id'] as String,
        // app_id arrives as a string, not an int — must be parsed.
        'appId': int.parse(join['app_id'] as String),
        'token': join['token'] as String,
        'isVideo': widget.isVideo,
        'userId': join['user_id'] as String,
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
