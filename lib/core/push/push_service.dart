import 'dart:convert';

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
  ///
  /// **Bug fix (F-13/F-24/F-29, Sarim's 24 Nov retest on 1.9.4 — one root
  /// cause behind all three): a LOCALLY-shown notification (every
  /// standard/critical push while the app is in the foreground, via
  /// [_showForegroundNotification]; and the full-screen remote-alarm push
  /// while backgrounded/terminated, via [firebaseMessagingBackgroundHandler])
  /// had NO tap handler registered at all.** `_localNotifications.initialize`
  /// was called with nothing but `android: androidInit` — no
  /// `onDidReceiveNotificationResponse`. Android still let the person tap
  /// it (flutter_local_notifications always wires a default "open the app"
  /// PendingIntent even with no callback set), but tapping just launched
  /// `MainActivity` with no payload for anything to route on, landing on
  /// the app's plain default screen. That's exactly: F-24 ("tap does
  /// nothing" — it does something, just not the deep link); F-29
  /// (`incoming_call`'s own push never got a chance to push
  /// `/calls/incoming`, because nothing ever read the push's `call_id`
  /// back out of the notification once Firebase's own auto-display wasn't
  /// in play); and F-13 ("rings about 2s, no full-screen alarm" — the
  /// full-screen notification posts and plays its sound once, but nothing
  /// ever navigates into `alarm_screen.dart`'s own looping-alarm-sound UI,
  /// because that only happens by actually opening `/dependent/alarm`,
  /// which never fires without a tap handler to fire it).
  ///
  /// Fixed by: every `.show(...)` call below now attaches a `payload`
  /// (the push's own `data` map, JSON-encoded); `onDidReceiveNotificationResponse`
  /// handles a tap while the app process is alive (foreground or
  /// backgrounded-but-not-killed) by decoding that payload and calling
  /// [onMessageTapped] with it, exactly like an FCM-native background tap
  /// already did; and a genuinely cold (fully terminated, then launched BY
  /// the tap) case is picked up via `getNotificationAppLaunchDetails()`
  /// after `initialize()` — the plugin's own purpose-built mechanism for
  /// this, parallel to `getInitialMessage()` already being used for an
  /// FCM-native cold start just below. `onDidReceiveBackgroundNotificationResponse`
  /// must also be wired (the plugin requires SOME handler registered for
  /// background delivery to work at all, mirroring why
  /// `FirebaseMessaging.onBackgroundMessage` needs one in main.dart) but is
  /// a deliberate no-op — see [_onBackgroundNotificationResponse]'s own
  /// doc comment for why it can't navigate directly and doesn't need to.
  ///
  /// **Signature change, not additive:** [onMessageTapped]/[onColdStartTap]
  /// now take the push's `Map<String, dynamic> data` directly rather than
  /// a whole `RemoteMessage` — the only reason they ever needed a
  /// `RemoteMessage` was to read `.data` back out of it
  /// ([navigateForNotificationTap] never touched anything else on it), and
  /// a locally-shown notification's tap has a JSON-decoded `Map`, never a
  /// real `RemoteMessage`, to hand back. One shared type lets a tap on
  /// EITHER kind of notification call the exact same navigation logic.
  ///
  /// **Still not verified against a real push or a real device** — same
  /// disclosed limit as every other push_service.dart fix: nothing in this
  /// sandbox can send an actual FCM message or tap a real Android
  /// notification tray entry. The payload-encode/decode round trip and the
  /// plugin API shapes used here (`onDidReceiveNotificationResponse`,
  /// `onDidReceiveBackgroundNotificationResponse`,
  /// `getNotificationAppLaunchDetails()`) are flutter_local_notifications
  /// 18.0.1's own documented, stable API (unchanged across the 9.x-18.x
  /// majors) — not guessed — but `flutter analyze`/`flutter test` is the
  /// first real check this gets, and a real-device tap test (does the
  /// alarm push actually open `/dependent/alarm`? does a call push open
  /// `/calls/incoming`?) is still needed before trusting F-13/F-24/F-29
  /// closed.
  Future<void> initializeChannelsAndHandlers({
    required void Function(Map<String, dynamic> data) onMessageTapped,
    // Bug fix (F-24, Sarim's 9 Nov report): optional, falls back to
    // [onMessageTapped] if not given. main.dart passes something DIFFERENT
    // here than onMessageTapped — see [pendingColdStartNotificationProvider]'s
    // doc comment below for why a cold-start tap can't safely navigate
    // immediately the way a background tap (app already running, a
    // session already active and showing a real screen, nothing to race)
    // can.
    void Function(Map<String, dynamic> data)? onColdStartTap,
  }) async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit),
      // Bug fix (F-13/F-24/F-29): see this method's own doc comment above.
      onDidReceiveNotificationResponse: (response) => _handleLocalNotificationTap(response, onMessageTapped),
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

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
    FirebaseMessaging.onMessageOpenedApp.listen((message) => onMessageTapped(message.data));

    // Cold start: the app was fully closed and opened BY tapping an
    // FCM-auto-displayed notification. Must be checked explicitly —
    // onMessageOpenedApp only fires for a background (not terminated) tap.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      (onColdStartTap ?? onMessageTapped)(initial.data);
      return;
    }

    // Bug fix (F-13/F-24/F-29): the OTHER cold-start shape —
    // getInitialMessage() above only ever sees a tap on Firebase's OWN
    // auto-displayed notification. It stays null for a tap on a
    // notification THIS class drew itself via flutter_local_notifications
    // (every standard/critical foreground alert, and the full-screen
    // remote-alarm one), so that case needs the plugin's own equivalent.
    final launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final data = _decodePayload(launchDetails!.notificationResponse?.payload);
      if (data != null) (onColdStartTap ?? onMessageTapped)(data);
    }
  }

  static void _handleLocalNotificationTap(
    NotificationResponse response,
    void Function(Map<String, dynamic> data) onMessageTapped,
  ) {
    final data = _decodePayload(response.payload);
    if (data != null) onMessageTapped(data);
  }

  /// Required by flutter_local_notifications for background delivery to
  /// work at all (same reason `firebaseMessagingBackgroundHandler` must be
  /// registered for FCM background delivery) — but a deliberate no-op.
  /// This runs in its own background isolate when the app is fully
  /// terminated and the person taps the notification, with no live
  /// `ProviderContainer`/`BuildContext`/router to navigate with. Rather
  /// than trying to navigate from here, [initializeChannelsAndHandlers]
  /// picks this exact tap back up the next time the app actually starts,
  /// by reading `getNotificationAppLaunchDetails()` — the OS keeps that
  /// record independently of this isolate, the same way
  /// `getInitialMessage()` already lets an FCM-native cold start be
  /// applied once a real app/context exists (see
  /// `splash_screen.dart`'s `_applyPendingColdStartNotification`).
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {}

  static Map<String, dynamic>? _decodePayload(String? payload) {
    if (payload == null) return null;
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final isCritical = message.data['priority'] == 'critical';
    final channelId = isCritical ? criticalChannelId : standardChannelId;
    await _localNotifications.show(
      // Bug fix (N-17, Sarim's 24 Nov + 1.9.5 retests: "notifications pile
      // up" / "one Panic alert gives a group of 15"): `notification`
      // (message.notification) is a fresh RemoteNotification instance
      // built from the platform channel on every delivery, and it has no
      // custom == / hashCode — so `.hashCode` was Dart's default identity
      // hash, different every single time even when the SAME logical
      // alert is redelivered (FCM retry, or onMessage firing twice for one
      // push). Android only replaces a notification that shares the same
      // id, so every redelivery stacked a brand-new tray entry instead of
      // updating the existing one. The first fix hashed `notification_id`
      // (notification_contract.md's stable id for one notification
      // record) — still not enough for a Panic that climbs the escalation
      // chain, where EACH reminder is its own notification record (own
      // `notification_id`) but shares one `event_id` for the whole open
      // Panic; `event_id` is the more specific, correct key where the
      // backend sends one (preferred first), falling back to
      // `notification_id` for everything else.
      (message.data['event_id'] as String?)?.hashCode ??
          (message.data['notification_id'] as String?)?.hashCode ??
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
      // Bug fix (F-13/F-24/F-29): see initializeChannelsAndHandlers' doc
      // comment — without this, there is nothing for a tap to route on.
      payload: jsonEncode(message.data),
    );
  }

  Future<String?> getToken() => _messaging.getToken();

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}

/// Must be a top-level (or static) function per the firebase_messaging
/// API — it runs in its own background isolate, which is why it
/// re-initializes Firebase rather than reusing anything from the main
/// isolate. For every push type except `remote_alarm`/`incoming_call`
/// this still does nothing else: the OS already auto-displays the push's
/// own `notification` payload while the app is backgrounded or
/// terminated (that's what `default_notification_channel_id` in
/// AndroidManifest.xml is for) — this handler exists only because
/// firebase_messaging requires one to be registered at all for
/// background delivery to work.
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
/// **Bug fix (F-29/F-24, Sarim's 1.9.5 retest): `incoming_call` got the
/// exact same passive-auto-display-only treatment `remote_alarm` had
/// before F-13 — this early-returned for every type except
/// `remote_alarm`, so a call push while backgrounded/terminated never
/// got a payload-bearing local notification of its own.** The tap-routing
/// machinery itself (`initializeChannelsAndHandlers`'s
/// `onDidReceiveNotificationResponse`/`getNotificationAppLaunchDetails`)
/// was already fixed for F-13/F-24/F-29 together, but it only ever fires
/// for a notification THIS app drew — Firebase's own passive auto-display
/// (if the push happens to carry a top-level `notification` block) still
/// routes a tap through `onMessageOpenedApp`/`getInitialMessage`
/// correctly too, but if the push is data-only (plausible — and likely,
/// given `call_contract.md`/`notification_contract.md` never mention a
/// `notification` block for `incoming_call`, only `data`), a data-only
/// message delivered while backgrounded/terminated shows **nothing at
/// all** — no banner, no sound, nothing to tap — which matches Sarim's
/// "tap does nothing" exactly (there was nothing there to tap). Now
/// drawn the same deliberate way as `remote_alarm`: full-screen, its own
/// category, with the payload attached. Uses
/// `AndroidNotificationCategory.call` (not `.alarm`) and `autoCancel:
/// true`/`ongoing: false` — unlike an alarm, answering or missing a call
/// is a one-shot interaction, not something that needs a separate "stop"
/// action to dismiss.
///
/// **Open dependencies, flagged rather than assumed — needs confirming
/// with Abdullah before either is genuinely done end to end:** (1) this
/// only replaces the OS's passive auto-display cleanly if the backend
/// sends these as data-only FCM messages (no top-level `notification`
/// key) — if either still carries one, the OS auto-displays its own
/// passive notification from `standard_alerts`/`critical_alerts_v2` at
/// the same time this handler shows its own, two notifications for one
/// event instead of one correct one; (2) this is not verified against a
/// real build or a real push, same limit as every other push_service.dart
/// fix — nothing in this sandbox can send an actual FCM message, so a
/// real-device retest of F-13/F-24/F-29 is still the thing that actually
/// closes them, not this read.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final type = message.data['type'] as String?;
  if (type != 'remote_alarm' && type != 'incoming_call') return;
  final isCall = type == 'incoming_call';

  final title = message.notification?.title ??
      (message.data['title'] as String?) ??
      (isCall ? 'Incoming call' : 'Remote alarm');
  final body = message.notification?.body ??
      (message.data['body'] as String?) ??
      (isCall ? 'Someone is calling you.' : 'Someone is trying to reach you.');

  await FlutterLocalNotificationsPlugin().show(
    // Bug fix (N-17, Sarim's 1.9.5 retest — "one Panic alert gives a
    // group of 15" / redelivered pushes stacking instead of replacing):
    // `message` itself is a fresh RemoteMessage per delivery with no
    // custom hashCode, so a redelivered/retried push got a new, unrelated
    // tray id every time. `notification_id` alone (the previous fix)
    // still didn't collapse a chain of DIFFERENT notification records
    // that all belong to the same underlying event (e.g. several
    // escalation reminders for one still-open Panic) — `event_id`
    // (notification_contract.md's own field for exactly this: the same
    // escalation/panic event across its whole lifecycle) is the correct,
    // more specific key where the backend sends one; `incoming_call` has
    // no `event_id`/`notification_id` at all (call_contract.md's push
    // shape is just call_id/call_type/caller_id/expires_at), so its own
    // `call_id` is the right collapsing key there — one call, one tray
    // entry, however many times it's redelivered.
    (message.data['event_id'] as String?)?.hashCode ??
        (message.data['notification_id'] as String?)?.hashCode ??
        (message.data['call_id'] as String?)?.hashCode ??
        message.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        PushService.criticalChannelId,
        'Critical alerts',
        importance: Importance.max,
        priority: Priority.max,
        category: isCall ? AndroidNotificationCategory.call : AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        // A ringing call is a one-shot interaction (answer/decline/miss),
        // not an ongoing state that needs its own separate "stop" action
        // the way a sounding alarm does — see this function's own doc
        // comment.
        ongoing: !isCall,
        autoCancel: isCall,
        sound: PushService._criticalChannelSound,
      ),
    ),
    // Bug fix (F-13/F-24/F-29, Sarim's 24 Nov + 1.9.5 retests): without a
    // payload, tapping (or the system's own full-screen-intent
    // auto-launch) had nothing to route on, so it never actually opened
    // `/dependent/alarm` or `/calls/incoming` — see
    // PushService.initializeChannelsAndHandlers' doc comment for the full
    // root-cause writeup, which applies to this notification too.
    payload: jsonEncode(message.data),
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
/// **Bug fix (Sarim's 1.9.5 retest, F-29/F-24): the push has no
/// `caller_name` field.** `call_contract.md` line 9 and
/// `notification_contract.md`'s own push-data list for `incoming_call`
/// both give the exact same shape: `data.call_id`, `data.call_type`,
/// `data.caller_id`, `data.expires_at` — `caller_id` is a user id, not a
/// display name, and there is no `caller_name` anywhere in the real
/// contract. Reading `data['caller_name']` always silently returned the
/// `''` fallback, so `IncomingCallScreen` showed a blank name/`'?'`
/// avatar every time — cosmetic on its own, but see this screen's own
/// doc comment and `incoming_call_screen.dart`'s for the bigger, actually
/// blocking F-29 root cause this was found alongside. The real name is
/// `other_name` from `GET /calls/{id}` (`call_contract.md` line 20),
/// which `IncomingCallScreen` already calls on load — fetched there now,
/// not guessed from the push.
Map<String, dynamic>? incomingCallPushData(Map<String, dynamic> data) {
  if (data['type'] != 'incoming_call') return null;
  final callId = data['call_id'] as String?;
  if (callId == null) return null;
  return {
    'callId': callId,
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
///
/// **Signature change (F-13/F-24/F-29 fix):** takes the push's
/// `Map<String, dynamic> data` directly, not a whole `RemoteMessage` — see
/// `initializeChannelsAndHandlers`' doc comment. This is what lets a tap on
/// a LOCALLY-shown notification (decoded from its JSON `payload`, never a
/// real `RemoteMessage`) call the exact same routing logic as a tap on an
/// FCM-native one.
void navigateForNotificationTap(BuildContext context, Map<String, dynamic> data) {
  // Task 4.7 — incoming_call needs more than a route string (see
  // incomingCallPushData's doc comment), so it's checked first, ahead of
  // the generic route-string mapper below.
  final callData = incomingCallPushData(data);
  if (callData != null) {
    GoRouter.of(context).push('/calls/incoming', extra: callData);
    return;
  }
  final route = routeForNotificationType(data['type'] as String?);
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
///
/// Holds `Map<String, dynamic>` (the push's own `data`), not a
/// `RemoteMessage` — see `navigateForNotificationTap`'s doc comment: a
/// cold start from tapping a LOCALLY-shown notification (the F-13/F-24/F-29
/// fix) only ever has a JSON-decoded `Map` to offer, never a real
/// `RemoteMessage`.
final pendingColdStartNotificationProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

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
