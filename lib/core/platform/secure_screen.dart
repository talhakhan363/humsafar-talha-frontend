import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bug fix (SEC-15, Sarim's 22 Nov security review, Low): screenshots and
/// the Recent-apps thumbnail (which doubles as background screen
/// recording on some OEM skins) were unrestricted everywhere, including
/// the screens that show real PHI — the medical vault, vitals history/
/// entry, and the records screens (appointments, doctor links, record
/// access, add record). Android's native `FLAG_SECURE` blocks both of
/// those for the whole activity window while it's set; there's no
/// per-widget equivalent, so this talks to `MainActivity.kt` over a
/// `MethodChannel` to flip it for the activity as a whole, and
/// `SecureScreenMixin` below turns it on/off from each secure screen's own
/// lifecycle.
///
/// Reference-counted rather than a plain on/off toggle: go_router (like
/// `Navigator` generally) keeps a pushed screen's `State` alive
/// underneath whatever gets pushed on top of it — only popping calls
/// `dispose()`, pushing never does. So e.g. Vitals -> Add Vital Reading
/// calls `enable()` a 2nd time while Vitals' own `enable()` (from its own
/// `initState`) is still in effect; if `disable()` unconditionally turned
/// the native flag off as soon as Add Vital Reading's `dispose()` ran (on
/// popping back to Vitals), the flag would go off while Vitals — still a
/// secure screen — is back on screen underneath. Counting means the
/// native flag only actually clears once the LAST secure screen in the
/// stack has gone away.
class SecureScreen {
  SecureScreen._();

  static const MethodChannel _channel = MethodChannel('humsafar.app/secure_screen');
  static int _activeCount = 0;

  static Future<void> enable() async {
    _activeCount++;
    if (_activeCount == 1) {
      await _invoke('enable');
    }
  }

  static Future<void> disable() async {
    if (_activeCount == 0) return;
    _activeCount--;
    if (_activeCount == 0) {
      await _invoke('disable');
    }
  }

  static Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod(method);
    } on PlatformException {
      // Best-effort: a missing/failed native call shouldn't crash the
      // screen it's meant to protect, and nothing else reads this
      // channel's result.
    } on MissingPluginException {
      // Same reasoning — e.g. a widget test that never attaches the real
      // platform channel.
    }
  }
}

/// Mix this into any screen's `State` that shows PHI (see [SecureScreen]'s
/// own doc comment for which screens and why) to keep `FLAG_SECURE` on
/// for as long as that screen is in the navigation stack. Works on
/// `ConsumerState` too, since that extends `State<T>`.
mixin SecureScreenMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
  }

  @override
  void dispose() {
    SecureScreen.disable();
    super.dispose();
  }
}
