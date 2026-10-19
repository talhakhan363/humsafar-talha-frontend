import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      setState(() => _loadError = e.code == 'NOT_LINKED_TO_DEPENDENT' ? 'You\'re not linked to this Dependent.' : e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _moduleLabel(String module) => module
      .split('_')
      .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Access'),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
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
    final modules = _modules ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_guardianRole != null) Text('Role: $_guardianRole', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...modules.entries.map(
          (entry) => ListTile(
            leading: Icon(entry.value ? Icons.check_circle : Icons.cancel,
                color: entry.value ? Colors.green : Colors.red),
            title: Text(_moduleLabel(entry.key)),
          ),
        ),
      ],
    );
  }
}
