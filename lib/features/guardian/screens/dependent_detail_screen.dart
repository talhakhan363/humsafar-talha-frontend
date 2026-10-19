import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/guardian/dependent_summary.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// New screen for Task 2.5 Step E. Shows who is linked to a Dependent
/// (GET /dependents/{id}/guardians, linkage_contract.md section 2) and the
/// role-gated next actions: a Primary can invite a Secondary or manage
/// permissions; a Secondary can view their own access.
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

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;

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
                    Text('Your role: ${summary.isPrimary ? 'Primary Guardian' : 'Secondary Guardian'}'),
                    Text('KYC status: ${summary.kycStatus}'),
                    Text('Account active: ${summary.accountActive ? 'Yes' : 'Not yet'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Linked Guardians', style: Theme.of(context).textTheme.titleMedium),
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
                      '${guardian['guardian_role']} · ${(guardian['verified'] as bool? ?? false) ? 'Verified' : 'Not verified'}',
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (summary.isPrimary) ...[
              ElevatedButton.icon(
                onPressed: () => context.push('/guardian/invite-secondary', extra: summary.dependentId),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Invite a Secondary Guardian'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.push('/guardian/permissions', extra: summary.dependentId),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Manage Permissions'),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: () => context.push('/guardian/my-access', extra: summary.dependentId),
                icon: const Icon(Icons.lock_outline),
                label: const Text('My Access'),
              ),
          ],
        ),
      ),
    );
  }
}
