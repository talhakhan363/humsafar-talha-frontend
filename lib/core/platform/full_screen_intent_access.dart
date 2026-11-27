import 'package:flutter/services.dart';

/// Bug fix (F-13, Sarim's 26 Nov retest: "alarm rings only with the app in
/// the background and the phone unlocked; no full-screen alarm when
/// locked or closed; check the Android 14+ full-screen notifications
/// access"). `AndroidManifest.xml` already declares
/// `USE_FULL_SCREEN_INTENT` (see that file's own comment on this task),
/// which is enough below Android 14 — but on Android 14 (API 34)+, Google
/// Play auto-revokes that permission at install for any app it doesn't
/// recognize as a calling/alarm app (source.android.com/docs/core/
/// permissions/fsi-limits), and nothing in this app could previously tell
/// whether that happened on a given phone. Without it, `remote_alarm`'s
/// and `incoming_call`'s full-screen notification
/// (`firebaseMessagingBackgroundHandler` in push_service.dart) silently
/// degrades to an ordinary heads-up banner that never wakes a locked
/// screen — exactly Sarim's symptom.
///
/// Talks to `MainActivity.kt`'s own `MethodChannel` for the one native
/// API that actually knows the answer (`NotificationManager`
/// .canUseFullScreenIntent(), API 34+ only — not on
/// `NotificationManagerCompat`, confirmed from the same Android source
/// docs page) and the one Settings screen that lets the person grant it
/// back (`Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT`). Below 34,
/// [canUseFullScreenIntent] always reports true from the native side —
/// there's nothing to check or grant pre-34.
class FullScreenIntentAccess {
  FullScreenIntentAccess._();

  static const MethodChannel _channel = MethodChannel('humsafar.app/full_screen_intent');

  /// Best-effort, like every other platform-channel call in this app
  /// (see `secure_screen.dart`'s `_invoke`) — a missing/failed native
  /// call must never block app startup, so this reports `true` (assume
  /// granted) on any failure rather than nagging the person over a check
  /// that couldn't actually run, e.g. in a widget test with no real
  /// platform channel attached.
  static Future<bool> canUseFullScreenIntent() async {
    try {
      final result = await _channel.invokeMethod<bool>('canUseFullScreenIntent');
      return result ?? true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true;
    }
  }

  /// Opens the Android 14+ "full screen intent" special-access settings
  /// screen for this app (native side falls back to the plain app-
  /// details page if that exact screen isn't available on a given OEM
  /// build — see `MainActivity.kt`'s own comment). Best-effort: nothing
  /// meaningful can be done from Dart if this fails outright.
  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openFullScreenIntentSettings');
    } on PlatformException {
      // best-effort, see class doc comment
    } on MissingPluginException {
      // best-effort, see class doc comment
    }
  }
}
