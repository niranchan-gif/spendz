import 'package:flutter/material.dart';

/// Spendz Funky Claymorphism Brand Palette & Semantic Theme Tokens.
///
/// Tangerine Punch, Sunshine Yellow, Periwinkle Sky Blue, Soft Cream,
/// and Deep Slate Ink with dual chromatic shadow accents.
class SpendzColors {
  // ─── STITCH CLAYMORPHISM PALETTE ──────────────────────────────────────────
  /// Tangerine Punch primary energy driver: #FF933E
  static const Color tangerine = Color(0xFFFF933E);
  static const Color tangerineDeep = Color(0xFF954A00);
  static const Color tangerineLight = Color(0xFFFFDCC6);
  static const Color tangerineDark = Color(0xFF6A3300);

  /// Sunshine Yellow secondary highlight: #FECA55 / #FFCB56
  static const Color sunshineYellow = Color(0xFFFECA55);
  static const Color sunshineDeep = Color(0xFF795900);
  static const Color sunshineLight = Color(0xFFFFDF9F);
  static const Color softButter = Color(0xFFFFE9A9);

  /// Periwinkle Sky Blue accent: #73A5CA / #82B4DA
  static const Color periwinkle = Color(0xFF73A5CA);
  static const Color periwinkleDeep = Color(0xFF2E6385);
  static const Color periwinkleLight = Color(0xFFC9E6FF);
  static const Color periwinkleDark = Color(0xFF024667);
  static const Color tertiarySky = periwinkle;

  /// Canvas Backdrops
  static const Color canvasLight = Color(0xFFF7F8FC);
  static const Color canvasWarmCream = Color(0xFFFDF8F0);
  static const Color canvasDark = Color(0xFF101713);
  static const Color canvasDeepDark = Color(0xFF101713);

  /// Surfaces (Light Claymorphic Layers - Warm tactile clay, NO empty flat white)
  static const Color surfaceLowest = Color(0xFFFFFDF9);
  static const Color surfaceLow = Color(0xFFF4F6FD);
  static const Color surfaceContainerColor = Color(0xFFEBF1FD);
  static const Color surfaceHigh = Color(0xFFE2EAFA);
  static const Color surfaceHighest = Color(0xFFD8E3FB);

  /// Tactile Claymorphism Pastel Tile Fills (Color Theory)
  static const Color clayYellow = Color(0xFFFECA55);
  static const Color clayYellowSoft = Color(0xFFFFF5D6);
  static const Color clayCream = Color(0xFFFFFBF2);
  static const Color clayPeriwinkle = Color(0xFFEAF2F9);
  static const Color clayTangerine = Color(0xFFFFF1E6);
  static const Color clayMint = Color(0xFFEDF8F2);
  static const Color clayLavender = Color(0xFFF3E8FF);

  /// Surfaces (Dark Claymorphic Layers)
  static const Color surfaceDark = Color(0xFF1A211D);
  static const Color surfaceElevatedDark = Color(0xFF222B25);
  static const Color borderDark = Color(0xFF29352D);

  /// Typography Bases
  static const Color inkSlate = Color(0xFF111C2D);
  static const Color inkSlateVariant = Color(0xFF554337);
  static const Color inkOutline = Color(0xFF897365);
  static const Color inkOutlineVariant = Color(0xFFDCC1B2);

  // ─── SEMANTIC INDICATORS ───────────────────────────────────────────────────
  /// Vibrant Expense / Coral: #E06A55 / #BA1A1A
  static const Color expense = Color(0xFFE06A55);
  static const Color error = expense;
  static const Color errorContainer = Color(0xFFFFDAD6);

  /// Healthy Inflow / Growth Emerald: #16A34A / #286B50
  static const Color income = Color(0xFF16A34A);

  /// Warning / Gold: #D99B26
  static const Color warning = Color(0xFFD99B26);

  /// Info / Tech: #2E6385
  static const Color info = Color(0xFF2E6385);

  // ─── BACKWARD COMPATIBILITY ALIASES ───────────────────────────────────────
  static const Color forestGreen = tangerineDeep;
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
  static const Color textPrimaryDark = Color(0xFFF1F5EF);
  static const Color textSecondaryDark = Color(0xFF9AA89B);

  // ─── DYNAMIC CONTEXT HELPERS ───────────────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? canvasDark : canvasLight;

  static Color surface(BuildContext context) =>
      isDark(context) ? surfaceDark : surfaceLowest;

  static Color surfaceElevated(BuildContext context) =>
      isDark(context) ? surfaceElevatedDark : surfaceLow;

  static Color surfaceRecessed(BuildContext context) =>
      isDark(context) ? const Color(0xFF141E2D) : surfaceLow;

  static Color surfaceContainerLow(BuildContext context) =>
      isDark(context) ? const Color(0xFF162030) : surfaceLow;

  static Color surfaceContainer(BuildContext context) =>
      isDark(context) ? const Color(0xFF1D2A40) : surfaceContainerColor;

  static Color surfaceContainerHigh(BuildContext context) =>
      isDark(context) ? const Color(0xFF223149) : surfaceHigh;

  static Color surfaceContainerHighest(BuildContext context) =>
      isDark(context) ? const Color(0xFF283A55) : surfaceHighest;

  static Color border(BuildContext context) =>
      isDark(context) ? borderDark : surfaceHigh;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? textPrimaryDark : inkSlate;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? textSecondaryDark : inkOutline;

  static Color primaryAccent(BuildContext context) => tangerine;

  static Color secondaryAccent(BuildContext context) => sunshineYellow;

  static Color tertiaryAccent(BuildContext context) => periwinkle;

  // ─── AUTHENTIC CLAYMORPHISM DROP SHADOWS & HIGHLIGHTS ─────────────────────
  static List<BoxShadow> clayDropShadow(
    BuildContext context, {
    double blur = 24.0,
    double spread = -4.0,
    Offset offset = const Offset(0, 10),
  }) {
    final dark = isDark(context);
    return [
      BoxShadow(
        color: dark
            ? Colors.black.withAlpha(90)
            : const Color(0xFF1E293B).withAlpha(18),
        offset: offset,
        blurRadius: blur,
        spreadRadius: spread,
      ),
      BoxShadow(
        color: dark
            ? const Color(0xFF2E6385).withAlpha(20)
            : tangerine.withAlpha(15),
        offset: Offset(0, offset.dy / 2),
        blurRadius: blur / 2,
        spreadRadius: -2,
      ),
    ];
  }

  static List<BoxShadow> clayInnerSheen({
    Color highlightColor = Colors.white,
    double opacity = 0.9,
  }) {
    return [
      BoxShadow(
        color: highlightColor.withAlpha((opacity * 255).round()),
        offset: const Offset(2.5, 2.5),
        blurRadius: 4.0,
        blurStyle: BlurStyle.inner,
      ),
      BoxShadow(
        color: const Color(0xFF1E293B).withAlpha(10),
        offset: const Offset(-2.5, -2.5),
        blurRadius: 4.0,
        blurStyle: BlurStyle.inner,
      ),
    ];
  }
}
