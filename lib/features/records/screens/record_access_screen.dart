import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';
import 'medical_vault_screen.dart' show categoryLabel;

const _categories = ['prescription', 'lab_report', 'xray', 'other'];

/// Task 5.6 — mockup 15e "Record access", grounded in
/// `records_contract.md`'s Task 5.2 section. Primary-only (the
/// contract's own `NOT_PRIMARY_GUARDIAN` error, and this screen is
/// only ever reached from a Primary's app-bar menu on
/// `MedicalVaultScreen` — see that screen's doc comment). Per
/// Secondary, four switches ("Prescriptions"/"Lab reports"/
/// "X-rays"/"Other") greyed out while that Secondary's own
/// `health_records_granted` is false, since the category flags only
/// count once that permission itself is on.
class RecordAccessScreen extends ConsumerStatefulWidget {
  const RecordAccessScreen({super.key, required this.dependentId});

  final String dependentId;

  @override
  ConsumerState<RecordAccessScreen> createState() => _RecordAccessScreenState();
}

class _RecordAccessScreenState extends ConsumerState<RecordAccessScreen> {
  List<Map<String, dynamic>> _secondaries = [];
  bool _isLoading = true;
  String? _loadError;
  final Set<String> _pendingToggle = {};

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
      final response =
          await ref.read(apiClientProvider).get<Map<String, dynamic>>('/dependents/${widget.dependentId}/records/access');
      if (!mounted) return;
      setState(() => _secondaries = (response.data?['secondaries'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.code == 'NOT_PRIMARY_GUARDIAN' ? AppLocalizations.of(context)!.notPrimaryGuardianMessage : e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggle(Map<String, dynamic> secondary, String category, bool visible) async {
    final guardianId = secondary['guardian_id'] as String;
    final key = '$guardianId-$category';
    setState(() {
      _pendingToggle.add(key);
      (secondary['categories'] as Map<String, dynamic>)[category] = visible; // optimistic
    });
    try {
      await ref.read(apiClientProvider).put(
            '/dependents/${widget.dependentId}/records/access/$category',
            data: {'guardian_id': guardianId, 'visible': visible},
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => (secondary['categories'] as Map<String, dynamic>)[category] = !visible); // revert
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _pendingToggle.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recordAccessScreenTitle),
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
      return Center(child: Text(l10n.noSecondariesMessage, textAlign: TextAlign.center));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _secondaries.map((secondary) {
        final granted = secondary['health_records_granted'] as bool? ?? false;
        final categories = (secondary['categories'] as Map<String, dynamic>?) ?? {};
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(secondary['email'] as String? ?? '', style: Theme.of(context).textTheme.titleMedium),
                if (!granted)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(l10n.healthRecordsNotGrantedNote, style: TextStyle(color: Colors.grey.shade600)),
                  ),
                const SizedBox(height: 8),
                ..._categories.map((category) {
                  final key = '${secondary['guardian_id']}-$category';
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(categoryLabel(l10n, category)),
                    value: categories[category] as bool? ?? true,
                    onChanged: !granted || _pendingToggle.contains(key)
                        ? null
                        : (value) => _toggle(secondary, category, value),
                  );
                }),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
