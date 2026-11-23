import 'package:flutter/material.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../widgets/legal_section.dart';

/// Mockup 03c "Terms" — see `privacy_policy_screen.dart`'s doc comment for
/// the shared spec/source/draft-status notes; this screen is its sibling,
/// same shape, reached via `context.push('/legal/terms')`.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.legalTermsTitle),
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
              LegalSection(title: l10n.termsAPrototypeTitle, body: l10n.termsAPrototypeBody),
              LegalSection(title: l10n.termsWhoCanUseTitle, body: l10n.termsWhoCanUseBody),
              LegalSection(title: l10n.termsYourResponsibilitiesTitle, body: l10n.termsYourResponsibilitiesBody),
              LegalSection(title: l10n.termsNotEmergencyServiceTitle, body: l10n.termsNotEmergencyServiceBody),
              LegalSection(title: l10n.termsHealthInformationTitle, body: l10n.termsHealthInformationBody),
              LegalSection(title: l10n.termsAccountsTitle, body: l10n.termsAccountsBody),
              LegalSection(title: l10n.termsChangesTitle, body: l10n.termsChangesBody),
            ],
          ),
        ),
      ),
    );
  }
}
