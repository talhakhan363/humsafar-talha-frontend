import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/guardian/dependent_summary.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

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
class GuardianHomeScreen extends ConsumerStatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  ConsumerState<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends ConsumerState<GuardianHomeScreen> {
  List<DependentSummary>? _dependents;
  String? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDependents();
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

  Future<void> _linkDependent() async {
    final linked = await context.push<bool>('/guardian/link-dependent');
    if (linked == true) _loadDependents();
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
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: l10n.switchModeTooltip,
            onPressed: () => context.go('/role-select'),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _loadDependents, child: _buildBody()),
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
    if (dependents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            l10n.noDependentsLinkedMessage,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: dependents.length,
      itemBuilder: (context, index) {
        final dependent = dependents[index];
        return Card(
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
        );
      },
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
