import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/guardian/dependent_summary.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/scheduling/schedule_helpers.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../notification_display.dart';

/// Task 1.8/1.11 built this as a static placeholder. Task 2.5 Step E wires
/// it to the real GET /guardians/me/dependents (linkage_contract.md
/// section 2) - the Dependent switcher FR-B4 asks for.
///
/// New screens reachable from here (link a Dependent, invite a Secondary,
/// manage/view permissions, accept an invite as an existing Secondary) are
/// their own new files - see dependent_detail_screen.dart,
/// link_dependent_screen.dart, invite_secondary_screen.dart,
/// permissions_dashboard_screen.dart, my_access_screen.dart, and
/// accept_invite_screen.dart.
///
/// Task 2.5 Step F closed the l10n gap this class comment used to flag:
/// every string on this screen and the linkage/permissions screens below
/// it now has an app_en.arb/app_ur.arb key pair, including the dynamic
/// kyc_status value mapped in [_kycStatusLabel].
///
/// Task 3.14 (2026-10-21) adds mockup 07's panic banner and "Needs
/// attention" alerts preview, both grounded in the same cross-Dependent
/// `GET /notifications?priority=critical&unacknowledged=true` AlertsScreen
/// uses, loaded alongside the dependent list. Two named scope cuts from
/// the mockup, flagged here rather than silently dropped:
///
/// 1. This screen still lists every linked Dependent (Task 2.5's original
///    design) rather than becoming mockup 07's single-Dependent switcher
///    with per-Dependent battery/last-active/safe-zone status tiles.
///    Those three tiles need a per-Dependent "current status" summary
///    (live battery reading, last location fix, geofence state) that no
///    Task 3.14 contract provides in one cross-Dependent call — building
///    it would mean a `GET` per Dependent card (N+1) or a new backend
///    summary endpoint, both bigger than this task's push/alerts scope.
///    A full single-Dependent Home redesign is left as a follow-up item.
/// 2. No Home-level "Map / Call / Alarm / Camera" quick-actions row
///    either, for the same reason: those actions need a *selected*
///    Dependent, which this list-based Home doesn't have. Map and the
///    new Emergency settings (Alarm) action are both already one tap away
///    on DependentDetailScreen; Camera has no screen built in any task
///    yet.
///
/// Task 4.6 (2026-10-22) adds a Messages icon in the AppBar (mockup 07's
/// own bottom-nav "Chat" tab, built here as an AppBar action instead
/// since this app has no bottom-nav shell at all — see
/// `app_router.dart`'s Task 4.6 doc comment) with a best-effort unread
/// badge from `GET /messages/conversations`'s own `total_unread`, loaded
/// the same best-effort way as the alerts preview below: a Guardian
/// offline or with zero conversations still sees their Dependent list
/// normally.
class GuardianHomeScreen extends ConsumerStatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  ConsumerState<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends ConsumerState<GuardianHomeScreen> {
  List<DependentSummary>? _dependents;
  String? _loadError;
  bool _isLoading = true;
  List<Map<String, dynamic>> _criticalAlerts = [];
  int _unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    _loadDependents();
    _loadAlerts();
    _loadUnreadMessages();
  }

  Future<void> _loadDependents() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final response = await ref.read(apiClientProvider).get<List<dynamic>>('/guardians/me/dependents');
      final list =
          (response.data ?? []).map((e) => DependentSummary.fromJson(e as Map<String, dynamic>)).toList();
      if (!mounted) return;
      setState(() => _dependents = list);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Best-effort, deliberately silent on failure: a Guardian with no
  /// alerts (or offline) should still see their Dependent list normally.
  /// [AlertsScreen] is the real inbox with its own retry UI — this is
  /// only a preview.
  Future<void> _loadAlerts() async {
    try {
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>(
            '/notifications',
            queryParameters: {'priority': 'critical', 'unacknowledged': true, 'limit': 10},
          );
      if (!mounted) return;
      setState(() => _criticalAlerts = (response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
    } on ApiException {
      // best-effort, see doc comment above
    }
  }

  /// Same best-effort reasoning as [_loadAlerts], for the Messages icon's
  /// badge (Task 4.6). `MessagesScreen` is the real inbox — this is only
  /// a count.
  Future<void> _loadUnreadMessages() async {
    try {
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/messages/conversations');
      if (!mounted) return;
      setState(() => _unreadMessages = response.data?['total_unread'] as int? ?? 0);
    } on ApiException {
      // best-effort, see doc comment above
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadDependents(), _loadAlerts(), _loadUnreadMessages()]);
  }

  Future<void> _linkDependent() async {
    final linked = await context.push<bool>('/guardian/link-dependent');
    if (linked == true) _loadDependents();
  }

  // Bug fix (2026-10-28, found live during ICP-1 step 23 - see
  // dependent_home_screen.dart's matching doc comment for the full
  // story): no screen in the app had a real logout button, even though
  // AuthRepository.logout() was already fully built and correct. Wired
  // up here as an AppBar icon next to the existing dev-only swap_horiz
  // button, since this screen has no "More" list to put it in instead.
  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).logout();
    if (mounted) context.go('/login');
  }

  String? _emailFor(String? dependentId) {
    if (dependentId == null) return null;
    final match = (_dependents ?? []).where((d) => d.dependentId == dependentId);
    return match.isEmpty ? null : match.first.email;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.guardianAppTitle),
        actions: [
          const LanguageSwitchButton(),
          const AccessibilityToggleButton(),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: l10n.messagesScreenTitle,
                onPressed: () => context.push('/messages'),
              ),
              if (_unreadMessages > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(color: HumsafarColors.danger, shape: BoxShape.circle),
                    child: Text(
                      '$_unreadMessages',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: l10n.switchModeTooltip,
            onPressed: () => context.go('/role-select'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logoutButton,
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _refreshAll, child: _buildBody()),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'accept-invite',
            onPressed: () => context.push('/invitations/accept'),
            icon: const Icon(Icons.mail_outline),
            label: Text(l10n.haveInviteCodeButton),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'link-dependent',
            onPressed: _linkDependent,
            icon: const Icon(Icons.person_add),
            label: Text(l10n.linkADependentLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadDependents, child: Text(l10n.retryButton)),
            ],
          ),
        ),
      );
    }
    final dependents = _dependents ?? [];
    final panic = _criticalAlerts.where((n) => n['type'] == 'panic');
    final others = _criticalAlerts.where((n) => n['type'] != 'panic').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        if (panic.isNotEmpty) ...[
          _PanicBanner(notification: panic.first, dependentLabel: _emailFor(panic.first['dependent_id'] as String?)),
          const SizedBox(height: 16),
        ],
        if (others.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.needsAttentionHeader, style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                onPressed: () => context.push('/guardian/alerts'),
                child: Text(l10n.seeAllLabel),
              ),
            ],
          ),
          ...others.take(3).map((n) => _AlertPreviewRow(notification: n)),
          const SizedBox(height: 16),
        ],
        if (dependents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(l10n.noDependentsLinkedMessage, textAlign: TextAlign.center),
          )
        else
          ...dependents.map((dependent) => Card(
                child: ListTile(
                  leading: Icon(dependent.isPrimary ? Icons.shield : Icons.visibility),
                  title: Text(dependent.email),
                  subtitle: Text(
                    '${dependent.isPrimary ? l10n.primaryRoleLabel : l10n.secondaryRoleLabel} · '
                    '${l10n.kycStatusPrefixLabel}: ${_kycStatusLabel(l10n, dependent.kycStatus)} · '
                    '${dependent.accountActive ? l10n.accountActiveLabel : l10n.accountNotActiveLabel}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/guardian/dependent-detail', extra: dependent),
                ),
              )),
      ],
    );
  }

  /// Maps the backend's raw kyc_status value (pending/verified/failed -
  /// kyc_contract.md) to its Urdu-capable label. Falls back to the raw
  /// value for anything the contract doesn't document yet, rather than
  /// hiding an unexpected status.
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
}

class _PanicBanner extends StatelessWidget {
  const _PanicBanner({required this.notification, required this.dependentLabel});

  final Map<String, dynamic> notification;
  final String? dependentLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sentAt = DateTime.tryParse(notification['sent_at'] as String? ?? '');
    return Container(
      // Fix #2 (Design Handoff v1.0, section 3): tokenized, kept red on
      // purpose — this banner only ever renders for an active Panic
      // event (see PanicBanner's own doc comment / call sites), so it
      // falls squarely under "red for Panic and critical alerts".
      decoration: BoxDecoration(color: HumsafarColors.danger, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.panicBannerTitle,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  l10n.panicBannerBody(
                    dependentLabel ?? '',
                    sentAt == null ? '' : formatClockTime(sentAt.toLocal()),
                  ),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/guardian/alerts'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: HumsafarColors.danger),
            child: Text(l10n.openButtonLabel),
          ),
        ],
      ),
    );
  }
}

class _AlertPreviewRow extends StatelessWidget {
  const _AlertPreviewRow({required this.notification});

  final Map<String, dynamic> notification;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = notification['type'] as String? ?? '';
    final visuals = alertVisualsFor(type);
    final data = notification['data'] as Map<String, dynamic>? ?? {};
    final tierBadge = tierBadgeLabel(l10n, data['tier'] as String?);
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: Icon(visuals.icon, color: visuals.color),
        title: Text(alertTypeLabel(l10n, type)),
        subtitle: tierBadge == null ? null : Text(tierBadge),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/guardian/alerts'),
      ),
    );
  }
}
