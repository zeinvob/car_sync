import 'package:flutter/material.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static void toggleTheme() {
    themeMode.value =
        (themeMode.value == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
  }

  static bool get isDark => themeMode.value == ThemeMode.dark;
}