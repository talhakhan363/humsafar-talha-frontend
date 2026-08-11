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
  /// **'Password must be at least 6 characters'**
  String get passwordTooShortError;

  /// No description provided for @passwordsDoNotMatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatchError;

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
