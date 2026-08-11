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
}
