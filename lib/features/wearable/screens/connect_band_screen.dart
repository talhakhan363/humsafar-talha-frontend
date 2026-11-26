import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../core/wearable/ble_band_service.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 5.8 — mockup 27b "Connect band", grounded in
/// `wearable_contract.md`. **Originally a named scope decision** (no
/// real BLE scan — manual address entry only, exactly as the contract's
/// own body allows), now partly closed: Task 5.5 (Abdullah's 25 Nov
/// spec) adds a real scan via `BleBandService`, so this screen can now
/// find the real band and fill the address in automatically. Manual
/// entry stays as the fallback — scanning can fail (permissions
/// refused, Bluetooth off, band out of range), and the contract itself
/// still validates/accepts a typed address the same way either path
/// fills it in. **Not yet tested against a real band** — see
/// `ble_band_service.dart`'s own doc comment.
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

  final _scanService = BleBandService();
  bool _isScanning = false;

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    _scanService.dispose();
    super.dispose();
  }

  /// Short discovery-only scan — connects to nothing, just finds the
  /// band's platform id (its BLE address on Android) and name, then
  /// fills both fields so the existing manual-entry `_pair()` flow below
  /// can run unchanged. Falls back to leaving the fields for manual
  /// entry on any failure (permission refused, Bluetooth off, band not
  /// found) rather than blocking the screen.
  Future<void> _scanForBand() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isScanning = true;
      _error = null;
    });
    try {
      final granted = await _scanService.requestPermissions();
      if (!granted) {
        if (!mounted) return;
        setState(() => _error = l10n.bandBluetoothPermissionDeniedMessage);
        return;
      }
      final device = await _scanService.scanForDevice();
      if (!mounted) return;
      if (device == null) {
        setState(() => _error = l10n.bandScanTimeoutMessage);
        return;
      }
      setState(() {
        _addressController.text = device.remoteId.str;
        _nameController.text = BleBandService.deviceName;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.bandScanTimeoutMessage);
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
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
      // Bug fix (2026-10-30): bottom-nav-bar overlap, see vitals_screen.dart.
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
        children: [
          Text(l10n.connectBandInstructions),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isScanning ? null : _scanForBand,
            icon: _isScanning
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.bluetooth_searching),
            label: Text(_isScanning ? l10n.bandScanningMessage : l10n.bandScanButtonLabel),
          ),
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
