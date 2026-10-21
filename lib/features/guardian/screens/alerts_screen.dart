import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/scheduling/schedule_helpers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../notification_display.dart';

/// Task 3.14 — the cross-Dependent notification inbox (mockup 08),
/// grounded in `notification_contract.md`'s `GET /notifications` /
/// `POST /notifications/{id}/acknowledge`. Deliberately NOT scoped to one
/// `DependentSummary` like the Live Map / schedule screens — the inbox
/// itself is one list per Guardian covering every linked Dependent, so
/// this screen takes no constructor args and reads `/notifications`
/// exactly as the contract describes it.
///
/// Open/Seen tabs: one `GET /notifications?priority=critical` call loads
/// every critical notification (the contract's example response shows
/// `is_acknowledged` on each item either way), then "Open" and "Seen"
/// are just a client-side filter on that one field — simpler than two
/// separate requests, and there's no server-side "acknowledged=true"
/// filter to ask for anyway (only `unacknowledged=true` exists, as the
/// convenience the home-screen badge count uses). Standard (all-clear)
/// notifications are not shown here at all: they're not something a
/// Guardian needs to act on, and mockup 08 only ever shows actionable
/// critical rows.
///
/// Tapping "I've seen it" on a `missed_dose` row opens the Missed dose
/// screen (mockup 08b) with everything that screen needs taken straight
/// from this row's own fields (`notification_id`, `data.confirmation_id`,
/// `dependent_id`) — not re-fetched — so the two screens share one
/// source of truth for which alert is which. Every other type's
/// "I've seen it" just acknowledges in place; there's no deeper screen
/// for geofence/battery/offline/wellness_check/panic/external_contact yet
/// (flagged in the delivery notes as an open item, same as the other
/// named scope cuts this task made).
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  List<Map<String, dynamic>> _open = [];
  List<Map<String, dynamic>> _seen = [];
  bool _showOpenTab = true;
  bool _isLoading = true;
  String? _loadError;
  final Set<String> _pendingAck = {};

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
            '/notifications',
            queryParameters: {'priority': 'critical'},
          );
      if (!mounted) return;
      final items = (response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      setState(() {
        _open = items.where((n) => n['is_acknowledged'] != true).toList();
        _seen = items.where((n) => n['is_acknowledged'] == true).toList();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acknowledge(Map<String, dynamic> notification) async {
    final notificationId = notification['notification_id'] as String;
    setState(() => _pendingAck.add(notificationId));
    try {
      await ref.read(apiClientProvider).post('/notifications/$notificationId/acknowledge');
      if (!mounted) return;
      _load();
      if (notification['type'] == 'missed_dose') {
        final data = notification['data'] as Map<String, dynamic>? ?? {};
        final confirmationId = data['confirmation_id'] as String?;
        final dependentId = notification['dependent_id'] as String?;
        if (confirmationId != null && dependentId != null) {
          context.push('/guardian/missed-dose', extra: {
            'confirmationId': confirmationId,
            'dependentId': dependentId,
            'notificationId': notificationId,
          });
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message.isEmpty
          ? AppLocalizations.of(context)!.acknowledgeFailedSnackbar
          : e.message)));
    } finally {
      if (mounted) setState(() => _pendingAck.remove(notificationId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.alertsScreenTitle),
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
    final rows = _showOpenTab ? _open : _seen;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Text(l10n.alertsOpenTabLabel(_open.length)),
                  selected: _showOpenTab,
                  onSelected: (_) => setState(() => _showOpenTab = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Text(l10n.alertsSeenTabLabel),
                  selected: !_showOpenTab,
                  onSelected: (_) => setState(() => _showOpenTab = false),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    _showOpenTab ? l10n.alertsEmptyOpenMessage : l10n.alertsEmptySeenMessage,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  children: [
                    ...rows.map((n) => _AlertCard(
                          notification: n,
                          showAckButton: _showOpenTab,
                          isPending: _pendingAck.contains(n['notification_id']),
                          onAcknowledge: () => _acknowledge(n),
                        )),
                    if (_showOpenTab && _open.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Card(
                        color: Colors.teal.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.seenStopsChainTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(l10n.seenStopsChainBody),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.notification,
    required this.showAckButton,
    required this.isPending,
    required this.onAcknowledge,
  });

  final Map<String, dynamic> notification;
  final bool showAckButton;
  final bool isPending;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = notification['type'] as String? ?? '';
    final visuals = alertVisualsFor(type);
    final data = notification['data'] as Map<String, dynamic>? ?? {};
    final tierBadge = tierBadgeLabel(l10n, data['tier'] as String?);
    final sentAt = DateTime.tryParse(notification['sent_at'] as String? ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: visuals.color, width: 4)),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(visuals.icon, color: visuals.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alertTypeLabel(l10n, type),
                    style: TextStyle(fontWeight: FontWeight.bold, color: visuals.color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              sentAt == null ? (notification['body'] as String? ?? '') : formatClockTime(sentAt.toLocal()),
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (tierBadge != null) ...[
              const SizedBox(height: 8),
              Chip(label: Text(tierBadge), visualDensity: VisualDensity.compact),
            ],
            if (showAckButton) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: isPending ? null : onAcknowledge,
                  child: isPending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.iveSeenItButton),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
