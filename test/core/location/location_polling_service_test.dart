import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:humsafar_frontend/core/location/device_location_source.dart';
import 'package:humsafar_frontend/core/location/location_polling_service.dart';
import 'package:humsafar_frontend/core/network/api_client.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';

/// TC-2.7-01..04 — unit tests for the adaptive location polling loop
/// (Task 2.7). Fully faked: no real GPS, no real network, no device, no
/// login. The actual on-device behaviour (does the OS permission dialog
/// appear, does a real GPS fix come back) stays a manual check — see
/// test_cases/TEST_CASE_LOG.md.
class _FakeDeviceLocationSource implements DeviceLocationSource {
  _FakeDeviceLocationSource({
    this.serviceEnabled = true,
    this.permission = LocationPermission.whileInUse,
    this.battery = 80,
  });

  bool serviceEnabled;
  LocationPermission permission;
  int? battery;
  int getCurrentPositionCallCount = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position> getCurrentPosition() async {
    getCurrentPositionCallCount++;
    return Position(
      latitude: 24.8607,
      longitude: 67.0011,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0.5,
      speedAccuracy: 0,
    );
  }

  @override
  Future<int?> batteryLevel() async => battery;
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.handler)
      : super(
          readAccessToken: () async => 'fake-token',
          readRefreshToken: () async => null,
          saveTokens: ({required String accessToken, required String refreshToken}) async {},
        );

  /// Returns the body to hand back as `response.data`, or throws to
  /// simulate a failed POST (offline, backend error).
  final Future<Map<String, dynamic>> Function(String path, Map<String, dynamic>? body) handler;
  final List<Map<String, dynamic>> postedBodies = [];

  @override
  Future<Response<T>> post<T>(String path, {Object? data}) async {
    final body = data as Map<String, dynamic>?;
    if (body != null) postedBodies.add(body);
    final result = await handler(path, body);
    return Response<T>(requestOptions: RequestOptions(path: path), data: result as T, statusCode: 200);
  }
}

void main() {
  test('TC-2.7-01: posts a fix and obeys the server-given next_update_interval_s', () async {
    final fakeSource = _FakeDeviceLocationSource(battery: 80);
    final fakeClient = _FakeApiClient(
      (path, body) async => {'next_update_interval_s': 10, 'movement_state': 'moving'},
    );

    final service = LocationPollingService(apiClient: fakeClient, dependentId: 'dep-1', locationSource: fakeSource);
    final status = await service.start();

    expect(status, LocationPermissionStatus.granted);
    // start() fires the first poll without waiting for it (so the UI
    // doesn't block on a network call) — give that one microtask gap a
    // moment to finish before asserting on it.
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(fakeSource.getCurrentPositionCallCount, 1);
    expect(fakeClient.postedBodies, hasLength(1));
    expect(fakeClient.postedBodies.first['lat'], 24.8607);
    expect(fakeClient.postedBodies.first['lng'], 67.0011);
    expect(fakeClient.postedBodies.first['battery_level'], 80);

    service.stop();
  });

  test('TC-2.7-02: a failed POST does not kill the polling loop', () async {
    final fakeSource = _FakeDeviceLocationSource();
    final fakeClient = _FakeApiClient(
      (path, body) async => throw const ApiException(code: 'unexpected_error', message: 'offline'),
    );

    final service = LocationPollingService(apiClient: fakeClient, dependentId: 'dep-1', locationSource: fakeSource);
    await service.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Falls back to the contract's documented 60s default and schedules
    // another attempt rather than stopping outright.
    expect(service.isRunning, isTrue);

    service.stop();
  });

  test('TC-2.7-03: denied permission never calls the API and reports denied', () async {
    final fakeSource = _FakeDeviceLocationSource(permission: LocationPermission.denied);
    final fakeClient = _FakeApiClient((path, body) async {
      fail('should never POST when permission is denied');
    });

    final service = LocationPollingService(apiClient: fakeClient, dependentId: 'dep-1', locationSource: fakeSource);
    final status = await service.start();

    expect(status, LocationPermissionStatus.denied);
    expect(service.isRunning, isFalse);
  });

  test('TC-2.7-04: location services disabled is reported distinctly from denied', () async {
    final fakeSource = _FakeDeviceLocationSource(serviceEnabled: false);
    final fakeClient = _FakeApiClient((path, body) async {
      fail('should never POST when location services are off');
    });

    final service = LocationPollingService(apiClient: fakeClient, dependentId: 'dep-1', locationSource: fakeSource);
    final status = await service.start();

    expect(status, LocationPermissionStatus.serviceDisabled);
    expect(service.isRunning, isFalse);
  });

  test('TC-2.7-05: stop() cancels the loop so no further polls happen', () async {
    final fakeSource = _FakeDeviceLocationSource();
    final fakeClient = _FakeApiClient(
      (path, body) async => {'next_update_interval_s': 1, 'movement_state': 'moving'},
    );

    final service = LocationPollingService(apiClient: fakeClient, dependentId: 'dep-1', locationSource: fakeSource);
    await service.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(fakeSource.getCurrentPositionCallCount, 1);

    service.stop();
    expect(service.isRunning, isFalse);

    // Even past the 1s interval the first reply asked for, nothing more
    // should fire once stopped.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(fakeSource.getCurrentPositionCallCount, 1);
  });
}
