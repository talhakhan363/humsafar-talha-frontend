import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';

/// Task 4.7 — mockup 17f "In call". Thin wrapper around ZegoCloud's
/// prebuilt call widget — this app's first native-SDK UI, so
/// deliberately kept as small a surface as possible: all of this app's
/// own logic (starting/accepting/declining/polling against
/// `call_contract.md`) lives in `OutgoingCallScreen`/`IncomingCallScreen`,
/// which only hand this screen a ready-to-join `appId`/`token`/`callId`
/// plus this device's own `userId`/`userName`.
///
/// **Direct-join mode, not ZegoCloud's own Call Invitation UI** — see
/// `OutgoingCallScreen`'s doc comment for why. `token` (not `appSign`)
/// is how this authenticates: the ZegoCloud Server Secret never ships
/// in this app at all, only the per-call token our own backend already
/// generates (`CALL_PROVIDER=zego`, Task 4.4b) — confirmed from
/// `zego_uikit_prebuilt_call`'s own published API
/// (pub.dev/documentation/zego_uikit_prebuilt_call), which exposes
/// `token` as an alternative to `appSign` on the same constructor.
///
/// **Fixed 2026-10-24 — real `call_contract.md` field names, confirmed
/// independently by both Abdullah and Sarim:** this screen used to be
/// handed this app's own `callId` and treat it as the ZegoCloud room id
/// too. The real backend's `join.room_id` (and `join.user_id`) are
/// separate values the token is actually signed for — passing the
/// wrong ones gets the join refused. [callId] now means only "this
/// app's own call id, for telling the backend the call ended"; the
/// ZegoCloud room is the new, separate [roomId] field below.
///
/// **Named testing scope cut:** `ZegoUIKitPrebuiltCall` itself needs a
/// real camera/microphone platform channel, so — same category as Task
/// 6.9's real camera streaming — this screen has no automated widget
/// test of its own (`test/features/calls/call_screen_test.dart` doesn't
/// exist). Everything feeding into it (the join parameters, the two
/// screens above) is tested instead. Deferred to the full team pass,
/// real device required.
///
/// Zego's prebuilt widget pops its own route when the local user taps
/// its built-in hang-up button or the other party leaves — that's the
/// whole point of a "prebuilt" screen. `onDispose` fires either way (or
/// on a plain back-navigation), and is used only to tell our own
/// backend the call ended from this device, best-effort — the real
/// source of truth for a call's final state is the backend's own 30s
/// missed-timeout job plus whichever side actually called
/// `POST /calls/{id}/end` first.
class CallScreen extends ConsumerWidget {
  const CallScreen({
    super.key,
    required this.callId,
    required this.roomId,
    required this.appId,
    required this.token,
    required this.userId,
    required this.userName,
    required this.isVideo,
  });

  /// This app's own backend call id — used only for
  /// `POST /calls/$callId/end`. NOT the ZegoCloud room; see [roomId].
  final String callId;

  /// ZegoCloud's own room/channel id (`join.room_id` from the backend's
  /// accept/poll response) — the token is signed for this specific
  /// room, which is not the same value as [callId]. See the 2026-10-24
  /// fix note on this class.
  final String roomId;
  final int appId;
  final String token;
  final String userId;
  final String userName;
  final bool isVideo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ZegoUIKitPrebuiltCall(
      appID: appId,
      token: token,
      callID: roomId,
      userID: userId,
      userName: userName,
      config: isVideo ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall() : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
      onDispose: () => unawaited(_endCallBestEffort(ref)),
    );
  }

  Future<void> _endCallBestEffort(WidgetRef ref) async {
    try {
      await ref.read(apiClientProvider).post('/calls/$callId/end');
    } on ApiException {
      // best-effort, see class doc comment
    } catch (_) {
      // covers the widget already being torn down mid-request, etc.
    }
  }
}
