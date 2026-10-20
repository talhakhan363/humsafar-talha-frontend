import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// New screen for Task 2.5 Step E. The Primary's permission dashboard:
/// GET /dependents/{id}/permissions, then PUT
/// /dependents/{id}/permissions/{module} per toggle
/// (permissions_contract.md). The module list comes from the response's
/// `modules` field rather than being hard-coded, per that contract's own
/// instruction (the list may grow).
class PermissionsDashboardScreen extends ConsumerStatefulWidget {
  const PermissionsDashboardScreen({super.key, required this.dependentId});

  final String dependentId;

  @override
  ConsumerState<PermissionsDashboardScreen> createState() => _PermissionsDashboardScreenState();
}

class _PermissionsDashboardScreenState extends ConsumerState<PermissionsDashboardScreen> {
  List<String> _modules = [];
  List<_SecondaryRow> _secondaries = [];
  final Set<String> _pending = {}; // "guardianId:module" currently in-flight
  bool _isLoading = true;
  String? _loadError;

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
          .get<Map<String, dynamic>>('/dependents/${widget.dependentId}/permissions');
      final modules = (response.data?['modules'] as List<dynamic>? ?? []).cast<String>();
      final secondaries = (response.data?['secondaries'] as List<dynamic>? ?? [])
          .map((e) => _SecondaryRow.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _modules = modules;
        _secondaries = secondaries;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = _messageFor(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggle(_SecondaryRow secondary, String module, bool granted) async {
    final key = '${secondary.guardianId}:$module';
    setState(() {
      _pending.add(key);
      secondary.modules[module] = granted; // optimistic
    });
    try {
      await ref.read(apiClientProvider).put(
            '/dependents/${widget.dependentId}/permissions/$module',
            data: {'guardian_id': secondary.guardianId, 'granted': granted},
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => secondary.modules[module] = !granted); // revert
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_messageFor(e))));
    } finally {
      if (mounted) setState(() => _pending.remove(key));
    }
  }

  String _messageFor(ApiException e) {
    final l10n = AppLocalizations.of(context)!;
    switch (e.code) {
      case 'GUARDIAN_NOT_VERIFIED':
        return l10n.guardianNotVerifiedGenericError;
      case 'NOT_PRIMARY_GUARDIAN':
        return l10n.notPrimaryGuardianError;
      case 'SECONDARY_NOT_FOUND':
        return l10n.secondaryNotFoundError;
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.managePermissionsButton),
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
    if (_secondaries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(l10n.noSecondariesYetMessage, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _secondaries.length,
      itemBuilder: (context, index) {
        final secondary = _secondaries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(secondary.email, style: Theme.of(context).textTheme.titleMedium),
                Text(secondary.phone, style: Theme.of(context).textTheme.bodySmall),
                const Divider(),
                ..._modules.map((module) {
                  final key = '${secondary.guardianId}:$module';
                  return SwitchListTile(
                    title: Text(_moduleLabel(l10n, module)),
                    value: secondary.modules[module] ?? false,
                    onChanged: _pending.contains(key) ? null : (value) => _toggle(secondary, module, value),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Maps a known permission module (permissions_contract.md's documented
  /// set) to its localized label. Falls back to a title-cased version of
  /// the raw snake_case name for any module the contract adds later that
  /// this screen doesn't have an Urdu translation for yet, rather than
  /// crashing or showing a blank label.
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
}

class _SecondaryRow {
  _SecondaryRow({required this.guardianId, required this.email, required this.phone, required this.modules});

  final String guardianId;
  final String email;
  final String phone;
  final Map<String, bool> modules;

  factory _SecondaryRow.fromJson(Map<String, dynamic> json) => _SecondaryRow(
        guardianId: json['guardian_id'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        modules: (json['modules'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value as bool)),
      );
}
