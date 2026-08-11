// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'ہمسفر';

  @override
  String get guardianAppTitle => 'گارڈین ایپ';

  @override
  String get dependentAppTitle => 'ڈیپینڈنٹ ایپ';

  @override
  String get devRoleSwitcherTitle => 'ہمسفر — ڈیو رول سوئچر';

  @override
  String get devRoleSwitcherBody =>
      'عارضی اسکرین — اسے اصل لاگ ان (ٹاسک 1.11 / 2.5) سے تبدیل کیا جائے گا۔';

  @override
  String get continueAsGuardian => 'بطور گارڈین جاری رکھیں';

  @override
  String get continueAsDependent => 'بطور ڈیپینڈنٹ جاری رکھیں';

  @override
  String get guardianHomePlaceholder =>
      'گارڈین ہوم اسکرین کی جگہ نما۔\nاصل ڈیش بورڈ مواد فیز 2 سے شامل ہوگا۔';

  @override
  String get dependentHomePlaceholder =>
      'ڈیپینڈنٹ ہوم اسکرین کی جگہ نما۔\nتین حفاظتی اقدامات (پینک موڈ، ویلنیس چیک، دوا) ٹاسک 3.10 سے یہاں شامل ہوں گے۔';

  @override
  String get switchModeTooltip => 'موڈ تبدیل کریں (صرف ڈیو)';

  @override
  String get switchToStandardView => 'معیاری ویو پر جائیں';

  @override
  String get switchToAccessibleView => 'بڑے حروف، ہائی کنٹراسٹ ویو پر جائیں';

  @override
  String get previewLoginLink => 'پیش منظر: لاگ ان اسکرین (ٹاسک 1.11)';

  @override
  String get previewRegisterLink => 'پیش منظر: رجسٹر اسکرین (ٹاسک 1.11)';

  @override
  String get registerScreenTitle => 'اکاؤنٹ بنائیں';

  @override
  String get loginScreenTitle => 'لاگ ان';

  @override
  String get guardianVerificationTitle => 'گارڈین کی تصدیق';

  @override
  String get dependentKycTitle => 'ڈیپینڈنٹ کی تصدیق (KYC)';

  @override
  String get fullNameLabel => 'پورا نام';

  @override
  String get emailLabel => 'ای میل';

  @override
  String get phoneLabel => 'فون نمبر';

  @override
  String get passwordLabel => 'پاس ورڈ';

  @override
  String get confirmPasswordLabel => 'پاس ورڈ کی تصدیق کریں';

  @override
  String get registeringAsLabel => 'بطور رجسٹر ہو رہے ہیں';

  @override
  String get roleGuardianOption => 'گارڈین';

  @override
  String get roleDependentOption => 'ڈیپینڈنٹ';

  @override
  String get registerButton => 'رجسٹر کریں';

  @override
  String get loginButton => 'لاگ ان کریں';

  @override
  String get alreadyHaveAccountPrompt => 'پہلے سے اکاؤنٹ ہے؟ لاگ ان کریں';

  @override
  String get dontHaveAccountPrompt => 'اکاؤنٹ نہیں ہے؟ رجسٹر کریں';

  @override
  String get fieldRequiredError => 'یہ خانہ ضروری ہے';

  @override
  String get invalidEmailError => 'درست ای میل ایڈریس درج کریں';

  @override
  String get passwordTooShortError => 'پاس ورڈ کم از کم 8 حروف کا ہونا چاہیے';

  @override
  String get passwordTooWeakError =>
      'پاس ورڈ میں کم از کم ایک حرف اور ایک ہندسہ ہونا ضروری ہے';

  @override
  String get passwordsDoNotMatchError => 'پاس ورڈ مماثل نہیں ہیں';

  @override
  String get invalidPhoneError =>
      'درست پاکستانی فون نمبر درج کریں (مثلاً 03XXXXXXXXX)';

  @override
  String get invalidCnicError =>
      'شناختی کارڈ نمبر اس فارمیٹ میں درج کریں: XXXXX-XXXXXXX-X';

  @override
  String get cnicLabel => 'شناختی کارڈ نمبر (CNIC)';

  @override
  String get cnicHint => 'XXXXX-XXXXXXX-X';

  @override
  String get sendOtpButton => 'OTP بھیجیں';

  @override
  String get otpSentDummyMessage =>
      'OTP بھیج دیا گیا (نمائشی — ٹاسک 1.11 صرف یو آئی)';

  @override
  String get otpLabel => 'OTP درج کریں';

  @override
  String get verifyAndContinueButton => 'تصدیق کریں اور جاری رکھیں';

  @override
  String get noLivenessRequiredNote =>
      'گارڈین کی تصدیق کے لیے لائیونیس تصویر درکار نہیں۔';

  @override
  String get captureLivenessButton => 'لائیونیس تصویر لیں';

  @override
  String get livenessCapturedConfirmation =>
      'لائیونیس تصویر لے لی گئی (نمائشی)';

  @override
  String get submitForVerificationButton => 'تصدیق کے لیے جمع کروائیں';
}
