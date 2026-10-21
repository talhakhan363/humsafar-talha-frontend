import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur')
  ];

  /// App name shown on the splash screen and window title.
  ///
  /// In en, this message translates to:
  /// **'Humsafar'**
  String get appTitle;

  /// No description provided for @guardianAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Guardian App'**
  String get guardianAppTitle;

  /// No description provided for @dependentAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Dependent App'**
  String get dependentAppTitle;

  /// No description provided for @devRoleSwitcherTitle.
  ///
  /// In en, this message translates to:
  /// **'Humsafar — Dev Role Switcher'**
  String get devRoleSwitcherTitle;

  /// No description provided for @devRoleSwitcherBody.
  ///
  /// In en, this message translates to:
  /// **'Temporary screen — will be replaced by real login (Task 1.11 / 2.5).'**
  String get devRoleSwitcherBody;

  /// No description provided for @continueAsGuardian.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guardian'**
  String get continueAsGuardian;

  /// No description provided for @continueAsDependent.
  ///
  /// In en, this message translates to:
  /// **'Continue as Dependent'**
  String get continueAsDependent;

  /// No description provided for @guardianHomePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Guardian home screen placeholder.\nReal dashboard content lands from Phase 2 onward.'**
  String get guardianHomePlaceholder;

  /// No description provided for @dependentHomePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Dependent home screen placeholder.\nThe 3 safety actions (Panic Mode, Wellness Check, Medication) land here from Task 3.10 onward.'**
  String get dependentHomePlaceholder;

  /// No description provided for @switchModeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch mode (dev only)'**
  String get switchModeTooltip;

  /// No description provided for @switchToStandardView.
  ///
  /// In en, this message translates to:
  /// **'Switch to standard view'**
  String get switchToStandardView;

  /// No description provided for @switchToAccessibleView.
  ///
  /// In en, this message translates to:
  /// **'Switch to large-text, high-contrast view'**
  String get switchToAccessibleView;

  /// No description provided for @previewLoginLink.
  ///
  /// In en, this message translates to:
  /// **'Preview: Login screen (Task 1.11)'**
  String get previewLoginLink;

  /// No description provided for @previewRegisterLink.
  ///
  /// In en, this message translates to:
  /// **'Preview: Register screen (Task 1.11)'**
  String get previewRegisterLink;

  /// No description provided for @registerScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerScreenTitle;

  /// No description provided for @loginScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginScreenTitle;

  /// No description provided for @guardianVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Guardian Verification'**
  String get guardianVerificationTitle;

  /// No description provided for @dependentKycTitle.
  ///
  /// In en, this message translates to:
  /// **'Dependent Verification (KYC)'**
  String get dependentKycTitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @registeringAsLabel.
  ///
  /// In en, this message translates to:
  /// **'Registering as'**
  String get registeringAsLabel;

  /// No description provided for @roleGuardianOption.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get roleGuardianOption;

  /// No description provided for @roleDependentOption.
  ///
  /// In en, this message translates to:
  /// **'Dependent'**
  String get roleDependentOption;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @alreadyHaveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccountPrompt;

  /// No description provided for @dontHaveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get dontHaveAccountPrompt;

  /// No description provided for @fieldRequiredError.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequiredError;

  /// No description provided for @invalidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmailError;

  /// No description provided for @passwordTooShortError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShortError;

  /// No description provided for @passwordTooWeakError.
  ///
  /// In en, this message translates to:
  /// **'Password must include at least one letter and one number'**
  String get passwordTooWeakError;

  /// No description provided for @passwordsDoNotMatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatchError;

  /// No description provided for @invalidPhoneError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Pakistani phone number (e.g. 03XXXXXXXXX)'**
  String get invalidPhoneError;

  /// No description provided for @invalidCnicError.
  ///
  /// In en, this message translates to:
  /// **'Enter CNIC in the format XXXXX-XXXXXXX-X'**
  String get invalidCnicError;

  /// No description provided for @cnicLabel.
  ///
  /// In en, this message translates to:
  /// **'CNIC Number'**
  String get cnicLabel;

  /// No description provided for @cnicHint.
  ///
  /// In en, this message translates to:
  /// **'XXXXX-XXXXXXX-X'**
  String get cnicHint;

  /// No description provided for @sendOtpButton.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtpButton;

  /// No description provided for @otpSentDummyMessage.
  ///
  /// In en, this message translates to:
  /// **'OTP sent (dummy — Task 1.11 UI only)'**
  String get otpSentDummyMessage;

  /// No description provided for @otpLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get otpLabel;

  /// No description provided for @verifyAndContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verifyAndContinueButton;

  /// No description provided for @noLivenessRequiredNote.
  ///
  /// In en, this message translates to:
  /// **'Guardian verification does not require a liveness photo.'**
  String get noLivenessRequiredNote;

  /// No description provided for @captureLivenessButton.
  ///
  /// In en, this message translates to:
  /// **'Capture Liveness Photo'**
  String get captureLivenessButton;

  /// No description provided for @livenessCapturedConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Liveness photo captured (mock)'**
  String get livenessCapturedConfirmation;

  /// No description provided for @submitForVerificationButton.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get submitForVerificationButton;

  /// No description provided for @genericValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please check the fields and try again.'**
  String get genericValidationError;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @tryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainButton;

  /// No description provided for @goToLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Go to login'**
  String get goToLoginButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @saveButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButtonLabel;

  /// No description provided for @yesLabel.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesLabel;

  /// No description provided for @notYetLabel.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYetLabel;

  /// No description provided for @primaryRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primaryRoleLabel;

  /// No description provided for @secondaryRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get secondaryRoleLabel;

  /// No description provided for @primaryGuardianFullLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary Guardian'**
  String get primaryGuardianFullLabel;

  /// No description provided for @secondaryGuardianFullLabel.
  ///
  /// In en, this message translates to:
  /// **'Secondary Guardian'**
  String get secondaryGuardianFullLabel;

  /// No description provided for @verifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedLabel;

  /// No description provided for @notVerifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get notVerifiedLabel;

  /// No description provided for @guardianVerifyEitherOptionNote.
  ///
  /// In en, this message translates to:
  /// **'Either option below is enough to verify your account — you don\'t need to do both.'**
  String get guardianVerifyEitherOptionNote;

  /// No description provided for @guardianVerifyOptionAHeader.
  ///
  /// In en, this message translates to:
  /// **'Option A: verify by phone OTP'**
  String get guardianVerifyOptionAHeader;

  /// No description provided for @guardianVerifyOptionBHeader.
  ///
  /// In en, this message translates to:
  /// **'Option B: verify by CNIC'**
  String get guardianVerifyOptionBHeader;

  /// No description provided for @resendOtpButton.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtpButton;

  /// No description provided for @otpSentSnackbar.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to your registered phone number.'**
  String get otpSentSnackbar;

  /// No description provided for @otpNotVerifiedYetSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet — try the CNIC check below instead.'**
  String get otpNotVerifiedYetSnackbar;

  /// No description provided for @otpInvalidError.
  ///
  /// In en, this message translates to:
  /// **'That code is wrong or expired. Try again or resend.'**
  String get otpInvalidError;

  /// No description provided for @cnicCheckFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'CNIC check failed — try the phone OTP above instead.'**
  String get cnicCheckFailedSnackbar;

  /// No description provided for @openingCameraLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening camera...'**
  String get openingCameraLabel;

  /// No description provided for @lostRegistrationDetailsError.
  ///
  /// In en, this message translates to:
  /// **'We lost track of your registration details (this happens if the app was closed). Please register again to continue.'**
  String get lostRegistrationDetailsError;

  /// No description provided for @kycInvalidCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Something\'s wrong with your account details - please register again.'**
  String get kycInvalidCredentialsError;

  /// No description provided for @kycAlreadyVerifiedError.
  ///
  /// In en, this message translates to:
  /// **'You\'re already verified. Try logging in once your guardian links you.'**
  String get kycAlreadyVerifiedError;

  /// No description provided for @cnicAlreadyRegisteredError.
  ///
  /// In en, this message translates to:
  /// **'This CNIC is already registered to another account.'**
  String get cnicAlreadyRegisteredError;

  /// No description provided for @kycValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please check the CNIC and photo and try again.'**
  String get kycValidationError;

  /// No description provided for @kycVerifiedWaitingDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Verified. Waiting for your Primary Guardian to link you.'**
  String get kycVerifiedWaitingDefaultMessage;

  /// No description provided for @shareIdWithGuardianLabel.
  ///
  /// In en, this message translates to:
  /// **'Share this ID with your Guardian so they can link you:'**
  String get shareIdWithGuardianLabel;

  /// No description provided for @kycVerifiedActiveDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re verified and active.'**
  String get kycVerifiedActiveDefaultMessage;

  /// No description provided for @kycPendingDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Still pending - please submit again.'**
  String get kycPendingDefaultMessage;

  /// No description provided for @kycFailedDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Verification failed - please try again.'**
  String get kycFailedDefaultMessage;

  /// No description provided for @inviteCodeOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code (optional)'**
  String get inviteCodeOptionalLabel;

  /// No description provided for @inviteCodeHelperText.
  ///
  /// In en, this message translates to:
  /// **'Only if a Primary Guardian invited you as a Secondary Guardian.'**
  String get inviteCodeHelperText;

  /// No description provided for @roleLockedToGuardianNote.
  ///
  /// In en, this message translates to:
  /// **'Role locked to Guardian while an invite code is entered.'**
  String get roleLockedToGuardianNote;

  /// No description provided for @inviteInvalidError.
  ///
  /// In en, this message translates to:
  /// **'That invite code isn\'t valid.'**
  String get inviteInvalidError;

  /// No description provided for @inviteExpiredError.
  ///
  /// In en, this message translates to:
  /// **'That invite code has expired - ask for a new one.'**
  String get inviteExpiredError;

  /// No description provided for @inviteNotForYouRegisterError.
  ///
  /// In en, this message translates to:
  /// **'This invite was sent to a different phone number - use the exact number it was sent to.'**
  String get inviteNotForYouRegisterError;

  /// No description provided for @guardianCapReachedError.
  ///
  /// In en, this message translates to:
  /// **'This Dependent already has the maximum of 3 Guardians.'**
  String get guardianCapReachedError;

  /// No description provided for @emailAlreadyRegisteredError.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Try logging in instead.'**
  String get emailAlreadyRegisteredError;

  /// No description provided for @phoneAlreadyRegisteredError.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already registered.'**
  String get phoneAlreadyRegisteredError;

  /// No description provided for @accountAlreadyRegisteredError.
  ///
  /// In en, this message translates to:
  /// **'This account already exists. Try logging in instead.'**
  String get accountAlreadyRegisteredError;

  /// No description provided for @invalidCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get invalidCredentialsError;

  /// No description provided for @accountNotActivatedError.
  ///
  /// In en, this message translates to:
  /// **'Your account isn\'t active yet — complete KYC and wait for your guardian to link you.'**
  String get accountNotActivatedError;

  /// No description provided for @haveInviteCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Have an invite code?'**
  String get haveInviteCodeButton;

  /// No description provided for @linkADependentLabel.
  ///
  /// In en, this message translates to:
  /// **'Link a Dependent'**
  String get linkADependentLabel;

  /// No description provided for @noDependentsLinkedMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re not linked to any Dependents yet. Use \"Link a Dependent\" below with their ID to get started.'**
  String get noDependentsLinkedMessage;

  /// No description provided for @kycStatusPrefixLabel.
  ///
  /// In en, this message translates to:
  /// **'KYC'**
  String get kycStatusPrefixLabel;

  /// No description provided for @accountActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get accountActiveLabel;

  /// No description provided for @accountNotActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Not active yet'**
  String get accountNotActiveLabel;

  /// No description provided for @kycStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get kycStatusPending;

  /// No description provided for @kycStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get kycStatusVerified;

  /// No description provided for @kycStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get kycStatusFailed;

  /// No description provided for @linkDependentInstructions.
  ///
  /// In en, this message translates to:
  /// **'Ask the Dependent for the ID shown on their verification screen, then enter it below.'**
  String get linkDependentInstructions;

  /// No description provided for @dependentIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Dependent\'s ID'**
  String get dependentIdLabel;

  /// No description provided for @linkButton.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get linkButton;

  /// No description provided for @linkedSuccessSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Linked! You can now see this Dependent on your home screen.'**
  String get linkedSuccessSnackbar;

  /// No description provided for @guardianNotVerifiedLinkError.
  ///
  /// In en, this message translates to:
  /// **'You need to verify your own account before you can link a Dependent.'**
  String get guardianNotVerifiedLinkError;

  /// No description provided for @secondaryCannotLinkError.
  ///
  /// In en, this message translates to:
  /// **'Only a Primary Guardian can link a Dependent - your account is Secondary.'**
  String get secondaryCannotLinkError;

  /// No description provided for @dependentNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'No account found with that ID - double check it and try again.'**
  String get dependentNotFoundError;

  /// No description provided for @alreadyLinkedError.
  ///
  /// In en, this message translates to:
  /// **'You\'re already linked to this Dependent.'**
  String get alreadyLinkedError;

  /// No description provided for @primaryAlreadyExistsError.
  ///
  /// In en, this message translates to:
  /// **'This Dependent already has a Primary Guardian.'**
  String get primaryAlreadyExistsError;

  /// No description provided for @yourRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Your role:'**
  String get yourRoleLabel;

  /// No description provided for @kycStatusColonLabel.
  ///
  /// In en, this message translates to:
  /// **'KYC status:'**
  String get kycStatusColonLabel;

  /// No description provided for @accountActiveColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Account active:'**
  String get accountActiveColonLabel;

  /// No description provided for @linkedGuardiansHeader.
  ///
  /// In en, this message translates to:
  /// **'Linked Guardians'**
  String get linkedGuardiansHeader;

  /// No description provided for @inviteASecondaryButton.
  ///
  /// In en, this message translates to:
  /// **'Invite a Secondary Guardian'**
  String get inviteASecondaryButton;

  /// No description provided for @managePermissionsButton.
  ///
  /// In en, this message translates to:
  /// **'Manage Permissions'**
  String get managePermissionsButton;

  /// No description provided for @myAccessButton.
  ///
  /// In en, this message translates to:
  /// **'My Access'**
  String get myAccessButton;

  /// No description provided for @invitePhoneInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter the Secondary Guardian\'s phone number. They\'ll need the code this generates.'**
  String get invitePhoneInstructions;

  /// No description provided for @sendInviteButton.
  ///
  /// In en, this message translates to:
  /// **'Send invite'**
  String get sendInviteButton;

  /// No description provided for @guardianNotVerifiedGenericError.
  ///
  /// In en, this message translates to:
  /// **'You need to verify your own account first.'**
  String get guardianNotVerifiedGenericError;

  /// No description provided for @notPrimaryGuardianError.
  ///
  /// In en, this message translates to:
  /// **'You\'re not this Dependent\'s Primary Guardian.'**
  String get notPrimaryGuardianError;

  /// No description provided for @inviteeNotEligibleError.
  ///
  /// In en, this message translates to:
  /// **'That number can\'t be invited (it may already belong to an account, or be the Dependent\'s own number).'**
  String get inviteeNotEligibleError;

  /// No description provided for @invitePhoneValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please check the phone number and try again.'**
  String get invitePhoneValidationError;

  /// No description provided for @inviteCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Invite created - valid for {days} days. Share this code with them:'**
  String inviteCreatedMessage(int days);

  /// No description provided for @copyCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCodeButton;

  /// No description provided for @copiedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Copied.'**
  String get copiedSnackbar;

  /// No description provided for @inviteShareFooterNote.
  ///
  /// In en, this message translates to:
  /// **'They enter this during registration (if they\'re new) or on the \"Have an invite code?\" screen (if they already have a Secondary account).'**
  String get inviteShareFooterNote;

  /// No description provided for @noSecondariesYetMessage.
  ///
  /// In en, this message translates to:
  /// **'No Secondary Guardians yet - invite one first.'**
  String get noSecondariesYetMessage;

  /// No description provided for @secondaryNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'That Guardian is no longer linked to this Dependent.'**
  String get secondaryNotFoundError;

  /// No description provided for @moduleLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'Live Location'**
  String get moduleLiveLocation;

  /// No description provided for @moduleHealthRecords.
  ///
  /// In en, this message translates to:
  /// **'Health Records'**
  String get moduleHealthRecords;

  /// No description provided for @moduleCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get moduleCommunication;

  /// No description provided for @moduleEmergencyAlerts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alerts'**
  String get moduleEmergencyAlerts;

  /// No description provided for @moduleCameraViewing.
  ///
  /// In en, this message translates to:
  /// **'Camera Viewing'**
  String get moduleCameraViewing;

  /// No description provided for @moduleMedicationManagement.
  ///
  /// In en, this message translates to:
  /// **'Medication Management'**
  String get moduleMedicationManagement;

  /// No description provided for @roleColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Role:'**
  String get roleColonLabel;

  /// No description provided for @notLinkedToDependentError.
  ///
  /// In en, this message translates to:
  /// **'You\'re not linked to this Dependent.'**
  String get notLinkedToDependentError;

  /// No description provided for @acceptAnInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept an invite'**
  String get acceptAnInviteTitle;

  /// No description provided for @pasteInviteCodeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Paste the invite code a Primary Guardian shared with you.'**
  String get pasteInviteCodeInstructions;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodeLabel;

  /// No description provided for @acceptButton.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptButton;

  /// No description provided for @inviteAcceptedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Accepted! This Dependent now shows on your home screen.'**
  String get inviteAcceptedSnackbar;

  /// No description provided for @primaryCannotAcceptInviteError.
  ///
  /// In en, this message translates to:
  /// **'A Primary Guardian account can\'t accept a Secondary invite.'**
  String get primaryCannotAcceptInviteError;

  /// No description provided for @inviteNotForYouAcceptError.
  ///
  /// In en, this message translates to:
  /// **'This code was sent to a different phone number than the one on your account.'**
  String get inviteNotForYouAcceptError;

  /// No description provided for @liveMapButton.
  ///
  /// In en, this message translates to:
  /// **'Live Map'**
  String get liveMapButton;

  /// No description provided for @noLocationYetMessage.
  ///
  /// In en, this message translates to:
  /// **'No location received yet.'**
  String get noLocationYetMessage;

  /// No description provided for @justNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNowLabel;

  /// No description provided for @lastSeenMinutesMessage.
  ///
  /// In en, this message translates to:
  /// **'Last seen {minutes} min ago'**
  String lastSeenMinutesMessage(int minutes);

  /// No description provided for @locationStaleWarning.
  ///
  /// In en, this message translates to:
  /// **'This location may be out of date.'**
  String get locationStaleWarning;

  /// No description provided for @zoneStatusInside.
  ///
  /// In en, this message translates to:
  /// **'Inside a safe zone'**
  String get zoneStatusInside;

  /// No description provided for @zoneStatusOutside.
  ///
  /// In en, this message translates to:
  /// **'Outside all safe zones'**
  String get zoneStatusOutside;

  /// No description provided for @zoneStatusNoZones.
  ///
  /// In en, this message translates to:
  /// **'No safe zones set up yet'**
  String get zoneStatusNoZones;

  /// No description provided for @zoneStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Location status unknown'**
  String get zoneStatusUnknown;

  /// No description provided for @moduleAccessDeniedLiveMapError.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to view this Dependent\'s location.'**
  String get moduleAccessDeniedLiveMapError;

  /// No description provided for @locationSharingActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Location sharing: Active'**
  String get locationSharingActiveLabel;

  /// No description provided for @locationPermissionNeededMessage.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed so your Guardian can see where you are.'**
  String get locationPermissionNeededMessage;

  /// No description provided for @grantLocationPermissionButton.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantLocationPermissionButton;

  /// No description provided for @locationPermissionDeniedForeverMessage.
  ///
  /// In en, this message translates to:
  /// **'Location permission was permanently denied. Enable it from your phone\'s Settings.'**
  String get locationPermissionDeniedForeverMessage;

  /// No description provided for @locationServiceDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Turn on Location Services in your phone\'s Settings to share your location.'**
  String get locationServiceDisabledMessage;

  /// No description provided for @openSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettingsButton;

  /// No description provided for @dependentHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get dependentHomeTitle;

  /// No description provided for @dependentHomeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Assalam o Alaikum, {name}'**
  String dependentHomeGreeting(String name);

  /// No description provided for @panicButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'PANIC'**
  String get panicButtonLabel;

  /// No description provided for @panicButtonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Press for help'**
  String get panicButtonSubtitle;

  /// No description provided for @iAmOkButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'I am OK'**
  String get iAmOkButtonLabel;

  /// No description provided for @myMedicineButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'My medicine'**
  String get myMedicineButtonLabel;

  /// No description provided for @nextWellnessCheckMessage.
  ///
  /// In en, this message translates to:
  /// **'Next check: {time}'**
  String nextWellnessCheckMessage(String time);

  /// No description provided for @noWellnessCheckScheduledMessage.
  ///
  /// In en, this message translates to:
  /// **'No wellness check scheduled'**
  String get noWellnessCheckScheduledMessage;

  /// No description provided for @nextMedicationMessage.
  ///
  /// In en, this message translates to:
  /// **'Next: {drug} at {time}'**
  String nextMedicationMessage(String drug, String time);

  /// No description provided for @noMedicationScheduledMessage.
  ///
  /// In en, this message translates to:
  /// **'No medicine scheduled'**
  String get noMedicationScheduledMessage;

  /// No description provided for @moreComingSoonLabel.
  ///
  /// In en, this message translates to:
  /// **'More: records · appointments · messages (coming soon)'**
  String get moreComingSoonLabel;

  /// No description provided for @panicScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Panic'**
  String get panicScreenTitle;

  /// No description provided for @panicNeedHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get panicNeedHelpTitle;

  /// No description provided for @panicHoldInstructions.
  ///
  /// In en, this message translates to:
  /// **'Press and hold the button for 2 seconds'**
  String get panicHoldInstructions;

  /// No description provided for @panicHoldButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'HOLD'**
  String get panicHoldButtonLabel;

  /// No description provided for @panicHoldButtonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'to send help'**
  String get panicHoldButtonSubtitle;

  /// No description provided for @panicSendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Sending alert...'**
  String get panicSendingLabel;

  /// No description provided for @panicAllGuardiansToldNote.
  ///
  /// In en, this message translates to:
  /// **'All your Guardians will be told at once.'**
  String get panicAllGuardiansToldNote;

  /// No description provided for @panicHoldStopsAccidentNote.
  ///
  /// In en, this message translates to:
  /// **'Holding stops accidental alerts.'**
  String get panicHoldStopsAccidentNote;

  /// No description provided for @panicHelpIsComingTitle.
  ///
  /// In en, this message translates to:
  /// **'Help is coming'**
  String get panicHelpIsComingTitle;

  /// No description provided for @panicToldCountMessage.
  ///
  /// In en, this message translates to:
  /// **'We told {count} Guardian(s)'**
  String panicToldCountMessage(int count);

  /// No description provided for @panicTriggeredAtMessage.
  ///
  /// In en, this message translates to:
  /// **'at {time}'**
  String panicTriggeredAtMessage(String time);

  /// No description provided for @panicAcknowledgedAtMessage.
  ///
  /// In en, this message translates to:
  /// **'Seen by a Guardian at {time}'**
  String panicAcknowledgedAtMessage(String time);

  /// No description provided for @panicWaitingForAckMessage.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a Guardian to see this'**
  String get panicWaitingForAckMessage;

  /// No description provided for @panicEscalatedMessage.
  ///
  /// In en, this message translates to:
  /// **'This has reached your emergency contact.'**
  String get panicEscalatedMessage;

  /// No description provided for @panicAutoEscalateNote.
  ///
  /// In en, this message translates to:
  /// **'If nobody answers within 5 minutes, your emergency contact is reached.'**
  String get panicAutoEscalateNote;

  /// No description provided for @iAmSafeNowButton.
  ///
  /// In en, this message translates to:
  /// **'I am safe now'**
  String get iAmSafeNowButton;

  /// No description provided for @panicResolvedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Marked safe. Glad you\'re OK.'**
  String get panicResolvedSnackbar;

  /// No description provided for @panicTriggerFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the alert. Check your connection and try again.'**
  String get panicTriggerFailedSnackbar;

  /// No description provided for @panicResolveFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t mark you safe. Try again.'**
  String get panicResolveFailedSnackbar;

  /// No description provided for @wellnessCheckScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Wellness check'**
  String get wellnessCheckScreenTitle;

  /// No description provided for @areYouOkTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you OK?'**
  String get areYouOkTitle;

  /// No description provided for @familyCheckingOnYouMessage.
  ///
  /// In en, this message translates to:
  /// **'Your family is checking on you'**
  String get familyCheckingOnYouMessage;

  /// No description provided for @answerWithinMessage.
  ///
  /// In en, this message translates to:
  /// **'Answer within {time}'**
  String answerWithinMessage(String time);

  /// No description provided for @yesIAmOkButton.
  ///
  /// In en, this message translates to:
  /// **'Yes, I am OK'**
  String get yesIAmOkButton;

  /// No description provided for @iNeedHelpButton.
  ///
  /// In en, this message translates to:
  /// **'I need help'**
  String get iNeedHelpButton;

  /// No description provided for @iNeedHelpOpensPanicNote.
  ///
  /// In en, this message translates to:
  /// **'\'I need help\' opens Panic.'**
  String get iNeedHelpOpensPanicNote;

  /// No description provided for @noAnswerGuardianToldNote.
  ///
  /// In en, this message translates to:
  /// **'No answer → your Guardian is told.'**
  String get noAnswerGuardianToldNote;

  /// No description provided for @noWellnessCheckPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'There\'s no wellness check waiting for a response right now.'**
  String get noWellnessCheckPendingMessage;

  /// No description provided for @wellnessCheckTimeUpNote.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up — your Guardian may be notified. You can still answer below.'**
  String get wellnessCheckTimeUpNote;

  /// No description provided for @wellnessCheckRespondedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Thanks — marked as OK.'**
  String get wellnessCheckRespondedSnackbar;

  /// No description provided for @wellnessCheckRespondFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your answer. Try again.'**
  String get wellnessCheckRespondFailedSnackbar;

  /// No description provided for @medicationScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'My medicine'**
  String get medicationScreenTitle;

  /// No description provided for @medicineStep1OfTwoLabel.
  ///
  /// In en, this message translates to:
  /// **'I took my medicine · Step 1 of 2'**
  String get medicineStep1OfTwoLabel;

  /// No description provided for @noMedicineDueMessage.
  ///
  /// In en, this message translates to:
  /// **'There\'s no medicine due right now.'**
  String get noMedicineDueMessage;

  /// No description provided for @medicineTimePromptTitle.
  ///
  /// In en, this message translates to:
  /// **'It\'s time for your medicine'**
  String get medicineTimePromptTitle;

  /// No description provided for @medicineTimePromptMessage.
  ///
  /// In en, this message translates to:
  /// **'{drug} ({dosage}) — did you take it?'**
  String medicineTimePromptMessage(String drug, String dosage);

  /// No description provided for @medicineTookItButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'I took it'**
  String get medicineTookItButtonLabel;

  /// No description provided for @medicineConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm you took it'**
  String get medicineConfirmTitle;

  /// No description provided for @medicineConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Please confirm: {drug} ({dosage})'**
  String medicineConfirmMessage(String drug, String dosage);

  /// No description provided for @medicineConfirmExpiresNote.
  ///
  /// In en, this message translates to:
  /// **'This confirmation expires in {time}'**
  String medicineConfirmExpiresNote(String time);

  /// No description provided for @medicineConfirmButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Yes, I took it'**
  String get medicineConfirmButtonLabel;

  /// No description provided for @medicineConfirmExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'This confirmation window expired.'**
  String get medicineConfirmExpiredMessage;

  /// No description provided for @medicineTryAgainButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get medicineTryAgainButtonLabel;

  /// No description provided for @medicineTakenTitle.
  ///
  /// In en, this message translates to:
  /// **'Marked as taken'**
  String get medicineTakenTitle;

  /// No description provided for @medicineTakenMessage.
  ///
  /// In en, this message translates to:
  /// **'{drug} is marked as taken.'**
  String medicineTakenMessage(String drug);

  /// No description provided for @medicineDoneButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get medicineDoneButtonLabel;

  /// No description provided for @medicineConfirmRequestFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the confirmation. Try again.'**
  String get medicineConfirmRequestFailedSnackbar;

  /// No description provided for @medicineConfirmFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t confirm. Try again.'**
  String get medicineConfirmFailedSnackbar;

  /// No description provided for @medicationScheduleButton.
  ///
  /// In en, this message translates to:
  /// **'Medication schedule'**
  String get medicationScheduleButton;

  /// No description provided for @wellnessScheduleButton.
  ///
  /// In en, this message translates to:
  /// **'Wellness check schedule'**
  String get wellnessScheduleButton;

  /// No description provided for @medicationScheduleScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Medication schedule'**
  String get medicationScheduleScreenTitle;

  /// No description provided for @wellnessScheduleScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Wellness check schedule'**
  String get wellnessScheduleScreenTitle;

  /// No description provided for @noMedicationSchedulesMessage.
  ///
  /// In en, this message translates to:
  /// **'No medicines scheduled yet.'**
  String get noMedicationSchedulesMessage;

  /// No description provided for @noWellnessSchedulesMessage.
  ///
  /// In en, this message translates to:
  /// **'No wellness check times scheduled yet.'**
  String get noWellnessSchedulesMessage;

  /// No description provided for @useDefaultScheduleButton.
  ///
  /// In en, this message translates to:
  /// **'Use default schedule (8am, 2pm, 8pm)'**
  String get useDefaultScheduleButton;

  /// No description provided for @medicationManagementDeniedNote.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to manage medicines. Ask the Primary Guardian.'**
  String get medicationManagementDeniedNote;

  /// No description provided for @wellnessManagementDeniedNote.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to manage wellness checks. Ask the Primary Guardian.'**
  String get wellnessManagementDeniedNote;

  /// No description provided for @drugNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Medicine name'**
  String get drugNameFieldLabel;

  /// No description provided for @dosageFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosageFieldLabel;

  /// No description provided for @timeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeFieldLabel;

  /// No description provided for @frequencyFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequencyFieldLabel;

  /// No description provided for @dailyLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyLabel;

  /// No description provided for @weeklyLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklyLabel;

  /// No description provided for @gracePeriodFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Grace period (minutes)'**
  String get gracePeriodFieldLabel;

  /// No description provided for @gracePeriodMinutesMessage.
  ///
  /// In en, this message translates to:
  /// **'Grace period: {minutes} min'**
  String gracePeriodMinutesMessage(int minutes);

  /// No description provided for @addMedicationScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Add medicine'**
  String get addMedicationScheduleTitle;

  /// No description provided for @editMedicationScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit medicine'**
  String get editMedicationScheduleTitle;

  /// No description provided for @addWellnessCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Add check time'**
  String get addWellnessCheckTitle;

  /// No description provided for @editWellnessCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit check time'**
  String get editWellnessCheckTitle;

  /// No description provided for @scheduleSavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get scheduleSavedSnackbar;

  /// No description provided for @scheduleSaveFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Try again.'**
  String get scheduleSaveFailedSnackbar;

  /// No description provided for @scheduleUpdateFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update. Try again.'**
  String get scheduleUpdateFailedSnackbar;

  /// No description provided for @weeklyDaysRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day for a weekly schedule.'**
  String get weeklyDaysRequiredError;

  /// No description provided for @wellnessLimitReachedError.
  ///
  /// In en, this message translates to:
  /// **'You can have at most 3 wellness check times.'**
  String get wellnessLimitReachedError;

  /// No description provided for @wellnessTimeExistsError.
  ///
  /// In en, this message translates to:
  /// **'There\'s already a check at that time.'**
  String get wellnessTimeExistsError;

  /// No description provided for @dayMonLabel.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMonLabel;

  /// No description provided for @dayTueLabel.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTueLabel;

  /// No description provided for @dayWedLabel.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWedLabel;

  /// No description provided for @dayThuLabel.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThuLabel;

  /// No description provided for @dayFriLabel.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFriLabel;

  /// No description provided for @daySatLabel.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySatLabel;

  /// No description provided for @daySunLabel.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySunLabel;

  /// No description provided for @goBackButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBackButtonLabel;

  /// No description provided for @alertTypePanic.
  ///
  /// In en, this message translates to:
  /// **'Panic alert'**
  String get alertTypePanic;

  /// No description provided for @alertTypeMissedDose.
  ///
  /// In en, this message translates to:
  /// **'Missed dose'**
  String get alertTypeMissedDose;

  /// No description provided for @alertTypeWellnessCheck.
  ///
  /// In en, this message translates to:
  /// **'Wellness check missed'**
  String get alertTypeWellnessCheck;

  /// No description provided for @alertTypeGeofenceBreach.
  ///
  /// In en, this message translates to:
  /// **'Left the safe zone'**
  String get alertTypeGeofenceBreach;

  /// No description provided for @alertTypeLowBattery.
  ///
  /// In en, this message translates to:
  /// **'Low battery'**
  String get alertTypeLowBattery;

  /// No description provided for @alertTypeDeviceOffline.
  ///
  /// In en, this message translates to:
  /// **'Phone offline'**
  String get alertTypeDeviceOffline;

  /// No description provided for @alertTypeExternalContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact alert'**
  String get alertTypeExternalContact;

  /// No description provided for @alertTypeGeneric.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alertTypeGeneric;

  /// No description provided for @tierLevel1PrimaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Level 1 · Primary'**
  String get tierLevel1PrimaryLabel;

  /// No description provided for @tierLevel2SecondaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Level 2 · Secondary'**
  String get tierLevel2SecondaryLabel;

  /// No description provided for @tierLevel3SmsLabel.
  ///
  /// In en, this message translates to:
  /// **'Level 3 · SMS sent'**
  String get tierLevel3SmsLabel;

  /// No description provided for @alertsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsScreenTitle;

  /// No description provided for @alertsOpenTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Open ({count})'**
  String alertsOpenTabLabel(int count);

  /// No description provided for @alertsSeenTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get alertsSeenTabLabel;

  /// No description provided for @alertsEmptyOpenMessage.
  ///
  /// In en, this message translates to:
  /// **'No open alerts.'**
  String get alertsEmptyOpenMessage;

  /// No description provided for @alertsEmptySeenMessage.
  ///
  /// In en, this message translates to:
  /// **'No seen alerts yet.'**
  String get alertsEmptySeenMessage;

  /// No description provided for @iveSeenItButton.
  ///
  /// In en, this message translates to:
  /// **'I\'ve seen it'**
  String get iveSeenItButton;

  /// No description provided for @seenStopsChainTitle.
  ///
  /// In en, this message translates to:
  /// **'Seen stops the chain'**
  String get seenStopsChainTitle;

  /// No description provided for @seenStopsChainBody.
  ///
  /// In en, this message translates to:
  /// **'Primary → Secondary (5 min) → SMS (5 min)'**
  String get seenStopsChainBody;

  /// No description provided for @acknowledgeFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t mark as seen. Try again.'**
  String get acknowledgeFailedSnackbar;

  /// No description provided for @needsAttentionHeader.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get needsAttentionHeader;

  /// No description provided for @seeAllLabel.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAllLabel;

  /// No description provided for @panicBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'PANIC ALERT'**
  String get panicBannerTitle;

  /// No description provided for @panicBannerBody.
  ///
  /// In en, this message translates to:
  /// **'{name} pressed panic · {time}'**
  String panicBannerBody(String name, String time);

  /// No description provided for @openButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openButtonLabel;

  /// No description provided for @missedDoseScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Missed dose'**
  String get missedDoseScreenTitle;

  /// No description provided for @missedDoseBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} has not taken {drug}'**
  String missedDoseBannerTitle(String name, String drug);

  /// No description provided for @whatHappensNextHeader.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get whatHappensNextHeader;

  /// No description provided for @missedDoseStepYouToldLabel.
  ///
  /// In en, this message translates to:
  /// **'You are told (Primary)'**
  String get missedDoseStepYouToldLabel;

  /// No description provided for @missedDoseStepSecondaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Secondaries told if unseen'**
  String get missedDoseStepSecondaryLabel;

  /// No description provided for @missedDoseStepSmsLabel.
  ///
  /// In en, this message translates to:
  /// **'SMS to emergency contact if unseen'**
  String get missedDoseStepSmsLabel;

  /// No description provided for @giveMoreTimeButton.
  ///
  /// In en, this message translates to:
  /// **'Give more time (+30 min)'**
  String get giveMoreTimeButton;

  /// No description provided for @tellOtherGuardiansButton.
  ///
  /// In en, this message translates to:
  /// **'Tell other Guardians now'**
  String get tellOtherGuardiansButton;

  /// No description provided for @callButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String callButtonLabel(String name);

  /// No description provided for @tappingCountsAsSeenNote.
  ///
  /// In en, this message translates to:
  /// **'Tapping any option counts as seen.'**
  String get tappingCountsAsSeenNote;

  /// No description provided for @extendSuccessSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Given 30 more minutes.'**
  String get extendSuccessSnackbar;

  /// No description provided for @escalateSuccessSnackbar.
  ///
  /// In en, this message translates to:
  /// **'{count} Secondary Guardian(s) notified.'**
  String escalateSuccessSnackbar(int count);

  /// No description provided for @escalateNoSecondarySnackbar.
  ///
  /// In en, this message translates to:
  /// **'No Secondary Guardian can see alerts yet.'**
  String get escalateNoSecondarySnackbar;

  /// No description provided for @doseAlreadyResolvedMessage.
  ///
  /// In en, this message translates to:
  /// **'This alert has already been resolved.'**
  String get doseAlreadyResolvedMessage;

  /// No description provided for @alreadyEscalatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Already told the other Guardians.'**
  String get alreadyEscalatedMessage;

  /// No description provided for @callFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the call.'**
  String get callFailedSnackbar;

  /// No description provided for @emergencySettingsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency settings'**
  String get emergencySettingsScreenTitle;

  /// No description provided for @emergencySettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Emergency settings'**
  String get emergencySettingsButton;

  /// No description provided for @remoteAlarmSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote alarm'**
  String get remoteAlarmSectionTitle;

  /// No description provided for @primaryOnlyBadge.
  ///
  /// In en, this message translates to:
  /// **'Primary only'**
  String get primaryOnlyBadge;

  /// No description provided for @remoteAlarmDescription.
  ///
  /// In en, this message translates to:
  /// **'Rings {name}\'s phone loudly, even on silent. Use it to find them nearby.'**
  String remoteAlarmDescription(String name);

  /// No description provided for @ringAlarmButton.
  ///
  /// In en, this message translates to:
  /// **'Ring alarm (60 s)'**
  String get ringAlarmButton;

  /// No description provided for @stopAlarmButton.
  ///
  /// In en, this message translates to:
  /// **'Stop alarm'**
  String get stopAlarmButton;

  /// No description provided for @alarmAlreadyActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Alarm is already sounding.'**
  String get alarmAlreadyActiveMessage;

  /// No description provided for @alarmStartFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the alarm. Try again.'**
  String get alarmStartFailedSnackbar;

  /// No description provided for @alarmStopFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t stop the alarm. Try again.'**
  String get alarmStopFailedSnackbar;

  /// No description provided for @notPrimaryGuardianNote.
  ///
  /// In en, this message translates to:
  /// **'Only the Primary Guardian can use the remote alarm and set the emergency contact.'**
  String get notPrimaryGuardianNote;

  /// No description provided for @emergencyContactSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get emergencyContactSectionTitle;

  /// No description provided for @emergencyContactDescription.
  ///
  /// In en, this message translates to:
  /// **'Gets one SMS if no Guardian answers an alert in 10 minutes.'**
  String get emergencyContactDescription;

  /// No description provided for @contactNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get contactNameFieldLabel;

  /// No description provided for @contactPhoneFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get contactPhoneFieldLabel;

  /// No description provided for @saveContactButton.
  ///
  /// In en, this message translates to:
  /// **'Save contact'**
  String get saveContactButton;

  /// No description provided for @contactSavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Contact saved.'**
  String get contactSavedSnackbar;

  /// No description provided for @contactSaveFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the contact. Try again.'**
  String get contactSaveFailedSnackbar;

  /// No description provided for @noEmergencyContactMessage.
  ///
  /// In en, this message translates to:
  /// **'No emergency contact set yet.'**
  String get noEmergencyContactMessage;

  /// No description provided for @removeContactButton.
  ///
  /// In en, this message translates to:
  /// **'Remove contact'**
  String get removeContactButton;

  /// No description provided for @contactRemovedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Contact removed.'**
  String get contactRemovedSnackbar;

  /// No description provided for @contactRemoveFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove the contact. Try again.'**
  String get contactRemoveFailedSnackbar;

  /// No description provided for @emergencyContactDeniedNote.
  ///
  /// In en, this message translates to:
  /// **'You can view this but only the Primary Guardian can change it.'**
  String get emergencyContactDeniedNote;

  /// No description provided for @alarmScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get alarmScreenTitle;

  /// No description provided for @alarmLookingForYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Guardian is looking for you'**
  String get alarmLookingForYouTitle;

  /// No description provided for @alarmScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alarm from your Guardian · {remaining} left'**
  String alarmScreenSubtitle(String remaining);

  /// No description provided for @stopAlarmButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop alarm'**
  String get stopAlarmButtonLabel;

  /// No description provided for @stopAlarmFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t stop the alarm. Try again.'**
  String get stopAlarmFailedSnackbar;

  /// No description provided for @noActiveAlarmMessage.
  ///
  /// In en, this message translates to:
  /// **'No alarm is sounding right now.'**
  String get noActiveAlarmMessage;

  /// No description provided for @messagesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesScreenTitle;

  /// No description provided for @noConversationsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet.'**
  String get noConversationsYetMessage;

  /// No description provided for @noMessagesYetPreview.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYetPreview;

  /// No description provided for @urgentVoiceMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Urgent voice message'**
  String get urgentVoiceMessageLabel;

  /// No description provided for @loadEarlierMessagesButton.
  ///
  /// In en, this message translates to:
  /// **'Load earlier messages'**
  String get loadEarlierMessagesButton;

  /// No description provided for @startConversationMessage.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hello!'**
  String get startConversationMessage;

  /// No description provided for @messageInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get messageInputHint;

  /// No description provided for @messageSendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get messageSendTooltip;

  /// No description provided for @sendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sendingLabel;

  /// No description provided for @notSentTapToRetryLabel.
  ///
  /// In en, this message translates to:
  /// **'Not sent · Tap to retry'**
  String get notSentTapToRetryLabel;

  /// No description provided for @readLabel.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get readLabel;

  /// No description provided for @communicationAccessDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Only Guardians with Communication access can message right now.'**
  String get communicationAccessDeniedMessage;

  /// No description provided for @messagesButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesButtonLabel;

  /// No description provided for @messageButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageButtonLabel;

  /// No description provided for @unreadMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} new message(s)'**
  String unreadMessagesSubtitle(int count);

  /// No description provided for @quickReplyIAmFine.
  ///
  /// In en, this message translates to:
  /// **'I am fine'**
  String get quickReplyIAmFine;

  /// No description provided for @quickReplyCallMe.
  ///
  /// In en, this message translates to:
  /// **'Call me'**
  String get quickReplyCallMe;

  /// No description provided for @quickReplyYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get quickReplyYes;

  /// No description provided for @quickReplyNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get quickReplyNo;

  /// No description provided for @recordUrgentVoiceSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Record an urgent voice message'**
  String get recordUrgentVoiceSheetTitle;

  /// No description provided for @urgentVoiceWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'This will ring as a critical alert on {peerName}\'s phone, even on silent.'**
  String urgentVoiceWarningMessage(String peerName);

  /// No description provided for @tapToStartRecordingLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to start recording'**
  String get tapToStartRecordingLabel;

  /// No description provided for @recordingInProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Recording… {time}'**
  String recordingInProgressLabel(String time);

  /// No description provided for @maxLengthReachedMessage.
  ///
  /// In en, this message translates to:
  /// **'Maximum length reached (2:00).'**
  String get maxLengthReachedMessage;

  /// No description provided for @stopRecordingButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopRecordingButtonLabel;

  /// No description provided for @discardRecordingButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardRecordingButtonLabel;

  /// No description provided for @playPreviewButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playPreviewButtonLabel;

  /// No description provided for @sendUrgentVoiceButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendUrgentVoiceButtonLabel;

  /// No description provided for @micPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is needed to record a voice message.'**
  String get micPermissionDeniedMessage;

  /// No description provided for @voiceSendFailedGenericMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the voice message. Try again.'**
  String get voiceSendFailedGenericMessage;

  /// No description provided for @audioDownloadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the voice message. Try again.'**
  String get audioDownloadFailedMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
