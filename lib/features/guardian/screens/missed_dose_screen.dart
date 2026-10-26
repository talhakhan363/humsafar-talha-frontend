import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 3.14 — mockup 08b, reached only from AlertsScreen tapping a
/// `missed_dose` row's "I've seen it" (see alerts_screen.dart's doc
/// comment). [confirmationId]/[dependentId] identify the dose;
/// [notificationId] is the alert that brought the Guardian here, used to
/// acknowledge it ("tapping any option counts as seen", per the mockup's
/// own footnote and escalation_contract.md rule 4 — acknowledging is what
/// actually stops the chain, not just viewing this screen).
///
/// Drug name/dosage/scheduled time are NOT taken from the push/alert
/// payload — this screen instead re-fetches
/// `GET /dependents/{id}/medication-doses` (medication_contract.md) and
/// finds the matching `confirmation_id`, so the screen works correctly
/// however it's reached and always shows the dose's current state (for
/// example after a "give more time" already moved it back to `pending`
/// elsewhere). If the dose isn't in that list anymore (already taken,
/// or the window reset), the alert has resolved itself — shown as a
/// plain "already resolved" message rather than an error.
///
/// The Guardian's own display name for [dependentId] isn't available from
/// any Task 3.14 contract, so (matching how DependentDetailScreen/
/// GuardianHomeScreen already show a Dependent) this re-fetches
/// `GET /guardians/me/dependents` and matches by id, for the dependent's
/// email (display label) and phone (the "Call" button).
///
/// [launchUrlOverride] exists only for tests: `url_launcher`'s real
/// `launchUrl` talks to a platform MethodChannel, whose behavior in a
/// plain `flutter test` run (no platform registered at all) isn't
/// something this screen can rely on being any particular value —
/// unlike `ApiException`, there's no app-level exception type to force
/// deterministically. Passing a fake here sidesteps that entirely rather
/// than asserting on real platform-channel behavior. Defaults to the
/// real `launchUrl` for production use.
class MissedDoseScreen extends ConsumerStatefulWidget {
  const MissedDoseScreen({
    super.key,
    required this.confirmationId,
    required this.dependentId,
    this.notificationId,
    this.launchUrlOverride,
  });

  final String confirmationId;
  final String dependentId;
  final String? notificationId;
  final Future<bool> Function(Uri uri)? launchUrlOverride;

  @override
  ConsumerState<MissedDoseScreen> createState() => _MissedDoseScreenState();
}

class _MissedDoseScreenState extends ConsumerState<MissedDoseScreen> {
  Map<String, dynamic>? _dose;
  String? _dependentLabel;
  String? _dependentPhone;
  bool _isLoading = true;
  bool _resolved = false;
  String? _loadError;
  bool _isActing = false;
  bool _acknowledged = false;

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
      final dosesResponse =
          await apiClient.get<Map<String, dynamic>>('/dependents/${widget.dependentId}/medication-doses');
      final doses = (dosesResponse.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      final match = doses.where((d) => d['confirmation_id'] == widget.confirmationId);

      final dependentsResponse = await apiClient.get<List<dynamic>>('/guardians/me/dependents');
      final dependents = (dependentsResponse.data ?? []).cast<Map<String, dynamic>>();
      final dependentMatch = dependents.where((d) => d['dependent_id'] == widget.dependentId);

      if (!mounted) return;
      setState(() {
        _dose = match.isEmpty ? null : match.first;
        _resolved = match.isEmpty;
        _dependentLabel = dependentMatch.isEmpty ? null : dependentMatch.first['email'] as String?;
        _dependentPhone = dependentMatch.isEmpty ? null : dependentMatch.first['phone'] as String?;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _messageFor(AppLocalizations l10n, ApiException e) {
    switch (e.code) {
      case 'DOSE_ALREADY_CONFIRMED':
      case 'DOSE_NOT_FOUND':
      case 'NO_OPEN_ALERT':
        return l10n.doseAlreadyResolvedMessage;
      case 'ALREADY_ESCALATED':
        return l10n.alreadyEscalatedMessage;
      default:
        return e.message;
    }
  }

  Future<void> _acknowledgeAlert() async {
    if (_acknowledged || widget.notificationId == null) return;
    _acknowledged = true; // best-effort, don't block/retry the main action over this
    try {
      await ref.read(apiClientProvider).post('/notifications/${widget.notificationId}/acknowledge');
    } on ApiException {
      // best-effort — see class doc comment
    }
  }

  Future<void> _giveMoreTime() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isActing = true);
    try {
      await ref
          .read(apiClientProvider)
          .post('/dependents/${widget.dependentId}/medication-doses/${widget.confirmationId}/extend');
      await _acknowledgeAlert();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.extendSuccessSnackbar)));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_messageFor(l10n, e))));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _escalateNow() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isActing = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .post<Map<String, dynamic>>('/dependents/${widget.dependentId}/medication-doses/${widget.confirmationId}/escalate');
      await _acknowledgeAlert();
      if (!mounted) return;
      final notified = response.data?['notified'] as int? ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(notified == 0 ? l10n.escalateNoSecondarySnackbar : l10n.escalateSuccessSnackbar(notified)),
      ));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_messageFor(l10n, e))));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _callDependent() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _dependentPhone;
    await _acknowledgeAlert();
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    final launchFn = widget.launchUrlOverride ?? launchUrl;
    // Broad catch, not just a `false` return: on a device with no dialer
    // app registered, launchUrl can throw rather than just returning false.
    bool launched = false;
    try {
      launched = await launchFn(uri);
    } catch (_) {
      launched = false;
    }
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.callFailedSnackbar)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.missedDoseScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
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
              ElevatedButton(onPressed: _load, child: Text(l10n.retryButton)),
            ],
          ),
        ),
      );
    }
    if (_resolved || _dose == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(l10n.doseAlreadyResolvedMessage, textAlign: TextAlign.center),
        ),
      );
    }

    final dose = _dose!;
    final name = _dependentLabel ?? widget.dependentId;
    final tier = dose['open_alert_tier'] as String?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: HumsafarColors.warningTint, borderRadius: BorderRadius.circular(8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: HumsafarColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.missedDoseBannerTitle(name, dose['drug_name'] as String? ?? ''),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(dose['dosage'] as String? ?? ''),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.whatHappensNextHeader, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _StepRow(label: l10n.missedDoseStepYouToldLabel, done: true),
                // Default escalation timers (escalation_contract.md's
                // `primary_timeout_s`/`secondary_timeout_s`, 5 min each)
                // shown as fixed labels, not computed clock times — this
                // screen has no `next_escalation_at` without a second call
                // to `GET /dependents/{id}/escalations`, which isn't
                // otherwise needed here.
                _StepRow(label: l10n.missedDoseStepSecondaryLabel, done: tier == 'secondary' || tier == 'external_contact'),
                _StepRow(label: l10n.missedDoseStepSmsLabel, done: tier == 'external_contact'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isActing ? null : _giveMoreTime,
          child: Text(l10n.giveMoreTimeButton),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isActing || tier == 'secondary' || tier == 'external_contact' ? null : _escalateNow,
          child: Text(l10n.tellOtherGuardiansButton),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _dependentPhone == null ? null : _callDependent,
          child: Text(l10n.callButtonLabel(name)),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            l10n.tappingCountsAsSeenNote,
            style: const TextStyle(color: HumsafarColors.muted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: done ? HumsafarColors.success : HumsafarColors.muted,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
