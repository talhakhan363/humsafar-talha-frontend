import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Task 1.10 — which language is active right now.
///
/// `null` means "follow the phone's system language" (the original
/// scaffold behavior). Once the user explicitly picks one from the
/// in-app switcher, this holds that explicit choice instead — same
/// convention most apps use: an explicit in-app choice overrides
/// whatever the system default was.
class AppLocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void setLocale(Locale locale) => state = locale;
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale?>(
  AppLocaleNotifier.new,
);
