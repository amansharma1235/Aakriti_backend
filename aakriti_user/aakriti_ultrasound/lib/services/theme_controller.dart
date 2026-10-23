import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _themePrefKey = "app_theme_dark_mode";
  static const String _adminThemePrefKey = "admin_theme_mode";

  final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  bool get isDarkMode => themeMode.value == ThemeMode.dark;
  bool get isDark => isDarkMode;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasUserDark = prefs.getBool(_themePrefKey);
      final adminMode = prefs.getString(_adminThemePrefKey);
      final isDark = hasUserDark ?? (adminMode == 'dark');
      themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      debugPrint('[ThemeController] init error: $e');
    }
  }

  void toggleDarkMode(bool value) async {
    themeMode.value = value ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePrefKey, value);
      await prefs.setString(_adminThemePrefKey, value ? 'dark' : 'light');
    } catch (e) {
      debugPrint('[ThemeController] save error: $e');
    }
  }

  void setTheme(ThemeMode mode) {
    toggleDarkMode(mode == ThemeMode.dark);
  }
}