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

  @override
  String get genericValidationError => 'Please check the fields and try again.';

  @override
  String get retryButton => 'Retry';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get goToLoginButton => 'Go to login';

  @override
  String get yesLabel => 'Yes';

  @override
  String get notYetLabel => 'Not yet';

  @override
  String get primaryRoleLabel => 'Primary';

  @override
  String get secondaryRoleLabel => 'Secondary';

  @override
  String get primaryGuardianFullLabel => 'Primary Guardian';

  @override
  String get secondaryGuardianFullLabel => 'Secondary Guardian';

  @override
  String get verifiedLabel => 'Verified';

  @override
  String get notVerifiedLabel => 'Not verified';

  @override
  String get guardianVerifyEitherOptionNote =>
      'Either option below is enough to verify your account — you don\'t need to do both.';

  @override
  String get guardianVerifyOptionAHeader => 'Option A: verify by phone OTP';

  @override
  String get guardianVerifyOptionBHeader => 'Option B: verify by CNIC';

  @override
  String get resendOtpButton => 'Resend OTP';

  @override
  String get otpSentSnackbar => 'OTP sent to your registered phone number.';

  @override
  String get otpNotVerifiedYetSnackbar =>
      'Not verified yet — try the CNIC check below instead.';

  @override
  String get otpInvalidError =>
      'That code is wrong or expired. Try again or resend.';

  @override
  String get cnicCheckFailedSnackbar =>
      'CNIC check failed — try the phone OTP above instead.';

  @override
  String get openingCameraLabel => 'Opening camera...';

  @override
  String get lostRegistrationDetailsError =>
      'We lost track of your registration details (this happens if the app was closed). Please register again to continue.';

  @override
  String get kycInvalidCredentialsError =>
      'Something\'s wrong with your account details - please register again.';

  @override
  String get kycAlreadyVerifiedError =>
      'You\'re already verified. Try logging in once your guardian links you.';

  @override
  String get cnicAlreadyRegisteredError =>
      'This CNIC is already registered to another account.';

  @override
  String get kycValidationError =>
      'Please check the CNIC and photo and try again.';

  @override
  String get kycVerifiedWaitingDefaultMessage =>
      'Verified. Waiting for your Primary Guardian to link you.';

  @override
  String get shareIdWithGuardianLabel =>
      'Share this ID with your Guardian so they can link you:';

  @override
  String get kycVerifiedActiveDefaultMessage => 'You\'re verified and active.';

  @override
  String get kycPendingDefaultMessage => 'Still pending - please submit again.';

  @override
  String get kycFailedDefaultMessage =>
      'Verification failed - please try again.';

  @override
  String get inviteCodeOptionalLabel => 'Invite code (optional)';

  @override
  String get inviteCodeHelperText =>
      'Only if a Primary Guardian invited you as a Secondary Guardian.';

  @override
  String get roleLockedToGuardianNote =>
      'Role locked to Guardian while an invite code is entered.';

  @override
  String get inviteInvalidError => 'That invite code isn\'t valid.';

  @override
  String get inviteExpiredError =>
      'That invite code has expired - ask for a new one.';

  @override
  String get inviteNotForYouRegisterError =>
      'This invite was sent to a different phone number - use the exact number it was sent to.';

  @override
  String get guardianCapReachedError =>
      'This Dependent already has the maximum of 3 Guardians.';

  @override
  String get emailAlreadyRegisteredError =>
      'This email is already registered. Try logging in instead.';

  @override
  String get phoneAlreadyRegisteredError =>
      'This phone number is already registered.';

  @override
  String get accountAlreadyRegisteredError =>
      'This account already exists. Try logging in instead.';

  @override
  String get invalidCredentialsError => 'Incorrect email or password.';

  @override
  String get accountNotActivatedError =>
      'Your account isn\'t active yet — complete KYC and wait for your guardian to link you.';

  @override
  String get haveInviteCodeButton => 'Have an invite code?';

  @override
  String get linkADependentLabel => 'Link a Dependent';

  @override
  String get noDependentsLinkedMessage =>
      'You\'re not linked to any Dependents yet. Use \"Link a Dependent\" below with their ID to get started.';

  @override
  String get kycStatusPrefixLabel => 'KYC';

  @override
  String get accountActiveLabel => 'Active';

  @override
  String get accountNotActiveLabel => 'Not active yet';

  @override
  String get kycStatusPending => 'Pending';

  @override
  String get kycStatusVerified => 'Verified';

  @override
  String get kycStatusFailed => 'Failed';

  @override
  String get linkDependentInstructions =>
      'Ask the Dependent for the ID shown on their verification screen, then enter it below.';

  @override
  String get dependentIdLabel => 'Dependent\'s ID';

  @override
  String get linkButton => 'Link';

  @override
  String get linkedSuccessSnackbar =>
      'Linked! You can now see this Dependent on your home screen.';

  @override
  String get guardianNotVerifiedLinkError =>
      'You need to verify your own account before you can link a Dependent.';

  @override
  String get secondaryCannotLinkError =>
      'Only a Primary Guardian can link a Dependent - your account is Secondary.';

  @override
  String get dependentNotFoundError =>
      'No account found with that ID - double check it and try again.';

  @override
  String get alreadyLinkedError => 'You\'re already linked to this Dependent.';

  @override
  String get primaryAlreadyExistsError =>
      'This Dependent already has a Primary Guardian.';

  @override
  String get yourRoleLabel => 'Your role:';

  @override
  String get kycStatusColonLabel => 'KYC status:';

  @override
  String get accountActiveColonLabel => 'Account active:';

  @override
  String get linkedGuardiansHeader => 'Linked Guardians';

  @override
  String get inviteASecondaryButton => 'Invite a Secondary Guardian';

  @override
  String get managePermissionsButton => 'Manage Permissions';

  @override
  String get myAccessButton => 'My Access';

  @override
  String get invitePhoneInstructions =>
      'Enter the Secondary Guardian\'s phone number. They\'ll need the code this generates.';

  @override
  String get sendInviteButton => 'Send invite';

  @override
  String get guardianNotVerifiedGenericError =>
      'You need to verify your own account first.';

  @override
  String get notPrimaryGuardianError =>
      'You\'re not this Dependent\'s Primary Guardian.';

  @override
  String get inviteeNotEligibleError =>
      'That number can\'t be invited (it may already belong to an account, or be the Dependent\'s own number).';

  @override
  String get invitePhoneValidationError =>
      'Please check the phone number and try again.';

  @override
  String inviteCreatedMessage(int days) {
    return 'Invite created - valid for $days days. Share this code with them:';
  }

  @override
  String get copyCodeButton => 'Copy code';

  @override
  String get copiedSnackbar => 'Copied.';

  @override
  String get inviteShareFooterNote =>
      'They enter this during registration (if they\'re new) or on the \"Have an invite code?\" screen (if they already have a Secondary account).';

  @override
  String get noSecondariesYetMessage =>
      'No Secondary Guardians yet - invite one first.';

  @override
  String get secondaryNotFoundError =>
      'That Guardian is no longer linked to this Dependent.';

  @override
  String get moduleLiveLocation => 'Live Location';

  @override
  String get moduleHealthRecords => 'Health Records';

  @override
  String get moduleCommunication => 'Communication';

  @override
  String get moduleEmergencyAlerts => 'Emergency Alerts';

  @override
  String get moduleCameraViewing => 'Camera Viewing';

  @override
  String get moduleMedicationManagement => 'Medication Management';

  @override
  String get roleColonLabel => 'Role:';

  @override
  String get notLinkedToDependentError =>
      'You\'re not linked to this Dependent.';

  @override
  String get acceptAnInviteTitle => 'Accept an invite';

  @override
  String get pasteInviteCodeInstructions =>
      'Paste the invite code a Primary Guardian shared with you.';

  @override
  String get inviteCodeLabel => 'Invite code';

  @override
  String get acceptButton => 'Accept';

  @override
  String get inviteAcceptedSnackbar =>
      'Accepted! This Dependent now shows on your home screen.';

  @override
  String get primaryCannotAcceptInviteError =>
      'A Primary Guardian account can\'t accept a Secondary invite.';

  @override
  String get inviteNotForYouAcceptError =>
      'This code was sent to a different phone number than the one on your account.';
}
