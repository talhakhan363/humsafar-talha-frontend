import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'device_location_source.dart';

/// Task 2.7 — background location service (client side of FR-C1). Per
/// Talha's handbook this is scoped to "handle permissions and adaptive
/// polling on the client side" while the app is active — the SRS itself
/// says the system tracks location "while the application is active," so
/// this deliberately does NOT use a persistent Android foreground
/// service / ACCESS_BACKGROUND_LOCATION. It starts/stops with the
/// screen's lifecycle instead (see DependentHomeScreen, which also stops
/// it when the app is backgrounded via WidgetsBindingObserver).
///
/// The server, not the phone, decides the polling rate
/// (`docs/api/location_contract.md`): every successful POST to
/// `/dependents/{id}/location` replies with `next_update_interval_s`, and
/// this service just waits that long before the next fix. Until a first
/// reply arrives, or if a POST fails (offline, server error), it falls
/// back to the contract's documented default of 60 seconds.
///
/// Named scope cut: offline fixes are not buffered/queued for later
/// resend. A failed POST just means that one cycle isn't recorded — the
/// next successful poll continues normally. The contract supports
/// resending buffered fixes via `recorded_at`, but a local offline queue
/// is a bigger piece of work than "adaptive polling" calls for and isn't
/// part of this task.
class LocationPollingService {
  LocationPollingService({
    required ApiClient apiClient,
    required String dependentId,
    DeviceLocationSource? locationSource,
  })  : _apiClient = apiClient,
        _dependentId = dependentId,
        _locationSource = locationSource ?? RealDeviceLocationSource();

  static const _defaultIntervalSeconds = 60;

  final ApiClient _apiClient;
  final String _dependentId;
  final DeviceLocationSource _locationSource;

  Timer? _timer;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<LocationPermissionStatus> ensurePermission() async {
    if (!await _locationSource.isLocationServiceEnabled()) {
      return LocationPermissionStatus.serviceDisabled;
    }
    var permission = await _locationSource.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _locationSource.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.deniedForever;
    }
    if (permission == LocationPermission.denied) {
      return LocationPermissionStatus.denied;
    }
    return LocationPermissionStatus.granted;
  }

  /// Checks/requests permission and, if granted, starts the poll loop.
  /// Returns the permission outcome so the caller can show the right
  /// message when it isn't `granted` — never throws for a denied/disabled
  /// outcome, only for a programmer error.
  Future<LocationPermissionStatus> start() async {
    if (_isRunning) return LocationPermissionStatus.granted;
    final status = await ensurePermission();
    if (status != LocationPermissionStatus.granted) return status;
    _isRunning = true;
    unawaited(_pollOnce());
    return LocationPermissionStatus.granted;
  }

  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _pollOnce() async {
    if (!_isRunning) return;
    var nextIntervalSeconds = _defaultIntervalSeconds;
    try {
      final position = await _locationSource.getCurrentPosition();
      final batteryLevel = await _locationSource.batteryLevel();
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/dependents/$_dependentId/location',
        data: {
          'lat': position.latitude,
          'lng': position.longitude,
          'speed_mps': position.speed,
          'accuracy_m': position.accuracy,
          if (batteryLevel != null) 'battery_level': batteryLevel,
        },
      );
      final interval = response.data?['next_update_interval_s'] as int?;
      if (interval != null) nextIntervalSeconds = interval;
    } on ApiException {
      // Offline or a backend error for this one cycle — contract says
      // fall back to 60s until a reply arrives again. Not fatal: the loop
      // keeps running and the next cycle just tries again.
    } catch (_) {
      // GPS failure (no fix yet, permission revoked mid-run, location
      // services turned off mid-run, etc). Same back-off rather than
      // hammering retries.
    }
    if (!_isRunning) return;
    _timer = Timer(Duration(seconds: nextIntervalSeconds), _pollOnce);
  }
}
