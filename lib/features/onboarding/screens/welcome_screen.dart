import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/theme/humsafar_colors.dart';
import '../../../providers/app_mode_provider.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 1.12/PR #106 (Sarim's handoff, docs/design/1.12_identity_access/
/// README.md's mockup 01 "Welcome (role choice)", FR-A1) — the real screen
/// a signed-out user lands on after 00b Launch, replacing the dev-only
/// `role_select_screen.dart` (see splash_screen.dart's doc comment on
/// why; closes QA finding UI-01 / the older F-07).
///
/// Brand v2.0 (Sarim's 22 Nov handoff, assets/brand/README.md): "Welcome
/// screen (01): teal hero with Humsafar_Symbol_v2.0_white-amber.svg and
/// Humsafar_Wordmark_v2.0_white.svg, the same pair as the launch screen."
/// Built as a solid teal hero (not the lighter tint shown in the older
/// v0.2 mockup PNG) on purpose, for that exact reason — the mockup is
/// explicitly flagged as pre-dating this brand handoff, and the written
/// "same pair as the launch screen" instruction is the more recent,
/// more specific source.
///
/// **English tagline not yet team-confirmed** — assets/brand/README.md
/// says the Urdu slogan is final but marks the English line "[to confirm
/// with the team]"; the text below is the older v0.2 mockup's own
/// placeholder copy, not a confirmed final. The new Urdu copy on this
/// screen generally (everything except the tagline itself, which is the
/// already-approved brand slogan) is a first draft and has not been
/// through Sarim's usual Urdu review pass (see the S7 UI-text process) —
/// flag both of these before this ships past the demo video.
///
/// Tapping a role card sets [appModeProvider] and pushes straight to
/// Create Account (register_screen.dart) pre-selected to that role, since
/// mockup 01's own next step in the Figma prototype is 03 Create account,
/// not a Home screen — "Log in" is the separate path for someone who
/// already has an account.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  // Same reasoning as role_select_screen.dart's `_confirmExit` — this is
  // the app's real root for a signed-out user (nothing below it in the
  // go_router stack), so back here should ask before actually exiting
  // rather than doing it silently.
  Future<void> _confirmExit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.exitAppConfirmTitle),
        content: Text(l10n.exitAppConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancelButton)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.exitAppButtonLabel)),
        ],
      ),
    );
    // Bug fix (`flutter analyze`'s use_build_context_synchronously): uses
    // SystemNavigator.pop() rather than Navigator.of(context).maybePop()
    // — same choice role_select_screen.dart's own `_confirmExit` already
    // makes, and for the same reason: it doesn't need a BuildContext at
    // all, so there's nothing to guard after the `await` above.
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  void _chooseRole(BuildContext context, WidgetRef ref, AppMode role) {
    ref.read(appModeProvider.notifier).state = role;
    context.push('/register', extra: role);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit(context);
      },
      child: Scaffold(
        backgroundColor: HumsafarColors.surface,
        appBar: AppBar(
          title: Text(l10n.welcomeScreenTitle),
          backgroundColor: HumsafarColors.surface,
          foregroundColor: HumsafarColors.text,
          elevation: 0,
          // Order matches mockup 01 exactly: Aa, then EN|UR.
          actions: const [AccessibilityToggleButton(), LanguageSwitchButton()],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                color: HumsafarColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/brand/logo/exports/symbol/Humsafar_Symbol_v2.0_white-amber.svg',
                      width: 88,
                    ),
                    const SizedBox(height: 20),
                    SvgPicture.asset(
                      'assets/brand/logo/exports/wordmark/Humsafar_Wordmark_v2.0_white.svg',
                      width: 200,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.welcomeTagline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 24 + MediaQuery.of(context).viewPadding.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.welcomeWhoIsUsingPrompt,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: HumsafarColors.text),
                      ),
                      const SizedBox(height: 16),
                      _RoleCard(
                        icon: Icons.shield,
                        title: l10n.welcomeGuardianCardTitle,
                        subtitle: l10n.welcomeGuardianCardSubtitle,
                        filled: true,
                        onTap: () => _chooseRole(context, ref, AppMode.guardian),
                      ),
                      const SizedBox(height: 12),
                      _RoleCard(
                        icon: Icons.person_outline,
                        title: l10n.welcomeDependentCardTitle,
                        subtitle: l10n.welcomeDependentCardSubtitle,
                        filled: false,
                        onTap: () => _chooseRole(context, ref, AppMode.dependent),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: TextButton(
                          onPressed: () => context.push('/login'),
                          child: Text.rich(
                            TextSpan(
                              text: '${l10n.welcomeAlreadyHaveAccountPrompt} ',
                              style: const TextStyle(color: HumsafarColors.muted),
                              children: [
                                TextSpan(
                                  text: l10n.loginButton,
                                  style: const TextStyle(color: HumsafarColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Style guide: buttons 54 px tall, 14 px radius, touch targets at least
/// 48x48 — this card comfortably clears all three with its icon + two
/// lines of text + internal padding.
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : HumsafarColors.primary;
    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: filled ? HumsafarColors.primary : HumsafarColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: filled ? null : Border.all(color: HumsafarColors.primary, width: 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: filled ? Colors.white : HumsafarColors.primaryTint,
            foregroundColor: HumsafarColors.primary,
            child: Icon(icon),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: foreground, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: filled ? Colors.white70 : HumsafarColors.muted, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: foreground),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
