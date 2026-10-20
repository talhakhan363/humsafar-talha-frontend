import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// New screen for Task 2.5 Step E. Read-only view of what the logged-in
/// Guardian (Primary or Secondary) may do for one Dependent:
/// GET /dependents/{id}/permissions/me (permissions_contract.md section 3).
class MyAccessScreen extends ConsumerStatefulWidget {
  const MyAccessScreen({super.key, required this.dependentId});

  final String dependentId;

  @override
  ConsumerState<MyAccessScreen> createState() => _MyAccessScreenState();
}

class _MyAccessScreenState extends ConsumerState<MyAccessScreen> {
  Map<String, bool>? _modules;
  String? _guardianRole;
  String? _loadError;
  bool _isLoading = true;

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
      final response = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('/dependents/${widget.dependentId}/permissions/me');
      final modules =
          (response.data?['modules'] as Map<String, dynamic>? ?? {}).map((key, value) => MapEntry(key, value as bool));
      if (!mounted) return;
      setState(() {
        _modules = modules;
        _guardianRole = response.data?['guardian_role'] as String?;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.code == 'NOT_LINKED_TO_DEPENDENT'
          ? AppLocalizations.of(context)!.notLinkedToDependentError
          : e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Same documented-module mapping as permissions_dashboard_screen.dart's
  /// own copy - kept local rather than shared since each screen's module
  /// list arrives from a different endpoint shape.
  String _moduleLabel(AppLocalizations l10n, String module) {
    switch (module) {
      case 'live_location':
        return l10n.moduleLiveLocation;
      case 'health_records':
        return l10n.moduleHealthRecords;
      case 'communication':
        return l10n.moduleCommunication;
      case 'emergency_alerts':
        return l10n.moduleEmergencyAlerts;
      case 'camera_viewing':
        return l10n.moduleCameraViewing;
      case 'medication_management':
        return l10n.moduleMedicationManagement;
      default:
        return module
            .split('_')
            .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
            .join(' ');
    }
  }

  String _roleLabel(AppLocalizations l10n, String role) {
    switch (role) {
      case 'primary':
        return l10n.primaryGuardianFullLabel;
      case 'secondary':
        return l10n.secondaryGuardianFullLabel;
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myAccessButton),
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
    final modules = _modules ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_guardianRole != null)
          Text(
            '${l10n.roleColonLabel} ${_roleLabel(l10n, _guardianRole!)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        const SizedBox(height: 12),
        ...modules.entries.map(
          (entry) => ListTile(
            leading: Icon(entry.value ? Icons.check_circle : Icons.cancel,
                color: entry.value ? Colors.green : Colors.red),
            title: Text(_moduleLabel(l10n, entry.key)),
          ),
        ),
      ],
    );
  }
}
