import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController {
  static final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));
  
  static const String _localeKey = 'app_locale';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);
    if (savedLocale != null) {
      locale.value = Locale(savedLocale);
    }
  }

  static Future<void> setLocale(Locale newLocale) async {
    locale.value = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);
  }

  static List<Locale> get supportedLocales => const [
    Locale('en'),
    Locale('zh'),
  ];

  static String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      default:
        return code;
    }
  }
}
