import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';

/// Thin wrapper around the `geolocator`/`battery_plus` plugins so
/// [LocationPollingService] (same folder) can be unit-tested without real
/// GPS/battery hardware. Calling `Geolocator.*` directly from a test hits
/// a real platform channel and throws `MissingPluginException` — there's
/// no device under `flutter test`. A fake implementation of this
/// interface sidesteps that entirely; see
/// test/core/location/location_polling_service_test.dart.
abstract class DeviceLocationSource {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position> getCurrentPosition();

  /// Null if the battery level genuinely can't be read (some platforms
  /// don't support it) — the field is optional on the wire per
  /// location_contract.md, so a null here just means it's left out of the
  /// POST body rather than failing the whole fix.
  Future<int?> batteryLevel();
}

class RealDeviceLocationSource implements DeviceLocationSource {
  final Battery _battery = Battery();

  @override
  Future<bool> isLocationServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() => Geolocator.requestPermission();

  @override
  Future<Position> getCurrentPosition() => Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

  @override
  Future<int?> batteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return null;
    }
  }
}

/// What [LocationPollingService.ensurePermission] found, mapped from
/// geolocator's own `LocationPermission` plus the service-enabled check
/// into the handful of outcomes the UI actually needs to react to
/// differently (see LocationStatusBanner).
enum LocationPermissionStatus { granted, denied, deniedForever, serviceDisabled }
