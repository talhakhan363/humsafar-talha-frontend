import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../network/api_exception.dart';
import '../network/providers.dart';

/// Task 3.14 — the Firebase Cloud Messaging client, grounded in
/// `notification_contract.md`'s "What the push looks like" section.
///
/// Two tiers (`priority: "critical"` / `"standard"`) map to two Android
/// notification channels, created once up front so the system picks the
/// right behavior (sound, heads-up) by channel regardless of whether the
/// OS is showing the push's own `notification` payload (app backgrounded
/// /terminated — see the `default_notification_channel_id` meta-data in
/// AndroidManifest.xml) or this class is showing a local one itself (app
/// in the foreground — FCM does NOT auto-display anything while the app
/// is open and in front of the person, so without this a foreground
/// critical alert would be silently invisible).
class PushService {
  PushService({FirebaseMessaging? messaging, FlutterLocalNotificationsPlugin? localNotifications})
      : _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  // Bug fix (F-23, Sarim's 9 Nov report): bumped from 'critical_alerts' to
  // a new id, NOT just edited in place. Android notification-channel
  // settings (sound, importance, vibration) are immutable once a channel
  // is first created on a device — any phone that already ran an earlier
  // build keeps using 'critical_alerts' exactly as it was first created
  // (default system sound, no custom alarm tone) no matter what this code
  // says now. A fresh id is the only way an already-installed phone
  // actually picks up the new alarm-style sound below.
  static const criticalChannelId = 'critical_alerts_v2';
  static const standardChannelId = 'standard_alerts';

  // Bug fix (F-23): android/app/src/main/res/raw/alarm_critical.wav — the
  // same placeholder tone already bundled as assets/sounds/alarm.wav for
  // alarm_screen.dart's F-13 fix, copied into the Android raw resources so
  // a *notification* (not just the in-app alarm screen) can use it as a
  // real alarm-style sound instead of the generic default notification
  // ping. Android raw-resource names can't have a file extension, hence
  // 'alarm_critical' here with no '.wav'.
  static const _criticalChannelSound = RawResourceAndroidNotificationSound('alarm_critical');

  bool _initialized = false;

  /// Creates the two Android channels, asks for notification permission
  /// (a no-op below Android 13, a real runtime prompt on 13+), and wires
  /// up the foreground/background-tap/cold-start-tap message streams.
  /// [onMessageTapped] is called whenever the person opens the app via a
  /// notification — on a running app (background tap) and once more for
  /// a cold start, if that's how the app was launched.
  Future<void> initializeChannelsAndHandlers({
    required void Function(RemoteMessage message) onMessageTapped,
    // Bug fix (F-24, Sarim's 9 Nov report): optional, falls back to
    // [onMessageTapped] if not given. main.dart passes something DIFFERENT
    // here than onMessageTapped — see [pendingColdStartNotificationProvider]'s
    // doc comment below for why a cold-start tap can't safely navigate
    // immediately the way a background tap (app already running, a
    // session already active and showing a real screen, nothing to race)
    // can.
    void Function(RemoteMessage message)? onColdStartTap,
  }) async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(const InitializationSettings(android: androidInit));

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      criticalChannelId,
      'Critical alerts',
      description: 'Panic, missed dose, geofence breach, remote alarm and other urgent alerts.',
      importance: Importance.max,
      playSound: true,
      // Bug fix (F-23, Sarim's 9 Nov report): was relying on the device's
      // default notification sound, which reads as just another ping, not
      // an alarm. Real backend-vs-test-tone caveat: alarm_critical.wav is
      // still the same synthesized placeholder noted in alarm_screen.dart's
      // F-13 doc comment, not a final sound design.
      sound: _criticalChannelSound,
    ));
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      standardChannelId,
      'Standard alerts',
      description: 'All-clear and informational messages.',
      importance: Importance.defaultImportance,
    ));

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageTapped);

    // Cold start: the app was fully closed and opened BY tapping a
    // notification. Must be checked explicitly — onMessageOpenedApp only
    // fires for a background (not terminated) tap.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) (onColdStartTap ?? onMessageTapped)(initial);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final isCritical = message.data['priority'] == 'critical';
    final channelId = isCritical ? criticalChannelId : standardChannelId;
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          isCritical ? 'Critical alerts' : 'Standard alerts',
          importance: isCritical ? Importance.max : Importance.defaultImportance,
          priority: isCritical ? Priority.max : Priority.defaultPriority,
          // Bug fix (F-23): matches the channel's own sound (see
          // createNotificationChannel above) — Android actually plays the
          // channel's sound regardless of this field on O+ (API 26+,
          // which this app's whole supported range is above), but setting
          // it here too keeps this call self-describing and correct on
          // the off chance a channel sound lookup ever fails.
          sound: isCritical ? _criticalChannelSound : null,
        ),
      ),
    );
  }

  Future<String?> getToken() => _messaging.getToken();

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}

/// Must be a top-level (or static) function per the firebase_messaging
/// API — it runs in its own background isolate, which is why it
/// re-initializes Firebase rather than reusing anything from the main
/// isolate. For every push type except `remote_alarm` this still does
/// nothing else: the OS already auto-displays the push's own
/// `notification` payload while the app is backgrounded or terminated
/// (that's what `default_notification_channel_id` in AndroidManifest.xml
/// is for) — this handler exists only because firebase_messaging requires
/// one to be registered at all for background delivery to work.
///
/// **Bug fix (F-13, Sarim's 9 Nov report): "alarm doesn't ring when the
/// app is closed."** A `remote_alarm` push used to rely entirely on that
/// same passive OS auto-display — a normal, silenceable notification that
/// doesn't wake the screen or loop a sound, nothing like an actual alarm.
/// `alarm_screen.dart`'s own F-13 fix already solved this for when the
/// screen is open (loops the alarm sound on Android's alarm stream, which
/// silent mode can't mute) — but that fix only runs once that screen is
/// showing, which never happens on its own while the app is backgrounded
/// or terminated. This shows a dedicated full-screen, alarm-category
/// local notification instead, matching how a real alarm clock or
/// incoming call behaves on a locked phone (requires
/// `USE_FULL_SCREEN_INTENT` in AndroidManifest.xml, added alongside this
/// fix).
///
/// **Open dependency, flagged rather than assumed — needs confirming with
/// Abdullah before this is genuinely done end to end:** this only
/// replaces the OS's passive auto-display cleanly if the backend sends
/// `remote_alarm` pushes as a data-only FCM message (no top-level
/// `notification` key). If the push still carries a `notification`
/// payload, the OS will ALSO auto-display its own passive notification
/// from `standard_alerts` at the same time this handler shows its own —
/// two separate notifications for one alarm, not one correct one. Not
/// verified against a real build or a real push for the same reason as
/// `alarm_screen.dart`'s own F-13 fix: nothing in this sandbox can send an
/// actual FCM message.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.data['type'] != 'remote_alarm') return;

  final title = message.notification?.title ?? (message.data['title'] as String?) ?? 'Remote alarm';
  final body = message.notification?.body ?? (message.data['body'] as String?) ?? 'Someone is trying to reach you.';

  await FlutterLocalNotificationsPlugin().show(
    message.hashCode,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        PushService.criticalChannelId,
        'Critical alerts',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        ongoing: true,
        autoCancel: false,
        sound: PushService._criticalChannelSound,
      ),
    ),
  );
}

/// Maps a push's `data.type` (notification_contract.md's full `type`
/// list) to the route to open when the person taps it. A pure function
/// (no Firebase/BuildContext involved) so it's unit-testable on its own.
///
/// Guardian-facing alert types all land on the Alerts inbox
/// (`/guardian/alerts`) rather than trying to deep-link into the
/// specific missed-dose/escalation screen from the push payload alone —
/// `notification_contract.md`'s own guidance is "call GET /notifications
/// ... and show the alert", and the Alerts screen already does exactly
/// that self-resolving lookup. The Missed dose screen's extend/escalate
/// actions are then one tap away, from a real `GET`-fetched row with a
/// real `confirmation_id` — not guessed from whatever happened to be in
/// the push's `data` map.
///
/// Task 4.6 (2026-10-22): `message`/`voice_message` now route to
/// `/messages` (the inbox, same role-neutral screen either direction —
/// see chat_screen.dart's doc comment), rather than returning null as
/// they did before this task shipped (there was simply no screen to
/// send them to yet). Deliberately the inbox, not a direct deep-link
/// into the specific thread: the payload's `data.from_user_id` would be
/// enough to know *who*, but not their display name, and this function
/// stays a pure `String?` (no second lookup, no role check) rather than
/// growing a signature just for these two cases — same "self-resolving
/// list over trusting push payload data" reasoning as the Alerts inbox
/// above. One extra tap from the inbox to the right thread is well
/// within NFR-07's budget.
///
/// Types with no screen yet (`appointment_update`, `appointment_reminder`
/// — Phase 5, not built) still return null: the app still opens
/// normally, just without a deep link.
///
/// `incoming_call` (Task 4.7) is deliberately NOT handled here even
/// though it's now built — it needs more than a route string (a call
/// id, caller name, and video/voice flag from the push's own `data`),
/// which doesn't fit this function's plain `String?` signature. See
/// [incomingCallPushData] below, which `main.dart`'s
/// `_handleNotificationTap` checks first, before falling back to this
/// function for every other type.
String? routeForNotificationType(String? type) {
  switch (type) {
    case 'geofence_breach':
    case 'low_battery':
    case 'device_offline':
    case 'missed_dose':
    case 'wellness_check':
    case 'panic':
    case 'external_contact':
      return '/guardian/alerts';
    case 'medication_reminder':
    case 'medication_due':
    case 'medication_extended':
      return '/dependent/medication';
    case 'wellness_check_prompt':
      return '/dependent/wellness-check';
    case 'remote_alarm':
    case 'remote_alarm_stop':
      return '/dependent/alarm';
    case 'message':
    case 'voice_message':
      return '/messages';
    default:
      return null;
  }
}

/// Task 4.7 — parses an `incoming_call` push's `data` into what
/// `IncomingCallScreen` needs, or `null` if this isn't that type (or is
/// missing the one field that actually matters, `call_id`). Kept as its
/// own small pure function for the same "unit-testable without
/// Firebase/BuildContext" reason [routeForNotificationType] is pure.
///
/// **Named field-name caveat** (same as the rest of Task 4.7 — see
/// `outgoing_call_screen.dart`'s doc comment for the full one): assumed
/// push `data` shape `{"type": "incoming_call", "call_id": ...,
/// "caller_name": ..., "call_type": "video"|"voice"}`. If the real
/// `notification_contract.md`/`call_contract.md` field names differ,
/// only this function needs adjusting.
Map<String, dynamic>? incomingCallPushData(Map<String, dynamic> data) {
  if (data['type'] != 'incoming_call') return null;
  final callId = data['call_id'] as String?;
  if (callId == null) return null;
  return {
    'callId': callId,
    'callerName': data['caller_name'] as String? ?? '',
    'isVideo': data['call_type'] == 'video',
  };
}

/// Navigates to wherever a tapped push says to go. A shared function
/// (not duplicated in main.dart and splash_screen.dart) so the
/// incoming_call-vs-everything-else routing decision only lives in one
/// place.
///
/// Used two different ways:
/// - main.dart's live background-tap path calls this immediately (a
///   session is already active and showing a real screen — nothing to
///   race).
/// - splash_screen.dart calls this too, but only for a COLD-START tap,
///   and only after its own session check has already picked the app's
///   real home route — see [pendingColdStartNotificationProvider]'s doc
///   comment for the F-24 bug this ordering fixes.
void navigateForNotificationTap(BuildContext context, RemoteMessage message) {
  // Task 4.7 — incoming_call needs more than a route string (see
  // incomingCallPushData's doc comment), so it's checked first, ahead of
  // the generic route-string mapper below.
  final callData = incomingCallPushData(message.data);
  if (callData != null) {
    GoRouter.of(context).push('/calls/incoming', extra: callData);
    return;
  }
  final route = routeForNotificationType(message.data['type'] as String?);
  if (route == null) return;
  GoRouter.of(context).push(route);
}

/// **Bug fix (F-24, Sarim's 9 Nov report): "tapping a notification
/// doesn't stay on its target screen."** A cold-start notification tap
/// (`initializeChannelsAndHandlers`'s `getInitialMessage` check) used to
/// call [navigateForNotificationTap] immediately, from a post-frame
/// callback in `main.dart`'s `initState` — racing `SplashScreen`'s own
/// `_checkSession()`, a real network round-trip to `GET /auth/me`.
/// Whichever finished second won, and since `SplashScreen`'s own
/// `context.go(...)` REPLACES the entire navigation stack rather than
/// pushing onto it, if the session check lost — er, finished AFTER the
/// notification's push, which it reliably does since it needs a network
/// round-trip and `getInitialMessage()` doesn't — it silently wiped the
/// notification's target screen off the stack, landing the person back
/// on their plain home screen with no obvious sign anything was ever
/// wrong.
///
/// Holding the tapped message here instead of navigating straight away
/// lets `SplashScreen` apply it itself, AFTER its own routing decision —
/// see `splash_screen.dart`'s `_applyPendingColdStartNotification`. A
/// background tap (app already running when the notification arrives)
/// never touches this provider at all: `main.dart`'s `onMessageTapped`
/// still navigates immediately for that case, since there's no splash
/// screen in the way once a session is already active.
final pendingColdStartNotificationProvider = StateProvider<RemoteMessage?>((ref) => null);

final pushServiceProvider = Provider<PushService>((ref) => PushService());

/// Riverpod splits "reading a provider" across two different types
/// depending on where you are — `Ref` inside a provider body (like
/// `RealAuthRepository`'s constructor), `WidgetRef` inside a
/// `ConsumerState` (like `SplashScreen`/`HomeApp`'s `_initializePush`).
/// Neither is a subtype of the other, but both expose the exact same
/// generic `read<T>(ProviderListenable<T>)` method shape, so
/// [registerPushToken]/[unregisterPushToken] take that method itself
/// (pass `ref.read`, not `ref`) instead of picking one concrete ref type
/// and being unusable from the other call sites. Caught by
/// `flutter analyze` the first time this shipped — `Ref` and `WidgetRef`
/// really don't unify, a plain `Ref ref` parameter only compiled for the
/// provider-side caller.
typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

/// Registers this device's current FCM token with the backend
/// (`PUT /devices/push-token`). Call after every successful login and
/// session restore, and whenever [PushService.onTokenRefresh] fires.
/// Best-effort and silent on failure by design — notification_contract.md
/// is explicit that a push failure must never be allowed to block or
/// break anything else (the inbox, via `GET /notifications`, is always
/// the source of truth regardless of whether push delivery works), and
/// that same principle extends to registration: a Dependent/Guardian who
/// can't currently reach Firebase (emulator with no Google Play, device
/// permission denied, flaky network) must still be able to log in and use
/// the app normally.
Future<void> registerPushToken(ProviderReader read) async {
  try {
    final token = await read(pushServiceProvider).getToken();
    if (token == null) return;
    await read(apiClientProvider).put('/devices/push-token', data: {'token': token, 'platform': 'android'});
  } on ApiException {
    // best-effort, see doc comment above
  } catch (_) {
    // covers getToken() failing outright (no Google Play Services, etc.)
  }
}

/// Forgets this device's current FCM token (`DELETE /devices/push-token`).
/// Call on logout, BEFORE clearing stored tokens — it needs a still-valid
/// access token to authenticate the call. Same best-effort-on-failure
/// reasoning as [registerPushToken]: a failed unregister must never block
/// logout itself, it just means this phone may keep receiving pushes for
/// the account that just logged out until the token naturally rotates.
Future<void> unregisterPushToken(ProviderReader read) async {
  try {
    final token = await read(pushServiceProvider).getToken();
    if (token == null) return;
    await read(apiClientProvider).delete('/devices/push-token', queryParameters: {'token': token});
  } on ApiException {
    // best-effort, see doc comment above
  } catch (_) {
    // covers getToken() failing outright
  }
}
