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
import '../widgets/camera_viewing_banner.dart';
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
/// Panic / "I am OK" route to their real destinations (Tasks 3.11/3.12).
///
/// Task 3.13 (medicine button, mockup 20 v0.2, Sarim 2026-10-21):
/// alongside the schedule-based "next dose" lookup above, this screen
/// also checks `GET .../medication-doses?status=pending` — the
/// *currently due* dose, if any exists right now. When one does, the
/// button itself becomes the first half of the dual confirmation:
/// its label switches to "I took my medicine · Step 1 of 2" and tapping
/// it opens MedicationConfirmScreen with `skipPrompt: true`, which
/// immediately fires step 1 and lands straight on the step-2 UI
/// (mockup 23b) — matching NFR-07's "every safety action within 2 taps
/// from Home." When nothing is currently due, the button falls back to
/// its previous behaviour: generic label + the schedule-based "next
/// dose" subtitle, opening the screen with nothing attached (it
/// self-resolves, same as before — see MedicationConfirmScreen's doc
/// comment). Mockup 23 (the step-1 prompt) is still reachable this way
/// and will also be reachable from Task 3.14's FCM reminder once that
/// ships.
///
/// Task 4.6 (2026-10-22): added a fourth action button, "Messages"
/// (mockup 20's "More" area graduates its first real destination out of
/// the placeholder footer — see the test case log's resolved note on
/// this), with a best-effort unread-count subtitle from
/// `GET /messages/conversations`'s own `total_unread`. Deliberately a
/// `SafetyActionButton` like "I am OK"/"My medicine" rather than a
/// smaller link, matching mockup 25's "one big row" sizing rule for
/// Dependent screens (NFR-07/22-38px text, 96-200px buttons) — messaging
/// a Guardian is a normal, frequent action here, not a rare "more"
/// destination.
///
/// Not automated-tested as a full screen, same reasoning as the old
/// placeholder: `_startLocationSharing` calls through to the real
/// Geolocator plugin, which has no platform channel under `flutter
/// test`. What IS tested without a device: `schedule_helpers.dart`'s
/// pure scheduling math, `PanicButton`/`SafetyActionButton`'s rendering,
/// and the real Panic/Wellness/Medication/Messages screens' own test
/// files.
///
/// Task 6.9 (2026-10-22): added `CameraViewingBanner` (FR-K1.3's
/// always-visible "a Guardian is watching" notice, mockup 29) right
/// below the location banner — both are passive status rows, so they
/// read as one group. It's its own `ConsumerStatefulWidget` with its own
/// test file precisely so adding it here doesn't touch this screen's
/// existing "not automated-tested as a full screen" situation.
///
/// Screen 05 fix (2026-10-22): added a 5th "More" row, "My ID", opening
/// the same `ShareIdScreen` the KYC outcome view now also opens — a
/// Dependent may need to share their ID again later (e.g. for a second
/// Guardian invite), not just once right after registration.
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
  Map<String, dynamic>? _duePendingDose;
  int _unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLocationSharing();
    _loadUpcoming();
    _loadUnreadMessages();
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
      final dueDosesResponse = await apiClient.get<Map<String, dynamic>>(
        '/dependents/${user.userId}/medication-doses',
        queryParameters: {'status': 'pending'},
      );

      final medItems = (medsResponse.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .where((m) => m['active'] == true)
          .toList();
      final wellnessItems = (wellnessResponse.data?['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .where((w) => w['active'] == true)
          .toList();
      final dueDoses = (dueDosesResponse.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>()
        ..sort((a, b) => (a['scheduled_for'] as String).compareTo(b['scheduled_for'] as String));

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
        _duePendingDose = dueDoses.isEmpty ? null : dueDoses.first;
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

  /// Best-effort, same reasoning as the schedule load above but never
  /// allowed to block it: a Dependent with no conversations yet, or
  /// temporarily offline, still sees Home normally. `MessagesScreen` is
  /// the real inbox — this is only a count.
  Future<void> _loadUnreadMessages() async {
    try {
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/messages/conversations');
      if (!mounted) return;
      setState(() => _unreadMessages = response.data?['total_unread'] as int? ?? 0);
    } on ApiException {
      // best-effort, see doc comment above
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadUpcoming(), _loadUnreadMessages()]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final languageCode = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final doseDue = _duePendingDose;

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
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LocationStatusBanner(status: _permissionStatus, onRetry: _startLocationSharing, onOpenSettings: _openSettings),
            if (user != null) CameraViewingBanner(dependentId: user.userId),
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
              onTap: () => doseDue != null
                  ? context.push('/dependent/medication', extra: true)
                  : context.push('/dependent/medication'),
              label: doseDue != null ? l10n.medicineStep1OfTwoLabel : l10n.myMedicineButtonLabel,
              subtitle: doseDue != null
                  ? ''
                  : (_isLoadingSchedules
                      ? ''
                      : (_nextMedication != null
                          ? l10n.nextMedicationMessage(_nextMedication!.item['drug_name'] as String, formatClockTime(_nextMedication!.at))
                          : l10n.noMedicationScheduledMessage)),
            ),
            const SizedBox(height: 16),
            SafetyActionButton(
              onTap: () => context.push('/messages'),
              label: l10n.messagesButtonLabel,
              subtitle: _unreadMessages > 0 ? l10n.unreadMessagesSubtitle(_unreadMessages) : '',
            ),
            if (_scheduleLoadError != null) ...[
              const SizedBox(height: 12),
              Text(_scheduleLoadError!, style: TextStyle(color: Colors.red.shade700)),
            ],
            const SizedBox(height: 24),
            // Tasks 5.6/5.7/5.8/6.8 (2026-10-22): the first four real
            // destinations to graduate out of this "More" footer (same
            // move 4.6's Messages button already made) — a Dependent's
            // own records/vitals/band/directory, each opening the exact
            // same role-neutral screen a Guardian reaches via
            // DependentDetailScreen, just with `user.userId` as the
            // dependentId instead of a linked Dependent's.
            Text(l10n.moreSectionHeader, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            if (user != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_shared_outlined),
                title: Text(l10n.medicalRecordsButton),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/records', extra: {'dependentId': user.userId, 'canManageAccess': false}),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.monitor_heart_outlined),
                title: Text(l10n.vitalsButton),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/vitals', extra: user.userId),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.watch_outlined),
                title: Text(l10n.wearableBandButton),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/wearable', extra: user.userId),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.local_hospital_outlined),
                title: Text(l10n.directoryButton),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/directory', extra: user.userId),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.qr_code),
                title: Text(l10n.myIdMenuLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/dependent/share-id', extra: user.userId),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
