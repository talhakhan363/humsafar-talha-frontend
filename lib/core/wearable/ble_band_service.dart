/// Task 5.5 — real wearable band integration. Talks BLE directly to the
/// physical "Humsafar Band" per Abdullah's 25 Nov hardware spec (firmware
/// v0.2, chat messages "Wed 5:18pm" and "Wed 5:18 2nd"): scan by
/// advertised name, connect, subscribe to one custom characteristic that
/// carries heart rate + SpO2 + temperature + steps in a single 9-byte
/// little-endian packet, once per second.
///
/// **Not yet verified against a real `flutter pub get`/compile or a real
/// band** — this sandbox has no Dart/Flutter toolchain and no physical
/// device to test against. Built directly from Abdullah's written spec
/// (exact service/characteristic UUIDs, byte offsets, sentinel values),
/// same "spec-grounded, not guessed" approach as every other
/// contract-driven screen in this app — but `flutter_blue_plus`'s own API
/// has shifted method/stream names across versions before (see
/// pubspec.yaml's comment on this dependency for the version-floor
/// research). If this doesn't compile as-is on Talha's machine, send the
/// real error; the shape of the fix is likely a renamed stream/method,
/// not a logic change.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// One parsed packet from the band's notify characteristic. The band
/// itself marks "no reading" with 0 (heart rate, SpO2) or the sentinel
/// 0x7FFF (temperature) — those are kept as `0`/`null` here, not hidden,
/// so callers decide what "no reading" means for their own UI, but every
/// `has*` getter exists specifically so a caller can implement rule 1 of
/// Abdullah's spec ("never send a 0/sentinel reading to the server")
/// without re-deriving the sentinel values itself.
class BandReading {
  const BandReading({
    required this.heartRate,
    required this.spo2,
    required this.temperatureC,
    required this.steps,
    required this.timestamp,
  });

  /// Beats per minute. 0 = no reading (the band's own sentinel, byte 1).
  final int heartRate;

  /// Percent. 0 = no reading (the band's own sentinel, byte 2).
  final int spo2;

  /// Degrees Celsius. null = sensor error (the band's 0x7FFF sentinel,
  /// bytes 3-4, signed int16 / 100).
  final double? temperatureC;

  /// Cumulative step count (bytes 5-8, uint32). Abdullah's spec: the
  /// server does not accept this metric — shown in the app only, never
  /// synced.
  final int steps;

  final DateTime timestamp;

  bool get hasHeartRate => heartRate > 0;
  bool get hasSpo2 => spo2 > 0;
  bool get hasTemperature => temperatureC != null;
}

enum BandConnectionPhase {
  idle,
  requestingPermissions,
  scanning,
  connecting,
  connected,
  disconnected,
  error,
}

class BandConnectionStatus {
  const BandConnectionStatus(this.phase, {this.message});
  final BandConnectionPhase phase;
  final String? message;
}

/// Wraps `flutter_blue_plus` the same way `DeviceLocationSource`/
/// `AudioRecorderSource` wrap their own native plugins elsewhere in this
/// app — one seam a screen talks to, so the BLE specifics live in exactly
/// one place.
class BleBandService {
  // Abdullah's 25 Nov spec, firmware v0.2. Do not change these without a
  // matching firmware/spec update — they're copied verbatim, not guessed.
  static const deviceName = 'Humsafar Band';
  static final Guid serviceUuid = Guid('7d1c0001-5a2e-4f3b-9b6a-4f5d9a1c0b01');
  static final Guid characteristicUuid = Guid('7d1c0002-5a2e-4f3b-9b6a-4f5d9a1c0b01');

  BluetoothDevice? _device;
  StreamSubscription<List<int>>? _valueSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  bool _disposed = false;

  final _statusController = StreamController<BandConnectionStatus>.broadcast();
  Stream<BandConnectionStatus> get status => _statusController.stream;

  final _readingsController = StreamController<BandReading>.broadcast();
  Stream<BandReading> get readings => _readingsController.stream;

  void _setStatus(BandConnectionPhase phase, {String? message}) {
    if (!_disposed && !_statusController.isClosed) {
      _statusController.add(BandConnectionStatus(phase, message: message));
    }
  }

  /// Requests the runtime permissions a BLE scan needs. Android 12+
  /// (API 31+) wants `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT`; below that, BLE
  /// scanning needs location, already requested for Task 2.7's location
  /// polling but re-checked here since a Dependent may never have opened
  /// the Live Map screen. `permission_handler` treats a permission that
  /// doesn't apply on the running OS version as already granted, so
  /// requesting all three unconditionally is safe across this app's
  /// whole supported range (minSdk 21).
  Future<bool> requestPermissions() async {
    _setStatus(BandConnectionPhase.requestingPermissions);
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  /// Scans for a device advertising the name "Humsafar Band" and returns
  /// it, or null if none is found within [timeout]. Always stops the scan
  /// before returning, found or not — a stray running scan drains battery
  /// and can block the next attempt.
  Future<BluetoothDevice?> scanForDevice({Duration timeout = const Duration(seconds: 12)}) async {
    _setStatus(BandConnectionPhase.scanning);
    final completer = Completer<BluetoothDevice?>();
    late final StreamSubscription<List<ScanResult>> sub;
    sub = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final advertisedName = result.advertisementData.advName;
        final name = advertisedName.isNotEmpty ? advertisedName : result.device.platformName;
        if (name == deviceName && !completer.isCompleted) {
          completer.complete(result.device);
          break;
        }
      }
    });
    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      return await completer.future.timeout(timeout, onTimeout: () => null);
    } finally {
      await sub.cancel();
      if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();
    }
  }

  /// Connects to [device], discovers the band's custom service, and
  /// starts pushing one [BandReading] per second onto [readings] as the
  /// characteristic notifies.
  Future<void> connect(BluetoothDevice device) async {
    _device = device;
    _setStatus(BandConnectionPhase.connecting);
    _connectionSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _setStatus(BandConnectionPhase.disconnected);
      }
    });
    await device.connect(timeout: const Duration(seconds: 15));
    final services = await device.discoverServices();
    final service = services.firstWhere(
      (s) => s.uuid == serviceUuid,
      orElse: () => throw StateError(
        'Humsafar Band service not found on this device — confirmed real band, firmware v0.2+?',
      ),
    );
    final characteristic = service.characteristics.firstWhere(
      (c) => c.uuid == characteristicUuid,
      orElse: () => throw StateError('Humsafar Band characteristic not found.'),
    );
    await characteristic.setNotifyValue(true);
    _valueSub = characteristic.lastValueStream.listen((bytes) {
      final reading = _parsePacket(bytes);
      if (reading != null && !_disposed && !_readingsController.isClosed) {
        _readingsController.add(reading);
      }
    });
    _setStatus(BandConnectionPhase.connected);
  }

  /// Byte layout (Abdullah's spec, little-endian):
  /// 0 = version, 1 = heart rate, 2 = SpO2, 3-4 = temperature (int16, x100,
  /// 0x7FFF = sensor error), 5-8 = step count (uint32).
  BandReading? _parsePacket(List<int> bytes) {
    if (bytes.length < 9) return null;
    final data = Uint8List.fromList(bytes).buffer.asByteData();
    final heartRate = data.getUint8(1);
    final spo2 = data.getUint8(2);
    final tempRaw = data.getInt16(3, Endian.little);
    final temperatureC = tempRaw == 0x7FFF ? null : tempRaw / 100.0;
    final steps = data.getUint32(5, Endian.little);
    return BandReading(
      heartRate: heartRate,
      spo2: spo2,
      temperatureC: temperatureC,
      steps: steps,
      timestamp: DateTime.now(),
    );
  }

  Future<void> disconnect() async {
    await _valueSub?.cancel();
    await _connectionSub?.cancel();
    _valueSub = null;
    _connectionSub = null;
    try {
      await _device?.disconnect();
    } catch (_) {
      // Best-effort cleanup — already disconnected is not an error here.
    }
    _device = null;
  }

  void dispose() {
    _disposed = true;
    unawaited(disconnect());
    _statusController.close();
    _readingsController.close();
  }
}
