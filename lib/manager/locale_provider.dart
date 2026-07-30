import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appLocaleProvider = StateNotifierProvider<AppLocaleController, Locale>(
  (ref) => AppLocaleController(),
);

class AppLocaleController extends StateNotifier<Locale> {
  AppLocaleController() : super(const Locale('en')) {
    unawaited(_loadSavedLocale());
  }

  static const _languageCodeKey = 'app_language_code';
  static const _supportedLanguageCodes = {'en', 'zh'};

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey);
    if (languageCode != null &&
        _supportedLanguageCodes.contains(languageCode)) {
      state = Locale(languageCode);
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (!_supportedLanguageCodes.contains(languageCode)) {
      return;
    }

    state = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, languageCode);
  }
}
