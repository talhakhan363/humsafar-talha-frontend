import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/auth/current_user_provider.dart';
import '../../../core/location/device_location_source.dart';
import '../../../core/location/location_polling_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/scheduling/schedule_helpers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../widgets/location_status_banner.dart';
import '../widgets/safety_action_buttons.dart';

/// Task 3.10 — the real Dependent Mode home screen (mockup screen 20:
/// greeting, Panic, "I am OK", "My medicine"), replacing the Task 1.11
/// placeholder. Task 2.7's location-sharing service/banner, previously
/// wired into that placeholder, moves here unchanged — this is the named
/// follow-up flagged when 2.7 shipped.
///
/// "What's next" for medication/wellness check is computed client-side
/// from the active *schedules* (`GET .../medications`,
/// `GET .../wellness-checks`), not from the dose-list endpoint — a dose
/// only exists in the system from 15 minutes before it's due
/// (medication_contract.md), so it can't tell you about something hours
/// away. The schedule's own `time`/`frequency`/`days` can, via
/// `schedule_helpers.dart`'s `earliestUpcoming`.
///
/// Panic / "I am OK" / "My medicine" route to a real destination now,
/// but that destination is a named placeholder (ComingSoonScreen) until
/// Tasks 3.11/3.12/3.13 build the real screens — not a silent gap.
///
/// Not automated-tested as a full screen, same reasoning as the old
/// placeholder: `_startLocationSharing` calls through to the real
/// Geolocator plugin, which has no platform channel under `flutter
/// test`. What IS tested without a device: `schedule_helpers.dart`'s
/// pure scheduling math, `PanicButton`/`SafetyActionButton`'s rendering,
/// and `ComingSoonScreen`'s per-kind text — see test/.
class DependentHomeScreen extends ConsumerStatefulWidget {
  const DependentHomeScreen({super.key});

  @override
  ConsumerState<DependentHomeScreen> createState() => _DependentHomeScreenState();
}

class _DependentHomeScreenState extends ConsumerState<DependentHomeScreen> with WidgetsBindingObserver {
  LocationPollingService? _locationService;
  LocationPermissionStatus? _permissionStatus;

  bool _isLoadingSchedules = true;
  String? _scheduleLoadError;
  ({Map<String, dynamic> item, DateTime at})? _nextMedication;
  ({Map<String, dynamic> item, DateTime at})? _nextWellnessCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLocationSharing();
    _loadUpcoming();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationService?.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startLocationSharing();
    } else {
      _locationService?.stop();
    }
  }

  Future<void> _startLocationSharing() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    _locationService ??= LocationPollingService(apiClient: ref.read(apiClientProvider), dependentId: user.userId);
    final status = await _locationService!.start();
    if (!mounted) return;
    setState(() => _permissionStatus = status);
  }

  void _openSettings() {
    if (_permissionStatus == LocationPermissionStatus.serviceDisabled) {
      unawaited(Geolocator.openLocationSettings());
    } else {
      unawaited(Geolocator.openAppSettings());
    }
  }

  Future<void> _loadUpcoming() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() {
      _isLoadingSchedules = true;
      _scheduleLoadError = null;
    });
    try {
      final now = DateTime.now();
      final apiClient = ref.read(apiClientProvider);
      final medsResponse = await apiClient.get<Map<String, dynamic>>('/dependents/${user.userId}/medications');
      final wellnessResponse = await apiClient.get<Map<String, dynamic>>('/dependents/${user.userId}/wellness-checks');

      final medItems = (medsResponse.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .where((m) => m['active'] == true)
          .toList();
      final wellnessItems = (wellnessResponse.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .where((w) => w['active'] == true)
          .toList();

      final nextMed = earliestUpcoming<Map<String, dynamic>>(
        items: medItems,
        timeOf: (m) => m['time'] as String,
        daysOf: (m) => (m['days'] as List<dynamic>?)?.cast<String>(),
        now: now,
      );
      final nextWellness = earliestUpcoming<Map<String, dynamic>>(
        items: wellnessItems,
        timeOf: (w) => w['time'] as String,
        now: now,
      );

      if (!mounted) return;
      setState(() {
        _nextMedication = nextMed;
        _nextWellnessCheck = nextWellness;
        _isLoadingSchedules = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSchedules = false;
        _scheduleLoadError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final languageCode = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dependentHomeTitle),
        actions: [
          const LanguageSwitchButton(),
          const AccessibilityToggleButton(),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: l10n.switchModeTooltip,
            onPressed: () => context.go('/role-select'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUpcoming,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LocationStatusBanner(status: _permissionStatus, onRetry: _startLocationSharing, onOpenSettings: _openSettings),
            const SizedBox(height: 16),
            Text(l10n.dependentHomeGreeting(user?.fullName ?? ''), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              '${weekdayName(now, languageCode)} · ${formatClockTime(now)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            PanicButton(
              onTap: () => context.push('/dependent/panic'),
              label: l10n.panicButtonLabel,
              subtitle: l10n.panicButtonSubtitle,
            ),
            const SizedBox(height: 16),
            SafetyActionButton(
              onTap: () => context.push('/dependent/wellness-check'),
              label: l10n.iAmOkButtonLabel,
              subtitle: _isLoadingSchedules
                  ? ''
                  : (_nextWellnessCheck != null
                      ? l10n.nextWellnessCheckMessage(formatClockTime(_nextWellnessCheck!.at))
                      : l10n.noWellnessCheckScheduledMessage),
            ),
            const SizedBox(height: 16),
            SafetyActionButton(
              onTap: () => context.push('/dependent/medication'),
              label: l10n.myMedicineButtonLabel,
              subtitle: _isLoadingSchedules
                  ? ''
                  : (_nextMedication != null
                      ? l10n.nextMedicationMessage(_nextMedication!.item['drug_name'] as String, formatClockTime(_nextMedication!.at))
                      : l10n.noMedicationScheduledMessage),
            ),
            if (_scheduleLoadError != null) ...[
              const SizedBox(height: 12),
              Text(_scheduleLoadError!, style: TextStyle(color: Colors.red.shade700)),
            ],
            const SizedBox(height: 24),
            Center(
              child: Text(
                l10n.moreComingSoonLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
