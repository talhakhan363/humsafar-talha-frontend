import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 5.8 — mockup 27b "Connect band", grounded in
/// `wearable_contract.md`. **Named scope decision:** no real BLE scan —
/// Task 2.4 (the BLE spike) and Task 5.5 (the real band) aren't built,
/// so this screen offers manual entry of the band's Bluetooth address,
/// exactly as the contract itself allows ("the phone knows the band's
/// Bluetooth address from its scan" — the scan is the only part
/// deferred; typing the address in is a legitimate stand-in the
/// contract's own body validates and accepts the same way). Matches
/// the handbook's explicit instruction to build 5.6-5.8 against the
/// mocked endpoints now rather than waiting on the purchase.
class ConnectBandScreen extends ConsumerStatefulWidget {
  const ConnectBandScreen({super.key, required this.dependentId});

  final String dependentId;

  @override
  ConsumerState<ConnectBandScreen> createState() => _ConnectBandScreenState();
}

class _ConnectBandScreenState extends ConsumerState<ConnectBandScreen> {
  final _addressController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    final l10n = AppLocalizations.of(context)!;
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      setState(() => _error = l10n.fieldRequiredError);
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).post(
            '/dependents/${widget.dependentId}/wearable',
            data: {'ble_address': address, if (_nameController.text.trim().isNotEmpty) 'name': _nameController.text.trim()},
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = _messageFor(l10n, e);
      });
    }
  }

  String _messageFor(AppLocalizations l10n, ApiException e) {
    switch (e.code) {
      case 'BAND_ALREADY_PAIRED':
        return l10n.bandAlreadyPairedMessage;
      case 'NOT_PRIMARY_GUARDIAN':
        return l10n.notPrimaryGuardianMessage;
      case 'VALIDATION_ERROR':
        return l10n.recordValidationErrorMessage;
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.connectBandScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.connectBandInstructions),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(labelText: l10n.bandAddressFieldLabel, hintText: 'C4:5B:BE:12:34:56'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _nameController, decoration: InputDecoration(labelText: l10n.bandNameFieldLabel)),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: HumsafarColors.warning)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _pair,
            child: _isSaving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.pairButtonLabel),
          ),
        ],
      ),
    );
  }
}
