import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 6.8 — mockup 18d "Activity log", grounded in
/// `booking_contract.md`'s `GET .../activity`. One timeline per
/// Dependent covering every organization contact and booking step,
/// newest first. Tapping a booking-type entry opens a detail sheet
/// covering mockup 18e's "Visit request" content (status, who asked,
/// Call, Confirm/Complete/Cancel) — see `directory_screen.dart`'s doc
/// comment for why this is a sheet here instead of a fifth route.
class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key, required this.dependentId});

  final String dependentId;

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  String? _loadError;

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
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/dependents/${widget.dependentId}/activity');
      if (!mounted) return;
      setState(() => _entries = (response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openBookingDetail(Map<String, dynamic> entry) async {
    final requestId = entry['reference_id'] as String?;
    if (requestId == null) return;
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('/dependents/${widget.dependentId}/bookings/$requestId');
      if (!mounted) return;
      final changed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _BookingDetailSheet(dependentId: widget.dependentId, booking: response.data!),
      );
      if (changed == true) _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _typeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'org_contact':
        return l10n.activityOrgContact;
      case 'booking_requested':
        return l10n.activityBookingRequested;
      case 'booking_confirmed':
        return l10n.activityBookingConfirmed;
      case 'booking_completed':
        return l10n.activityBookingCompleted;
      case 'booking_cancelled':
        return l10n.activityBookingCancelled;
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activityLogScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
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
    if (_entries.isEmpty) return Center(child: Text(l10n.noActivityMessage, textAlign: TextAlign.center));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _entries.map((entry) {
        final type = entry['type'] as String? ?? '';
        final isBooking = type.startsWith('booking_');
        final initiatedBy = entry['initiated_by'] as Map<String, dynamic>?;
        final occurredAt = DateTime.tryParse(entry['occurred_at'] as String? ?? '')?.toLocal();
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: isBooking ? () => _openBookingDetail(entry) : null,
            leading: Icon(type == 'org_contact' ? Icons.call_outlined : Icons.event_note_outlined),
            title: Text('${_typeLabel(l10n, type)} · ${entry['subject_name'] as String? ?? ''}'),
            subtitle: Text(
              '${initiatedBy?['full_name'] as String? ?? ''}'
              '${occurredAt == null ? '' : ' · ${occurredAt.hour.toString().padLeft(2, '0')}:${occurredAt.minute.toString().padLeft(2, '0')}'}',
            ),
            trailing: isBooking ? const Icon(Icons.chevron_right) : null,
          ),
        );
      }).toList(),
    );
  }
}

class _BookingDetailSheet extends ConsumerStatefulWidget {
  const _BookingDetailSheet({required this.dependentId, required this.booking});

  final String dependentId;
  final Map<String, dynamic> booking;

  @override
  ConsumerState<_BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends ConsumerState<_BookingDetailSheet> {
  bool _isActing = false;

  Future<void> _act(String action) async {
    setState(() => _isActing = true);
    try {
      await ref
          .read(apiClientProvider)
          .post('/dependents/${widget.dependentId}/bookings/${widget.booking['request_id']}/$action');
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.code == 'BOOKING_STATUS_CONFLICT' ? l10n.bookingStatusConflictMessage : e.message)),
      );
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final booking = widget.booking;
    final status = booking['status'] as String? ?? '';
    final contact = booking['contact'] as String?;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking['provider_name'] as String? ?? '', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Chip(label: Text(_statusLabel(l10n, status))),
            const SizedBox(height: 8),
            Text('${l10n.requestedByLabel}: ${booking['requested_by_name'] as String? ?? ''}'),
            if ((booking['note'] as String?)?.isNotEmpty == true) Text(booking['note'] as String),
            const SizedBox(height: 16),
            if (contact != null)
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri(scheme: 'tel', path: contact);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                icon: const Icon(Icons.call),
                label: Text(l10n.callToArrangeButtonLabel),
              ),
            const SizedBox(height: 12),
            if (_isActing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  if (status == 'pending')
                    Expanded(
                      child: ElevatedButton(onPressed: () => _act('confirm'), child: Text(l10n.confirmBookingButtonLabel)),
                    ),
                  if (status == 'confirmed')
                    Expanded(
                      child: ElevatedButton(onPressed: () => _act('complete'), child: Text(l10n.completeBookingButtonLabel)),
                    ),
                  if (status == 'pending' || status == 'confirmed') const SizedBox(width: 12),
                  if (status == 'pending' || status == 'confirmed')
                    Expanded(
                      child: OutlinedButton(onPressed: () => _act('cancel'), child: Text(l10n.cancelBookingButtonLabel)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'pending':
        return l10n.bookingStatusPending;
      case 'confirmed':
        return l10n.bookingStatusConfirmed;
      case 'completed':
        return l10n.bookingStatusCompleted;
      case 'cancelled':
        return l10n.bookingStatusCancelled;
      default:
        return status;
    }
  }
}
