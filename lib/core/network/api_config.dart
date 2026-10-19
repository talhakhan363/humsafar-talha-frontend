/// Single source of truth for the backend's base URL. Defaults to the
/// Android emulator address per `docs/backend/RUNNING_THE_BACKEND.md` —
/// override for a real device or desktop with:
///   flutter run --dart-define=API_BASE_URL=http://<your-pc-LAN-IP>:8000
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);
