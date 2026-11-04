import 'package:flutter/material.dart';

/// Spendz 2.0 Brand Palette and Semantic Theme Tokens.
///
/// Deep Forest Green, Emerald, Olive, Sage with authentic Light and Dark modes.
class SpendzColors {
  // ─── LIGHT PALETTE ──────────────────────────────────────────────────────────
  /// Deep forest green brand anchor: #142D25
  static const Color forestGreen = Color(0xFF142D25);

  /// Emerald accent: #286B50
  static const Color emerald = Color(0xFF286B50);

  /// Bright mint highlight: #34D399
  static const Color mint = Color(0xFF34D399);

  /// Olive accent: #687A46
  static const Color olive = Color(0xFF687A46);

  /// Sage accent: #A8B99B
  static const Color sage = Color(0xFFA8B99B);

  /// Soft light background: #F5F6F0
  static const Color softBackground = Color(0xFFF5F6F0);

  /// Primary light surface: #FFFFFF
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Elevated light surface: #EBF0E9
  static const Color surfaceElevatedLight = Color(0xFFEBF0E9);

  /// Light border: #DFE5DC
  static const Color borderLight = Color(0xFFDFE5DC);

  /// Primary text (Light): #17231D
  static const Color textPrimaryLight = Color(0xFF17231D);

  /// Secondary text (Light): #818A80
  static const Color textSecondaryLight = Color(0xFF818A80);

  // ─── DARK PALETTE ───────────────────────────────────────────────────────────
  /// Primary dark background: #101713
  static const Color backgroundDark = Color(0xFF101713);

  /// Primary dark surface: #19231D
  static const Color surfaceDark = Color(0xFF19231D);

  /// Elevated dark surface: #202D25
  static const Color surfaceElevatedDark = Color(0xFF202D25);

  /// Dark border: #27382E
  static const Color borderDark = Color(0xFF27382E);

  /// Primary text (Dark): #F1F5EF
  static const Color textPrimaryDark = Color(0xFFF1F5EF);

  /// Secondary text (Dark): #9AA89B
  static const Color textSecondaryDark = Color(0xFF9AA89B);

  // ─── SEMANTIC INDICATORS ───────────────────────────────────────────────────
  /// Muted coral expense indicator: #E06A55
  static const Color expense = Color(0xFFE06A55);

  /// Emerald income indicator: #286B50
  static const Color income = Color(0xFF286B50);

  /// Warning / Pending indicator: #D99B26
  static const Color warning = Color(0xFFD99B26);

  /// Info / Sync indicator: #3B82F6
  static const Color info = Color(0xFF3B82F6);

  // ─── DYNAMIC CONTEXT HELPERS ───────────────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? backgroundDark : softBackground;

  static Color surface(BuildContext context) =>
      isDark(context) ? surfaceDark : surfaceLight;

  static Color surfaceElevated(BuildContext context) =>
      isDark(context) ? surfaceElevatedDark : surfaceElevatedLight;

  static Color border(BuildContext context) =>
      isDark(context) ? borderDark : borderLight;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondaryLight;

  static Color primaryAccent(BuildContext context) =>
      isDark(context) ? mint : emerald;
}
