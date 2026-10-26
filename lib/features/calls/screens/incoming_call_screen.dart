import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/auth/current_user_provider.dart';
import '../../../core/theme/humsafar_colors.dart';

/// Task 4.7 — mockup 25d "Incoming call" (Dependent side). Reached from
/// a tap on the critical `incoming_call` push (see `main.dart`'s
/// `_handleNotificationTap`, which special-cases this type via
/// `push_service.dart`'s `incomingCallPushData` — that function returns
/// more than a route string, so it doesn't fit `routeForNotificationType`'s
/// plain `String?` signature and is kept separate).
///
/// On load, confirms the call is still `"ringing"` via a fresh
/// `GET /calls/{id}` before showing Accept/Decline — the push payload
/// itself is trusted only for *which* call to look at, not for whether
/// it's still live (the caller may have already hung up, or it may have
/// already timed out by the time this screen opens), same "trust the
/// push for identity, re-verify with a real GET" shape as
/// `WellnessCheckScreen`'s self-resolving pending check. See
/// `OutgoingCallScreen`'s doc comment for the full named field-name
/// caveat on `call_contract.md`'s assumed shape, and for why this
/// doesn't use ZegoCloud's own Call Invitation UI.
class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({super.key, required this.callId, required this.callerName, required this.isVideo});

  final String callId;
  final String callerName;
  final bool isVideo;

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

enum _IncomingCallState { loading, ringing, accepting, alreadyOver, error }

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> {
  _IncomingCallState _state = _IncomingCallState.loading;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkStillRinging();
  }

  Future<void> _checkStillRinging() async {
    try {
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/calls/${widget.callId}');
      final status = response.data?['status'] as String?;
      if (!mounted) return;
      setState(() => _state = status == 'ringing' ? _IncomingCallState.ringing : _IncomingCallState.alreadyOver);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _IncomingCallState.error;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _accept() async {
    setState(() => _state = _IncomingCallState.accepting);
    try {
      final response = await ref.read(apiClientProvider).post<Map<String, dynamic>>('/calls/${widget.callId}/accept');
      // Fixed 2026-10-24: the real backend sends this under `join`, not
      // `zego` — see call_screen.dart's class doc comment.
      final join = response.data?['join'] as Map<String, dynamic>?;
      if (!mounted) return;
      if (join == null) {
        setState(() => _state = _IncomingCallState.error);
        return;
      }
      final me = ref.read(currentUserProvider);
      context.pushReplacement(
        '/calls/active',
        extra: {
          'callId': widget.callId,
          'roomId': join['room_id'] as String,
          // app_id arrives as a string, not an int — must be parsed.
          'appId': int.parse(join['app_id'] as String),
          'token': join['token'] as String,
          'isVideo': widget.isVideo,
          'userId': join['user_id'] as String,
          'userName': me?.fullName ?? '',
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _IncomingCallState.error;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _decline() async {
    try {
      await ref.read(apiClientProvider).post('/calls/${widget.callId}/decline');
    } on ApiException {
      // best-effort — declining is a courtesy; the backend's own missed-
      // timeout job is the fallback if this doesn't land, same reasoning
      // as OutgoingCallScreen's _cancelCall.
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
            child: _state == _IncomingCallState.loading
                ? const CircularProgressIndicator(color: Colors.white)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        child: Text(widget.callerName.isNotEmpty ? widget.callerName[0].toUpperCase() : '?'),
                      ),
                      const SizedBox(height: 16),
                      Text(widget.callerName, style: const TextStyle(color: Colors.white, fontSize: 22)),
                      const SizedBox(height: 8),
                      Text(_subtitle(l10n), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 32),
                      if (_state == _IncomingCallState.ringing)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: _decline,
                              icon: const Icon(Icons.call_end, color: Colors.white),
                              iconSize: 56,
                              style: IconButton.styleFrom(backgroundColor: HumsafarColors.danger, shape: const CircleBorder()),
                              tooltip: l10n.declineCallButton,
                            ),
                            IconButton(
                              onPressed: _accept,
                              icon: const Icon(Icons.call, color: Colors.white),
                              iconSize: 56,
                              style: IconButton.styleFrom(backgroundColor: HumsafarColors.success, shape: const CircleBorder()),
                              tooltip: l10n.acceptCallButton,
                            ),
                          ],
                        )
                      else if (_state == _IncomingCallState.accepting)
                        const CircularProgressIndicator(color: Colors.white)
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

  String _subtitle(AppLocalizations l10n) {
    switch (_state) {
      case _IncomingCallState.loading:
        return '';
      case _IncomingCallState.ringing:
        return widget.isVideo ? l10n.incomingVideoCallLabel : l10n.incomingVoiceCallLabel;
      case _IncomingCallState.accepting:
        return l10n.callConnectingLabel;
      case _IncomingCallState.alreadyOver:
        return l10n.callAlreadyEndedMessage;
      case _IncomingCallState.error:
        return _errorMessage ?? l10n.callFailedMessage;
    }
  }
}
