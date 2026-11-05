import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'spendz_colors.dart';

/// Application-wide warm clay theme. Accents are intentionally restrained.
class SpendzTheme {
  static ThemeData get lightTheme {
    final scheme = ColorScheme.light(
      primary: SpendzColors.tangerineDeep,
      onPrimary: Colors.white,
      primaryContainer: SpendzColors.clayTangerine,
      onPrimaryContainer: SpendzColors.tangerineDark,
      secondary: SpendzColors.sunshineDeep,
      onSecondary: SpendzColors.inkSlate,
      secondaryContainer: SpendzColors.clayYellow,
      onSecondaryContainer: SpendzColors.sunshineDeep,
      tertiary: SpendzColors.periwinkleDeep,
      onTertiary: Colors.white,
      tertiaryContainer: SpendzColors.clayPeriwinkle,
      onTertiaryContainer: SpendzColors.periwinkleDark,
      error: SpendzColors.error,
      onError: Colors.white,
      surface: SpendzColors.surfaceLowest,
      onSurface: SpendzColors.inkSlate,
      surfaceContainerLowest: SpendzColors.surfaceLowest,
      surfaceContainerLow: SpendzColors.surfaceLow,
      surfaceContainer: SpendzColors.surfaceContainerColor,
      surfaceContainerHigh: SpendzColors.surfaceHigh,
      surfaceContainerHighest: SpendzColors.surfaceHighest,
      outline: SpendzColors.inkOutline,
      outlineVariant: SpendzColors.inkOutlineVariant,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      primaryColor: SpendzColors.tangerine,
      scaffoldBackgroundColor: SpendzColors.canvasLight,
      fontFamily: 'Plus Jakarta Sans',
      appBarTheme: const AppBarTheme(
        backgroundColor: SpendzColors.canvasLight,
        foregroundColor: SpendzColors.inkSlate,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: SpendzColors.surfaceLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: SpendzColors.inkOutlineVariant),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: SpendzColors.inkOutlineVariant,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SpendzColors.surfaceLow,
        hintStyle: const TextStyle(color: SpendzColors.inkOutline),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SpendzColors.inkOutlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SpendzColors.tangerine, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: SpendzColors.surfaceLowest,
        indicatorColor: SpendzColors.clayTangerine,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? SpendzColors.tangerineDeep
                : SpendzColors.inkOutline,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.dark(
      primary: SpendzColors.tangerine,
      onPrimary: SpendzColors.inkSlate,
      primaryContainer: const Color(0xFF583824),
      onPrimaryContainer: const Color(0xFFFFDFC8),
      secondary: SpendzColors.sunshineYellow,
      onSecondary: SpendzColors.inkSlate,
      secondaryContainer: const Color(0xFF514326),
      onSecondaryContainer: const Color(0xFFFFE9A9),
      tertiary: SpendzColors.periwinkle,
      onTertiary: SpendzColors.inkSlate,
      tertiaryContainer: const Color(0xFF2C465A),
      onTertiaryContainer: SpendzColors.periwinkleLight,
      error: SpendzColors.error,
      onError: Colors.white,
      surface: SpendzColors.surfaceDark,
      onSurface: SpendzColors.textPrimaryDark,
      surfaceContainerLowest: SpendzColors.canvasDeepDark,
      surfaceContainerLow: SpendzColors.canvasDark,
      surfaceContainer: SpendzColors.surfaceDark,
      surfaceContainerHigh: SpendzColors.surfaceElevatedDark,
      surfaceContainerHighest: SpendzColors.borderDark,
      outline: SpendzColors.textSecondaryDark,
      outlineVariant: SpendzColors.borderDark,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      primaryColor: SpendzColors.tangerine,
      scaffoldBackgroundColor: SpendzColors.canvasDark,
      fontFamily: 'Plus Jakarta Sans',
      appBarTheme: const AppBarTheme(
        backgroundColor: SpendzColors.canvasDark,
        foregroundColor: SpendzColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: SpendzColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: SpendzColors.borderDark),
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
