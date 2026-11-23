package com.example.humsafar_talha_frontend

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
    }
}
