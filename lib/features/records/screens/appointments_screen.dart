import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/formatting/format_helpers.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 5.6 — mockup 15d "Appointments", grounded in
/// `appointment_contract.md`. Upcoming/History tabs (`when=upcoming`/
/// `when=past`), add/edit/cancel/delete, each gated server-side the
/// same "any health-records reader" way as the Medical Vault — no
/// client-side permission pre-check here either, same reasoning as
/// `medication_schedule_screen.dart`.
class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key, required this.dependentId});

  final String dependentId;

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _showUpcoming = true;
  bool _isLoading = true;
  String? _loadError;
  final Set<String> _pendingAction = {};

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
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>(
            '/dependents/${widget.dependentId}/appointments',
            queryParameters: {'when': _showUpcoming ? 'upcoming' : 'past'},
          );
      if (!mounted) return;
      setState(() => _appointments = (response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = _messageFor(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _messageFor(ApiException e) {
    final l10n = AppLocalizations.of(context)!;
    if (e.code == 'MODULE_ACCESS_DENIED') return l10n.healthRecordsAccessDeniedMessage;
    return e.message;
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AppointmentForm(existing: existing),
    );
    if (result == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      if (existing == null) {
        await ref.read(apiClientProvider).post('/dependents/${widget.dependentId}/appointments', data: result);
      } else {
        await ref.read(apiClientProvider).patch(
              '/dependents/${widget.dependentId}/appointments/${existing['appointment_id']}',
              data: result,
            );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.appointmentSavedSnackbar)));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_formMessageFor(l10n, e))));
    }
  }

  String _formMessageFor(AppLocalizations l10n, ApiException e) {
    switch (e.code) {
      case 'APPOINTMENT_IN_PAST':
        return l10n.appointmentInPastError;
      case 'APPOINTMENT_EXISTS':
        return l10n.appointmentExistsError;
      case 'APPOINTMENTS_LIMIT':
        return l10n.appointmentsLimitError;
      case 'APPOINTMENT_CANCELLED':
        return l10n.appointmentCancelledError;
      case 'MODULE_ACCESS_DENIED':
        return l10n.healthRecordsAccessDeniedMessage;
      default:
        return e.message;
    }
  }

  Future<void> _cancel(Map<String, dynamic> appointment) async {
    final appointmentId = appointment['appointment_id'] as String;
    setState(() => _pendingAction.add(appointmentId));
    try {
      await ref
          .read(apiClientProvider)
          .post('/dependents/${widget.dependentId}/appointments/$appointmentId/cancel');
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_formMessageFor(AppLocalizations.of(context)!, e))));
    } finally {
      if (mounted) setState(() => _pendingAction.remove(appointmentId));
    }
  }

  Future<void> _delete(Map<String, dynamic> appointment) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAppointmentConfirmTitle),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancelButton)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.deleteButtonLabel)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final appointmentId = appointment['appointment_id'] as String;
    setState(() => _pendingAction.add(appointmentId));
    try {
      await ref.read(apiClientProvider).delete('/dependents/${widget.dependentId}/appointments/$appointmentId');
      if (!mounted) return;
      setState(() => _appointments.removeWhere((a) => a['appointment_id'] == appointmentId));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _pendingAction.remove(appointmentId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appointmentsScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      floatingActionButton: _showUpcoming
          ? FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add))
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text(l10n.appointmentsUpcomingTabLabel),
                    selected: _showUpcoming,
                    onSelected: (_) {
                      setState(() => _showUpcoming = true);
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text(l10n.appointmentsHistoryTabLabel),
                    selected: !_showUpcoming,
                    onSelected: (_) {
                      setState(() => _showUpcoming = false);
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: RefreshIndicator(onRefresh: _load, child: _buildBody(l10n))),
        ],
      ),
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
    if (_appointments.isEmpty) {
      return Center(
        child: Text(_showUpcoming ? l10n.noUpcomingAppointmentsMessage : l10n.noPastAppointmentsMessage,
            textAlign: TextAlign.center),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _appointments.map((appointment) {
        final appointmentId = appointment['appointment_id'] as String;
        final scheduledAt = DateTime.tryParse(appointment['scheduled_at'] as String? ?? '')?.toLocal();
        final isCancelled = appointment['status'] == 'cancelled';
        final isPending = _pendingAction.contains(appointmentId);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: _showUpcoming && !isCancelled ? () => _openForm(existing: appointment) : null,
            leading: Icon(isCancelled ? Icons.event_busy : Icons.event_outlined),
            title: Text(appointment['provider_name'] as String? ?? ''),
            subtitle: Text(
              scheduledAt == null
                  ? ''
                  : '${formatDateDisplay(scheduledAt, Localizations.localeOf(context).languageCode)} · ${formatClockTimeOf(scheduledAt)}'
                      '${isCancelled ? ' · ${l10n.appointmentCancelledLabel}' : ''}',
            ),
            trailing: isPending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : (_showUpcoming && !isCancelled
                    ? PopupMenuButton<String>(
                        onSelected: (value) => value == 'cancel' ? _cancel(appointment) : _delete(appointment),
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'cancel', child: Text(l10n.cancelAppointmentMenuItem)),
                          PopupMenuItem(value: 'delete', child: Text(l10n.deleteButtonLabel)),
                        ],
                      )
                    : IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(appointment))),
          ),
        );
      }).toList(),
    );
  }
}

/// Small local wrapper so this file doesn't need a second import of
/// `schedule_helpers.dart`'s `formatClockTime` under a conflicting name
/// — kept here rather than in that shared file since it's only ever
/// used on an already-local `DateTime`.
String formatClockTimeOf(DateTime time) {
  final hour24 = time.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = hour24 < 12 ? 'AM' : 'PM';
  return '$hour12:$minute $suffix';
}

class _AppointmentForm extends StatefulWidget {
  const _AppointmentForm({this.existing});

  final Map<String, dynamic>? existing;

  @override
  State<_AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<_AppointmentForm> {
  late final TextEditingController _providerController;
  late final TextEditingController _notesController;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _providerController = TextEditingController(text: existing?['provider_name'] as String? ?? '');
    _notesController = TextEditingController(text: existing?['notes'] as String? ?? '');
    final existingAt = DateTime.tryParse(existing?['scheduled_at'] as String? ?? '')?.toLocal();
    if (existingAt != null) {
      _date = existingAt;
      _time = TimeOfDay(hour: existingAt.hour, minute: existingAt.minute);
    }
  }

  @override
  void dispose() {
    _providerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime.now()) ? DateTime.now() : _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    if (_providerController.text.trim().isEmpty) {
      setState(() => _error = l10n.fieldRequiredError);
      return;
    }
    final scheduledAt = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    Navigator.of(context).pop({
      'provider_name': _providerController.text.trim(),
      'scheduled_at': scheduledAt.toIso8601String(),
      'notes': _notesController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? l10n.addAppointmentTitle : l10n.editAppointmentTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(controller: _providerController, decoration: InputDecoration(labelText: l10n.providerNameFieldLabel)),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.dateFieldLabel),
            trailing: Text(formatDateDisplay(_date, languageCode)),
            onTap: _pickDate,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.timeFieldLabel),
            trailing: Text(formatClockTimeOf(DateTime(2000, 1, 1, _time.hour, _time.minute))),
            onTap: _pickTime,
          ),
          const SizedBox(height: 8),
          TextField(controller: _notesController, decoration: InputDecoration(labelText: l10n.appointmentNotesFieldLabel)),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.red.shade700)),
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
