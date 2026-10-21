import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  static const criticalChannelId = 'critical_alerts';
  static const standardChannelId = 'standard_alerts';

  bool _initialized = false;

  /// Creates the two Android channels, asks for notification permission
  /// (a no-op below Android 13, a real runtime prompt on 13+), and wires
  /// up the foreground/background-tap/cold-start-tap message streams.
  /// [onMessageTapped] is called whenever the person opens the app via a
  /// notification — on a running app (background tap) and once more for
  /// a cold start, if that's how the app was launched.
  Future<void> initializeChannelsAndHandlers({
    required void Function(RemoteMessage message) onMessageTapped,
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
      description: 'Panic, missed dose, geofence breach and other urgent alerts.',
      importance: Importance.max,
      playSound: true,
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
    if (initial != null) onMessageTapped(initial);
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
/// isolate. Deliberately does nothing else: the OS already auto-displays
/// the push's own `notification` payload while the app is backgrounded
/// or terminated (that's what `default_notification_channel_id` in
/// AndroidManifest.xml is for) — this handler exists only because
/// firebase_messaging requires one to be registered at all for
/// background delivery to work, not because this app needs custom
/// background processing.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
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
/// Types with no screen yet (`incoming_call`, `appointment_update`,
/// `appointment_reminder` — Phase 4.7/5, not built) still return null:
/// the app still opens normally, just without a deep link.
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
