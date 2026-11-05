import 'package:flutter/material.dart';

/// Spendz Funky Claymorphism Brand Palette & Semantic Theme Tokens.
///
/// Palette strictly limited to:
/// - Warm Chartreuse: #D4E09B
/// - Soft Cream Butter: #F6F4D2
/// - Pale Pistachio: #CBDFBD
/// - Coral Terracotta: #F19C79
/// - Deep Crimson Brick: #A44A3F
///
/// Matte tactile surfaces with defined borders, layered elevation,
/// and subtle physical shadows (NO translucent boxes, NO glows).
class SpendzColors {
  // ─── THE 5 CORE FUNKY CLAY PALETTE COLORS ────────────────────────────────
  /// 1. Warm Chartreuse Olive: #D4E09B
  static const Color chartreuse = Color(0xFFD4E09B);

  /// 2. Soft Cream Butter: #F6F4D2
  static const Color cream = Color(0xFFF6F4D2);

  /// 3. Pale Pistachio Mint Clay: #CBDFBD
  static const Color pistachio = Color(0xFFCBDFBD);

  /// 4. Coral Terracotta Action / Outflow: #F19C79
  static const Color terracotta = Color(0xFFF19C79);

  /// 5. Deep Crimson Brick Accent / Dark Clay: #A44A3F
  static const Color brick = Color(0xFFA44A3F);

  /// Matte Espresso Ink for high-contrast crisp readability on light clay
  static const Color espresso = Color(0xFF2C221E);
  static const Color espressoMuted = Color(0xFF63564F);

  // ─── SEMANTIC BRAND MAPPING ──────────────────────────────────────────────
  static const Color tangerine = terracotta; // #F19C79
  static const Color tangerineDeep = brick; // #A44A3F
  static const Color tangerineLight = cream; // #F6F4D2
  static const Color tangerineDark = brick; // #A44A3F

  static const Color sunshineYellow = chartreuse; // #D4E09B
  static const Color sunshineDeep = espresso;
  static const Color sunshineLight = cream;
  static const Color softButter = cream;

  static const Color periwinkle = pistachio; // #CBDFBD
  static const Color periwinkleDeep = brick; // #A44A3F
  static const Color periwinkleLight = cream;
  static const Color periwinkleDark = espresso;
  static const Color tertiarySky = pistachio; // #CBDFBD

  /// Canvas Backdrops (Matte Cream #F6F4D2)
  static const Color canvasLight = cream;
  static const Color canvasWarmCream = cream;
  static const Color canvasDark = cream; // Consistent matte light clay
  static const Color canvasDeepDark = cream;

  /// Surfaces (Tactile Matte Clay Layers - Defined by palette)
  static const Color surfaceLowest = cream; // #F6F4D2
  static const Color surfaceLow = pistachio; // #CBDFBD
  static const Color surfaceContainerColor = pistachio; // #CBDFBD
  static const Color surfaceHigh = chartreuse; // #D4E09B
  static const Color surfaceHighest = terracotta; // #F19C79

  /// Tactile Claymorphism Tile Fills
  static const Color clayYellow = chartreuse; // #D4E09B
  static const Color clayYellowSoft = cream; // #F6F4D2
  static const Color clayCream = cream; // #F6F4D2
  static const Color clayPeriwinkle = pistachio; // #CBDFBD
  static const Color clayTangerine = terracotta; // #F19C79
  static const Color clayMint = pistachio; // #CBDFBD
  static const Color clayLavender = chartreuse; // #D4E09B

  /// Surfaces (Matte Clay Accents)
  static const Color surfaceDark = pistachio;
  static const Color surfaceElevatedDark = cream;
  static const Color borderDark = Color(0xFFB5CCA7);

  static const Color matteTangerine = terracotta;
  static const Color matteSunshine = chartreuse;
  static const Color mattePeriwinkle = pistachio;
  static const Color matteMint = pistachio;
  static const Color matteNeutral = cream;

  /// Typography Bases
  static const Color inkSlate = espresso;
  static const Color inkSlateVariant = brick;
  static const Color inkOutline = espressoMuted;
  static const Color inkOutlineVariant = Color(0xFFB5CCA7);

  // ─── SEMANTIC INDICATORS ───────────────────────────────────────────────────
  static const Color expense = brick; // #A44A3F
  static const Color error = brick;
  static const Color errorContainer = terracotta;
  static const Color income = Color(0xFF4C6B22); // Deep chartreuse olive
  static const Color warning = terracotta;
  static const Color info = pistachio;

  // ─── BACKWARD COMPATIBILITY ALIASES ───────────────────────────────────────
  static const Color forestGreen = brick;
  static const Color emerald = chartreuse;
  static const Color mint = pistachio;
  static const Color olive = chartreuse;
  static const Color sage = pistachio;
  static const Color softBackground = cream;
  static const Color surfaceLight = surfaceLowest;
  static const Color surfaceElevatedLight = surfaceLow;
  static const Color borderLight = Color(0xFFB5CCA7);
  static const Color textPrimaryLight = espresso;
  static const Color textSecondaryLight = espressoMuted;
  static const Color backgroundDark = cream;
  static const Color textPrimaryDark = espresso;
  static const Color textSecondaryDark = espressoMuted;

  // ─── DYNAMIC CONTEXT HELPERS ───────────────────────────────────────────────
  static bool isDark(BuildContext context) => false; // User requested strictly matte light theme

  static Color background(BuildContext context) => cream;

  static Color surface(BuildContext context) => cream;

  static Color surfaceElevated(BuildContext context) => pistachio;

  static Color surfaceRecessed(BuildContext context) => Color(0xFFE2E0BD);

  static Color surfaceContainerLow(BuildContext context) => cream;

  static Color surfaceContainer(BuildContext context) => pistachio;

  static Color surfaceContainerHigh(BuildContext context) => chartreuse;

  static Color surfaceContainerHighest(BuildContext context) => terracotta;

  static Color border(BuildContext context) => Colors.transparent;

  static Color textPrimary(BuildContext context) => espresso;

  static Color textSecondary(BuildContext context) => espressoMuted;

  static Color primaryAccent(BuildContext context) => terracotta;

  static Color secondaryAccent(BuildContext context) => chartreuse;

  static Color tertiaryAccent(BuildContext context) => pistachio;

  // ─── AUTHENTIC MATTE CLAY DROP SHADOWS (NO GLOWS) ─────────────────────────
  static List<BoxShadow> clayDropShadow(
    BuildContext context, {
    double blur = 6.0,
    double spread = 0.0,
    Offset offset = const Offset(2.0, 3.5),
  }) {
    return [
      BoxShadow(
        color: const Color(0xFF2C221E).withAlpha(18),
        offset: offset,
        blurRadius: blur,
        spreadRadius: spread,
      ),
      const BoxShadow(
        color: Color(0xFFFFFFFF),
        offset: Offset(-1.5, -1.5),
        blurRadius: 2.0,
        spreadRadius: 0.5,
      ),
    ];
  }

  static List<BoxShadow> clayInnerSheen({
    Color highlightColor = Colors.white,
    double opacity = 0.6,
  }) {
    return [
      BoxShadow(
        color: highlightColor.withAlpha((opacity * 255).round()),
        offset: const Offset(1.5, 1.5),
        blurRadius: 2.5,
        blurStyle: BlurStyle.inner,
      ),
      BoxShadow(
        color: const Color(0xFF2C221E).withAlpha(12),
        offset: const Offset(-1.5, -1.5),
        blurRadius: 2.5,
        blurStyle: BlurStyle.inner,
      ),
    ];
  }
}
