import 'package:flutter/material.dart';

/// Spendz Light Theme Provider.
/// Application strictly uses the Funky Claymorphism Light Palette.
class ThemeProvider extends ChangeNotifier {
  ThemeMode get themeMode => ThemeMode.light;

  bool get isDarkMode => false;

  Future<void> setThemeMode(ThemeMode mode) async {
    // Application is locked to human-crafted light theme per user request
    notifyListeners();
  }
}
