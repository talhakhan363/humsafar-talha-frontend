import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/sharing/share_source.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';
import 'medical_vault_screen.dart' show categoryLabel;

/// Task 5.6 — mockup 15f "Doctor links", grounded in
/// `records_contract.md`'s doctor-link section (FR-G3). Create a
/// time-limited, no-login link to the Medical Vault PDF; list existing
/// links with their status; cancel one. The secret `token` is shown
/// only once, right after creation (the server only ever stores a
/// hash of it) — this screen hands the full share URL to `ShareSource`
/// immediately rather than only displaying it, per the contract's own
/// "share it by WhatsApp or SMS" suggestion.
class DoctorLinksScreen extends ConsumerStatefulWidget {
  const DoctorLinksScreen({super.key, required this.dependentId});

  final String dependentId;

  @override
  ConsumerState<DoctorLinksScreen> createState() => _DoctorLinksScreenState();
}

class _DoctorLinksScreenState extends ConsumerState<DoctorLinksScreen> {
  List<Map<String, dynamic>> _links = [];
  bool _isLoading = true;
  String? _loadError;
  final Set<String> _pendingCancel = {};

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
          await ref.read(apiClientProvider).get<Map<String, dynamic>>('/dependents/${widget.dependentId}/records/share');
      if (!mounted) return;
      setState(() => _links = (response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createLink() async {
    final options = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CreateLinkForm(),
    );
    if (options == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await ref
          .read(apiClientProvider)
          .post<Map<String, dynamic>>('/dependents/${widget.dependentId}/records/share', data: options);
      if (!mounted) return;
      final url = response.data?['url'] as String? ?? '';
      await ref.read(shareSourceProvider).shareText('${l10n.doctorLinkShareIntro}\n$url');
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = e.code == 'SHARE_LIMIT' ? l10n.shareLimitError : e.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _cancel(Map<String, dynamic> link) async {
    final shareId = link['share_id'] as String;
    setState(() => _pendingCancel.add(shareId));
    try {
      await ref.read(apiClientProvider).delete('/dependents/${widget.dependentId}/records/share/$shareId');
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _pendingCancel.remove(shareId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.doctorLinksScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _createLink, child: const Icon(Icons.add_link)),
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
    if (_links.isEmpty) {
      return Center(child: Text(l10n.noDoctorLinksMessage, textAlign: TextAlign.center));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _links.map((link) {
        final shareId = link['share_id'] as String;
        final status = link['status'] as String? ?? '';
        final isActive = status == 'active';
        final categories = (link['categories'] as List<dynamic>?)?.cast<String>();
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(isActive ? Icons.link : Icons.link_off, color: isActive ? Colors.teal : Colors.grey),
            title: Text(_statusLabel(l10n, status)),
            subtitle: Text(
              '${categories == null || categories.length == 4 ? l10n.allCategoriesLabel : categories.map((c) => categoryLabel(l10n, c)).join(', ')}'
              ' · ${l10n.openedCountLabel((link['open_count'] as int?) ?? 0)}',
            ),
            trailing: isActive
                ? (_pendingCancel.contains(shareId)
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : TextButton(onPressed: () => _cancel(link), child: Text(l10n.cancelLinkButtonLabel)))
                : null,
          ),
        );
      }).toList(),
    );
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'active':
        return l10n.shareStatusActive;
      case 'expired':
        return l10n.shareStatusExpired;
      case 'revoked':
        return l10n.shareStatusRevoked;
      default:
        return status;
    }
  }
}

class _CreateLinkForm extends StatefulWidget {
  const _CreateLinkForm();

  @override
  State<_CreateLinkForm> createState() => _CreateLinkFormState();
}

class _CreateLinkFormState extends State<_CreateLinkForm> {
  int _hours = 72;
  bool _includeVitals = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.createDoctorLinkTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(l10n.createDoctorLinkBody),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.linkExpiresInFieldLabel),
            trailing: DropdownButton<int>(
              value: _hours,
              items: const [24, 72, 168, 720]
                  .map((h) => DropdownMenuItem(value: h, child: Text(h == 720 ? '30d' : '${h}h')))
                  .toList(),
              onChanged: (value) => setState(() => _hours = value!),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.includeVitalsFieldLabel),
            value: _includeVitals,
            onChanged: (value) => setState(() => _includeVitals = value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancelButton))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop({'hours': _hours, 'include_vitals': _includeVitals}),
                  child: Text(l10n.createLinkButtonLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
