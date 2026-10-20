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
