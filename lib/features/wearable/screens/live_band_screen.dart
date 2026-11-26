import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../core/wearable/ble_band_service.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 5.5 — live BLE session with the real band (Abdullah's 25 Nov
/// spec; minimal first version per his own ask: scan, connect, show live
/// readings, sync to the server every 30-60s). Opened from
/// `my_band_screen.dart`'s paired state. Deliberately separate from
/// `connect_band_screen.dart`, which only handles one-time *registration*
/// with the server (`POST .../wearable`) — this screen is the ongoing
/// *live session* with the physical device (scan, connect, read, sync),
/// matching the spec's own split between pairing once and sending
/// readings repeatedly.
///
/// **Not yet tested against a real band or a real `flutter pub get`/
/// `flutter analyze`** — see `ble_band_service.dart`'s own doc comment
/// for why, and what to do if it doesn't compile as-is.
class LiveBandScreen extends ConsumerStatefulWidget {
  const LiveBandScreen({super.key, required this.dependentId});

  final String dependentId;

  @override
  ConsumerState<LiveBandScreen> createState() => _LiveBandScreenState();
}

class _LiveBandScreenState extends ConsumerState<LiveBandScreen> {
  final _service = BleBandService();
  StreamSubscription<BandConnectionStatus>? _statusSub;
  StreamSubscription<BandReading>? _readingsSub;
  Timer? _syncTimer;

  BandConnectionPhase _phase = BandConnectionPhase.idle;
  String? _errorCode;
  BandReading? _latestReading;
  DateTime? _lastSyncedAt;
  bool _isSyncing = false;

  // Rule 3 (optional, Abdullah's spec): the first few heart-rate values
  // after a finger goes on the sensor are unsettled — skip the first 3
  // non-zero ones per connection. SpO2/temperature aren't covered by
  // this rule in the spec, so they're queued as soon as they're real.
  int _nonZeroHeartRatesSeen = 0;
  static const _settlingReadingsToSkip = 3;

  final List<Map<String, dynamic>> _pendingReadings = [];
  // Server limit, Abdullah's spec: max 500 readings per sync call. Used
  // here as a buffer cap too, so a long-disconnected sync loop can't grow
  // this list without bound.
  static const _maxBufferedReadings = 500;

  @override
  void initState() {
    super.initState();
    _statusSub = _service.status.listen((status) {
      if (!mounted) return;
      setState(() {
        _phase = status.phase;
        if (status.phase == BandConnectionPhase.connecting || status.phase == BandConnectionPhase.scanning) {
          _nonZeroHeartRatesSeen = 0;
        }
      });
    });
    _readingsSub = _service.readings.listen(_onReading);
    _syncTimer = Timer.periodic(const Duration(seconds: 45), (_) => _syncPending());
    // Deferred to after first frame so AppLocalizations.of(context) is
    // safe to read from _connect()'s error paths.
    WidgetsBinding.instance.addPostFrameCallback((_) => _connect());
  }

  Future<void> _connect() async {
    if (!mounted) return;
    setState(() => _errorCode = null);
    final granted = await _service.requestPermissions();
    if (!mounted) return;
    if (!granted) {
      setState(() {
        _phase = BandConnectionPhase.error;
        _errorCode = 'permission_denied';
      });
      return;
    }
    try {
      final device = await _service.scanForDevice();
      if (!mounted) return;
      if (device == null) {
        setState(() {
          _phase = BandConnectionPhase.error;
          _errorCode = 'not_found';
        });
        return;
      }
      await _service.connect(device);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = BandConnectionPhase.error;
        _errorCode = 'connect_failed';
      });
    }
  }

  void _onReading(BandReading reading) {
    if (!mounted) return;
    setState(() => _latestReading = reading);

    var includeHeartRate = reading.hasHeartRate;
    if (includeHeartRate) {
      _nonZeroHeartRatesSeen++;
      if (_nonZeroHeartRatesSeen <= _settlingReadingsToSkip) includeHeartRate = false;
    }

    final recordedAt = reading.timestamp.toUtc().toIso8601String();
    // Rule 1 (Abdullah's spec): never send a 0/sentinel "no reading"
    // value to the server — each metric is only queued when it's real.
    if (includeHeartRate) _queue('heart_rate', reading.heartRate, recordedAt);
    if (reading.hasSpo2) _queue('spo2', reading.spo2, recordedAt);
    if (reading.hasTemperature) _queue('temperature', reading.temperatureC!, recordedAt);
    // Steps: rule 2 — the server doesn't accept this metric. Shown in
    // the UI only (via _latestReading above), never queued for sync.
  }

  void _queue(String metricType, num value, String recordedAt) {
    if (_pendingReadings.length >= _maxBufferedReadings) _pendingReadings.removeAt(0);
    _pendingReadings.add({'metric_type': metricType, 'value': value, 'recorded_at': recordedAt});
  }

  Future<void> _syncPending() async {
    if (_pendingReadings.isEmpty || _isSyncing) return;
    final batch = List<Map<String, dynamic>>.from(_pendingReadings);
    setState(() => _isSyncing = true);
    try {
      await ref.read(apiClientProvider).post('/dependents/${widget.dependentId}/wearable/sync', data: {'readings': batch});
      _pendingReadings.removeRange(0, batch.length);
      if (mounted) setState(() => _lastSyncedAt = DateTime.now());
    } on ApiException catch (_) {
      // Left queued — the next timer tick retries. Abdullah's spec: a
      // retried batch is safe, the server skips duplicates.
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _statusSub?.cancel();
    _readingsSub?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.liveBandScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
          child: _buildBody(l10n),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_phase == BandConnectionPhase.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bluetooth_disabled, size: 48, color: HumsafarColors.warning),
            const SizedBox(height: 12),
            Text(_errorMessage(l10n), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _connect, child: Text(l10n.retryButton)),
          ],
        ),
      );
    }

    if (_phase != BandConnectionPhase.connected) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_statusMessage(l10n), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final reading = _latestReading;
    return ListView(
      children: [
        Row(
          children: [
            const Icon(Icons.bluetooth_connected, color: HumsafarColors.success),
            const SizedBox(width: 8),
            Text(l10n.liveBandConnectedMessage),
          ],
        ),
        const SizedBox(height: 16),
        _buildMetricTile(
          l10n.liveHeartRateLabel,
          reading?.hasHeartRate == true ? '${reading!.heartRate} bpm' : l10n.liveNoReadingYetLabel,
        ),
        _buildMetricTile(
          l10n.liveSpo2Label,
          reading?.hasSpo2 == true ? '${reading!.spo2}%' : l10n.liveNoReadingYetLabel,
        ),
        _buildMetricTile(
          l10n.liveTemperatureLabel,
          reading?.hasTemperature == true ? '${reading!.temperatureC!.toStringAsFixed(1)}°C' : l10n.liveNoReadingYetLabel,
        ),
        _buildMetricTile(
          l10n.liveStepsLabel,
          reading == null ? l10n.liveNoReadingYetLabel : '${reading.steps}',
        ),
        const SizedBox(height: 24),
        if (_isSyncing) Text(l10n.liveBandSyncingMessage, style: Theme.of(context).textTheme.bodySmall),
        if (!_isSyncing && _lastSyncedAt != null)
          Text(
            '${l10n.liveBandLastSyncedLabel}: ${TimeOfDay.fromDateTime(_lastSyncedAt!).format(context)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: HumsafarColors.muted)),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  String _statusMessage(AppLocalizations l10n) {
    switch (_phase) {
      case BandConnectionPhase.requestingPermissions:
        return l10n.liveBandRequestingPermissionsMessage;
      case BandConnectionPhase.scanning:
        return l10n.liveBandScanningMessage;
      case BandConnectionPhase.connecting:
        return l10n.liveBandConnectingMessage;
      case BandConnectionPhase.disconnected:
        return l10n.liveBandDisconnectedMessage;
      default:
        return l10n.liveBandScanningMessage;
    }
  }

  String _errorMessage(AppLocalizations l10n) {
    switch (_errorCode) {
      case 'permission_denied':
        return l10n.liveBandPermissionDeniedMessage;
      case 'not_found':
        return l10n.liveBandNotFoundMessage;
      default:
        return l10n.liveBandConnectFailedMessage;
    }
  }
}
