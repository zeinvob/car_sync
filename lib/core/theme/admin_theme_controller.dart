import 'package:flutter/material.dart';

class AdminThemeController {
  static final ValueNotifier<bool> isDark = ValueNotifier<bool>(false);

  static void toggleTheme() {
    isDark.value = !isDark.value;
  }

  static void setTheme(bool value) {
    isDark.value = value;
  }
}