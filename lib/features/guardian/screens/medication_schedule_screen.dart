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

/// Task 3.15 — Guardian-side medication schedule configuration (one of
/// the two screens for this task; see wellness_schedule_screen.dart for
/// the other). No Sarim mockup exists for this task ("No Sarim
/// dependency" per the task list), so this is a plain list-plus-form
/// screen, styled consistently with permissions_dashboard_screen.dart
/// and my_access_screen.dart rather than following a specific design.
///
/// Grounded in medication_contract.md:
///   GET    /dependents/{id}/medications?include_inactive=true
///   POST   /dependents/{id}/medications
///   PUT    /dependents/{id}/medications/{schedule_id}
/// `DELETE .../medications/{schedule_id}` exists too but has the exact
/// same effect as `PUT {active: false}` (both are a soft-off per the
/// contract) — this screen uses one Active switch for that rather than
/// a second control that does the same thing under a different name.
///
/// Permission model (same contract): "any Guardian can read", so the
/// list always loads for Primary and Secondary alike; only
/// create/edit/toggle need `medication_management`. Rather than
/// duplicating permission logic client-side as a security boundary,
/// this follows live_map_screen.dart's established pattern — attempt
/// the write, map a MODULE_ACCESS_DENIED failure to a clear message.
/// It also checks `GET /dependents/{id}/permissions/me` up front (the
/// same call my_access_screen.dart already makes) purely so a
/// Secondary without the permission sees a read-only screen instead of
/// tapping "Add" only to be told no afterwards — a UX nicety, not the
/// real gate (the backend remains that).
class MedicationScheduleScreen extends ConsumerStatefulWidget {
  const MedicationScheduleScreen({super.key, required this.summary});

  final DependentSummary summary;

  @override
  ConsumerState<MedicationScheduleScreen> createState() => _MedicationScheduleScreenState();
}

class _MedicationScheduleScreenState extends ConsumerState<MedicationScheduleScreen> {
  List<Map<String, dynamic>> _schedules = [];
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
        '/dependents/${widget.summary.dependentId}/medications',
        queryParameters: {'include_inactive': true},
      );
      var canManage = widget.summary.isPrimary;
      if (!canManage) {
        final permsResponse =
            await apiClient.get<Map<String, dynamic>>('/dependents/${widget.summary.dependentId}/permissions/me');
        final modules = permsResponse.data?['modules'] as Map<String, dynamic>? ?? {};
        canManage = modules['medication_management'] == true;
      }
      if (!mounted) return;
      setState(() {
        _schedules = (response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
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
    final scheduleId = schedule['schedule_id'] as String;
    setState(() {
      _pendingToggle.add(scheduleId);
      schedule['active'] = active; // optimistic
    });
    try {
      await ref.read(apiClientProvider).put(
            '/dependents/${widget.summary.dependentId}/medications/$scheduleId',
            data: {'active': active},
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => schedule['active'] = !active); // revert
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_messageFor(e))));
    } finally {
      if (mounted) setState(() => _pendingToggle.remove(scheduleId));
    }
  }

  String _messageFor(ApiException e) {
    final l10n = AppLocalizations.of(context)!;
    if (e.code == 'MODULE_ACCESS_DENIED') return l10n.medicationManagementDeniedNote;
    return e.message;
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MedicationScheduleForm(existing: existing),
    );
    if (result == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      if (existing == null) {
        await ref.read(apiClientProvider).post('/dependents/${widget.summary.dependentId}/medications', data: result);
      } else {
        await ref.read(apiClientProvider).put(
              '/dependents/${widget.summary.dependentId}/medications/${existing['schedule_id']}',
              data: result,
            );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.scheduleSavedSnackbar)));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      final fallback = existing == null ? l10n.scheduleSaveFailedSnackbar : l10n.scheduleUpdateFailedSnackbar;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.code == 'MODULE_ACCESS_DENIED' ? _messageFor(e) : fallback)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicationScheduleScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      floatingActionButton:
          _canManage ? FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)) : null,
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(l10n)),
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
            child: Text(l10n.medicationManagementDeniedNote, style: const TextStyle(color: HumsafarColors.muted)),
          ),
        if (_schedules.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(l10n.noMedicationSchedulesMessage, textAlign: TextAlign.center),
          )
        else
          ..._schedules.map((schedule) {
            final scheduleId = schedule['schedule_id'] as String;
            final days = (schedule['days'] as List<dynamic>?)?.cast<String>() ?? const <String>[];
            final frequencyLabel = schedule['frequency'] == 'weekly'
                ? '${l10n.weeklyLabel} (${days.map((d) => weekdayShortLabel(l10n, d)).join(', ')})'
                : l10n.dailyLabel;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: _canManage ? () => _openForm(existing: schedule) : null,
                title: Text('${schedule['drug_name']} · ${schedule['dosage']}'),
                subtitle: Text('${formatHHMM(schedule['time'] as String)} · $frequencyLabel'),
                trailing: Switch(
                  value: schedule['active'] as bool? ?? true,
                  onChanged: !_canManage || _pendingToggle.contains(scheduleId)
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

/// Localized short label for one of `schedule_helpers.dart`'s
/// `weekdayAbbreviations` ("mon".."sun") — shared by both this screen's
/// list view and its add/edit form below, and by
/// wellness_schedule_screen.dart's analogous day display if it ever
/// needs one (it currently doesn't — wellness checks have no `days`
/// field in the contract, only medication schedules do).
String weekdayShortLabel(AppLocalizations l10n, String day) {
  switch (day) {
    case 'mon':
      return l10n.dayMonLabel;
    case 'tue':
      return l10n.dayTueLabel;
    case 'wed':
      return l10n.dayWedLabel;
    case 'thu':
      return l10n.dayThuLabel;
    case 'fri':
      return l10n.dayFriLabel;
    case 'sat':
      return l10n.daySatLabel;
    case 'sun':
      return l10n.daySunLabel;
    default:
      return day;
  }
}

class _MedicationScheduleForm extends StatefulWidget {
  const _MedicationScheduleForm({this.existing});

  final Map<String, dynamic>? existing;

  @override
  State<_MedicationScheduleForm> createState() => _MedicationScheduleFormState();
}

class _MedicationScheduleFormState extends State<_MedicationScheduleForm> {
  late final TextEditingController _drugController;
  late final TextEditingController _dosageController;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  String _frequency = 'daily';
  final Set<String> _days = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _drugController = TextEditingController(text: existing?['drug_name'] as String? ?? '');
    _dosageController = TextEditingController(text: existing?['dosage'] as String? ?? '');
    if (existing != null) {
      final timeStr = existing['time'] as String?;
      final parts = timeStr?.split(':');
      if (parts != null && parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) _time = TimeOfDay(hour: h, minute: m);
      }
      _frequency = existing['frequency'] as String? ?? 'daily';
      _days.addAll((existing['days'] as List<dynamic>?)?.cast<String>() ?? const <String>[]);
    }
  }

  @override
  void dispose() {
    _drugController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    if (_drugController.text.trim().isEmpty || _dosageController.text.trim().isEmpty) {
      setState(() => _error = l10n.fieldRequiredError);
      return;
    }
    if (_frequency == 'weekly' && _days.isEmpty) {
      setState(() => _error = l10n.weeklyDaysRequiredError);
      return;
    }
    final timeStr = '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    Navigator.of(context).pop({
      'drug_name': _drugController.text.trim(),
      'dosage': _dosageController.text.trim(),
      'time': timeStr,
      'frequency': _frequency,
      if (_frequency == 'weekly') 'days': _days.toList(),
    });
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
            widget.existing == null ? l10n.addMedicationScheduleTitle : l10n.editMedicationScheduleTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(controller: _drugController, decoration: InputDecoration(labelText: l10n.drugNameFieldLabel)),
          const SizedBox(height: 12),
          TextField(controller: _dosageController, decoration: InputDecoration(labelText: l10n.dosageFieldLabel)),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.timeFieldLabel),
            trailing: Text(formatHHMM(timeStr)),
            onTap: _pickTime,
          ),
          const SizedBox(height: 4),
          Text(l10n.frequencyFieldLabel, style: Theme.of(context).textTheme.bodyMedium),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.dailyLabel),
                  value: 'daily',
                  groupValue: _frequency,
                  onChanged: (value) => setState(() => _frequency = value!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.weeklyLabel),
                  value: 'weekly',
                  groupValue: _frequency,
                  onChanged: (value) => setState(() => _frequency = value!),
                ),
              ),
            ],
          ),
          if (_frequency == 'weekly') ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: weekdayAbbreviations.map((day) {
                final selected = _days.contains(day);
                return FilterChip(
                  label: Text(weekdayShortLabel(l10n, day)),
                  selected: selected,
                  onSelected: (value) => setState(() => value ? _days.add(day) : _days.remove(day)),
                );
              }).toList(),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: HumsafarColors.warning)),
          ],
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
