import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

/// Complete Dual Theme System (Light & Dark) for Spendz 2.0 Fintech UI.
class AppTheme {
  // ─── LIGHT THEME ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primaryLightMode,
      onPrimary: Colors.white,
      primaryContainer: AppColors.surfaceContainerLightMode,
      onPrimaryContainer: AppColors.primaryLightMode,
      secondary: AppColors.secondaryLightMode,
      onSecondary: Colors.white,
      surface: AppColors.surfaceLightMode,
      onSurface: AppColors.textPrimaryLightMode,
      surfaceContainerHighest: AppColors.surfaceVariantLightMode,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.borderLightMode,
      outlineVariant: AppColors.dividerLightMode,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLightMode,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLightMode),
        titleTextStyle: AppTextStyles.heading2.copyWith(color: AppColors.textPrimaryLightMode),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLightMode,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedCard,
          side: const BorderSide(color: AppColors.borderLightMode, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLightMode,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLightMode,
        selectedItemColor: AppColors.primaryLightMode,
        unselectedItemColor: AppColors.textHintLightMode,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLightMode,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.roundedMd,
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLightMode,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.borderLightMode, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.roundedMd,
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariantLightMode,
        border: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: const BorderSide(color: AppColors.borderLightMode, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: const BorderSide(color: AppColors.borderLightMode, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: const BorderSide(color: AppColors.primaryLightMode, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLightMode),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHintLightMode),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLightMode,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
        elevation: 6,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLightMode,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLightMode,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ─── DARK THEME ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primaryDarkMode,
      onPrimary: AppColors.backgroundDarkMode,
      primaryContainer: AppColors.surfaceContainerDarkMode,
      onPrimaryContainer: AppColors.primaryLightDarkMode,
      secondary: AppColors.primaryDarkDarkMode,
      onSecondary: Colors.white,
      surface: AppColors.surfaceDarkMode,
      onSurface: AppColors.textPrimaryDarkMode,
      surfaceContainerHighest: AppColors.surfaceVariantDarkMode,
      error: AppColors.errorDark,
      onError: Colors.white,
      outline: AppColors.borderDarkMode,
      outlineVariant: AppColors.dividerDarkMode,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDarkMode,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDarkMode),
        titleTextStyle: AppTextStyles.heading2.copyWith(color: AppColors.textPrimaryDarkMode),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDarkMode,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedCard,
          side: const BorderSide(color: AppColors.borderDarkMode, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDarkMode,
        foregroundColor: AppColors.backgroundDarkMode,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDarkMode,
        selectedItemColor: AppColors.primaryDarkMode,
        unselectedItemColor: AppColors.textHintDarkMode,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDarkMode,
          foregroundColor: AppColors.backgroundDarkMode,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.roundedMd,
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.backgroundDarkMode),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDarkMode,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.borderDarkMode, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.roundedMd,
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariantDarkMode,
        border: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: const BorderSide(color: AppColors.borderDarkMode, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: const BorderSide(color: AppColors.borderDarkMode, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: const BorderSide(color: AppColors.primaryDarkMode, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: const BorderSide(color: AppColors.errorDark, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDarkMode),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHintDarkMode),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDarkMode,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
        elevation: 6,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDarkMode,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDarkMode,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
