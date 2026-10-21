import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/auth/current_user_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/scheduling/schedule_helpers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 3.13 — the Medication Confirmation screen (mockups 23 "Medicine
/// time — step 1 'I took it'" and 23b "Confirm medicine — step 2 +
/// taken state", FR-F1.3), grounded in `medication_contract.md`'s
/// two-step confirm flow:
///   Step 1: `POST /medications/{schedule_id}/confirm-request` -> a
///   short-lived `confirm_token` (2 minutes).
///   Step 2: `POST /medications/{schedule_id}/confirm` with that token
///   -> the dose is marked taken.
///
/// One screen covers both mockups rather than two separate widgets,
/// because Sarim's Home-screen v0.2 update (2026-10-21, after 3.10
/// shipped) changes which mockup a given entry point lands on:
///   - Opened from Home's medicine button when a dose is currently due,
///     Home already asked "did you take it?" by showing "I took my
///     medicine · Step 1 of 2" — so this screen is told [skipPrompt] =
///     true and immediately fires step 1, landing straight on the
///     step-2 UI (23b). No separate confirmation tap is asked for twice.
///   - Opened any other way (manually, or - once Task 3.14's FCM lands
///     - from a reminder notification), [skipPrompt] is false/absent
///     and the screen shows the step-1 prompt first (23) before firing
///     the same step-1 call.
///
/// Like 3.12's WellnessCheckScreen, this screen self-resolves which
/// dose it's about via `GET /dependents/{id}/medication-doses?status=
/// pending` rather than requiring the exact dose to be passed in - a
/// dose only exists in that list from 15 minutes before it's due
/// (medication_contract.md), and self-resolving means this screen
/// works correctly whether Home linked straight to it or (later) a
/// notification did. If more than one dose is somehow pending at once,
/// the soonest `scheduled_for` wins.
///
/// Named scope cut: the Guardian-side "extend +30 min" action
/// (`POST .../medication-doses/{id}/extend`) noted as an open
/// discussion point in Sarim's 3.9 README is a Guardian action, not a
/// Dependent one - it belongs with Task 3.14's Guardian alert UI, not
/// here.
class MedicationConfirmScreen extends ConsumerStatefulWidget {
  const MedicationConfirmScreen({super.key, this.skipPrompt = false});

  final bool skipPrompt;

  @override
  ConsumerState<MedicationConfirmScreen> createState() => _MedicationConfirmScreenState();
}

enum _Phase { loading, loadError, noneDue, prompt, confirm, taken }

class _MedicationConfirmScreenState extends ConsumerState<MedicationConfirmScreen> {
  _Phase _phase = _Phase.loading;
  String? _loadError;
  bool _isSubmitting = false;

  Map<String, dynamic> _dose = const <String, dynamic>{};
  String? _confirmToken;
  DateTime? _tokenExpiresAt;
  DateTime _now = DateTime.now();
  Timer? _tickTimer;

  String get _dependentId => ref.read(currentUserProvider)!.userId;

  @override
  void initState() {
    super.initState();
    _resolveDose();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _resolveDose() async {
    setState(() {
      _phase = _Phase.loading;
      _loadError = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('/dependents/$_dependentId/medication-doses', queryParameters: {'status': 'pending'});
      final items = (response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      if (items.isEmpty) {
        if (!mounted) return;
        setState(() => _phase = _Phase.noneDue);
        return;
      }
      items.sort((a, b) => (a['scheduled_for'] as String).compareTo(b['scheduled_for'] as String));
      if (!mounted) return;
      setState(() => _dose = items.first);

      if (widget.skipPrompt) {
        await _startConfirm(fromPrompt: false);
      } else {
        setState(() => _phase = _Phase.prompt);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.loadError;
        _loadError = e.message;
      });
    }
  }

  Future<void> _startConfirm({required bool fromPrompt}) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSubmitting = true);
    try {
      final scheduleId = _dose['schedule_id'] as String;
      final confirmationId = _dose['confirmation_id'] as String?;
      final response = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
            '/medications/$scheduleId/confirm-request',
            data: confirmationId == null ? null : {'confirmation_id': confirmationId},
          );
      final data = response.data ?? const <String, dynamic>{};
      final expiresInS = data['expires_in_s'] as int? ?? 120;
      if (!mounted) return;
      _tickTimer?.cancel();
      setState(() {
        _confirmToken = data['confirm_token'] as String?;
        _tokenExpiresAt = DateTime.now().add(Duration(seconds: expiresInS));
        _now = DateTime.now();
        _phase = _Phase.confirm;
      });
      _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (fromPrompt) {
        // The user tapped "I took it" from the step-1 prompt and it
        // failed - keep them on that same prompt so they can just try
        // tapping it again, instead of bouncing them to a generic error
        // screen over a transient failure.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.medicineConfirmRequestFailedSnackbar)));
      } else {
        // Auto-triggered from Home (skipPrompt) with no prompt UI to
        // fall back to - show a real retry affordance instead.
        setState(() {
          _phase = _Phase.loadError;
          _loadError = e.message;
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmTaken() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSubmitting = true);
    try {
      final scheduleId = _dose['schedule_id'] as String;
      await ref.read(apiClientProvider).post<Map<String, dynamic>>(
            '/medications/$scheduleId/confirm',
            data: {'confirm_token': _confirmToken},
          );
      if (!mounted) return;
      _tickTimer?.cancel();
      setState(() => _phase = _Phase.taken);
    } on ApiException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.medicineConfirmFailedSnackbar)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dependent');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTaken = _phase == _Phase.taken;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicationScreenTitle),
        automaticallyImplyLeading: !isTaken,
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    switch (_phase) {
      case _Phase.loading:
        return const Center(child: CircularProgressIndicator());
      case _Phase.loadError:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_loadError ?? '', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _resolveDose, child: Text(l10n.retryButton)),
              ],
            ),
          ),
        );
      case _Phase.noneDue:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(l10n.noMedicineDueMessage, textAlign: TextAlign.center),
          ),
        );
      case _Phase.prompt:
        return _buildPromptView(l10n);
      case _Phase.confirm:
        return _buildConfirmView(l10n);
      case _Phase.taken:
        return _buildTakenView(l10n);
    }
  }

  Widget _buildPromptView(AppLocalizations l10n) {
    final drug = _dose['drug_name'] as String? ?? '';
    final dosage = _dose['dosage'] as String? ?? '';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication, size: 56, color: Colors.teal.shade700),
            const SizedBox(height: 16),
            Text(l10n.medicineTimePromptTitle, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l10n.medicineTimePromptMessage(drug, dosage), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () => _startConfirm(fromPrompt: true),
              child: Text(l10n.medicineTookItButtonLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmView(AppLocalizations l10n) {
    final drug = _dose['drug_name'] as String? ?? '';
    final dosage = _dose['dosage'] as String? ?? '';
    final expiresAt = _tokenExpiresAt;
    final expired = expiresAt != null && !_now.isBefore(expiresAt);
    final remaining = expiresAt == null ? Duration.zero : expiresAt.difference(_now);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 56, color: Colors.teal.shade700),
            const SizedBox(height: 16),
            Text(l10n.medicineConfirmTitle, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l10n.medicineConfirmMessage(drug, dosage), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            if (expired)
              Text(l10n.medicineConfirmExpiredMessage, style: TextStyle(color: Colors.amber.shade900), textAlign: TextAlign.center)
            else
              Chip(label: Text(l10n.medicineConfirmExpiresNote(formatCountdown(remaining)))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : (expired ? () => _startConfirm(fromPrompt: false) : _confirmTaken),
              child: Text(expired ? l10n.medicineTryAgainButtonLabel : l10n.medicineConfirmButtonLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTakenView(AppLocalizations l10n) {
    final drug = _dose['drug_name'] as String? ?? '';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green.shade700),
            const SizedBox(height: 16),
            Text(l10n.medicineTakenTitle, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l10n.medicineTakenMessage(drug), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _goBack, child: Text(l10n.medicineDoneButtonLabel)),
          ],
        ),
      ),
    );
  }
}
