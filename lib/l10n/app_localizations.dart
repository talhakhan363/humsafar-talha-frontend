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
