import 'package:flutter/material.dart';

/// Central color design tokens for Spendz 2.0 Glassmorphism Fintech Design System.
///
/// Features authentic Light and Dark palettes with Deep Olive/Emerald,
/// Sage, Champagne, and tailored glass tokens for translucent surfaces.
class AppColors {
  // ─── LIGHT PALETTE ──────────────────────────────────────────────────────────
  /// Primary background: #F6F4D2 (Cream)
  static const Color backgroundLightMode = Color(0xFFF6F4D2);

  /// Primary surface: #F6F4D2 (Cream)
  static const Color surfaceLightMode = Color(0xFFF6F4D2);

  /// Secondary surface: #CBDFBD (Pistachio)
  static const Color surfaceSecondaryLightMode = Color(0xFFCBDFBD);

  /// Primary brand anchor: #F19C79 (Terracotta)
  static const Color primaryLightMode = Color(0xFFF19C79);

  /// Emerald accent: #D4E09B (Chartreuse)
  static const Color emeraldAccentLightMode = Color(0xFFD4E09B);

  /// Sage accent: #CBDFBD (Pistachio)
  static const Color sageLightMode = Color(0xFFCBDFBD);

  /// Champagne highlight: #D4E09B (Chartreuse)
  static const Color champagneLightMode = Color(0xFFD4E09B);

  /// Primary text: #2C221E (Espresso)
  static const Color textPrimaryLightMode = Color(0xFF2C221E);

  /// Secondary text: #63564F (Espresso Muted)
  static const Color textSecondaryLightMode = Color(0xFF63564F);

  /// Border: Transparent (Zero border requirement)
  static const Color borderLightMode = Colors.transparent;

  /// Divider: #CBDFBD
  static const Color dividerLightMode = Color(0xFFCBDFBD);

  static const Color surfaceVariantLightMode = surfaceSecondaryLightMode;
  static const Color surfaceContainerLightMode = surfaceSecondaryLightMode;
  static const Color secondaryLightMode = surfaceSecondaryLightMode;
  static const Color textHintLightMode = Color(0xFF63564F);

  // ─── DARK PALETTE (MAPPED TO LIGHT PASTEL CLAY PALETTE) ─────────────────────
  static const Color backgroundDarkMode = Color(0xFFF6F4D2);
  static const Color surfaceDarkMode = Color(0xFFF6F4D2);
  static const Color surfaceSecondaryDarkMode = Color(0xFFCBDFBD);
  static const Color primaryDarkMode = Color(0xFFF19C79);
  static const Color emeraldAccentDarkMode = Color(0xFFD4E09B);
  static const Color sageDarkMode = Color(0xFFCBDFBD);
  static const Color champagneDarkMode = Color(0xFFD4E09B);
  static const Color textPrimaryDarkMode = Color(0xFF2C221E);
  static const Color textSecondaryDarkMode = Color(0xFF63564F);
  static const Color borderDarkMode = Colors.transparent;
  static const Color dividerDarkMode = Color(0xFFCBDFBD);

  static const Color surfaceVariantDarkMode = surfaceSecondaryDarkMode;
  static const Color surfaceContainerDarkMode = surfaceSecondaryDarkMode;
  static const Color secondaryDarkMode = surfaceSecondaryDarkMode;
  static const Color textHintDarkMode = Color(0xFF63564F);

  // ─── STATIC CONSTANTS (Backward Compatible Defaults) ────────────────────────
  static const Color primary = primaryLightMode;
  static const Color primaryLight = emeraldAccentLightMode;
  static const Color primaryDark = primaryLightMode;
  static const Color secondary = emeraldAccentLightMode;
  static const Color accent = emeraldAccentLightMode;
  static const Color sage = sageLightMode;
  static const Color champagne = champagneLightMode;

  static const Color background = backgroundLightMode;
  static const Color surface = surfaceLightMode;
  static const Color surfaceVariant = surfaceVariantLightMode;

  static const Color textPrimary = textPrimaryLightMode;
  static const Color textSecondary = textSecondaryLightMode;
  static const Color textHint = textHintLightMode;

  static const Color border = Colors.transparent;
  static const Color divider = dividerLightMode;

  // ─── SEMANTIC INDICATORS ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF22C55E);

  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFF87171);

  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFFBBF24);

  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF60A5FA);

  // ─── DYNAMIC THEME RESOLVERS ────────────────────────────────────────────────
  static bool isDark(BuildContext context) => false; // User requested strictly light theme

  static Color getPrimary(BuildContext context) => primaryLightMode;

  static Color getBackground(BuildContext context) => backgroundLightMode;

  static Color getSurface(BuildContext context) => surfaceLightMode;

  static Color getSecondarySurface(BuildContext context) => surfaceSecondaryLightMode;

  static Color getSurfaceVariant(BuildContext context) => surfaceVariantLightMode;

  static Color getSurfaceContainer(BuildContext context) => surfaceContainerLightMode;

  static Color getEmeraldAccent(BuildContext context) => emeraldAccentLightMode;

  static Color getSage(BuildContext context) => sageLightMode;

  static Color getChampagne(BuildContext context) => champagneLightMode;

  static Color getTextPrimary(BuildContext context) => textPrimaryLightMode;

  static Color getTextSecondary(BuildContext context) => textSecondaryLightMode;

  static Color getTextHint(BuildContext context) => textHintLightMode;

  static Color getBorder(BuildContext context) => Colors.transparent;

  static Color getDivider(BuildContext context) => dividerLightMode;

  static Color getSuccess(BuildContext context) {
    return isDark(context) ? successDark : success;
  }

  static Color getError(BuildContext context) {
    return isDark(context) ? errorDark : error;
  }

  static Color getWarning(BuildContext context) {
    return isDark(context) ? warningDark : warning;
  }

  static Color getInfo(BuildContext context) {
    return isDark(context) ? infoDark : info;
  }

  // ─── GLASS SYSTEM COLORS ────────────────────────────────────────────────────
  /// Translucent background tint for glass surfaces (Smoked Obsidian in Dark, Frosted White in Light)
  static Color getGlassBackground(BuildContext context) => getSurface(context);

  /// Subtle perimeter border for glass components (Specular Refractive Hairline)
  static Color getGlassBorder(BuildContext context) => getBorder(context);

  /// Specular ambient highlight color for glass gradients
  static Color getGlassHighlight(BuildContext context) {
    return isDark(context)
        ? Colors.white.withAlpha(30)
        : Colors.white.withAlpha(90);
  }
}
