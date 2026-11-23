import 'package:flutter/material.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../widgets/legal_section.dart';

/// Mockup 03b "Privacy Policy" — Sarim's 23 Nov spec (`docs/design/
/// 1.12_identity_access/README.md`'s "Consent line, Privacy Policy and
/// Terms" section, text and string keys from `docs/design/ui_text/
/// Humsafar_Privacy_and_Terms_v0.2.pdf`): "a simple scrolling text screen
/// with the usual app bar (back, title, Aa, EN|UR) and a version line."
/// Reached from the new consent line under Create account's button
/// (`register_screen.dart`'s `_buildConsentLine`) and reusable from
/// anywhere else later (Settings, say) via `context.push('/legal/privacy')`
/// — this screen takes no arguments and reads nothing from the backend,
/// so it's safe to reach whether or not the person is signed in yet.
///
/// **Draft, not final text** (flagged here deliberately, not hidden): the
/// source PDF's own banner says "Not legal advice. To be read by the
/// supervisor and, before any public release, by a lawyer." Two items in
/// the body below are still open `[square-bracket]` placeholders exactly
/// as the source PDF has them — the photo-deletion wording (pending
/// Abdullah's confirmation) and the contact email (pending the team) —
/// deliberately NOT invented or silently resolved here. Both need a real
/// value before this ships past an internal debug APK.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.legalPrivacyTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.legalDraftVersionLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HumsafarColors.muted),
              ),
              const SizedBox(height: 20),
              LegalSection(title: l10n.privacyWhatThisIsTitle, body: l10n.privacyWhatThisIsBody),
              LegalSection(title: l10n.privacyWhatWeCollectTitle, body: l10n.privacyWhatWeCollectBody),
              LegalSection(title: l10n.privacyWhyWeCollectTitle, body: l10n.privacyWhyWeCollectBody),
              LegalSection(title: l10n.privacyWhoCanSeeTitle, body: l10n.privacyWhoCanSeeBody),
              LegalSection(title: l10n.privacyServicesWeUseTitle, body: l10n.privacyServicesWeUseBody),
              LegalSection(title: l10n.privacyHowWeProtectTitle, body: l10n.privacyHowWeProtectBody),
              LegalSection(title: l10n.privacyHowLongWeKeepTitle, body: l10n.privacyHowLongWeKeepBody),
              LegalSection(title: l10n.privacyYourChoicesTitle, body: l10n.privacyYourChoicesBody),
              LegalSection(title: l10n.privacyNotMedicalAdviceTitle, body: l10n.privacyNotMedicalAdviceBody),
              LegalSection(title: l10n.privacyContactTitle, body: l10n.privacyContactBody),
            ],
          ),
        ),
      ),
    );
  }
}
