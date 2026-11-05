import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'spendz_colors.dart';
import 'spendz_spacing.dart';

/// Complete Spendz 2.0 Theme Configuration for Light and Dark Modes.
class SpendzTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: SpendzColors.forestGreen,
      scaffoldBackgroundColor: SpendzColors.softBackground,
      colorScheme: const ColorScheme.light(
        primary: SpendzColors.forestGreen,
        secondary: SpendzColors.emerald,
        tertiary: SpendzColors.olive,
        surface: SpendzColors.surfaceLight,
        surfaceContainerHighest: SpendzColors.surfaceElevatedLight,
        error: SpendzColors.expense,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: SpendzColors.textPrimaryLight,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SpendzColors.softBackground,
        foregroundColor: SpendzColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: SpendzColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpendzSpacing.radiusLg),
          side: BorderSide.none,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: SpendzColors.borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: SpendzColors.mint,
      scaffoldBackgroundColor: SpendzColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: SpendzColors.mint,
        secondary: SpendzColors.emerald,
        tertiary: SpendzColors.sage,
        surface: SpendzColors.surfaceDark,
        surfaceContainerHighest: SpendzColors.surfaceElevatedDark,
        error: SpendzColors.expense,
        onPrimary: SpendzColors.backgroundDark,
        onSecondary: Colors.white,
        onSurface: SpendzColors.textPrimaryDark,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SpendzColors.backgroundDark,
        foregroundColor: SpendzColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: SpendzColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpendzSpacing.radiusLg),
          side: BorderSide.none,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: SpendzColors.borderDark,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
