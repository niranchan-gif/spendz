import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's appearance preference.
class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'spendz_theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == 'light') _themeMode = ThemeMode.light;
      if (saved == 'dark') _themeMode = ThemeMode.dark;
      if (saved == 'system' || saved == null) _themeMode = ThemeMode.system;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await prefs.setString(_prefKey, value);
    } catch (_) {}
  }
}
