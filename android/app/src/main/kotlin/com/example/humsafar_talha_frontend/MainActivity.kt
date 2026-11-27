package com.example.humsafar_talha_frontend

import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Bug fix (SEC-15, Sarim's 22 Nov security review): backs
// lib/core/platform/secure_screen.dart's MethodChannel. FLAG_SECURE is a
// window-level flag (there's no per-widget equivalent), so Dart can only
// ask the native Activity to set/clear it for the whole app window; see
// secure_screen.dart's own doc comment for why it's reference-counted on
// the Dart side rather than called as a plain toggle.
class MainActivity : FlutterActivity() {
    private val secureScreenChannel = "humsafar.app/secure_screen"

    // Bug fix (F-13, Sarim's 26 Nov retest): backs
    // lib/core/platform/full_screen_intent_access.dart. Declaring
    // USE_FULL_SCREEN_INTENT in AndroidManifest.xml (already done, see
    // that file's own comment) is necessary but not sufficient on
    // Android 14 (API 34)+ — Google Play auto-revokes it at install for
    // any app it doesn't recognize as a calling/alarm app, and there's no
    // way to tell from Dart alone whether that happened on a given
    // device. `NotificationManager.canUseFullScreenIntent()` (confirmed
    // from source.android.com/docs/core/permissions/fsi-limits, API 34+
    // only — NOT on NotificationManagerCompat, which doesn't expose this)
    // is the only way to actually know, and
    // `Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT` is the one
    // Settings screen that lets the person grant it back. Below 34 this
    // channel's "canUse" always reports true (there's nothing to check or
    // grant pre-34 — the manifest declaration alone is enough), matching
    // every other per-SDK-level permission gate already in this app
    // (POST_NOTIFICATIONS in push_service.dart, the BLUETOOTH_SCAN/CONNECT
    // split in AndroidManifest.xml).
    //
    // Compile-time dependency, named so this isn't a mystery if it fails:
    // `NotificationManager.canUseFullScreenIntent()` only resolves at all
    // if `compileSdk` (build.gradle.kts: `flutter.compileSdkVersion`,
    // i.e. whatever Flutter 3.32.1's bundled Android Gradle plugin
    // defaults to) is 34+. Every other API-33/34-level permission in
    // this app (POST_NOTIFICATIONS, BLUETOOTH_SCAN/CONNECT) already
    // compiles fine, which is why this wasn't independently re-verified
    // here — if `flutter build apk` disagrees, that default is the first
    // thing to check.
    private val fullScreenIntentChannel = "humsafar.app/full_screen_intent"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, secureScreenChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enable" -> {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE
                        )
                        result.success(null)
                    }
                    "disable" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, fullScreenIntentChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canUseFullScreenIntent" -> {
                        // 34 = Android 14. Using the raw int rather than
                        // Build.VERSION_CODES.UPSIDE_DOWN_CAKE on purpose —
                        // couldn't independently confirm that exact constant
                        // name against Android's own reference docs before
                        // this needed to ship (fetch returned only a nav
                        // index, not the field list), and a wrong constant
                        // name is a compile error Talha would hit blind,
                        // whereas the numeric SDK level is unambiguous and
                        // already how this same comparison is written
                        // elsewhere if this project ever needs it again.
                        if (Build.VERSION.SDK_INT >= 34) {
                            val manager = getSystemService(NotificationManager::class.java)
                            result.success(manager?.canUseFullScreenIntent() ?: true)
                        } else {
                            // Pre-34: the manifest declaration alone is enough,
                            // nothing to check or grant — see the field doc
                            // comment above.
                            result.success(true)
                        }
                    }
                    "openFullScreenIntentSettings" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= 34) { // Android 14, see the "canUseFullScreenIntent" branch above
                                startActivity(
                                    Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT)
                                        .setData(Uri.parse("package:$packageName"))
                                )
                            }
                            result.success(null)
                        } catch (e: Exception) {
                            // Best-effort fallback: some OEM builds don't ship
                            // this exact settings screen even on 34+ — the
                            // plain app-details page at least gets the person
                            // one tap away from the right place, same
                            // defensive spirit as every other best-effort
                            // platform call in this app (see
                            // alarm_screen.dart's _startAlarmSound).
                            try {
                                startActivity(
                                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                        .setData(Uri.parse("package:$packageName"))
                                )
                            } catch (e2: Exception) {
                                // Nothing more this method can do.
                            }
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
