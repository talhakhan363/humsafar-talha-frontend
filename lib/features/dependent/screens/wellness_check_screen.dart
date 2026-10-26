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

/// Task 3.12 — the Wellness Check response screen (mockup screen 22
/// "Wellness check" / "Are you OK?"), `wellness_contract.md` (Task 3.4,
/// FR-D4).
///
/// **Named scope decision:** the mockup assumes entry from a push
/// notification carrying a live `response_id` (that's Task 3.14's FCM
/// work, not built yet). Until then, Home's "I am OK" button opens this
/// screen with nothing extra attached, so it looks up whichever wellness
/// check is currently `pending` for the Dependent themself
/// (`GET /dependents/{id}/wellness-check-responses?status=pending`,
/// allowed per the contract's "Read checks and history" row — the
/// Dependent can read their own) and answers that one. If more than one
/// is somehow pending, the one with the soonest `deadline` is shown — the
/// mockup only has room for one card, and in practice at most one check
/// is normally open at a time. If none are pending (the Dependent opened
/// this screen on their own, not from a prompt), the screen says so
/// plainly instead of showing a countdown for something that doesn't
/// exist.
///
/// Per Sarim's 3.9 design note, "Wellness 'I need help' opens the Panic
/// screen (no separate endpoint needed)" — that button is always
/// available here, independent of whether a check is pending.
class WellnessCheckScreen extends ConsumerStatefulWidget {
  const WellnessCheckScreen({super.key});

  @override
  ConsumerState<WellnessCheckScreen> createState() => _WellnessCheckScreenState();
}

enum _Phase { loading, loadError, noPending, pending, responding }

class _WellnessCheckScreenState extends ConsumerState<WellnessCheckScreen> {
  _Phase _phase = _Phase.loading;
  String? _loadErrorMessage;
  Map<String, dynamic>? _response;
  Timer? _tickTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  String get _dependentId => ref.read(currentUserProvider)!.userId;

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _loadErrorMessage = null;
    });
    try {
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>(
        '/dependents/$_dependentId/wellness-check-responses',
        queryParameters: {'status': 'pending'},
      );
      final items = (response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      if (items.isEmpty) {
        setState(() {
          _response = null;
          _phase = _Phase.noPending;
        });
        return;
      }
      items.sort((a, b) {
        final deadlineA = DateTime.tryParse(a['deadline'] as String? ?? '') ?? DateTime(9999);
        final deadlineB = DateTime.tryParse(b['deadline'] as String? ?? '') ?? DateTime(9999);
        return deadlineA.compareTo(deadlineB);
      });
      setState(() {
        _response = items.first;
        _phase = _Phase.pending;
      });
      _tickTimer?.cancel();
      _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.loadError;
        _loadErrorMessage = _messageFor(e);
      });
    }
  }

  Future<void> _respond() async {
    final l10n = AppLocalizations.of(context)!;
    final responseId = _response?['response_id'] as String?;
    if (responseId == null) return;
    setState(() => _phase = _Phase.responding);
    try {
      await ref.read(apiClientProvider).post<Map<String, dynamic>>('/wellness-checks/$responseId/respond');
      if (!mounted) return;
      _tickTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.wellnessCheckRespondedSnackbar)));
      _goBack();
    } on ApiException {
      if (!mounted) return;
      setState(() => _phase = _Phase.pending);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.wellnessCheckRespondFailedSnackbar)));
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dependent');
    }
  }

  void _openPanic() => context.push('/dependent/panic');

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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.wellnessCheckScreenTitle),
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_loadErrorMessage ?? '', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _load, child: Text(l10n.retryButton)),
              ],
            ),
          ),
        );
      case _Phase.noPending:
        return _buildActions(l10n, header: Text(l10n.noWellnessCheckPendingMessage, textAlign: TextAlign.center));
      case _Phase.pending:
      case _Phase.responding:
        return _buildPendingView(l10n);
    }
  }

  Widget _buildPendingView(AppLocalizations l10n) {
    final deadlineRaw = _response?['deadline'] as String?;
    final deadline = deadlineRaw != null ? DateTime.tryParse(deadlineRaw)?.toLocal() : null;
    final remaining = deadline?.difference(_now);
    final isOverdue = remaining != null && remaining.isNegative;

    return _buildActions(
      l10n,
      header: Column(
        children: [
          Text(l10n.areYouOkTitle, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            l10n.familyCheckingOnYouMessage,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (remaining != null) Chip(label: Text(l10n.answerWithinMessage(formatCountdown(remaining)))),
          if (isOverdue) ...[
            const SizedBox(height: 8),
            Text(
              l10n.wellnessCheckTimeUpNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HumsafarColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(AppLocalizations l10n, {required Widget header}) {
    final isPending = _phase == _Phase.pending || _phase == _Phase.responding;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          header,
          const SizedBox(height: 32),
          if (isPending)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _phase == _Phase.responding ? null : _respond,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HumsafarColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(80),
                ),
                child: _phase == _Phase.responding
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        l10n.yesIAmOkButton,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _openPanic,
              style: OutlinedButton.styleFrom(
                // Fix #2 (Design Handoff v1.0, section 3): tokenized, kept
                // red on purpose — per Sarim's 3.9 design note, this
                // button always opens the Panic screen directly, so it
                // falls under the handoff's "red for Panic" rule rather
                // than the "errors/warnings on Dependent screens are
                // never red" one (this isn't an error, it's a Panic entry
                // point).
                foregroundColor: HumsafarColors.danger,
                side: const BorderSide(color: HumsafarColors.danger, width: 2),
                minimumSize: const Size.fromHeight(80),
              ),
              child: Text(
                l10n.iNeedHelpButton,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: HumsafarColors.danger),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.iNeedHelpOpensPanicNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HumsafarColors.muted),
            textAlign: TextAlign.center,
          ),
          Text(
            l10n.noAnswerGuardianToldNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HumsafarColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
