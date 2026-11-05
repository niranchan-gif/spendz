import 'package:flutter/material.dart';

/// Spendz brand tokens. Warm, tactile clay surfaces with four restrained brand accents.
class SpendzColors {
  // Brand palette supplied for Spendz.
  static const Color tangerine = Color(0xFFFF933E);
  static const Color sunshineYellow = Color(0xFFFFCB56);
  static const Color softButter = Color(0xFFFFE9A9);
  static const Color periwinkle = Color(0xFF73A5CA);

  // Tonal companions derived from the brand palette.
  static const Color tangerineDeep = Color(0xFFB95618);
  static const Color tangerineLight = Color(0xFFFFE4D0);
  static const Color tangerineDark = Color(0xFF71330F);
  static const Color sunshineDeep = Color(0xFF8A5A00);
  static const Color sunshineLight = Color(0xFFFFF1C9);
  static const Color periwinkleDeep = Color(0xFF365F7D);
  static const Color periwinkleLight = Color(0xFFDCECF7);
  static const Color periwinkleDark = Color(0xFF24445D);
  static const Color tertiarySky = periwinkle;

  // Light canvas and the three tactile surface elevations.
  static const Color canvasLight = Color(0xFFFFF8F0);
  static const Color canvasWarmCream = Color(0xFFFFF4E8);
  static const Color surfaceLowest = Color(0xFFFFFEFC);
  static const Color surfaceLow = Color(0xFFFFF9F1);
  static const Color surfaceContainerColor = Color(0xFFF7EFE5);
  static const Color surfaceHigh = Color(0xFFEFE4D7);
  static const Color surfaceHighest = Color(0xFFE5D8C9);

  // Pastel clay tints: accent colour is used as a tint, not a full-screen fill.
  static const Color clayYellow = Color(0xFFFFF0C8);
  static const Color clayYellowSoft = Color(0xFFFFF7E3);
  static const Color clayCream = Color(0xFFFFFBF5);
  static const Color clayPeriwinkle = Color(0xFFEAF3F9);
  static const Color clayTangerine = Color(0xFFFFF0E4);
  static const Color clayMint = Color(0xFFEAF5EE);
  static const Color clayLavender = Color(0xFFF1ECF8);

  // Dark surfaces retain the warm ink character without becoming pure black.
  static const Color canvasDark = Color(0xFF1C2028);
  static const Color canvasDeepDark = Color(0xFF171B22);
  static const Color surfaceDark = Color(0xFF252B35);
  static const Color surfaceElevatedDark = Color(0xFF2D3541);
  static const Color surfaceInsetDark = Color(0xFF1D232C);
  static const Color borderDark = Color(0xFF3A4350);

  // Typography and neutral borders.
  static const Color inkSlate = Color(0xFF292D36);
  static const Color inkSlateVariant = Color(0xFF565B65);
  static const Color inkOutline = Color(0xFF777B83);
  static const Color inkOutlineVariant = Color(0xFFE5D9CC);
  static const Color textPrimaryDark = Color(0xFFF8F2EA);
  static const Color textSecondaryDark = Color(0xFFB9B4AD);

  // Semantic finance colours remain independent from brand accents.
  static const Color expense = Color(0xFFD85C50);
  static const Color error = expense;
  static const Color errorContainer = Color(0xFFFFE4E0);
  static const Color income = Color(0xFF26845B);
  static const Color warning = Color(0xFFB97816);
  static const Color info = periwinkleDeep;

  // Compatibility aliases used by older screens.
  static const Color forestGreen = inkSlate;
  static const Color emerald = tangerine;
  static const Color mint = sunshineYellow;
  static const Color olive = periwinkle;
  static const Color sage = periwinkleLight;
  static const Color softBackground = canvasLight;
  static const Color surfaceLight = surfaceLowest;
  static const Color surfaceElevatedLight = surfaceLow;
  static const Color borderLight = surfaceHigh;
  static const Color textPrimaryLight = inkSlate;
  static const Color textSecondaryLight = inkOutline;
  static const Color backgroundDark = canvasDark;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? canvasDark : canvasLight;
  static Color surface(BuildContext context) =>
      isDark(context) ? surfaceDark : surfaceLowest;
  static Color surfaceElevated(BuildContext context) =>
      isDark(context) ? surfaceElevatedDark : surfaceLow;
  static Color surfaceRecessed(BuildContext context) =>
      isDark(context) ? surfaceInsetDark : surfaceContainerColor;
  static Color surfaceContainerLow(BuildContext context) =>
      isDark(context) ? surfaceInsetDark : surfaceLow;
  static Color surfaceContainer(BuildContext context) =>
      isDark(context) ? surfaceDark : surfaceContainerColor;
  static Color surfaceContainerHigh(BuildContext context) =>
      isDark(context) ? surfaceElevatedDark : surfaceHigh;
  static Color surfaceContainerHighest(BuildContext context) =>
      isDark(context) ? borderDark : surfaceHighest;
  static Color border(BuildContext context) =>
      isDark(context) ? borderDark : surfaceHigh;
  static Color textPrimary(BuildContext context) =>
      isDark(context) ? textPrimaryDark : inkSlate;
  static Color textSecondary(BuildContext context) =>
      isDark(context) ? textSecondaryDark : inkOutline;
  static Color primaryAccent(BuildContext context) => tangerine;
  static Color secondaryAccent(BuildContext context) => sunshineYellow;
  static Color tertiaryAccent(BuildContext context) => periwinkle;

  /// Soft ambient lift. Keep blur broad and opacity low; clay should feel moulded,
  /// not like a stack of floating material cards.
  static List<BoxShadow> clayDropShadow(
    BuildContext context, {
    double blur = 22,
    double spread = -5,
    Offset offset = const Offset(0, 8),
  }) {
    final dark = isDark(context);
    return [
      BoxShadow(
        color: dark
            ? Colors.black.withAlpha(70)
            : const Color(0xFF765A3E).withAlpha(18),
        offset: offset,
        blurRadius: blur,
        spreadRadius: spread,
      ),
      BoxShadow(
        color: dark
            ? Colors.white.withAlpha(7)
            : Colors.white.withAlpha(220),
        offset: const Offset(-1, -1),
        blurRadius: 2,
        spreadRadius: -1,
      ),
    ];
  }

  /// Directional inner bevel: top-left light, bottom-right warm shade.
  static List<BoxShadow> clayInnerSheen({
    Color highlightColor = Colors.white,
    double opacity = 0.78,
  }) => [
    BoxShadow(
      color: highlightColor.withAlpha((opacity * 255).round()),
      offset: const Offset(-2, -2),
      blurRadius: 5,
      blurStyle: BlurStyle.inner,
    ),
    const BoxShadow(
      color: Color(0x1A72583F),
      offset: Offset(2, 2),
      blurRadius: 5,
      blurStyle: BlurStyle.inner,
    ),
  ];
}
