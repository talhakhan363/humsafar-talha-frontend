import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/guardian/dependent_summary.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/scheduling/schedule_helpers.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 3.15 — Guardian-side wellness check schedule configuration (the
/// second of the two screens for this task; see
/// medication_schedule_screen.dart for the other and for the shared
/// reasoning on permission handling / why no Sarim mockup applies).
///
/// Grounded in wellness_contract.md:
///   GET  /dependents/{id}/wellness-checks?include_inactive=true
///   POST /dependents/{id}/wellness-checks  — req `times` (1–3 "HH:MM"
///        strings) + `grace_period_min`; adds to the existing schedule
///        rather than replacing it (errors `WELLNESS_LIMIT_REACHED` at
///        4+ total, `WELLNESS_TIME_EXISTS` on a duplicate time) — so
///        this screen's "add" form posts exactly one new time at a
///        time, matching that incremental semantics rather than trying
///        to resend the whole list.
///   POST /dependents/{id}/wellness-checks/default-schedule — the
///        08:00/14:00/20:00 @ 30 min convenience shortcut; only offered
///        while the schedule is empty, since calling it with an
///        existing schedule just 409s (`SCHEDULE_ALREADY_EXISTS`) for
///        no benefit.
///   PUT  /dependents/{id}/wellness-checks/{wc_id} — time /
///        grace_period_min / active.
/// `DELETE .../wellness-checks/{wc_id}` exists too but is the same
/// soft-off `PUT {active: false}` already gives, so (as in the
/// medication screen) this uses one Active switch rather than two
/// controls for the same effect.
class WellnessScheduleScreen extends ConsumerStatefulWidget {
  const WellnessScheduleScreen({super.key, required this.summary});

  final DependentSummary summary;

  @override
  ConsumerState<WellnessScheduleScreen> createState() => _WellnessScheduleScreenState();
}

class _WellnessScheduleScreenState extends ConsumerState<WellnessScheduleScreen> {
  List<Map<String, dynamic>> _schedules = [];
  int _defaultGraceMinutes = 30;
  bool _canManage = false;
  bool _isLoading = true;
  String? _loadError;
  final Set<String> _pendingToggle = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get<Map<String, dynamic>>(
        '/dependents/${widget.summary.dependentId}/wellness-checks',
        queryParameters: {'include_inactive': true},
      );
      var canManage = widget.summary.isPrimary;
      if (!canManage) {
        final permsResponse =
            await apiClient.get<Map<String, dynamic>>('/dependents/${widget.summary.dependentId}/permissions/me');
        final modules = permsResponse.data?['modules'] as Map<String, dynamic>? ?? {};
        canManage = modules['emergency_alerts'] == true;
      }
      if (!mounted) return;
      setState(() {
        _schedules = (response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        _defaultGraceMinutes = response.data?['default_grace_period_min'] as int? ?? 30;
        _canManage = canManage;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> schedule, bool active) async {
    final wcId = schedule['wc_id'] as String;
    setState(() {
      _pendingToggle.add(wcId);
      schedule['active'] = active; // optimistic
    });
    try {
      await ref
          .read(apiClientProvider)
          .put('/dependents/${widget.summary.dependentId}/wellness-checks/$wcId', data: {'active': active});
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => schedule['active'] = !active); // revert
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_messageFor(e))));
    } finally {
      if (mounted) setState(() => _pendingToggle.remove(wcId));
    }
  }

  String _messageFor(ApiException e) {
    final l10n = AppLocalizations.of(context)!;
    switch (e.code) {
      case 'MODULE_ACCESS_DENIED':
        return l10n.wellnessManagementDeniedNote;
      case 'WELLNESS_LIMIT_REACHED':
        return l10n.wellnessLimitReachedError;
      case 'WELLNESS_TIME_EXISTS':
        return l10n.wellnessTimeExistsError;
      default:
        return e.message;
    }
  }

  Future<void> _useDefaultSchedule() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(apiClientProvider)
          .post('/dependents/${widget.summary.dependentId}/wellness-checks/default-schedule');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.scheduleSavedSnackbar)));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_messageFor(e))));
    }
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _WellnessScheduleForm(existing: existing, defaultGraceMinutes: _defaultGraceMinutes),
    );
    if (result == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      if (existing == null) {
        await ref.read(apiClientProvider).post(
              '/dependents/${widget.summary.dependentId}/wellness-checks',
              data: {'times': [result['time']], 'grace_period_min': result['grace_period_min']},
            );
      } else {
        await ref.read(apiClientProvider).put(
              '/dependents/${widget.summary.dependentId}/wellness-checks/${existing['wc_id']}',
              data: {'time': result['time'], 'grace_period_min': result['grace_period_min']},
            );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.scheduleSavedSnackbar)));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      final fallback = existing == null ? l10n.scheduleSaveFailedSnackbar : l10n.scheduleUpdateFailedSnackbar;
      final mapped = _messageFor(e);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mapped == e.message ? fallback : mapped)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.wellnessScheduleScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      floatingActionButton:
          _canManage ? FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)) : null,
      // Bug fix (2026-10-30): bottom-nav-bar overlap, see vitals_screen.dart.
      body: SafeArea(bottom: true, top: false, child: RefreshIndicator(onRefresh: _load, child: _buildBody(l10n))),
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
              ElevatedButton(onPressed: _load, child: Text(l10n.retryButton)),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!_canManage)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(l10n.wellnessManagementDeniedNote, style: const TextStyle(color: HumsafarColors.muted)),
          ),
        if (_schedules.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l10n.noWellnessSchedulesMessage, textAlign: TextAlign.center),
          ),
          if (_canManage)
            Center(
              child: OutlinedButton(onPressed: _useDefaultSchedule, child: Text(l10n.useDefaultScheduleButton)),
            ),
        ] else
          ..._schedules.map((schedule) {
            final wcId = schedule['wc_id'] as String;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: _canManage ? () => _openForm(existing: schedule) : null,
                title: Text(formatHHMM(schedule['time'] as String)),
                subtitle: Text(l10n.gracePeriodMinutesMessage(schedule['grace_period_min'] as int)),
                trailing: Switch(
                  value: schedule['active'] as bool? ?? true,
                  onChanged: !_canManage || _pendingToggle.contains(wcId)
                      ? null
                      : (value) => _toggleActive(schedule, value),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _WellnessScheduleForm extends StatefulWidget {
  const _WellnessScheduleForm({this.existing, required this.defaultGraceMinutes});

  final Map<String, dynamic>? existing;
  final int defaultGraceMinutes;

  @override
  State<_WellnessScheduleForm> createState() => _WellnessScheduleFormState();
}

class _WellnessScheduleFormState extends State<_WellnessScheduleForm> {
  late TimeOfDay _time;
  late final TextEditingController _graceController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _time = const TimeOfDay(hour: 8, minute: 0);
    if (existing != null) {
      final parts = (existing['time'] as String?)?.split(':');
      if (parts != null && parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) _time = TimeOfDay(hour: h, minute: m);
      }
    }
    _graceController = TextEditingController(
      text: (existing?['grace_period_min'] as int? ?? widget.defaultGraceMinutes).toString(),
    );
  }

  @override
  void dispose() {
    _graceController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final grace = int.tryParse(_graceController.text.trim()) ?? widget.defaultGraceMinutes;
    final timeStr = '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    Navigator.of(context).pop({'time': timeStr, 'grace_period_min': grace});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeStr = '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? l10n.addWellnessCheckTitle : l10n.editWellnessCheckTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.timeFieldLabel),
            trailing: Text(formatHHMM(timeStr)),
            onTap: _pickTime,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _graceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.gracePeriodFieldLabel),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancelButton))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: _save, child: Text(l10n.saveButtonLabel))),
            ],
          ),
        ],
      ),
    );
  }
}
