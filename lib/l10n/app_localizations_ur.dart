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
  String get moreComingSoonLabel =>
      'مزید: ریکارڈز · اپائنٹمنٹس · پیغامات (جلد آرہا ہے)';

  @override
  String get medicationComingSoonMessage =>
      'دوا کی تصدیق ٹاسک 3.13 میں شامل ہوگی۔';

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
}
