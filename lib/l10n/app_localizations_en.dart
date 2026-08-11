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

  @override
  String get previewLoginLink => 'Preview: Login screen (Task 1.11)';

  @override
  String get previewRegisterLink => 'Preview: Register screen (Task 1.11)';

  @override
  String get registerScreenTitle => 'Create Account';

  @override
  String get loginScreenTitle => 'Login';

  @override
  String get guardianVerificationTitle => 'Guardian Verification';

  @override
  String get dependentKycTitle => 'Dependent Verification (KYC)';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get emailLabel => 'Email';

  @override
  String get phoneLabel => 'Phone Number';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get registeringAsLabel => 'Registering as';

  @override
  String get roleGuardianOption => 'Guardian';

  @override
  String get roleDependentOption => 'Dependent';

  @override
  String get registerButton => 'Register';

  @override
  String get loginButton => 'Login';

  @override
  String get alreadyHaveAccountPrompt => 'Already have an account? Login';

  @override
  String get dontHaveAccountPrompt => 'Don\'t have an account? Register';

  @override
  String get fieldRequiredError => 'This field is required';

  @override
  String get invalidEmailError => 'Enter a valid email address';

  @override
  String get passwordTooShortError => 'Password must be at least 8 characters';

  @override
  String get passwordTooWeakError =>
      'Password must include at least one letter and one number';

  @override
  String get passwordsDoNotMatchError => 'Passwords do not match';

  @override
  String get invalidPhoneError =>
      'Enter a valid Pakistani phone number (e.g. 03XXXXXXXXX)';

  @override
  String get invalidCnicError => 'Enter CNIC in the format XXXXX-XXXXXXX-X';

  @override
  String get cnicLabel => 'CNIC Number';

  @override
  String get cnicHint => 'XXXXX-XXXXXXX-X';

  @override
  String get sendOtpButton => 'Send OTP';

  @override
  String get otpSentDummyMessage => 'OTP sent (dummy — Task 1.11 UI only)';

  @override
  String get otpLabel => 'Enter OTP';

  @override
  String get verifyAndContinueButton => 'Verify & Continue';

  @override
  String get noLivenessRequiredNote =>
      'Guardian verification does not require a liveness photo.';

  @override
  String get captureLivenessButton => 'Capture Liveness Photo';

  @override
  String get livenessCapturedConfirmation => 'Liveness photo captured (mock)';

  @override
  String get submitForVerificationButton => 'Submit for Verification';
}
