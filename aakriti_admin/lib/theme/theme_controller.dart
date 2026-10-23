import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _themePrefKey = "admin_theme_mode";

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );

  bool get isDark {
    return themeMode.value == ThemeMode.dark;
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themePrefKey);
      if (savedMode == 'dark') {
        themeMode.value = ThemeMode.dark;
      } else {
        themeMode.value = ThemeMode.light;
      }
    } catch (e) {
      debugPrint('[Admin ThemeController] init error: $e');
    }
  }

  void setTheme(ThemeMode mode) async {
    themeMode.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePrefKey, mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (e) {
      debugPrint('[Admin ThemeController] save error: $e');
    }
  }
}
