/// Single source of truth for the backend's base URL.
///
/// Bug fix (F-31, Sarim's 23 Nov report on debug-apk-1.9.2): the default
/// used to be the Android-emulator-only address (`10.0.2.2`), which is
/// meaningless on a real phone. Every real-device build Talha has shared
/// with Sarim is meant to hit the deployed backend, and the
/// `--dart-define` override has twice been the one flag missing from the
/// actual build command (this exact incident, and the earlier F-22) —
/// each time producing an APK that fails Login instantly on every real
/// phone with no obvious cause from the error alone. Defaulting to the
/// real deployed backend instead means an *omitted* `--dart-define` now
/// fails safe (still hits production) instead of failing broken (hits an
/// address that only resolves inside an emulator). A real local-LAN
/// override for `flutter run` against a teammate's own machine still
/// works exactly as before — just pass it explicitly:
///   flutter run --dart-define=API_BASE_URL=http://<your-pc-LAN-IP>:8000
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://humsafar-api-s851.onrender.com',
);
