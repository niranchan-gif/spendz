import 'package:flutter/material.dart';

/// Central color design tokens for Spendz 2.0 Fintech Design System.
///
/// Refined with Deep Olive Green, Muted Sage, Warm Off-White, and accessible
/// semantic indicators across both Light and Dark themes.
class AppColors {
  // ─── LIGHT PALETTE ──────────────────────────────────────────────────────────
  /// Deep Olive Green — primary brand anchor
  static const Color primaryLightMode = Color(0xFF273822);
  /// Muted Sage accent
  static const Color secondaryLightMode = Color(0xFF4A6242);
  /// Warm Off-White background
  static const Color backgroundLightMode = Color(0xFFF9FAF8);
  /// Clean White surface
  static const Color surfaceLightMode = Color(0xFFFFFFFF);
  /// Layered surface for cards and segmented items
  static const Color surfaceVariantLightMode = Color(0xFFF0F3EE);
  /// Container highlight surface
  static const Color surfaceContainerLightMode = Color(0xFFE5ECE2);

  /// Deep Charcoal for maximum contrast
  static const Color textPrimaryLightMode = Color(0xFF161C14);
  /// Muted Slate Grey for secondary metadata
  static const Color textSecondaryLightMode = Color(0xFF5A6657);
  /// Hint text
  static const Color textHintLightMode = Color(0xFF869283);

  /// Subtle border
  static const Color borderLightMode = Color(0xFFD8E1D5);
  /// Divider line
  static const Color dividerLightMode = Color(0xFFE5ECE2);

  // ─── DARK PALETTE ───────────────────────────────────────────────────────────
  /// Soft Sage glow — primary brand anchor in dark mode
  static const Color primaryDarkMode = Color(0xFFACC8A2);
  static const Color primaryLightDarkMode = Color(0xFFC7DEBE);
  static const Color primaryDarkDarkMode = Color(0xFF86A57B);

  /// Deep Night Olive background
  static const Color backgroundDarkMode = Color(0xFF131B11);
  /// Elevated Olive Charcoal surface
  static const Color surfaceDarkMode = Color(0xFF1B2618);
  /// Surface variant for grouped items
  static const Color surfaceVariantDarkMode = Color(0xFF243320);
  /// Deep container highlight
  static const Color surfaceContainerDarkMode = Color(0xFF2C3E28);

  /// Pristine White
  static const Color textPrimaryDarkMode = Color(0xFFF6F8F5);
  /// Muted Canopy Green
  static const Color textSecondaryDarkMode = Color(0xFFA2B2A0);
  /// Hint text
  static const Color textHintDarkMode = Color(0xFF728070);

  /// Subtle dark border
  static const Color borderDarkMode = Color(0xFF384934);
  /// Dark divider
  static const Color dividerDarkMode = Color(0xFF263323);

  // ─── STATIC CONSTANTS (Backward Compatible Defaults) ────────────────────────
  // Existing dark-mode constants preserved for full compatibility
  static const Color primary = primaryDarkMode;
  static const Color primaryLight = primaryLightDarkMode;
  static const Color primaryDark = primaryDarkDarkMode;
  static const Color secondary = secondaryLightMode;
  static const Color accent = primaryLightDarkMode;

  static const Color background = backgroundDarkMode;
  static const Color surface = surfaceDarkMode;
  static const Color surfaceVariant = surfaceVariantDarkMode;

  static const Color textPrimary = textPrimaryDarkMode;
  static const Color textSecondary = textSecondaryDarkMode;
  static const Color textHint = textHintDarkMode;

  static const Color border = borderDarkMode;
  static const Color divider = dividerDarkMode;

  // ─── SEMANTIC INDICATORS (WCAG AA/AAA Compliant) ─────────────────────────────
  /// Positive / Income / Success
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF22C55E);

  /// Negative / Expense / Error
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFF87171);

  /// Warning / Pending / Expiry Attention
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFFBBF24);

  /// Information / Bank / Cloud Sync
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

  static Color getSurfaceVariant(BuildContext context) {
    return isDark(context) ? surfaceVariantDarkMode : surfaceVariantLightMode;
  }

  static Color getSurfaceContainer(BuildContext context) {
    return isDark(context) ? surfaceContainerDarkMode : surfaceContainerLightMode;
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
}
