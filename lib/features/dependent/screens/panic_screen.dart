import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/auth/current_user_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/scheduling/schedule_helpers.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../widgets/panic_hold_button.dart';

/// Task 3.11 — the Panic Mode screen (mockup screens 21 "Panic" and 21b
/// "Help is coming"), `panic_contract.md` (Task 3.6, FR-D2).
///
/// **Named deviation from Sarim's 21b mockup, grounded in the contract:**
/// the mockup shows a per-Guardian list with individual "Seen"/"Told"
/// chips for named people ("Ali (son)", "Sara (daughter)", ...). Neither
/// `POST /dependents/{id}/panic` nor `GET /dependents/{id}/panic` returns
/// anything at that granularity — only a `notified` count and a single
/// `acknowledged_at` timestamp for the whole event (whichever Guardian
/// opens it first stops the chain for everyone, per
/// `escalation_contract.md` point 4 — "acknowledge" is per-event, not
/// per-Guardian-per-event in the response shape). Building the named-list
/// UI would mean inventing data the backend doesn't provide. This screen
/// shows the honest version instead: "We told N Guardian(s)" plus one
/// acknowledged state. Flagged for Sarim/Abdullah — if per-Guardian
/// acknowledgment ever becomes real, read-back data, this screen can be
/// upgraded to match 21b exactly.
///
/// **Named correction, also contract-grounded:** the mockup's "If nobody
/// answers in 10 minutes..." note doesn't match the real timer.
/// `escalation_contract.md` documents `primary_timeout_s: 300` (5
/// minutes), and Panic already tells every Guardian in one shot, so a
/// missed panic goes straight from `primary` to `external_contact` after
/// that single 5-minute window (no separate secondary wait — the
/// contract's point 5: "a level with nobody new to tell is skipped", and
/// everyone was already told). This screen says "5 minutes", not "10" —
/// the real configured default. If Abdullah's `.env` ever changes
/// `ESCALATION_PRIMARY_TIMEOUT_S`, this static copy will drift; there's
/// no endpoint a Dependent can read that value from
/// (`GET /dependents/{id}/escalations` is Guardian-only per its
/// contract), so this is a known, accepted limitation, not a bug to chase
/// down now.
///
/// Always re-checks real status on open (`GET /dependents/{id}/panic`)
/// rather than assuming idle — handles the double-tap-safe case
/// (`already_active`) honestly, same reasoning as `LiveMapScreen` always
/// re-fetching instead of trusting stale state. While a panic is active,
/// this screen also polls the same endpoint every 15s so the
/// acknowledged/escalated state stays current without the Dependent
/// having to back out and re-open the screen.
class PanicScreen extends ConsumerStatefulWidget {
  const PanicScreen({super.key});

  @override
  ConsumerState<PanicScreen> createState() => _PanicScreenState();
}

enum _Phase { checking, checkError, idle, triggering, active }

class _PanicScreenState extends ConsumerState<PanicScreen> {
  static const _refreshInterval = Duration(seconds: 15);

  _Phase _phase = _Phase.checking;
  String? _checkErrorMessage;
  Map<String, dynamic>? _panic;
  bool _isResolving = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String get _dependentId => ref.read(currentUserProvider)!.userId;

  Future<void> _checkStatus() async {
    setState(() {
      _phase = _Phase.checking;
      _checkErrorMessage = null;
    });
    try {
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/dependents/$_dependentId/panic');
      final active = response.data?['active'] as bool? ?? false;
      final panic = response.data?['panic'] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _panic = active ? panic : null;
        _phase = active ? _Phase.active : _Phase.idle;
      });
      _manageRefreshTimer();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.checkError;
        _checkErrorMessage = _messageFor(e);
      });
    }
  }

  void _manageRefreshTimer() {
    _refreshTimer?.cancel();
    if (_phase == _Phase.active) {
      _refreshTimer = Timer.periodic(_refreshInterval, (_) => _refreshActive());
    }
  }

  Future<void> _refreshActive() async {
    try {
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/dependents/$_dependentId/panic');
      final active = response.data?['active'] as bool? ?? false;
      if (!mounted) return;
      if (!active) {
        setState(() {
          _panic = null;
          _phase = _Phase.idle;
        });
        _refreshTimer?.cancel();
      } else {
        setState(() => _panic = response.data?['panic'] as Map<String, dynamic>?);
      }
    } on ApiException {
      // Silent: this is a background refresh while the screen is already
      // showing the active state. The next tick tries again; a hard
      // failure already would have surfaced on the initial check.
    }
  }

  Future<void> _triggerPanic() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _phase = _Phase.triggering);
    try {
      final response = await ref.read(apiClientProvider).post<Map<String, dynamic>>('/dependents/$_dependentId/panic');
      if (!mounted) return;
      setState(() {
        _panic = response.data;
        _phase = _Phase.active;
      });
      _manageRefreshTimer();
    } on ApiException {
      if (!mounted) return;
      setState(() => _phase = _Phase.idle);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.panicTriggerFailedSnackbar)));
    }
  }

  Future<void> _resolvePanic() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isResolving = true);
    try {
      await ref.read(apiClientProvider).post<Map<String, dynamic>>('/dependents/$_dependentId/panic/resolve');
      if (!mounted) return;
      _refreshTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.panicResolvedSnackbar)));
      _goBack();
    } on ApiException {
      if (!mounted) return;
      setState(() => _isResolving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.panicResolveFailedSnackbar)));
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dependent');
    }
  }

  String _messageFor(ApiException e) {
    final l10n = AppLocalizations.of(context)!;
    switch (e.code) {
      case 'NOT_LINKED_TO_DEPENDENT':
        return l10n.notLinkedToDependentError;
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = _phase == _Phase.active;

    return Scaffold(
      appBar: AppBar(
        title: Text(isActive ? l10n.panicHelpIsComingTitle : l10n.panicScreenTitle),
        automaticallyImplyLeading: !isActive,
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      // Bug fix (2026-10-30): bottom-nav-bar overlap, see vitals_screen.dart.
      body: SafeArea(bottom: true, top: false, child: _buildBody(l10n)),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    switch (_phase) {
      case _Phase.checking:
        return const Center(child: CircularProgressIndicator());
      case _Phase.checkError:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_checkErrorMessage ?? '', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _checkStatus, child: Text(l10n.retryButton)),
              ],
            ),
          ),
        );
      case _Phase.idle:
      case _Phase.triggering:
        return _buildHoldView(l10n);
      case _Phase.active:
        return _buildActiveView(l10n);
    }
  }

  Widget _buildHoldView(AppLocalizations l10n) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.panicNeedHelpTitle, style: textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l10n.panicHoldInstructions, style: textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            PanicHoldButton(
              label: l10n.panicHoldButtonLabel,
              subtitle: l10n.panicHoldButtonSubtitle,
              enabled: _phase == _Phase.idle,
              onHoldComplete: _triggerPanic,
            ),
            if (_phase == _Phase.triggering) ...[
              const SizedBox(height: 12),
              Text(l10n.panicSendingLabel, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: 32),
            Text(l10n.panicAllGuardiansToldNote, style: textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              l10n.panicHoldStopsAccidentNote,
              style: textTheme.bodyMedium?.copyWith(color: HumsafarColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _phase == _Phase.idle ? _goBack : null,
              child: Text(l10n.cancelButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveView(AppLocalizations l10n) {
    final textTheme = Theme.of(context).textTheme;
    final panic = _panic ?? const <String, dynamic>{};
    final notified = panic['notified'] as int? ?? 0;
    final triggeredAtRaw = panic['triggered_at'] as String?;
    final acknowledgedAtRaw = panic['acknowledged_at'] as String?;
    final tier = panic['tier'] as String?;

    final triggeredAt = triggeredAtRaw != null ? DateTime.tryParse(triggeredAtRaw)?.toLocal() : null;
    final acknowledgedAt = acknowledgedAtRaw != null ? DateTime.tryParse(acknowledgedAtRaw)?.toLocal() : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Fixed 2026-10-25 — Design Handoff v1.0 fix #6: this whole view
          // used to lean on red (icon, title, escalation note), but by the
          // time a Dependent sees "help is coming" the Panic has already
          // been sent — mockup 21b uses calm colours here, keeping red only
          // on the hold-to-trigger button (_buildHoldView, untouched by
          // this fix). A checkmark reads as reassurance, so it's styled
          // with the success token rather than danger.
          const Icon(Icons.check_circle, color: HumsafarColors.success, size: 96),
          const SizedBox(height: 16),
          Text(
            l10n.panicHelpIsComingTitle,
            style: textTheme.headlineSmall?.copyWith(color: HumsafarColors.success, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(l10n.panicToldCountMessage(notified), style: textTheme.titleMedium, textAlign: TextAlign.center),
          if (triggeredAt != null)
            Text(
              l10n.panicTriggeredAtMessage(formatClockTime(triggeredAt)),
              style: textTheme.bodyMedium?.copyWith(color: HumsafarColors.muted),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          Text(
            acknowledgedAt != null
                ? l10n.panicAcknowledgedAtMessage(formatClockTime(acknowledgedAt))
                : l10n.panicWaitingForAckMessage,
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (tier == 'external_contact') ...[
            const SizedBox(height: 8),
            // Still amber, not red — this view stays calm throughout per
            // fix #6; an escalation note here is a status update, not a
            // new Panic trigger.
            Text(
              l10n.panicEscalatedMessage,
              style: textTheme.bodyLarge?.copyWith(color: HumsafarColors.warning, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.panicAutoEscalateNote,
            style: textTheme.bodySmall?.copyWith(color: HumsafarColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isResolving ? null : _resolvePanic,
              child: _isResolving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.iAmSafeNowButton),
            ),
          ),
        ],
      ),
    );
  }
}
