import 'package:flutter/material.dart';

/// Spendz semantic colour system: warm mineral neutrals, deep emerald,
/// soft sage and restrained champagne. Legacy names remain as aliases so
/// existing screens can migrate without breaking their behaviour.
class SpendzColors {
  // Brand accents
  static const Color forestGreen = Color(0xFF245B43);
  static const Color emerald = Color(0xFF2F805B);
  static const Color mint = Color(0xFFBFD8C5);
  static const Color olive = Color(0xFF879B82);
  static const Color sage = Color(0xFFDCE8DD);
  static const Color champagne = Color(0xFFC9AD73);

  // Compatibility names used by older screens. Tangerine now resolves to
  // the emerald action colour; yellow/periwinkle resolve to sage/champagne.
  static const Color tangerine = emerald;
  static const Color tangerineDeep = forestGreen;
  static const Color tangerineLight = Color(0xFFDDEDE3);
  static const Color tangerineDark = Color(0xFF17432F);
  static const Color sunshineYellow = champagne;
  static const Color sunshineDeep = Color(0xFF80683D);
  static const Color sunshineLight = Color(0xFFF0E7D2);
  static const Color softButter = Color(0xFFF4EEDC);
  static const Color periwinkle = olive;
  static const Color periwinkleDeep = forestGreen;
  static const Color periwinkleLight = sage;
  static const Color periwinkleDark = Color(0xFF345844);
  static const Color tertiarySky = olive;

  // Canvas and surface layers
  static const Color canvasLight = Color(0xFFF0F3EF);
  static const Color canvasWarmCream = Color(0xFFF5F3EB);
  static const Color canvasDark = Color(0xFF101713);
  static const Color canvasDeepDark = Color(0xFF0B120E);
  static const Color surfaceLowest = Color(0xFFFAFCF9);
  static const Color surfaceLow = Color(0xFFEEF2ED);
  static const Color surfaceContainerColor = Color(0xFFE5EBE4);
  static const Color surfaceHigh = Color(0xFFDCE5DC);
  static const Color surfaceHighest = Color(0xFFD1DDD2);

  // Soft category fills; these are supporting tints, not competing brand hues.
  static const Color clayYellow = Color(0xFFE9DFC5);
  static const Color clayYellowSoft = Color(0xFFF5F0E3);
  static const Color clayCream = Color(0xFFFAF8F1);
  static const Color clayPeriwinkle = Color(0xFFE7EEE8);
  static const Color clayTangerine = Color(0xFFE8F1EA);
  static const Color clayMint = Color(0xFFE5F0E8);
  static const Color clayLavender = Color(0xFFEBEEE8);

  // Dark clay layers
  static const Color surfaceDark = Color(0xFF17221B);
  static const Color surfaceElevatedDark = Color(0xFF202D24);
  static const Color borderDark = Color(0xFF34463A);

  // Text
  static const Color inkSlate = Color(0xFF1B2820);
  static const Color inkSlateVariant = Color(0xFF58665C);
  static const Color inkOutline = Color(0xFF77847A);
  static const Color inkOutlineVariant = Color(0xFFD4DED5);

  // Semantic values
  static const Color expense = Color(0xFFC66C61);
  static const Color error = expense;
  static const Color errorContainer = Color(0xFFF7E5E2);
  static const Color income = Color(0xFF27835B);
  static const Color warning = Color(0xFFAA8244);
  static const Color info = Color(0xFF668A78);

  // Backward-compatible aliases
  static const Color softBackground = canvasLight;
  static const Color surfaceLight = surfaceLowest;
  static const Color surfaceElevatedLight = surfaceLow;
  static const Color borderLight = surfaceHigh;
  static const Color textPrimaryLight = inkSlate;
  static const Color textSecondaryLight = inkOutline;
  static const Color backgroundDark = canvasDark;
  static const Color textPrimaryDark = Color(0xFFF0F4EF);
  static const Color textSecondaryDark = Color(0xFFA4B2A7);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? canvasDark : canvasLight;
  static Color surface(BuildContext context) =>
      isDark(context) ? surfaceDark : surfaceLowest;
  static Color surfaceElevated(BuildContext context) =>
      isDark(context) ? surfaceElevatedDark : surfaceLow;
  static Color surfaceRecessed(BuildContext context) =>
      isDark(context) ? const Color(0xFF111A14) : const Color(0xFFE9EEE8);
  static Color surfaceContainerLow(BuildContext context) =>
      isDark(context) ? const Color(0xFF19251D) : surfaceLow;
  static Color surfaceContainer(BuildContext context) =>
      isDark(context) ? const Color(0xFF202D24) : surfaceContainerColor;
  static Color surfaceContainerHigh(BuildContext context) =>
      isDark(context) ? const Color(0xFF29382D) : surfaceHigh;
  static Color surfaceContainerHighest(BuildContext context) =>
      isDark(context) ? const Color(0xFF304136) : surfaceHighest;
  static Color border(BuildContext context) =>
      isDark(context) ? borderDark : surfaceHigh;
  static Color textPrimary(BuildContext context) =>
      isDark(context) ? textPrimaryDark : inkSlate;
  static Color textSecondary(BuildContext context) =>
      isDark(context) ? textSecondaryDark : inkOutline;
  static Color primaryAccent(BuildContext context) => isDark(context)
      ? const Color(0xFF62B98A)
      : emerald;
  static Color secondaryAccent(BuildContext context) => champagne;
  static Color tertiaryAccent(BuildContext context) => olive;

  /// Soft ambient lift. Keep this shadow low contrast; depth should come
  /// from the paired highlight and recessed edge, not a dark floating halo.
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
            ? Colors.black.withAlpha(75)
            : const Color(0xFF314337).withAlpha(18),
        offset: offset,
        blurRadius: blur,
        spreadRadius: spread,
      ),
      BoxShadow(
        color: dark
            ? const Color(0xFF91B99B).withAlpha(10)
            : Colors.white.withAlpha(210),
        offset: const Offset(-1, -1),
        blurRadius: 5,
        spreadRadius: -2,
      ),
    ];
  }

  static List<BoxShadow> clayInnerSheen({
    Color highlightColor = Colors.white,
    double opacity = 0.72,
  }) => [
    BoxShadow(
      color: highlightColor.withAlpha((opacity * 255).round()),
      offset: const Offset(-2, -2),
      blurRadius: 5,
      blurStyle: BlurStyle.inner,
    ),
    const BoxShadow(
      color: Color(0x1A26382B),
      offset: Offset(2, 2),
      blurRadius: 5,
      blurStyle: BlurStyle.inner,
    ),
  ];
}
