import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';

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
    switch (e.code) {
      case 'GUARDIAN_NOT_VERIFIED':
        return 'You need to verify your own account first.';
      case 'NOT_PRIMARY_GUARDIAN':
        return 'You\'re not this Dependent\'s Primary Guardian.';
      case 'SECONDARY_NOT_FOUND':
        return 'That Guardian is no longer linked to this Dependent.';
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Permissions')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
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
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_secondaries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No Secondary Guardians yet - invite one first.', textAlign: TextAlign.center),
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
                    title: Text(_moduleLabel(module)),
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

  String _moduleLabel(String module) => module
      .split('_')
      .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
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
