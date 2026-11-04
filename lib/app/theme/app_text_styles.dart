import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Central typography scale for Spendz 2.0 Fintech UI.
class AppTextStyles {
  // ─── LARGE BALANCES & AMOUNTS ───────────────────────────────────────────────
  static TextStyle displayLarge = GoogleFonts.outfit(
    fontSize: 38,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
  );

  static TextStyle displayMedium = GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
  );

  // ─── HEADINGS ───────────────────────────────────────────────────────────────
  static TextStyle heading1 = GoogleFonts.outfit(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle heading2 = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle heading3 = GoogleFonts.outfit(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle headingLarge = heading1;
  static TextStyle headingMedium = heading2;
  static TextStyle headingSmall = heading3;
  static TextStyle caption = bodySmall;

  // ─── BODY TEXT ──────────────────────────────────────────────────────────────
  static TextStyle bodyLarge = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ─── LABELS & BUTTONS ───────────────────────────────────────────────────────
  static TextStyle labelLarge = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle labelMedium = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  static TextStyle labelSmall = GoogleFonts.outfit(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  // ─── FINANCIAL & CARD NUMBERS (Tabular / Monospace) ─────────────────────────
  static TextStyle cardNumber = GoogleFonts.robotoMono(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.2,
    color: Colors.white,
  );

  static TextStyle currencyValue = GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  // ─── CONTEXT-AWARE HELPERS ──────────────────────────────────────────────────
  static TextStyle getHeading1(BuildContext context) {
    return heading1.copyWith(color: AppColors.getTextPrimary(context));
  }

  static TextStyle getHeading2(BuildContext context) {
    return heading2.copyWith(color: AppColors.getTextPrimary(context));
  }

  static TextStyle getHeading3(BuildContext context) {
    return heading3.copyWith(color: AppColors.getTextPrimary(context));
  }

  static TextStyle getHeadingLarge(BuildContext context) => getHeading1(context);
  static TextStyle getHeadingMedium(BuildContext context) => getHeading2(context);
  static TextStyle getHeadingSmall(BuildContext context) => getHeading3(context);
  static TextStyle getCaption(BuildContext context) => getBodySmall(context);

  static TextStyle getBodyLarge(BuildContext context) {
    return bodyLarge.copyWith(color: AppColors.getTextPrimary(context));
  }

  static TextStyle getBodyMedium(BuildContext context) {
    return bodyMedium.copyWith(color: AppColors.getTextPrimary(context));
  }

  static TextStyle getBodySmall(BuildContext context) {
    return bodySmall.copyWith(color: AppColors.getTextSecondary(context));
  }

  static TextStyle getLabelLarge(BuildContext context) {
    return labelLarge.copyWith(color: AppColors.getTextPrimary(context));
  }
}
