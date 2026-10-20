import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// New screen for Task 2.6. Shows a Dependent's live location and geofence
/// boundaries on a map — GET /dependents/{id}/location and
/// GET /dependents/{id}/geofences, geofence breach colour from
/// GET /dependents/{id}/geofence-status (location_contract.md,
/// geofence_contract.md).
///
/// Uses `flutter_map` (OpenStreetMap tiles) rather than
/// `google_maps_flutter` — no Google Cloud project, API key, or billing
/// needed, and this task only needs a basemap with a marker and circle
/// overlays, which OSM tiles do fine.
///
/// Named scope decision: this screen is read-only (view location +
/// zones). Creating/editing/deleting safe zones is NOT part of Task 2.6's
/// stated scope ("Live Map screen (location + geofence overlay)" per the
/// handbook) even though Sarim's 2.8 mockup bundle also includes a
/// "Safe zones list" / "Edit safe zone" screen — those are a deliberately
/// deferred follow-up, not a silent gap.
///
/// Also worth knowing for testing: this screen has nothing to show until
/// a Dependent's phone has actually POSTed a location fix. Task 2.7
/// (background location service) is what makes the Dependent's own app
/// send those automatically, and it isn't built yet — so until 2.7 ships,
/// the way to see this screen with real data is to POST a fix by hand via
/// Postman against a Dependent's own token, same as the test case log
/// explains.
class LiveMapScreen extends ConsumerStatefulWidget {
  const LiveMapScreen({super.key, required this.dependentId, required this.dependentLabel});

  final String dependentId;
  final String dependentLabel;

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  static const _pollInterval = Duration(seconds: 20);

  final _mapController = MapController();
  Timer? _timer;
  bool _isLoading = true;
  String? _loadError;
  ll.LatLng? _position;
  int? _ageSeconds;
  bool _isStale = true;
  List<_GeofenceCircle> _geofences = [];
  String _zoneStatus = 'unknown';
  bool _hasCenteredOnce = false;

  @override
  void initState() {
    super.initState();
    _loadGeofences();
    _loadLocation();
    _timer = Timer.periodic(_pollInterval, (_) => _loadLocation());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadGeofences() async {
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('/dependents/${widget.dependentId}/geofences');
      final list = (response.data?['geofences'] as List<dynamic>? ?? [])
          .map((e) => _GeofenceCircle.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _geofences = list);
    } on ApiException {
      // Non-fatal: the map still works without zone overlays. The
      // location call below is what surfaces the real permission/link
      // errors to the user, so this failure is swallowed rather than
      // shown twice.
    }
  }

  Future<void> _loadLocation() async {
    try {
      final locationResponse =
          await ref.read(apiClientProvider).get<Map<String, dynamic>>('/dependents/${widget.dependentId}/location');
      final statusResponse = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('/dependents/${widget.dependentId}/geofence-status');
      if (!mounted) return;

      final loc = locationResponse.data?['location'] as Map<String, dynamic>?;
      setState(() {
        _isLoading = false;
        _loadError = null;
        _position = loc == null ? null : ll.LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
        _ageSeconds = locationResponse.data?['age_seconds'] as int?;
        _isStale = (locationResponse.data?['is_stale'] as bool?) ?? true;
        _zoneStatus = statusResponse.data?['status'] as String? ?? 'unknown';
      });

      if (_position != null && !_hasCenteredOnce) {
        _hasCenteredOnce = true;
        _mapController.move(_position!, 15);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = _messageFor(e);
      });
    }
  }

  String _messageFor(ApiException e) {
    final l10n = AppLocalizations.of(context)!;
    switch (e.code) {
      case 'MODULE_ACCESS_DENIED':
        return l10n.moduleAccessDeniedLiveMapError;
      case 'NOT_LINKED_TO_DEPENDENT':
        return l10n.notLinkedToDependentError;
      case 'GUARDIAN_NOT_VERIFIED':
        return l10n.guardianNotVerifiedGenericError;
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dependentLabel),
        actions: [
          const LanguageSwitchButton(),
          const AccessibilityToggleButton(),
          IconButton(icon: const Icon(Icons.refresh), tooltip: l10n.retryButton, onPressed: _loadLocation),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadLocation, child: Text(l10n.retryButton)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildStatusBanner(l10n),
        Expanded(
          child: _position == null
              ? Center(child: Text(l10n.noLocationYetMessage, textAlign: TextAlign.center))
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: _position!, initialZoom: 15),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.humsafar.frontend',
                    ),
                    CircleLayer(
                      circles: _geofences
                          .map(
                            (g) => CircleMarker(
                              point: ll.LatLng(g.lat, g.lng),
                              radius: g.radiusM,
                              useRadiusInMeter: true,
                              color: Colors.teal.withValues(alpha: 0.15),
                              borderColor: Colors.teal,
                              borderStrokeWidth: 2,
                            ),
                          )
                          .toList(),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _position!,
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.person_pin_circle,
                            // Amber for outside a safe zone (warning), never red —
                            // matches Sarim's 2.8 mockup convention: red is
                            // reserved for Panic only.
                            color: _zoneStatus == 'outside' ? Colors.amber.shade800 : Colors.teal,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(AppLocalizations l10n) {
    final statusText = switch (_zoneStatus) {
      'inside' => l10n.zoneStatusInside,
      'outside' => l10n.zoneStatusOutside,
      'no_zones' => l10n.zoneStatusNoZones,
      _ => l10n.zoneStatusUnknown,
    };
    final isWarning = _zoneStatus == 'outside';
    final lastSeenText = _position == null
        ? null
        : (_ageSeconds != null && _ageSeconds! < 60)
            ? l10n.justNowLabel
            : l10n.lastSeenMinutesMessage(((_ageSeconds ?? 0) / 60).round());

    return Container(
      width: double.infinity,
      color: isWarning ? Colors.amber.shade100 : Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statusText,
            style: TextStyle(fontWeight: FontWeight.bold, color: isWarning ? Colors.amber.shade900 : null),
          ),
          if (lastSeenText != null) Text(lastSeenText, style: Theme.of(context).textTheme.bodySmall),
          if (_isStale && _position != null)
            Text(l10n.locationStaleWarning, style: TextStyle(fontSize: 12, color: Colors.amber.shade900)),
        ],
      ),
    );
  }
}

class _GeofenceCircle {
  _GeofenceCircle({required this.lat, required this.lng, required this.radiusM});

  final double lat;
  final double lng;
  final double radiusM;

  factory _GeofenceCircle.fromJson(Map<String, dynamic> json) => _GeofenceCircle(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        radiusM: (json['radius_m'] as num).toDouble(),
      );
}
