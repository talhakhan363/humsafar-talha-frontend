import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/guardian/dependent_summary.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 3.14 — mockup 14. Two independent contracts share this one
/// screen because Sarim's mockup put them together: `alarm_contract.md`
/// (remote alarm) and `emergency_contact_contract.md` (external contact).
///
/// Remote alarm is gated purely on `widget.summary.isPrimary` — unlike
/// every permission-flag gate elsewhere in this app (medication/wellness/
/// emergency_alerts), alarm_contract.md is explicit this "cannot be
/// delegated... even if the Primary grants every permission", and its own
/// `GET /dependents/{id}/alarm` is "the Primary, or the Dependent" only —
/// not even a Secondary WITH every permission can call it. So a Secondary
/// here never calls `GET/POST .../alarm` at all (it would just 403); the
/// button area shows the "Primary only" note instead.
///
/// Emergency contact is different: a Secondary with `emergency_alerts`
/// CAN read it (`403 MODULE_ACCESS_DENIED` without that permission), only
/// writing it is Primary-only. Rather than a second `permissions/me`
/// call (the approach the 3.15 schedule screens use, because their GET
/// is open to any Guardian), this screen just attempts the GET and
/// treats a `403 MODULE_ACCESS_DENIED` as "no read access" — the GET
/// itself is already permission-gated server-side, so there's nothing a
/// second check would add.
class EmergencySettingsScreen extends ConsumerStatefulWidget {
  const EmergencySettingsScreen({super.key, required this.summary});

  final DependentSummary summary;

  @override
  ConsumerState<EmergencySettingsScreen> createState() => _EmergencySettingsScreenState();
}

class _EmergencySettingsScreenState extends ConsumerState<EmergencySettingsScreen> {
  bool _isLoading = true;
  bool _alarmActive = false;
  bool _isAlarmActing = false;
  // Bug fix (F-15, QA ICP-3 Results v1.1, step 11): after the alarm's
  // own duration_s/expires_at passes, the server auto-expires it, but
  // this screen never re-checked — "Stop alarm" stayed on screen and
  // tapping it got a 409 NO_ACTIVE_ALARM the UI just showed as a plain
  // "Couldn't stop" failure, leaving the button dead until the screen
  // was closed and reopened. Fix: re-sync with the server at
  // expires_at, and treat NO_ACTIVE_ALARM on stop as "already stopped"
  // rather than an error (see _scheduleAutoRefresh / _toggleAlarm).
  Timer? _autoRefreshTimer;

  Map<String, dynamic>? _contact; // null once loaded + no contact set
  bool _contactDenied = false;
  String? _contactLoadError;
  bool _isContactActing = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// (F-15 fix) Re-check with the server right after the alarm's own
  /// `expires_at` so a stale "Stop alarm" button never outlives the
  /// real alarm. A little slack (1 s) covers clock skew between this
  /// phone and the server.
  void _scheduleAutoRefresh(String? expiresAtIso) {
    _autoRefreshTimer?.cancel();
    final expiresAt = expiresAtIso == null ? null : DateTime.tryParse(expiresAtIso);
    if (expiresAt == null) return;
    final remaining = expiresAt.difference(DateTime.now()) + const Duration(seconds: 1);
    _autoRefreshTimer = Timer(remaining.isNegative ? Duration.zero : remaining, () {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final apiClient = ref.read(apiClientProvider);

    if (widget.summary.isPrimary) {
      try {
        final response = await apiClient.get<Map<String, dynamic>>('/dependents/${widget.summary.dependentId}/alarm');
        if (!mounted) return;
        final isActive = response.data?['active'] as bool? ?? false;
        final alarm = response.data?['alarm'] as Map<String, dynamic>?;
        setState(() => _alarmActive = isActive);
        if (isActive) {
          _scheduleAutoRefresh(alarm?['expires_at'] as String?);
        } else {
          _autoRefreshTimer?.cancel();
        }
      } on ApiException {
        // non-fatal — the Ring/Stop button just won't reflect live state
      }
    }

    try {
      final response =
          await apiClient.get<Map<String, dynamic>>('/dependents/${widget.summary.dependentId}/emergency-contact');
      if (!mounted) return;
      setState(() {
        _contact = response.data;
        _nameController.text = response.data?['name'] as String? ?? '';
        _phoneController.text = response.data?['phone'] as String? ?? '';
        _contactDenied = false;
        _contactLoadError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _contact = null;
        _contactDenied = e.code == 'MODULE_ACCESS_DENIED';
        _contactLoadError = e.code == 'EMERGENCY_CONTACT_NOT_FOUND' || e.code == 'MODULE_ACCESS_DENIED' ? null : e.message;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAlarm() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isAlarmActing = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      if (_alarmActive) {
        await apiClient.post('/dependents/${widget.summary.dependentId}/alarm/stop');
        _autoRefreshTimer?.cancel();
      } else {
        final response =
            await apiClient.post<Map<String, dynamic>>('/dependents/${widget.summary.dependentId}/alarm');
        if (response.data?['already_active'] == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.alarmAlreadyActiveMessage)));
        }
        // (F-15 fix) schedule the re-check for whenever this alarm
        // (new or already-active) actually expires, instead of just
        // flipping a local bool that never gets re-verified.
        _scheduleAutoRefresh(response.data?['expires_at'] as String?);
      }
      if (!mounted) return;
      setState(() => _alarmActive = !_alarmActive);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Bug fix (F-15): the alarm already auto-expired server-side
      // (409 NO_ACTIVE_ALARM) between this screen showing "Stop alarm"
      // and the tap landing — that is not a failure, it is the normal
      // end of the alarm the auto-refresh above should usually have
      // already caught. Reflect reality instead of showing an error on
      // a button that was, correctly, trying to stop a finished alarm.
      if (_alarmActive && e.code == 'NO_ACTIVE_ALARM') {
        _autoRefreshTimer?.cancel();
        setState(() => _alarmActive = false);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_alarmActive ? l10n.alarmStopFailedSnackbar : l10n.alarmStartFailedSnackbar),
      ));
    } finally {
      if (mounted) setState(() => _isAlarmActing = false);
    }
  }

  Future<void> _saveContact() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isContactActing = true);
    try {
      final response = await ref.read(apiClientProvider).put<Map<String, dynamic>>(
            '/dependents/${widget.summary.dependentId}/emergency-contact',
            data: {'name': _nameController.text.trim(), 'phone': _phoneController.text.trim()},
          );
      if (!mounted) return;
      setState(() => _contact = response.data);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.contactSavedSnackbar)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.code == 'VALIDATION_ERROR' ? e.message : l10n.contactSaveFailedSnackbar)));
    } finally {
      if (mounted) setState(() => _isContactActing = false);
    }
  }

  Future<void> _removeContact() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isContactActing = true);
    try {
      await ref.read(apiClientProvider).delete('/dependents/${widget.summary.dependentId}/emergency-contact');
      if (!mounted) return;
      setState(() {
        _contact = null;
        _nameController.clear();
        _phoneController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.contactRemovedSnackbar)));
    } on ApiException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.contactRemoveFailedSnackbar)));
    } finally {
      if (mounted) setState(() => _isContactActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emergencySettingsScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      // Bug fix (2026-10-30): bottom-nav-bar overlap, see vitals_screen.dart.
      body: SafeArea(
        bottom: true,
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(onRefresh: _load, child: _buildBody(l10n)),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final isPrimary = widget.summary.isPrimary;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.remoteAlarmSectionTitle, style: Theme.of(context).textTheme.titleMedium),
                    Chip(label: Text(l10n.primaryOnlyBadge), visualDensity: VisualDensity.compact),
                  ],
                ),
                const SizedBox(height: 8),
                Text(l10n.remoteAlarmDescription(widget.summary.email)),
                const SizedBox(height: 16),
                if (isPrimary)
                  ElevatedButton(
                    onPressed: _isAlarmActing ? null : _toggleAlarm,
                    // Still red on purpose while active — this mirrors a
                    // live remote alarm actually ringing on the
                    // Dependent's phone, a critical state, not a plain
                    // error (fix #2, Design Handoff v1.0 section 3).
                    // Bug fix (F-14): ElevatedButton's default
                    // foreground on an overridden backgroundColor was
                    // the theme's dark-red text colour, not a
                    // button-default white — label landed dark red on
                    // red, well under 4.5:1. HumsafarColors.surface is
                    // pure white, >7:1 on HumsafarColors.danger.
                    style: _alarmActive
                        ? ElevatedButton.styleFrom(
                            backgroundColor: HumsafarColors.danger,
                            foregroundColor: HumsafarColors.surface,
                          )
                        : null,
                    child: Text(_alarmActive ? l10n.stopAlarmButton : l10n.ringAlarmButton),
                  )
                else
                  Text(l10n.notPrimaryGuardianNote, style: const TextStyle(color: HumsafarColors.muted)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.emergencyContactSectionTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(l10n.emergencyContactDescription, style: const TextStyle(color: HumsafarColors.muted)),
        const SizedBox(height: 12),
        if (_contactDenied)
          Text(l10n.emergencyContactDeniedNote, style: const TextStyle(color: HumsafarColors.muted))
        else if (_contactLoadError != null) ...[
          Text(_contactLoadError!, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _load, child: Text(l10n.retryButton)),
        ] else if (!isPrimary) ...[
          if (_contact == null)
            Text(l10n.noEmergencyContactMessage)
          else
            Card(
              child: ListTile(
                title: Text(_contact!['name'] as String? ?? ''),
                subtitle: Text(_contact!['phone'] as String? ?? ''),
              ),
            ),
        ] else ...[
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.contactNameFieldLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: l10n.contactPhoneFieldLabel),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isContactActing ? null : _saveContact,
            child: Text(l10n.saveContactButton),
          ),
          if (_contact != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isContactActing ? null : _removeContact,
              child: Text(l10n.removeContactButton),
            ),
          ],
        ],
      ],
    );
  }
}
