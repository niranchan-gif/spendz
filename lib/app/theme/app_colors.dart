import 'package:flutter/material.dart';

/// Central color design tokens for Spendz 2.0 Glassmorphism Fintech Design System.
///
/// Features authentic Light and Dark palettes with Deep Olive/Emerald,
/// Sage, Champagne, and tailored glass tokens for translucent surfaces.
class AppColors {
  // ─── LIGHT PALETTE ──────────────────────────────────────────────────────────
  /// Primary background: #F2F6F2
  static const Color backgroundLightMode = Color(0xFFF2F6F2);
  /// Primary surface: #FFFFFF
  static const Color surfaceLightMode = Color(0xFFFFFFFF);
  /// Secondary surface: #E8F0E9
  static const Color surfaceSecondaryLightMode = Color(0xFFE8F0E9);
  /// Primary brand anchor: #174D3B
  static const Color primaryLightMode = Color(0xFF174D3B);
  /// Emerald accent: #42A982
  static const Color emeraldAccentLightMode = Color(0xFF42A982);
  /// Sage accent: #A9C7B0
  static const Color sageLightMode = Color(0xFFA9C7B0);
  /// Champagne highlight: #D6B779
  static const Color champagneLightMode = Color(0xFFD6B779);
  /// Primary text: #19271F
  static const Color textPrimaryLightMode = Color(0xFF19271F);
  /// Secondary text: #718076
  static const Color textSecondaryLightMode = Color(0xFF718076);
  /// Border: #DFE8E0
  static const Color borderLightMode = Color(0xFFDFE8E0);
  /// Divider
  static const Color dividerLightMode = Color(0xFFE5EDE6);

  static const Color surfaceVariantLightMode = surfaceSecondaryLightMode;
  static const Color surfaceContainerLightMode = surfaceSecondaryLightMode;
  static const Color secondaryLightMode = surfaceSecondaryLightMode;
  static const Color textHintLightMode = Color(0xFF8FA094);

  // ─── DARK PALETTE ───────────────────────────────────────────────────────────
  /// Primary dark background: #0C1712
  static const Color backgroundDarkMode = Color(0xFF0C1712);
  /// Primary surface: #14231B
  static const Color surfaceDarkMode = Color(0xFF14231B);
  /// Secondary surface: #1B3025
  static const Color surfaceSecondaryDarkMode = Color(0xFF1B3025);
  /// Primary brand anchor: #48B98B
  static const Color primaryDarkMode = Color(0xFF48B98B);
  /// Emerald accent: #65D0A4
  static const Color emeraldAccentDarkMode = Color(0xFF65D0A4);
  /// Sage accent: #A8C7B0
  static const Color sageDarkMode = Color(0xFFA8C7B0);
  /// Champagne highlight: #E6C587
  static const Color champagneDarkMode = Color(0xFFE6C587);
  /// Primary text: #F2F6F2
  static const Color textPrimaryDarkMode = Color(0xFFF2F6F2);
  /// Secondary text: #A2B3A7
  static const Color textSecondaryDarkMode = Color(0xFFA2B3A7);
  /// Border: #304638
  static const Color borderDarkMode = Color(0xFF304638);
  /// Divider
  static const Color dividerDarkMode = Color(0xFF22362A);

  static const Color surfaceVariantDarkMode = surfaceSecondaryDarkMode;
  static const Color surfaceContainerDarkMode = surfaceSecondaryDarkMode;
  static const Color secondaryDarkMode = surfaceSecondaryDarkMode;
  static const Color textHintDarkMode = Color(0xFF6E8073);

  // ─── STATIC CONSTANTS (Backward Compatible Defaults) ────────────────────────
  static const Color primary = primaryDarkMode;
  static const Color primaryLight = emeraldAccentDarkMode;
  static const Color primaryDark = Color(0xFF2E8A64);
  static const Color secondary = emeraldAccentLightMode;
  static const Color accent = emeraldAccentDarkMode;
  static const Color sage = sageDarkMode;
  static const Color champagne = champagneDarkMode;

  static const Color background = backgroundDarkMode;
  static const Color surface = surfaceDarkMode;
  static const Color surfaceVariant = surfaceVariantDarkMode;

  static const Color textPrimary = textPrimaryDarkMode;
  static const Color textSecondary = textSecondaryDarkMode;
  static const Color textHint = textHintDarkMode;

  static const Color border = borderDarkMode;
  static const Color divider = dividerDarkMode;

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
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getPrimary(BuildContext context) {
    return isDark(context) ? primaryDarkMode : primaryLightMode;
  }

  static Color getBackground(BuildContext context) {
    return isDark(context) ? backgroundDarkMode : backgroundLightMode;
  }

  static Color getSurface(BuildContext context) {
    return isDark(context) ? surfaceDarkMode : surfaceLightMode;
  }

  static Color getSecondarySurface(BuildContext context) {
    return isDark(context) ? surfaceSecondaryDarkMode : surfaceSecondaryLightMode;
  }

  static Color getSurfaceVariant(BuildContext context) {
    return isDark(context) ? surfaceVariantDarkMode : surfaceVariantLightMode;
  }

  static Color getSurfaceContainer(BuildContext context) {
    return isDark(context) ? surfaceContainerDarkMode : surfaceContainerLightMode;
  }

  static Color getEmeraldAccent(BuildContext context) {
    return isDark(context) ? emeraldAccentDarkMode : emeraldAccentLightMode;
  }

  static Color getSage(BuildContext context) {
    return isDark(context) ? sageDarkMode : sageLightMode;
  }

  static Color getChampagne(BuildContext context) {
    return isDark(context) ? champagneDarkMode : champagneLightMode;
  }

  static Color getTextPrimary(BuildContext context) {
    return isDark(context) ? textPrimaryDarkMode : textPrimaryLightMode;
  }

  static Color getTextSecondary(BuildContext context) {
    return isDark(context) ? textSecondaryDarkMode : textSecondaryLightMode;
  }

  static Color getTextHint(BuildContext context) {
    return isDark(context) ? textHintDarkMode : textHintLightMode;
  }

  static Color getBorder(BuildContext context) {
    return isDark(context) ? borderDarkMode : borderLightMode;
  }

  static Color getDivider(BuildContext context) {
    return isDark(context) ? dividerDarkMode : dividerLightMode;
  }

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
  /// Translucent background tint for glass surfaces
  static Color getGlassBackground(BuildContext context) {
    return isDark(context)
        ? const Color(0xFF14231B).withAlpha(190)
        : const Color(0xFFFFFFFF).withAlpha(205);
  }

  /// Subtle perimeter border for glass components
  static Color getGlassBorder(BuildContext context) {
    return isDark(context)
        ? const Color(0xFF65D0A4).withAlpha(35)
        : const Color(0xFFFFFFFF).withAlpha(220);
  }

  /// Specular ambient highlight color for glass gradients
  static Color getGlassHighlight(BuildContext context) {
    return isDark(context)
        ? Colors.white.withAlpha(20)
        : Colors.white.withAlpha(90);
  }
}
