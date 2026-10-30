import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/formatting/format_helpers.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 6.8 — mockup 18c "Request a visit", grounded in
/// `booking_contract.md`. "Nothing is sent to the provider" — the
/// contract is explicit this is only a note of intent the family
/// keeps; after it saves, the provider's `contact` is shown with a
/// Call button, same `tel:` pattern as `directory_screen.dart`.
class RequestVisitScreen extends ConsumerStatefulWidget {
  const RequestVisitScreen({super.key, required this.dependentId, required this.provider});

  final String dependentId;
  final Map<String, dynamic> provider;

  @override
  ConsumerState<RequestVisitScreen> createState() => _RequestVisitScreenState();
}

class _RequestVisitScreenState extends ConsumerState<RequestVisitScreen> {
  final _noteController = TextEditingController();
  DateTime? _preferredAt;
  bool _isSaving = false;
  String? _error;
  Map<String, dynamic>? _created;
  // Bug fix (2026-10-30, Sarim's G-01): this was a hand-rolled
  // timestamp+random string, not a real UUID, so the backend's safe-retry
  // check 422'd every visit request.
  final String _clientId = const Uuid().v4();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPreferredAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
    if (time == null) return;
    setState(() => _preferredAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final note = _noteController.text.trim();
    if (note.length > 300) {
      setState(() => _error = l10n.noteTooLongError);
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final response = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
            '/dependents/${widget.dependentId}/bookings',
            data: {
              'provider_id': widget.provider['provider_id'],
              // Bug fix (2026-10-30, Sarim's G-02): `_preferredAt` is a
              // LOCAL DateTime (built from showDatePicker/showTimePicker,
              // no `.toUtc()` applied). Calling `.toIso8601String()`
              // directly on a local DateTime produces a string with no
              // 'Z'/offset at all — e.g. "2026-11-05T14:30:00.000" for
              // 2:30 PM Pakistan time — so the backend has no way to
              // know which time zone that wall-clock time is in.
              // `.toUtc()` first both makes the zone explicit (adds the
              // trailing 'Z') and sends the correct UTC instant for what
              // the Guardian actually picked, instead of the ambiguous
              // raw local clock value.
              if (_preferredAt != null) 'preferred_at': _preferredAt!.toUtc().toIso8601String(),
              if (note.isNotEmpty) 'note': note,
              'client_id': _clientId,
            },
          );
      if (!mounted) return;
      setState(() {
        _created = response.data;
        _isSaving = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = _messageFor(l10n, e);
      });
    }
  }

  String _messageFor(AppLocalizations l10n, ApiException e) {
    switch (e.code) {
      case 'BOOKING_ALREADY_OPEN':
        return l10n.bookingAlreadyOpenError;
      case 'TOO_MANY_OPEN_BOOKINGS':
        return l10n.tooManyOpenBookingsError;
      case 'MODULE_ACCESS_DENIED':
        return l10n.healthRecordsAccessDeniedMessage;
      case 'VALIDATION_ERROR':
        return l10n.recordValidationErrorMessage;
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.requestVisitScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      // Bug fix (2026-10-30): bottom-nav-bar overlap, see vitals_screen.dart.
      body: SafeArea(
        bottom: true,
        top: false,
        child: _created != null ? _buildSuccess(l10n) : _buildForm(l10n, languageCode),
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n, String languageCode) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(widget.provider['name'] as String? ?? '', style: Theme.of(context).textTheme.titleMedium),
        Text(
          '${widget.provider['specialization'] as String? ?? ''} · '
          '${formatPkrOrAsk(widget.provider['service_charge'] as num?, l10n.askForPriceLabel)}',
        ),
        const SizedBox(height: 8),
        Text(l10n.nothingSentToProviderNote, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.preferredTimeFieldLabel),
          subtitle: _preferredAt == null
              ? Text(l10n.noPreferenceLabel)
              : Text(formatDateDisplay(_preferredAt!, languageCode)),
          trailing: TextButton(onPressed: _pickPreferredAt, child: Text(l10n.pickTimeButtonLabel)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(labelText: l10n.visitNoteFieldLabel),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: HumsafarColors.warning)),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.saveRequestButtonLabel),
        ),
      ],
    );
  }

  Widget _buildSuccess(AppLocalizations l10n) {
    final contact = _created?['contact'] as String?;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 48, color: HumsafarColors.success),
            const SizedBox(height: 12),
            Text(l10n.visitRequestSavedMessage, textAlign: TextAlign.center),
            if (contact != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri(scheme: 'tel', path: contact);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                icon: const Icon(Icons.call),
                label: Text(l10n.callToArrangeButtonLabel),
              ),
            ],
            const SizedBox(height: 16),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.doneButtonLabel)),
          ],
        ),
      ),
    );
  }
}
