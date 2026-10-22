import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/files/file_providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Screen 05 "Share my ID" fix. Task 2.5's KYC outcome view showed a
/// freshly-verified Dependent their own ID as plain `SelectableText` —
/// functional, but exactly the gap Sarim's design-check flagged
/// (`Humsafar_Full_Task_List_All_Members.md`, Task 2.5's row): "an
/// elderly Dependent must be able to send their ID to a Guardian with
/// one tap (or show a QR), and plain text is hard for them to copy."
/// This is the dedicated screen Sarim's hi-fi mockup 05 called for
/// (`docs/design/1.12_identity_access/Humsafar_Design_05_Share_my_ID_
/// v0.1.png`): a QR code, a Copy ID button, and a Share button.
///
/// Deliberately a pure, API-free screen — it takes [dependentId] as a
/// plain string and does nothing but render/copy/share it. That matters
/// for two reasons: (1) it's reachable straight from the KYC outcome
/// view (`dependent_kyc_screen.dart`), where the Dependent has no JWT
/// yet (SDS 11.3) — a screen that called any authenticated endpoint
/// wouldn't work there; (2) it's also reachable later from
/// `dependent_home_screen.dart`'s "More" footer, once the Dependent is
/// fully signed in, with no behavior difference needed between the two
/// entry points.
///
/// Copy uses Flutter's own `Clipboard` directly (not wrapped behind a
/// seam like `ShareSource`/`FilePickerSource`) — unlike every real
/// native plugin in this app, `Clipboard.setData`/`getData` already work
/// under `flutter test` out of the box (`flutter_test`'s default binding
/// mocks the platform channel they use), so there's no seam needed for
/// testability here. Share reuses the existing `shareSourceProvider`
/// (`ShareSource.shareText`, Task 5.6) rather than adding a second way
/// to reach the OS share sheet.
class ShareIdScreen extends ConsumerWidget {
  const ShareIdScreen({super.key, required this.dependentId});

  final String dependentId;

  Future<void> _copyId(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: dependentId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.idCopiedConfirmation)),
    );
  }

  Future<void> _shareId(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(shareSourceProvider).shareText('${l10n.shareIdShareIntro}\n$dependentId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shareIdScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(l10n.shareIdScreenExplanation, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: dependentId,
                    size: 200,
                    semanticsLabel: l10n.shareIdScreenTitle,
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    dependentId,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyId(context),
                    icon: const Icon(Icons.copy_outlined),
                    label: Text(l10n.copyIdButtonLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareId(context, ref),
                    icon: const Icon(Icons.share_outlined),
                    label: Text(l10n.shareIdButtonLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
