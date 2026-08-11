// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Humsafar';

  @override
  String get guardianAppTitle => 'Guardian App';

  @override
  String get dependentAppTitle => 'Dependent App';

  @override
  String get devRoleSwitcherTitle => 'Humsafar — Dev Role Switcher';

  @override
  String get devRoleSwitcherBody =>
      'Temporary screen — will be replaced by real login (Task 1.11 / 2.5).';

  @override
  String get continueAsGuardian => 'Continue as Guardian';

  @override
  String get continueAsDependent => 'Continue as Dependent';

  @override
  String get guardianHomePlaceholder =>
      'Guardian home screen placeholder.\nReal dashboard content lands from Phase 2 onward.';

  @override
  String get dependentHomePlaceholder =>
      'Dependent home screen placeholder.\nThe 3 safety actions (Panic Mode, Wellness Check, Medication) land here from Task 3.10 onward.';

  @override
  String get switchModeTooltip => 'Switch mode (dev only)';

  @override
  String get switchToStandardView => 'Switch to standard view';

  @override
  String get switchToAccessibleView =>
      'Switch to large-text, high-contrast view';
}
