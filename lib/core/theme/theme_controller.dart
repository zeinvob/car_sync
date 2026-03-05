import 'package:flutter/material.dart';

class ThemeController {
  // start with light (or ThemeMode.system if you want)
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static void toggleTheme() {
    themeMode.value =
        (themeMode.value == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
  }
}