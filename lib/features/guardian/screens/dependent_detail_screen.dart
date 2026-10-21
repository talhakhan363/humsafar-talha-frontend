import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/guardian/dependent_summary.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// New screen for Task 2.5 Step E. Shows who is linked to a Dependent
/// (GET /dependents/{id}/guardians, linkage_contract.md section 2) and the
/// role-gated next actions: a Primary can invite a Secondary or manage
/// permissions; a Secondary can view their own access.
///
/// Task 3.15 (2026-10-21): added the "Medication schedule" and
/// "Wellness check schedule" buttons. Both sit outside the
/// Primary/Secondary branch below (unlike Invite/Permissions, which are
/// Primary-only) because both contracts say "any Guardian can read" —
/// a Secondary can always open these screens to see the schedule; the
/// screens themselves gate whether that Secondary can also edit it.
///
/// Task 3.14 (2026-10-21): added "Emergency settings" (mockup 14), same
/// placement reasoning as the two buttons above — `emergency_contact_
/// contract.md`'s GET is readable by a Secondary with `emergency_alerts`,
/// so this isn't Primary-only at the navigation level either; the
/// Remote Alarm half of that screen (Primary-only, no exceptions, per
/// `alarm_contract.md`) is gated inside emergency_settings_screen.dart.
///
/// Task 4.6 (2026-10-22): added "Message" — same placement reasoning
/// again (`messaging_contract.md`: "the Primary can always talk; a
/// Secondary needs the `communication` permission", not Primary-only at
/// the navigation level; `ChatScreen` itself attempts the send and maps
/// a `403 MODULE_ACCESS_DENIED` rather than this screen pre-checking).
/// Goes straight to `ChatScreen` with this Dependent as the peer,
/// skipping the Messages inbox entirely — the peer is already known
/// here, so there's nothing the inbox would add.
class DependentDetailScreen extends ConsumerStatefulWidget {
  const DependentDetailScreen({super.key, required this.summary});

  final DependentSummary summary;

  @override
  ConsumerState<DependentDetailScreen> createState() => _DependentDetailScreenState();
}

class _DependentDetailScreenState extends ConsumerState<DependentDetailScreen> {
  List<Map<String, dynamic>>? _guardians;
  String? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGuardians();
  }

  Future<void> _loadGuardians() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<List<dynamic>>('/dependents/${widget.summary.dependentId}/guardians');
      if (!mounted) return;
      setState(() => _guardians = (response.data ?? []).cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _kycStatusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'pending':
        return l10n.kycStatusPending;
      case 'verified':
        return l10n.kycStatusVerified;
      case 'failed':
        return l10n.kycStatusFailed;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(summary.email),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: RefreshIndicator(
        onRefresh: _loadGuardians,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.yourRoleLabel} ${summary.isPrimary ? l10n.primaryGuardianFullLabel : l10n.secondaryGuardianFullLabel}',
                    ),
                    Text('${l10n.kycStatusColonLabel} ${_kycStatusLabel(l10n, summary.kycStatus)}'),
                    Text('${l10n.accountActiveColonLabel} ${summary.accountActive ? l10n.yesLabel : l10n.notYetLabel}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.linkedGuardiansHeader, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_loadError != null) Text(_loadError!),
            if (_guardians != null)
              ..._guardians!.map(
                (guardian) => Card(
                  child: ListTile(
                    leading: Icon(guardian['guardian_role'] == 'primary' ? Icons.shield : Icons.visibility),
                    title: Text(guardian['email'] as String? ?? ''),
                    subtitle: Text(
                      '${guardian['guardian_role'] == 'primary' ? l10n.primaryGuardianFullLabel : l10n.secondaryGuardianFullLabel} · '
                      '${(guardian['verified'] as bool? ?? false) ? l10n.verifiedLabel : l10n.notVerifiedLabel}',
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Viewing location is Primary-always / Secondary-with-permission
            // (location_contract.md, geofence_contract.md) - not Primary-only
            // like Invite/Permissions below, so this sits outside that branch.
            ElevatedButton.icon(
              onPressed: () => context.push('/guardian/live-map', extra: summary),
              icon: const Icon(Icons.map_outlined),
              label: Text(l10n.liveMapButton),
            ),
            const SizedBox(height: 12),
            // Task 4.6 — same "any Guardian can attempt, the screen gates
            // the actual write" shape as Live Map above.
            ElevatedButton.icon(
              onPressed: () => context.push('/messages/chat', extra: {'peerId': summary.dependentId, 'peerName': summary.email}),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(l10n.messageButtonLabel),
            ),
            const SizedBox(height: 12),
            // Task 3.15 — same "any Guardian can read, permission only
            // gates editing" shape as Live Map above, so these two also
            // sit outside the Primary/Secondary branch.
            ElevatedButton.icon(
              onPressed: () => context.push('/guardian/medication-schedule', extra: summary),
              icon: const Icon(Icons.medication_outlined),
              label: Text(l10n.medicationScheduleButton),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.push('/guardian/wellness-schedule', extra: summary),
              icon: const Icon(Icons.health_and_safety_outlined),
              label: Text(l10n.wellnessScheduleButton),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.push('/guardian/emergency-settings', extra: summary),
              icon: const Icon(Icons.emergency_outlined),
              label: Text(l10n.emergencySettingsButton),
            ),
            const SizedBox(height: 12),
            if (summary.isPrimary) ...[
              ElevatedButton.icon(
                onPressed: () => context.push('/guardian/invite-secondary', extra: summary.dependentId),
                icon: const Icon(Icons.person_add_alt),
                label: Text(l10n.inviteASecondaryButton),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.push('/guardian/permissions', extra: summary.dependentId),
                icon: const Icon(Icons.admin_panel_settings),
                label: Text(l10n.managePermissionsButton),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: () => context.push('/guardian/my-access', extra: summary.dependentId),
                icon: const Icon(Icons.lock_outline),
                label: Text(l10n.myAccessButton),
              ),
          ],
        ),
      ),
    );
  }
}
