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

  @override
  String get genericValidationError =>
      'براہ کرم خانے چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get retryButton => 'دوبارہ کوشش کریں';

  @override
  String get tryAgainButton => 'دوبارہ کوشش کریں';

  @override
  String get goToLoginButton => 'لاگ ان پر جائیں';

  @override
  String get cancelButton => 'منسوخ کریں';

  @override
  String get saveButtonLabel => 'محفوظ کریں';

  @override
  String get yesLabel => 'جی ہاں';

  @override
  String get notYetLabel => 'ابھی نہیں';

  @override
  String get primaryRoleLabel => 'پرائمری';

  @override
  String get secondaryRoleLabel => 'سیکنڈری';

  @override
  String get primaryGuardianFullLabel => 'پرائمری گارڈین';

  @override
  String get secondaryGuardianFullLabel => 'سیکنڈری گارڈین';

  @override
  String get verifiedLabel => 'تصدیق شدہ';

  @override
  String get notVerifiedLabel => 'غیر تصدیق شدہ';

  @override
  String get guardianVerifyEitherOptionNote =>
      'دونوں میں سے کوئی ایک طریقہ اپنانا کافی ہے — آپ کو دونوں کرنے کی ضرورت نہیں۔';

  @override
  String get guardianVerifyOptionAHeader =>
      'طریقہ الف: فون OTP کے ذریعے تصدیق کریں';

  @override
  String get guardianVerifyOptionBHeader =>
      'طریقہ ب: شناختی کارڈ (CNIC) کے ذریعے تصدیق کریں';

  @override
  String get resendOtpButton => 'OTP دوبارہ بھیجیں';

  @override
  String get otpSentSnackbar => 'آپ کے رجسٹرڈ فون نمبر پر OTP بھیج دیا گیا۔';

  @override
  String get otpNotVerifiedYetSnackbar =>
      'ابھی تصدیق نہیں ہوئی — نیچے CNIC چیک آزمائیں۔';

  @override
  String get otpInvalidError =>
      'یہ کوڈ غلط ہے یا میعاد ختم ہو چکی ہے۔ دوبارہ کوشش کریں یا دوبارہ بھیجیں۔';

  @override
  String get cnicCheckFailedSnackbar =>
      'CNIC چیک ناکام ہوگیا — اوپر فون OTP آزمائیں۔';

  @override
  String get openingCameraLabel => 'کیمرہ کھل رہا ہے...';

  @override
  String get lostRegistrationDetailsError =>
      'آپ کی رجسٹریشن کی تفصیلات محفوظ نہیں رہیں (یہ اس وقت ہوتا ہے جب ایپ بند ہو جائے)۔ جاری رکھنے کے لیے دوبارہ رجسٹر کریں۔';

  @override
  String get kycInvalidCredentialsError =>
      'آپ کے اکاؤنٹ کی تفصیلات میں کچھ غلط ہے - براہ کرم دوبارہ رجسٹر کریں۔';

  @override
  String get kycAlreadyVerifiedError =>
      'آپ کی تصدیق پہلے ہی ہو چکی ہے۔ گارڈین کے لنک کرنے کے بعد لاگ ان کرنے کی کوشش کریں۔';

  @override
  String get cnicAlreadyRegisteredError =>
      'یہ شناختی کارڈ نمبر پہلے ہی کسی اور اکاؤنٹ سے رجسٹرڈ ہے۔';

  @override
  String get kycValidationError =>
      'براہ کرم CNIC اور تصویر چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get kycVerifiedWaitingDefaultMessage =>
      'تصدیق ہوگئی۔ آپ کے پرائمری گارڈین کے لنک کرنے کا انتظار ہے۔';

  @override
  String get shareIdWithGuardianLabel =>
      'یہ ID اپنے گارڈین کے ساتھ شیئر کریں تاکہ وہ آپ کو لنک کر سکیں:';

  @override
  String get kycVerifiedActiveDefaultMessage =>
      'آپ کی تصدیق ہو چکی ہے اور اکاؤنٹ فعال ہے۔';

  @override
  String get kycPendingDefaultMessage =>
      'ابھی زیرِ التوا ہے - براہ کرم دوبارہ جمع کروائیں۔';

  @override
  String get kycFailedDefaultMessage =>
      'تصدیق ناکام ہوگئی - براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get inviteCodeOptionalLabel => 'دعوتی کوڈ (اختیاری)';

  @override
  String get inviteCodeHelperText =>
      'صرف اس صورت میں جب کسی پرائمری گارڈین نے آپ کو سیکنڈری گارڈین کے طور پر مدعو کیا ہو۔';

  @override
  String get roleLockedToGuardianNote =>
      'دعوتی کوڈ درج ہونے پر کردار گارڈین تک محدود ہے۔';

  @override
  String get inviteInvalidError => 'یہ دعوتی کوڈ درست نہیں ہے۔';

  @override
  String get inviteExpiredError =>
      'اس دعوتی کوڈ کی میعاد ختم ہو چکی ہے - نیا کوڈ طلب کریں۔';

  @override
  String get inviteNotForYouRegisterError =>
      'یہ دعوت کسی اور فون نمبر پر بھیجی گئی تھی - وہی نمبر استعمال کریں جس پر یہ بھیجی گئی تھی۔';

  @override
  String get guardianCapReachedError =>
      'اس ڈیپینڈنٹ کے پاس پہلے ہی زیادہ سے زیادہ 3 گارڈینز موجود ہیں۔';

  @override
  String get emailAlreadyRegisteredError =>
      'یہ ای میل پہلے ہی رجسٹرڈ ہے۔ اس کے بجائے لاگ ان کرنے کی کوشش کریں۔';

  @override
  String get phoneAlreadyRegisteredError => 'یہ فون نمبر پہلے ہی رجسٹرڈ ہے۔';

  @override
  String get accountAlreadyRegisteredError =>
      'یہ اکاؤنٹ پہلے سے موجود ہے۔ اس کے بجائے لاگ ان کرنے کی کوشش کریں۔';

  @override
  String get invalidCredentialsError => 'غلط ای میل یا پاس ورڈ۔';

  @override
  String get accountNotActivatedError =>
      'آپ کا اکاؤنٹ ابھی فعال نہیں ہوا — KYC مکمل کریں اور اپنے گارڈین کے لنک کرنے کا انتظار کریں۔';

  @override
  String get haveInviteCodeButton => 'دعوتی کوڈ ہے؟';

  @override
  String get linkADependentLabel => 'ڈیپینڈنٹ لنک کریں';

  @override
  String get noDependentsLinkedMessage =>
      'آپ ابھی تک کسی ڈیپینڈنٹ سے لنک نہیں ہیں۔ شروع کرنے کے لیے نیچے \"ڈیپینڈنٹ لنک کریں\" کا استعمال کریں۔';

  @override
  String get kycStatusPrefixLabel => 'KYC';

  @override
  String get accountActiveLabel => 'فعال';

  @override
  String get accountNotActiveLabel => 'ابھی فعال نہیں';

  @override
  String get kycStatusPending => 'زیرِ التوا';

  @override
  String get kycStatusVerified => 'تصدیق شدہ';

  @override
  String get kycStatusFailed => 'ناکام';

  @override
  String get linkDependentInstructions =>
      'ڈیپینڈنٹ سے ان کی تصدیقی اسکرین پر دکھائی گئی ID مانگیں، پھر اسے نیچے درج کریں۔';

  @override
  String get dependentIdLabel => 'ڈیپینڈنٹ کی ID';

  @override
  String get linkButton => 'لنک کریں';

  @override
  String get linkedSuccessSnackbar =>
      'لنک ہوگیا! اب آپ اپنی ہوم اسکرین پر یہ ڈیپینڈنٹ دیکھ سکتے ہیں۔';

  @override
  String get guardianNotVerifiedLinkError =>
      'ڈیپینڈنٹ لنک کرنے سے پہلے آپ کو اپنے اکاؤنٹ کی تصدیق کرنی ہوگی۔';

  @override
  String get secondaryCannotLinkError =>
      'صرف پرائمری گارڈین ہی ڈیپینڈنٹ لنک کر سکتا ہے - آپ کا اکاؤنٹ سیکنڈری ہے۔';

  @override
  String get dependentNotFoundError =>
      'اس ID کے ساتھ کوئی اکاؤنٹ نہیں ملا - دوبارہ چیک کریں اور کوشش کریں۔';

  @override
  String get alreadyLinkedError => 'آپ پہلے ہی اس ڈیپینڈنٹ سے لنک ہیں۔';

  @override
  String get primaryAlreadyExistsError =>
      'اس ڈیپینڈنٹ کا پہلے ہی ایک پرائمری گارڈین موجود ہے۔';

  @override
  String get yourRoleLabel => 'آپ کا کردار:';

  @override
  String get kycStatusColonLabel => 'KYC حیثیت:';

  @override
  String get accountActiveColonLabel => 'اکاؤنٹ فعال:';

  @override
  String get linkedGuardiansHeader => 'لنک شدہ گارڈینز';

  @override
  String get inviteASecondaryButton => 'سیکنڈری گارڈین کو مدعو کریں';

  @override
  String get managePermissionsButton => 'اجازتیں منظم کریں';

  @override
  String get myAccessButton => 'میری رسائی';

  @override
  String get invitePhoneInstructions =>
      'سیکنڈری گارڈین کا فون نمبر درج کریں۔ انہیں اس سے بننے والا کوڈ درکار ہوگا۔';

  @override
  String get sendInviteButton => 'دعوت بھیجیں';

  @override
  String get guardianNotVerifiedGenericError =>
      'پہلے اپنے اکاؤنٹ کی تصدیق کرنی ہوگی۔';

  @override
  String get notPrimaryGuardianError =>
      'آپ اس ڈیپینڈنٹ کے پرائمری گارڈین نہیں ہیں۔';

  @override
  String get inviteeNotEligibleError =>
      'اس نمبر کو مدعو نہیں کیا جا سکتا (یہ پہلے سے کسی اکاؤنٹ سے منسلک ہو سکتا ہے، یا یہ خود ڈیپینڈنٹ کا نمبر ہو سکتا ہے)۔';

  @override
  String get invitePhoneValidationError =>
      'براہ کرم فون نمبر چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String inviteCreatedMessage(int days) {
    return 'دعوت بن گئی - $days دن کے لیے درست ہے۔ یہ کوڈ ان کے ساتھ شیئر کریں:';
  }

  @override
  String get copyCodeButton => 'کوڈ کاپی کریں';

  @override
  String get copiedSnackbar => 'کاپی ہوگیا۔';

  @override
  String get inviteShareFooterNote =>
      'وہ رجسٹریشن کے دوران یہ درج کریں گے (اگر نئے ہیں) یا \"دعوتی کوڈ ہے؟\" اسکرین پر (اگر پہلے سے سیکنڈری اکاؤنٹ رکھتے ہیں)۔';

  @override
  String get noSecondariesYetMessage =>
      'ابھی تک کوئی سیکنڈری گارڈین نہیں ہے - پہلے ایک کو مدعو کریں۔';

  @override
  String get secondaryNotFoundError =>
      'وہ گارڈین اب اس ڈیپینڈنٹ سے لنک نہیں ہے۔';

  @override
  String get moduleLiveLocation => 'لائیو لوکیشن';

  @override
  String get moduleHealthRecords => 'صحت کے ریکارڈز';

  @override
  String get moduleCommunication => 'رابطہ';

  @override
  String get moduleEmergencyAlerts => 'ایمرجنسی الرٹس';

  @override
  String get moduleCameraViewing => 'کیمرہ ویو';

  @override
  String get moduleMedicationManagement => 'دوا کا انتظام';

  @override
  String get roleColonLabel => 'کردار:';

  @override
  String get notLinkedToDependentError => 'آپ اس ڈیپینڈنٹ سے لنک نہیں ہیں۔';

  @override
  String get acceptAnInviteTitle => 'دعوت قبول کریں';

  @override
  String get pasteInviteCodeInstructions =>
      'وہ دعوتی کوڈ پیسٹ کریں جو پرائمری گارڈین نے آپ کے ساتھ شیئر کیا۔';

  @override
  String get inviteCodeLabel => 'دعوتی کوڈ';

  @override
  String get acceptButton => 'قبول کریں';

  @override
  String get inviteAcceptedSnackbar =>
      'قبول ہوگیا! یہ ڈیپینڈنٹ اب آپ کی ہوم اسکرین پر نظر آئے گا۔';

  @override
  String get primaryCannotAcceptInviteError =>
      'پرائمری گارڈین اکاؤنٹ سیکنڈری دعوت قبول نہیں کر سکتا۔';

  @override
  String get inviteNotForYouAcceptError =>
      'یہ کوڈ آپ کے اکاؤنٹ کے نمبر سے مختلف نمبر پر بھیجا گیا تھا۔';

  @override
  String get liveMapButton => 'لائیو میپ';

  @override
  String get noLocationYetMessage => 'ابھی تک کوئی مقام موصول نہیں ہوا۔';

  @override
  String get justNowLabel => 'ابھی ابھی';

  @override
  String lastSeenMinutesMessage(int minutes) {
    return 'آخری بار $minutes منٹ پہلے دیکھا گیا';
  }

  @override
  String get locationStaleWarning => 'یہ مقام پرانا ہو سکتا ہے۔';

  @override
  String get zoneStatusInside => 'محفوظ زون کے اندر';

  @override
  String get zoneStatusOutside => 'تمام محفوظ زونز سے باہر';

  @override
  String get zoneStatusNoZones => 'ابھی تک کوئی محفوظ زون سیٹ اپ نہیں ہوا';

  @override
  String get zoneStatusUnknown => 'مقام کی حیثیت نامعلوم ہے';

  @override
  String get moduleAccessDeniedLiveMapError =>
      'آپ کو اس ڈیپینڈنٹ کا مقام دیکھنے کی اجازت نہیں ہے۔';

  @override
  String get locationSharingActiveLabel => 'مقام کا اشتراک: فعال';

  @override
  String get locationPermissionNeededMessage =>
      'آپ کے گارڈین کو آپ کا مقام دیکھنے کے لیے لوکیشن کی اجازت درکار ہے۔';

  @override
  String get grantLocationPermissionButton => 'اجازت دیں';

  @override
  String get locationPermissionDeniedForeverMessage =>
      'لوکیشن کی اجازت مستقل طور پر مسترد کر دی گئی ہے۔ براہ کرم اسے اپنے فون کی سیٹنگز سے فعال کریں۔';

  @override
  String get locationServiceDisabledMessage =>
      'اپنا مقام شیئر کرنے کے لیے براہ کرم اپنے فون کی سیٹنگز میں لوکیشن سروسز آن کریں۔';

  @override
  String get openSettingsButton => 'سیٹنگز کھولیں';

  @override
  String get dependentHomeTitle => 'ہوم';

  @override
  String dependentHomeGreeting(String name) {
    return 'السلام علیکم، $name';
  }

  @override
  String get panicButtonLabel => 'ایمرجنسی';

  @override
  String get panicButtonSubtitle => 'مدد کے لیے دبائیں';

  @override
  String get iAmOkButtonLabel => 'میں ٹھیک ہوں';

  @override
  String get myMedicineButtonLabel => 'میری دوا';

  @override
  String nextWellnessCheckMessage(String time) {
    return 'اگلا چیک: $time';
  }

  @override
  String get noWellnessCheckScheduledMessage => 'کوئی ویلنیس چیک شیڈول نہیں ہے';

  @override
  String nextMedicationMessage(String drug, String time) {
    return 'اگلی خوراک: $drug, $time پر';
  }

  @override
  String get noMedicationScheduledMessage => 'کوئی دوا شیڈول نہیں ہے';

  @override
  String get panicScreenTitle => 'ایمرجنسی';

  @override
  String get panicNeedHelpTitle => 'مدد چاہیے؟';

  @override
  String get panicHoldInstructions => 'بٹن کو 2 سیکنڈ تک دبائے رکھیں';

  @override
  String get panicHoldButtonLabel => 'دبائیں';

  @override
  String get panicHoldButtonSubtitle => 'مدد بھیجنے کے لیے';

  @override
  String get panicSendingLabel => 'الرٹ بھیجا جا رہا ہے...';

  @override
  String get panicAllGuardiansToldNote =>
      'آپ کے تمام گارڈینز کو ایک ساتھ بتایا جائے گا۔';

  @override
  String get panicHoldStopsAccidentNote =>
      'دبائے رکھنے سے غلطی سے الرٹ جانے سے بچا جاتا ہے۔';

  @override
  String get panicHelpIsComingTitle => 'مدد آ رہی ہے';

  @override
  String panicToldCountMessage(int count) {
    return 'ہم نے $count گارڈین کو بتا دیا';
  }

  @override
  String panicTriggeredAtMessage(String time) {
    return 'بوقت $time';
  }

  @override
  String panicAcknowledgedAtMessage(String time) {
    return '$time پر گارڈین نے دیکھ لیا';
  }

  @override
  String get panicWaitingForAckMessage => 'گارڈین کے دیکھنے کا انتظار ہے';

  @override
  String get panicEscalatedMessage => 'یہ آپ کے ایمرجنسی رابطے تک پہنچ گیا ہے۔';

  @override
  String get panicAutoEscalateNote =>
      'اگر 5 منٹ میں کوئی جواب نہ دے تو آپ کے ایمرجنسی رابطے کو بتایا جائے گا۔';

  @override
  String get iAmSafeNowButton => 'میں اب محفوظ ہوں';

  @override
  String get panicResolvedSnackbar =>
      'محفوظ کے طور پر نشان زد کر دیا گیا۔ خوشی ہوئی کہ آپ ٹھیک ہیں۔';

  @override
  String get panicTriggerFailedSnackbar =>
      'الرٹ نہیں بھیجا جا سکا۔ اپنا کنکشن چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get panicResolveFailedSnackbar =>
      'آپ کو محفوظ نشان زد نہیں کیا جا سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get wellnessCheckScreenTitle => 'ویلنیس چیک';

  @override
  String get areYouOkTitle => 'کیا آپ ٹھیک ہیں؟';

  @override
  String get familyCheckingOnYouMessage =>
      'آپ کا خاندان آپ کی خیریت دریافت کر رہا ہے';

  @override
  String answerWithinMessage(String time) {
    return '$time میں جواب دیں';
  }

  @override
  String get yesIAmOkButton => 'جی ہاں، میں ٹھیک ہوں';

  @override
  String get iNeedHelpButton => 'مجھے مدد چاہیے';

  @override
  String get iNeedHelpOpensPanicNote =>
      '\'مجھے مدد چاہیے\' ایمرجنسی اسکرین کھولتا ہے۔';

  @override
  String get noAnswerGuardianToldNote =>
      'کوئی جواب نہ ملنے پر → آپ کے گارڈین کو بتایا جائے گا۔';

  @override
  String get noWellnessCheckPendingMessage =>
      'ابھی کوئی ویلنیس چیک جواب کا منتظر نہیں ہے۔';

  @override
  String get wellnessCheckTimeUpNote =>
      'وقت ختم ہوگیا — آپ کے گارڈین کو مطلع کیا جا سکتا ہے۔ آپ اب بھی نیچے جواب دے سکتے ہیں۔';

  @override
  String get wellnessCheckRespondedSnackbar =>
      'شکریہ — ٹھیک کے طور پر نشان زد کر دیا گیا۔';

  @override
  String get wellnessCheckRespondFailedSnackbar =>
      'آپ کا جواب نہیں بھیجا جا سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get medicationScreenTitle => 'میری دوا';

  @override
  String get medicineStep1OfTwoLabel => 'میں نے دوا لے لی · مرحلہ 1 از 2';

  @override
  String get noMedicineDueMessage => 'ابھی کوئی دوا کا وقت نہیں ہے۔';

  @override
  String get medicineTimePromptTitle => 'آپ کی دوا کا وقت ہوگیا ہے';

  @override
  String medicineTimePromptMessage(String drug, String dosage) {
    return '$drug ($dosage) — کیا آپ نے لے لی؟';
  }

  @override
  String get medicineTookItButtonLabel => 'میں نے لے لی';

  @override
  String get medicineConfirmTitle => 'تصدیق کریں کہ آپ نے لی ہے';

  @override
  String medicineConfirmMessage(String drug, String dosage) {
    return 'براہ کرم تصدیق کریں: $drug ($dosage)';
  }

  @override
  String medicineConfirmExpiresNote(String time) {
    return 'یہ تصدیق $time میں ختم ہوجائے گی';
  }

  @override
  String get medicineConfirmButtonLabel => 'جی ہاں، لے لی';

  @override
  String get medicineConfirmExpiredMessage => 'تصدیق کا وقت ختم ہوگیا۔';

  @override
  String get medicineTryAgainButtonLabel => 'دوبارہ کوشش کریں';

  @override
  String get medicineTakenTitle => 'لی گئی کے طور پر نشان زد';

  @override
  String medicineTakenMessage(String drug) {
    return '$drug کو لی گئی کے طور پر نشان زد کر دیا گیا ہے۔';
  }

  @override
  String get medicineDoneButtonLabel => 'ہوگیا';

  @override
  String get medicineConfirmRequestFailedSnackbar =>
      'تصدیق شروع نہیں ہو سکی۔ دوبارہ کوشش کریں۔';

  @override
  String get medicineConfirmFailedSnackbar =>
      'تصدیق نہیں ہو سکی۔ دوبارہ کوشش کریں۔';

  @override
  String get medicationScheduleButton => 'دوا کا شیڈول';

  @override
  String get wellnessScheduleButton => 'ویلنیس چیک شیڈول';

  @override
  String get medicationScheduleScreenTitle => 'دوا کا شیڈول';

  @override
  String get wellnessScheduleScreenTitle => 'ویلنیس چیک شیڈول';

  @override
  String get noMedicationSchedulesMessage =>
      'ابھی تک کوئی دوا شیڈول نہیں کی گئی۔';

  @override
  String get noWellnessSchedulesMessage =>
      'ابھی تک کوئی ویلنیس چیک کا وقت شیڈول نہیں کیا گیا۔';

  @override
  String get useDefaultScheduleButton =>
      'ڈیفالٹ شیڈول استعمال کریں (صبح 8، دوپہر 2، رات 8)';

  @override
  String get medicationManagementDeniedNote =>
      'آپ کو دوا کا انتظام کرنے کی اجازت نہیں ہے۔ پرائمری گارڈین سے پوچھیں۔';

  @override
  String get wellnessManagementDeniedNote =>
      'آپ کو ویلنیس چیک کا انتظام کرنے کی اجازت نہیں ہے۔ پرائمری گارڈین سے پوچھیں۔';

  @override
  String get drugNameFieldLabel => 'دوا کا نام';

  @override
  String get dosageFieldLabel => 'خوراک';

  @override
  String get timeFieldLabel => 'وقت';

  @override
  String get frequencyFieldLabel => 'تکرار';

  @override
  String get dailyLabel => 'روزانہ';

  @override
  String get weeklyLabel => 'ہفتہ وار';

  @override
  String get gracePeriodFieldLabel => 'رعایتی وقت (منٹ)';

  @override
  String gracePeriodMinutesMessage(int minutes) {
    return 'رعایتی وقت: $minutes منٹ';
  }

  @override
  String get addMedicationScheduleTitle => 'دوا شامل کریں';

  @override
  String get editMedicationScheduleTitle => 'دوا میں ترمیم کریں';

  @override
  String get addWellnessCheckTitle => 'چیک کا وقت شامل کریں';

  @override
  String get editWellnessCheckTitle => 'چیک کے وقت میں ترمیم کریں';

  @override
  String get scheduleSavedSnackbar => 'محفوظ ہوگیا۔';

  @override
  String get scheduleSaveFailedSnackbar =>
      'محفوظ نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get scheduleUpdateFailedSnackbar =>
      'اپڈیٹ نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get weeklyDaysRequiredError =>
      'ہفتہ وار شیڈول کے لیے کم از کم ایک دن منتخب کریں۔';

  @override
  String get wellnessLimitReachedError =>
      'آپ زیادہ سے زیادہ 3 ویلنیس چیک کے اوقات رکھ سکتے ہیں۔';

  @override
  String get wellnessTimeExistsError => 'اس وقت پر پہلے سے ایک چیک موجود ہے۔';

  @override
  String get dayMonLabel => 'پیر';

  @override
  String get dayTueLabel => 'منگل';

  @override
  String get dayWedLabel => 'بدھ';

  @override
  String get dayThuLabel => 'جمعرات';

  @override
  String get dayFriLabel => 'جمعہ';

  @override
  String get daySatLabel => 'ہفتہ';

  @override
  String get daySunLabel => 'اتوار';

  @override
  String get goBackButtonLabel => 'واپس جائیں';

  @override
  String get alertTypePanic => 'پینک الرٹ';

  @override
  String get alertTypeMissedDose => 'دوا چھوٹ گئی';

  @override
  String get alertTypeWellnessCheck => 'ویلنیس چیک چھوٹ گیا';

  @override
  String get alertTypeGeofenceBreach => 'محفوظ علاقے سے باہر';

  @override
  String get alertTypeLowBattery => 'بیٹری کم ہے';

  @override
  String get alertTypeDeviceOffline => 'فون آف لائن ہے';

  @override
  String get alertTypeExternalContact => 'ایمرجنسی رابطہ الرٹ';

  @override
  String get alertTypeGeneric => 'الرٹ';

  @override
  String get tierLevel1PrimaryLabel => 'سطح 1 · پرائمری';

  @override
  String get tierLevel2SecondaryLabel => 'سطح 2 · سیکنڈری';

  @override
  String get tierLevel3SmsLabel => 'سطح 3 · ایس ایم ایس بھیج دیا گیا';

  @override
  String get alertsScreenTitle => 'الرٹس';

  @override
  String alertsOpenTabLabel(int count) {
    return 'کھلے ($count)';
  }

  @override
  String get alertsSeenTabLabel => 'دیکھے گئے';

  @override
  String get alertsEmptyOpenMessage => 'کوئی کھلا الرٹ نہیں ہے۔';

  @override
  String get alertsEmptySeenMessage => 'ابھی تک کوئی دیکھا گیا الرٹ نہیں ہے۔';

  @override
  String get iveSeenItButton => 'میں نے دیکھ لیا';

  @override
  String get seenStopsChainTitle => 'دیکھنا سلسلہ روک دیتا ہے';

  @override
  String get seenStopsChainBody =>
      'پرائمری → سیکنڈری (5 منٹ) → ایس ایم ایس (5 منٹ)';

  @override
  String get acknowledgeFailedSnackbar =>
      'دیکھا گیا کے طور پر نشان زد نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get needsAttentionHeader => 'توجہ درکار ہے';

  @override
  String get seeAllLabel => 'سب دیکھیں';

  @override
  String get panicBannerTitle => 'پینک الرٹ';

  @override
  String panicBannerBody(String name, String time) {
    return '$name نے پینک دبایا · $time';
  }

  @override
  String get openButtonLabel => 'کھولیں';

  @override
  String get missedDoseScreenTitle => 'چھوٹی ہوئی دوا';

  @override
  String missedDoseBannerTitle(String name, String drug) {
    return '$name نے $drug نہیں لی';
  }

  @override
  String get whatHappensNextHeader => 'اب آگے کیا ہوگا';

  @override
  String get missedDoseStepYouToldLabel => 'آپ کو بتا دیا گیا (پرائمری)';

  @override
  String get missedDoseStepSecondaryLabel =>
      'نہ دیکھنے پر سیکنڈری کو بتایا جائے گا';

  @override
  String get missedDoseStepSmsLabel =>
      'نہ دیکھنے پر ایمرجنسی رابطے کو ایس ایم ایس';

  @override
  String get giveMoreTimeButton => 'مزید وقت دیں (+30 منٹ)';

  @override
  String get tellOtherGuardiansButton => 'ابھی دوسرے گارڈینز کو بتائیں';

  @override
  String callButtonLabel(String name) {
    return '$name کو کال کریں';
  }

  @override
  String get tappingCountsAsSeenNote =>
      'کوئی بھی آپشن دبانا دیکھے جانے کے طور پر شمار ہوگا۔';

  @override
  String get extendSuccessSnackbar => '30 منٹ مزید دے دیے گئے۔';

  @override
  String escalateSuccessSnackbar(int count) {
    return '$count سیکنڈری گارڈین کو مطلع کر دیا گیا۔';
  }

  @override
  String get escalateNoSecondarySnackbar =>
      'ابھی کوئی سیکنڈری گارڈین الرٹس نہیں دیکھ سکتا۔';

  @override
  String get doseAlreadyResolvedMessage => 'یہ الرٹ پہلے ہی حل ہو چکا ہے۔';

  @override
  String get alreadyEscalatedMessage =>
      'دوسرے گارڈینز کو پہلے ہی بتا دیا گیا ہے۔';

  @override
  String get callFailedSnackbar => 'کال شروع نہیں ہو سکی۔';

  @override
  String get emergencySettingsScreenTitle => 'ایمرجنسی ترتیبات';

  @override
  String get emergencySettingsButton => 'ایمرجنسی ترتیبات';

  @override
  String get remoteAlarmSectionTitle => 'ریموٹ الارم';

  @override
  String get primaryOnlyBadge => 'صرف پرائمری';

  @override
  String remoteAlarmDescription(String name) {
    return '$name کے فون پر زور سے بجاتا ہے، خاموش موڈ میں بھی۔ انہیں قریب تلاش کرنے کے لیے استعمال کریں۔';
  }

  @override
  String get ringAlarmButton => 'الارم بجائیں (60 سیکنڈ)';

  @override
  String get stopAlarmButton => 'الارم بند کریں';

  @override
  String get alarmAlreadyActiveMessage => 'الارم پہلے ہی بج رہا ہے۔';

  @override
  String get alarmStartFailedSnackbar =>
      'الارم شروع نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get alarmStopFailedSnackbar =>
      'الارم بند نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get notPrimaryGuardianNote =>
      'صرف پرائمری گارڈین ریموٹ الارم استعمال کر سکتا ہے اور ایمرجنسی رابطہ سیٹ کر سکتا ہے۔';

  @override
  String get emergencyContactSectionTitle => 'ایمرجنسی رابطہ';

  @override
  String get emergencyContactDescription =>
      'اگر 10 منٹ میں کوئی گارڈین الرٹ کا جواب نہیں دیتا تو ایک ایس ایم ایس بھیجا جاتا ہے۔';

  @override
  String get contactNameFieldLabel => 'نام';

  @override
  String get contactPhoneFieldLabel => 'فون';

  @override
  String get saveContactButton => 'رابطہ محفوظ کریں';

  @override
  String get contactSavedSnackbar => 'رابطہ محفوظ ہوگیا۔';

  @override
  String get contactSaveFailedSnackbar =>
      'رابطہ محفوظ نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get noEmergencyContactMessage =>
      'ابھی تک کوئی ایمرجنسی رابطہ سیٹ نہیں کیا گیا۔';

  @override
  String get removeContactButton => 'رابطہ ہٹائیں';

  @override
  String get contactRemovedSnackbar => 'رابطہ ہٹا دیا گیا۔';

  @override
  String get contactRemoveFailedSnackbar =>
      'رابطہ نہیں ہٹایا جا سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get emergencyContactDeniedNote =>
      'آپ یہ دیکھ سکتے ہیں لیکن صرف پرائمری گارڈین اسے تبدیل کر سکتا ہے۔';

  @override
  String get alarmScreenTitle => 'الارم';

  @override
  String get alarmLookingForYouTitle => 'آپ کا گارڈین آپ کو ڈھونڈ رہا ہے';

  @override
  String alarmScreenSubtitle(String remaining) {
    return 'آپ کے گارڈین کا الارم · $remaining باقی';
  }

  @override
  String get stopAlarmButtonLabel => 'الارم بند کریں';

  @override
  String get stopAlarmFailedSnackbar =>
      'الارم بند نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get noActiveAlarmMessage => 'ابھی کوئی الارم نہیں بج رہا۔';

  @override
  String get messagesScreenTitle => 'پیغامات';

  @override
  String get noConversationsYetMessage => 'ابھی تک کوئی گفتگو نہیں۔';

  @override
  String get noMessagesYetPreview => 'ابھی تک کوئی پیغام نہیں';

  @override
  String get urgentVoiceMessageLabel => 'فوری صوتی پیغام';

  @override
  String get loadEarlierMessagesButton => 'پرانے پیغامات دیکھیں';

  @override
  String get startConversationMessage => 'ابھی تک کوئی پیغام نہیں۔ سلام کہیں!';

  @override
  String get messageInputHint => 'پیغام لکھیں';

  @override
  String get messageSendTooltip => 'بھیجیں';

  @override
  String get sendingLabel => 'بھیجا جا رہا ہے…';

  @override
  String get notSentTapToRetryLabel =>
      'نہیں بھیجا گیا · دوبارہ کوشش کے لیے دبائیں';

  @override
  String get readLabel => 'پڑھ لیا گیا';

  @override
  String get communicationAccessDeniedMessage =>
      'صرف وہ گارڈینز جن کے پاس Communication تک رسائی ہے ابھی پیغام بھیج سکتے ہیں۔';

  @override
  String get messagesButtonLabel => 'پیغامات';

  @override
  String get messageButtonLabel => 'پیغام بھیجیں';

  @override
  String unreadMessagesSubtitle(int count) {
    return '$count نئے پیغام';
  }

  @override
  String get quickReplyIAmFine => 'میں ٹھیک ہوں';

  @override
  String get quickReplyCallMe => 'مجھے کال کریں';

  @override
  String get quickReplyYes => 'جی ہاں';

  @override
  String get quickReplyNo => 'نہیں';

  @override
  String get recordUrgentVoiceSheetTitle => 'فوری صوتی پیغام ریکارڈ کریں';

  @override
  String urgentVoiceWarningMessage(String peerName) {
    return 'یہ $peerName کے فون پر اہم الرٹ کی طرح بجے گا، خاموش موڈ میں بھی۔';
  }

  @override
  String get tapToStartRecordingLabel => 'ریکارڈنگ شروع کرنے کے لیے دبائیں';

  @override
  String recordingInProgressLabel(String time) {
    return 'ریکارڈ ہو رہا ہے… $time';
  }

  @override
  String get maxLengthReachedMessage => 'زیادہ سے زیادہ وقت ختم ہو گیا (2:00)۔';

  @override
  String get stopRecordingButtonLabel => 'روکیں';

  @override
  String get discardRecordingButtonLabel => 'حذف کریں';

  @override
  String get playPreviewButtonLabel => 'چلائیں';

  @override
  String get sendUrgentVoiceButtonLabel => 'بھیجیں';

  @override
  String get micPermissionDeniedMessage =>
      'صوتی پیغام ریکارڈ کرنے کے لیے مائیکروفون کی اجازت درکار ہے۔';

  @override
  String get voiceSendFailedGenericMessage =>
      'صوتی پیغام نہیں بھیجا جا سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get audioDownloadFailedMessage =>
      'صوتی پیغام لوڈ نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get activityBookingCancelled => 'بکنگ منسوخ';

  @override
  String get activityBookingCompleted => 'بکنگ مکمل';

  @override
  String get activityBookingConfirmed => 'بکنگ کی تصدیق';

  @override
  String get activityBookingRequested => 'وزٹ کی درخواست';

  @override
  String get activityLogMenuItem => 'سرگرمی لاگ';

  @override
  String get activityLogScreenTitle => 'سرگرمی لاگ';

  @override
  String get activityOrgContact => 'ادارے کو کال کی';

  @override
  String get addAppointmentTitle => 'اپائنٹمنٹ شامل کریں';

  @override
  String get addRecordTitle => 'ریکارڈ شامل کریں';

  @override
  String get addVitalReadingTitle => 'ریڈنگ شامل کریں';

  @override
  String get allCategoriesLabel => 'تمام';

  @override
  String get appointmentCancelledError =>
      'یہ اپائنٹمنٹ پہلے ہی منسوخ ہو چکی ہے۔';

  @override
  String get appointmentCancelledLabel => 'منسوخ';

  @override
  String get appointmentExistsError =>
      'اس وقت آپ کی ایک اپائنٹمنٹ پہلے سے موجود ہے۔';

  @override
  String get appointmentInPastError =>
      'گزرے ہوئے وقت کے لیے اپائنٹمنٹ شیڈول نہیں کی جا سکتی۔';

  @override
  String get appointmentNotesFieldLabel => 'نوٹس';

  @override
  String get appointmentSavedSnackbar => 'اپائنٹمنٹ محفوظ ہو گئی';

  @override
  String get appointmentsButton => 'اپائنٹمنٹس';

  @override
  String get appointmentsHistoryTabLabel => 'ماضی کی';

  @override
  String get appointmentsLimitError =>
      'آپ آنے والی اپائنٹمنٹس کی حد تک پہنچ گئے ہیں۔';

  @override
  String get appointmentsScreenTitle => 'اپائنٹمنٹس';

  @override
  String get appointmentsUpcomingTabLabel => 'آنے والی';

  @override
  String get askForPriceLabel => 'قیمت دریافت کریں';

  @override
  String get attachFileButtonLabel => 'فائل منسلک کریں';

  @override
  String get bandAddressFieldLabel => 'بلوٹوتھ ایڈریس';

  @override
  String get bandAlreadyPairedMessage =>
      'اس ڈیپینڈنٹ کے ساتھ ایک بینڈ پہلے سے جوڑا جا چکا ہے۔';

  @override
  String get bandNameFieldLabel => 'بینڈ کا نام (اختیاری)';

  @override
  String get bandNoDataBanner =>
      'حال ہی میں کوئی ریڈنگ موصول نہیں ہوئی۔ چیک کریں کہ بینڈ آن ہے اور قریب موجود ہے۔';

  @override
  String get bandStatusLabel => 'صورتحال';

  @override
  String get bandStatusNoData => 'حالیہ ڈیٹا موجود نہیں';

  @override
  String get bandStatusNotPaired => 'جوڑا نہیں گیا';

  @override
  String get bandStatusReceiving => 'ڈیٹا موصول ہو رہا ہے';

  @override
  String get bandStatusWaitingForFirstData => 'پہلے ڈیٹا کا انتظار';

  @override
  String get bloodSugarFieldLabel => 'بلڈ شوگر';

  @override
  String get bookingAlreadyOpenError =>
      'اس فراہم کنندہ کے ساتھ آپ کی ایک درخواست پہلے سے کھلی ہے۔';

  @override
  String get bookingStatusCancelled => 'منسوخ';

  @override
  String get bookingStatusCompleted => 'مکمل';

  @override
  String get bookingStatusConfirmed => 'تصدیق شدہ';

  @override
  String get bookingStatusConflictMessage =>
      'اس بکنگ کی صورتحال پہلے ہی تبدیل ہو چکی ہے۔';

  @override
  String get bookingStatusPending => 'زیر التواء';

  @override
  String get callToArrangeButtonLabel => 'انتظام کے لیے کال کریں';

  @override
  String get cancelAppointmentMenuItem => 'اپائنٹمنٹ منسوخ کریں';

  @override
  String get cancelBookingButtonLabel => 'منسوخ کریں';

  @override
  String get cancelLinkButtonLabel => 'لنک منسوخ کریں';

  @override
  String get categoryNotAllowedMessage => 'یہ قسم ریکارڈز کے لیے جائز نہیں ہے۔';

  @override
  String get completeBookingButtonLabel => 'مکمل شدہ نشان زد کریں';

  @override
  String get confirmBookingButtonLabel => 'تصدیق کریں';

  @override
  String get connectBandButtonLabel => 'بینڈ جوڑیں';

  @override
  String get connectBandInstructions =>
      'اپنے بینڈ کا بلوٹوتھ آن کریں اور اسے جوڑنے کے لیے نیچے اس کا ایڈریس درج کریں۔';

  @override
  String get connectBandScreenTitle => 'بینڈ جوڑیں';

  @override
  String get createDoctorLinkBody =>
      'ایک لنک بنائیں جسے کوئی بھی لاگ ان کے بغیر کھول سکے۔ یہ خود بخود ختم ہو جائے گا۔';

  @override
  String get createDoctorLinkTitle => 'ڈاکٹر لنک بنائیں';

  @override
  String get createLinkButtonLabel => 'لنک بنائیں';

  @override
  String get dateFieldLabel => 'تاریخ';

  @override
  String get deleteAppointmentConfirmTitle => 'کیا یہ اپائنٹمنٹ حذف کر دیں؟';

  @override
  String get deleteButtonLabel => 'حذف کریں';

  @override
  String get deleteRecordConfirmBody =>
      'یہ ریکارڈ مستقل طور پر حذف ہو جائے گا۔';

  @override
  String get deleteRecordConfirmTitle => 'کیا یہ ریکارڈ حذف کر دیں؟';

  @override
  String get demoDataDisabledMessage =>
      'اس بینڈ کے لیے ڈیمو ڈیٹا دستیاب نہیں ہے۔';

  @override
  String get diastolicFieldLabel => 'ڈایاسٹولک';

  @override
  String get directoryButton => 'ڈائریکٹری اور خدمات';

  @override
  String get directoryOrganizationsTabLabel => 'ادارے';

  @override
  String get directoryProvidersTabLabel => 'گھریلو نگہداشت';

  @override
  String get directoryScreenTitle => 'ڈائریکٹری';

  @override
  String get doctorLinkShareIntro =>
      'طبی ریکارڈز دیکھنے کے لیے یہ ایک محفوظ لنک ہے:';

  @override
  String get doctorLinksMenuItem => 'ڈاکٹر لنکس';

  @override
  String get doctorLinksScreenTitle => 'ڈاکٹر لنکس';

  @override
  String get doneButtonLabel => 'ہو گیا';

  @override
  String get downloadFileTooltip => 'ڈاؤن لوڈ کریں';

  @override
  String get editAppointmentTitle => 'اپائنٹمنٹ میں ترمیم کریں';

  @override
  String get editRecordTitle => 'ریکارڈ میں ترمیم کریں';

  @override
  String get exportButtonLabel => 'ایکسپورٹ';

  @override
  String get exportFailedMessage =>
      'ایکسپورٹ تیار نہیں ہو سکا۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get exportRecordsMenuItem => 'ریکارڈز ایکسپورٹ کریں';

  @override
  String get exportScopeCompleteLabel => 'سب کچھ';

  @override
  String get exportScopeMonthLabel => 'اس مہینے';

  @override
  String get exportScopeYearLabel => 'اس سال';

  @override
  String get exportSheetTitle => 'ایکسپورٹ';

  @override
  String get fileCannotBeReplacedNote =>
      'فائل کو تبدیل نہیں کیا جا سکتا۔ اس کے بجائے یہ ریکارڈ حذف کر کے نیا شامل کریں۔';

  @override
  String get fileTooLargeMessage => 'یہ فائل بہت بڑی ہے۔ حد 10 MB ہے۔';

  @override
  String get fromBandNote => 'بینڈ سے';

  @override
  String get generateDemoDataButtonLabel => 'ڈیمو ڈیٹا بنائیں';

  @override
  String get healthRecordsAccessDeniedMessage =>
      'آپ کو اس ڈیپینڈنٹ کے طبی ریکارڈز تک رسائی حاصل نہیں ہے۔';

  @override
  String get healthRecordsNotGrantedNote =>
      'طبی ریکارڈز تک رسائی ابھی نہیں دی گئی۔';

  @override
  String get includeVitalsFieldLabel => 'وائٹلز شامل کریں';

  @override
  String get latestHeartRateLabel => 'تازہ ترین دل کی دھڑکن';

  @override
  String get linkExpiresInFieldLabel => 'لنک کی میعاد';

  @override
  String get loadMoreButtonLabel => 'مزید لوڈ کریں';

  @override
  String get medicalRecordsButton => 'طبی ریکارڈز';

  @override
  String get medicalVaultScreenTitle => 'طبی والٹ';

  @override
  String get metricBloodPressure => 'بلڈ پریشر';

  @override
  String get metricBloodSugar => 'بلڈ شوگر';

  @override
  String get metricHeartRate => 'دل کی دھڑکن';

  @override
  String get metricSpo2 => 'ایس پی او 2';

  @override
  String get metricTemperature => 'درجہ حرارت';

  @override
  String get moreSectionHeader => 'مزید';

  @override
  String get myBandScreenTitle => 'میرا بینڈ';

  @override
  String get nearMeButtonLabel => 'میرے قریب';

  @override
  String get noActivityMessage => 'ابھی تک کوئی سرگرمی نہیں۔';

  @override
  String get noDirectoryResultsMessage => 'کوئی نتیجہ نہیں ملا۔';

  @override
  String get noDoctorLinksMessage => 'ابھی تک کوئی ڈاکٹر لنک نہیں۔';

  @override
  String get noPastAppointmentsMessage => 'کوئی گزشتہ اپائنٹمنٹ نہیں۔';

  @override
  String get noPreferenceLabel => 'کوئی ترجیح نہیں';

  @override
  String get noRecordsMessage => 'ابھی تک کوئی ریکارڈ نہیں۔';

  @override
  String get noSecondariesMessage => 'ابھی تک کوئی سیکنڈری گارڈین نہیں۔';

  @override
  String get noUpcomingAppointmentsMessage => 'کوئی آنے والی اپائنٹمنٹ نہیں۔';

  @override
  String get noVitalsReadingsMessage => 'ابھی تک کوئی ریڈنگ نہیں۔';

  @override
  String get notPrimaryGuardianMessage => 'یہ صرف پرائمری گارڈین کر سکتا ہے۔';

  @override
  String get noteTooLongError => 'نوٹ بہت طویل ہے۔ اسے 300 حروف سے کم رکھیں۔';

  @override
  String get nothingSentToProviderNote =>
      'فراہم کنندہ کو کچھ نہیں بھیجا جاتا — یہ صرف آپ کے اپنے ریکارڈ کے لیے ایک نوٹ ہے۔';

  @override
  String openedCountLabel(int count) {
    return '$count بار کھولا گیا';
  }

  @override
  String get pairButtonLabel => 'جوڑیں';

  @override
  String get pickTimeButtonLabel => 'وقت منتخب کریں';

  @override
  String get preferredTimeFieldLabel => 'ترجیحی وقت';

  @override
  String get preparingExportMessage => 'آپ کا ایکسپورٹ تیار ہو رہا ہے…';

  @override
  String get providerNameFieldLabel => 'فراہم کنندہ کا نام';

  @override
  String get recordAccessMenuItem => 'ریکارڈ تک رسائی';

  @override
  String get recordAccessScreenTitle => 'ریکارڈ تک رسائی';

  @override
  String get recordCategoryAll => 'تمام';

  @override
  String get recordCategoryFieldLabel => 'قسم';

  @override
  String get recordCategoryLabReport => 'لیب رپورٹ';

  @override
  String get recordCategoryOther => 'دیگر';

  @override
  String get recordCategoryPrescription => 'نسخہ';

  @override
  String get recordCategoryXray => 'ایکسرے';

  @override
  String get recordDateFieldLabel => 'ریکارڈ کی تاریخ';

  @override
  String get recordModifyDeniedMessage =>
      'آپ کو اس ریکارڈ میں ترمیم کرنے کی اجازت نہیں ہے۔';

  @override
  String get recordNeedsContentError =>
      'محفوظ کرنے سے پہلے فائل یا کچھ نوٹس شامل کریں۔';

  @override
  String get recordNotFoundMessage => 'یہ ریکارڈ نہیں ملا۔';

  @override
  String get recordNotesFieldLabel => 'نوٹس';

  @override
  String get recordTitleFieldLabel => 'عنوان';

  @override
  String get recordValidationErrorMessage =>
      'براہ کرم تفصیلات چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get recordsLimitMessage => 'آپ طبی ریکارڈز کی حد تک پہنچ گئے ہیں۔';

  @override
  String get requestVisitButtonLabel => 'وزٹ کی درخواست دیں';

  @override
  String get requestVisitScreenTitle => 'وزٹ کی درخواست دیں';

  @override
  String get requestedByLabel => 'درخواست دہندہ';

  @override
  String get sampleEntryLabel => 'نمونہ';

  @override
  String get saveRequestButtonLabel => 'درخواست محفوظ کریں';

  @override
  String get searchDirectoryHint => 'نام یا مہارت سے تلاش کریں';

  @override
  String get shareLimitError => 'آپ فعال ڈاکٹر لنکس کی حد تک پہنچ گئے ہیں۔';

  @override
  String get shareStatusActive => 'فعال';

  @override
  String get shareStatusExpired => 'ختم شدہ';

  @override
  String get shareStatusRevoked => 'منسوخ شدہ';

  @override
  String get spo2FieldLabel => 'ایس پی او 2 (%)';

  @override
  String get sugarContextAfterMeal => 'کھانے کے بعد';

  @override
  String get sugarContextFasting => 'روزہ';

  @override
  String get sugarContextFieldLabel => 'سیاق و سباق (اختیاری)';

  @override
  String get sugarContextNone => 'کوئی نہیں';

  @override
  String get sugarContextRandom => 'بے ترتیب';

  @override
  String get systolicFieldLabel => 'سسٹولک';

  @override
  String get temperatureFieldLabel => 'درجہ حرارت';

  @override
  String get tooManyOpenBookingsError =>
      'آپ کی پہلے سے بہت سی کھلی درخواستیں ہیں۔ پہلے ایک منسوخ کریں۔';

  @override
  String get unitFieldLabel => 'یونٹ';

  @override
  String get unpairBandConfirmBody => 'یہ بینڈ اس ڈیپینڈنٹ سے الگ ہو جائے گا۔';

  @override
  String get unpairBandConfirmTitle => 'کیا یہ بینڈ الگ کر دیں؟';

  @override
  String get unpairButtonLabel => 'الگ کریں';

  @override
  String get unsupportedFileMessage =>
      'یہ فائل کی قسم قابل قبول نہیں ہے۔ PDF, JPG یا PNG استعمال کریں۔';

  @override
  String get visitNoteFieldLabel => 'نوٹ (اختیاری)';

  @override
  String get visitRequestSavedMessage =>
      'آپ کی وزٹ کی درخواست محفوظ ہو گئی ہے۔';

  @override
  String get vitalNoteFieldLabel => 'نوٹ (اختیاری)';

  @override
  String get vitalOutOfRangeMessage =>
      'یہ قدر حد سے باہر لگتی ہے۔ براہ کرم چیک کریں۔';

  @override
  String get vitalsButton => 'وائٹلز';

  @override
  String get vitalsHistoryHeader => 'ماضی کی ریڈنگز';

  @override
  String get vitalsLimitMessage => 'آپ وائٹلز ریڈنگز کی حد تک پہنچ گئے ہیں۔';

  @override
  String get vitalsScreenTitle => 'وائٹلز';

  @override
  String get wearableBandButton => 'پہننے والا بینڈ';

  @override
  String get shareIdScreenTitle => 'میری آئی ڈی';

  @override
  String get shareIdScreenExplanation =>
      'یہ اپنے سرپرست کو دکھائیں، یا اسے کاپی یا شیئر کریں تاکہ وہ آپ کو لنک کر سکیں۔';

  @override
  String get copyIdButtonLabel => 'آئی ڈی کاپی کریں';

  @override
  String get idCopiedConfirmation => 'آئی ڈی کاپی ہو گئی';

  @override
  String get shareIdButtonLabel => 'شیئر کریں';

  @override
  String get shareIdShareIntro => 'یہ میری ہمسفر آئی ڈی ہے:';

  @override
  String get viewShareMyIdButton => 'میری آئی ڈی دیکھیں اور شیئر کریں';

  @override
  String get myIdMenuLabel => 'میری آئی ڈی';

  @override
  String get cameraButtonLabel => 'کیمرہ';

  @override
  String get cameraScreenTitle => 'کیمرہ';

  @override
  String get cameraNotPairedMessage =>
      'اس ڈیپنڈنٹ کے لیے ابھی تک کوئی کیمرہ جوڑا نہیں گیا۔';

  @override
  String get cameraOfflineError =>
      'کیمرہ جڑا ہوا ہے لیکن ابھی قابلِ رسائی نہیں ہے۔';

  @override
  String get moduleAccessDeniedCameraError =>
      'آپ کو یہ کیمرہ دیکھنے کی اجازت نہیں ہے۔';

  @override
  String get cameraMaxViewersError =>
      'بہت سے سرپرست پہلے ہی دیکھ رہے ہیں۔ تھوڑی دیر بعد دوبارہ کوشش کریں۔';

  @override
  String get startWatchingButtonLabel => 'دیکھنا شروع کریں';

  @override
  String get stopWatchingButtonLabel => 'دیکھنا بند کریں';

  @override
  String get cameraWatchingPlaceholderMessage =>
      'لائیو ویڈیو ابھی تک فعال نہیں ہے - یہ اسکرین صرف دیکھنے کا سیشن ٹریک کرتی ہے؛ تصویر بعد میں شامل ہوگی۔';

  @override
  String cameraViewerCountLabel(int count) {
    return '$count لوگ ابھی دیکھ رہے ہیں';
  }

  @override
  String get savedClipsButtonLabel => 'محفوظ شدہ کلپس';

  @override
  String get cameraClipsScreenTitle => 'محفوظ شدہ کلپس';

  @override
  String get noSavedClipsMessage => 'ابھی تک کوئی کلپ محفوظ نہیں ہے۔';

  @override
  String get clipTriggerPanicLabel => 'پینک موڈ';

  @override
  String get clipTriggerAlarmLabel => 'ریموٹ الارم';

  @override
  String get clipStatusUploaded => 'محفوظ ہو گیا';

  @override
  String get clipStatusPending => 'ریکارڈ ہو رہا ہے...';

  @override
  String get clipStatusMissed => 'مِس ہو گیا';

  @override
  String get downloadClipButtonLabel => 'ڈاؤن لوڈ کریں';

  @override
  String get deleteClipButtonLabel => 'حذف کریں';

  @override
  String get deleteClipConfirmTitle => 'یہ کلپ حذف کریں؟';

  @override
  String get deleteClipConfirmBody => 'یہ محفوظ شدہ کلپ ہٹا دیا جائے گا۔';

  @override
  String get clipDeletedConfirmation => 'کلپ حذف ہو گئی';

  @override
  String get cameraBeingViewedBanner =>
      'ایک سرپرست ابھی آپ کا کیمرہ دیکھ رہا ہے';

  @override
  String get analyticsButtonLabel => 'تحلیل';

  @override
  String get analyticsScreenTitle => 'تحلیل';

  @override
  String get analyticsDays7Label => '7 دن';

  @override
  String get analyticsDays30Label => '30 دن';

  @override
  String get analyticsDays90Label => '90 دن';

  @override
  String get adherenceSectionHeader => 'دوا کی پابندی';

  @override
  String get adherenceRateLabel => 'پابندی کی شرح';

  @override
  String get adherenceTakenLabel => 'لی گئی';

  @override
  String get adherenceMissedLabel => 'مِس ہوئی';

  @override
  String get adherenceWaitingLabel => 'باقی';

  @override
  String adherenceStreakLabel(int days) {
    return 'تسلسل: $days دن';
  }

  @override
  String get adherenceChangeVsPreviousLabel =>
      'پچھلے عرصے کے مقابلے میں تبدیلی';

  @override
  String get adherencePerMedicineHeader => 'دوا کے لحاظ سے';

  @override
  String get adherenceAccessDeniedMessage =>
      'آپ کو اس ڈیپنڈنٹ کی دوا کی پابندی دیکھنے کی اجازت نہیں ہے۔';

  @override
  String get noAdherenceDataMessage =>
      'اس عرصے کے لیے ابھی تک دوا کا کوئی ڈیٹا نہیں ہے۔';

  @override
  String get vitalsSectionHeader => 'وائٹلز کا رجحان';

  @override
  String get vitalsAccessDeniedMessage =>
      'آپ کو اس ڈیپنڈنٹ کے وائٹلز کا رجحان دیکھنے کی اجازت نہیں ہے۔';

  @override
  String get vitalsMetricCountLabel => 'ریڈنگز';

  @override
  String get vitalsMinLabel => 'کم ترین';

  @override
  String get vitalsMaxLabel => 'زیادہ ترین';

  @override
  String get vitalsAverageLabel => 'اوسط';

  @override
  String get vitalsLatestLabel => 'تازہ ترین';

  @override
  String get vitalsTrendLabel => 'رجحان';

  @override
  String get vitalsTrendRising => 'بڑھ رہا ہے';

  @override
  String get vitalsTrendFalling => 'گر رہا ہے';

  @override
  String get vitalsTrendSteady => 'مستحکم';

  @override
  String get noVitalsTrendDataMessage =>
      'اس عرصے کے لیے ابھی تک وائٹلز کا کوئی ڈیٹا نہیں ہے۔';

  @override
  String get bloodPressureChartSystolicOnlyNote =>
      'چارٹ صرف سسٹولک (اوپر والا) نمبر دکھاتا ہے۔';

  @override
  String get callDependentButtonLabel => 'کال';

  @override
  String get callButtonTooltip => 'کال';

  @override
  String get voiceCallOption => 'وائس کال';

  @override
  String get videoCallOption => 'ویڈیو کال';

  @override
  String get callStartingLabel => 'کال شروع ہو رہی ہے…';

  @override
  String get callRingingLabel => 'کال کی جا رہی ہے…';

  @override
  String get callFailedMessage => 'کال شروع نہیں ہو سکی۔ دوبارہ کوشش کریں۔';

  @override
  String get callDeclinedMessage => 'کال مسترد کر دی گئی۔';

  @override
  String get callNoAnswerMessage => 'کوئی جواب نہیں۔';

  @override
  String get callEndedMessage => 'کال ختم ہو گئی۔';

  @override
  String get callScreenOkButton => 'ٹھیک ہے';

  @override
  String get declineCallButton => 'مسترد کریں';

  @override
  String get acceptCallButton => 'قبول کریں';

  @override
  String get incomingVideoCallLabel => 'آنے والی ویڈیو کال';

  @override
  String get incomingVoiceCallLabel => 'آنے والی وائس کال';

  @override
  String get callConnectingLabel => 'رابطہ ہو رہا ہے…';

  @override
  String get callAlreadyEndedMessage => 'یہ کال پہلے ہی ختم ہو چکی ہے۔';
}
