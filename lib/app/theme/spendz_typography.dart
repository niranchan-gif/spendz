import 'package:flutter/material.dart';
import 'spendz_colors.dart';

/// Clean, editorial typography scale for Spendz 2.0.
class SpendzTypography {
  static TextStyle displayHero(BuildContext context) {
    return TextStyle(
      fontSize: 38,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
      color: SpendzColors.textPrimary(context),
      height: 1.1,
    );
  }

  static TextStyle headingLarge(BuildContext context) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      color: SpendzColors.textPrimary(context),
      height: 1.2,
    );
  }

  static TextStyle headingMedium(BuildContext context) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: SpendzColors.textPrimary(context),
      height: 1.25,
    );
  }

  static TextStyle headingSmall(BuildContext context) {
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: SpendzColors.textPrimary(context),
    );
  }

  static TextStyle body(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: SpendzColors.textPrimary(context),
      height: 1.4,
    );
  }

  static TextStyle bodyMedium(BuildContext context) {
    return TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: SpendzColors.textSecondary(context),
      height: 1.35,
    );
  }

  static TextStyle caption(BuildContext context) {
    return TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      color: SpendzColors.textSecondary(context),
      letterSpacing: 0.1,
    );
  }

  static TextStyle labelTracked(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      color: color ?? SpendzColors.textSecondary(context),
    );
  }

  static TextStyle monoAmount({
    required BuildContext context,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.4,
      color: color ?? SpendzColors.textPrimary(context),
    );
  }
}
