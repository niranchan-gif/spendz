import 'package:flutter/material.dart';

/// Central border radius tokens for Spendz 2.0.
class AppRadius {
  /// 6 px — Badges, micro tags
  static const double xs = 6.0;

  /// 8 px — Buttons, chips, icon containers
  static const double sm = 8.0;

  /// 12 px — Small controls, text fields, menu sheets
  static const double md = 12.0;

  /// 16 px — Standard cards, list items, action tiles
  static const double card = 16.0;

  /// 20 px — Elevated cards, dialogs, medium feature cards
  static const double lg = 20.0;

  /// 24 px — Large feature cards, overview hero containers
  static const double xl = 24.0;

  /// 28 px — Modal bottom sheets, floating navigation pill
  static const double sheet = 28.0;

  /// 36 px — App icon / floating surfaces
  static const double full = 36.0;

  // ─── BORDER RADIUS OBJECTS ──────────────────────────────────────────────────
  static final BorderRadius roundedSm = BorderRadius.circular(sm);
  static final BorderRadius roundedMd = BorderRadius.circular(md);
  static final BorderRadius roundedCard = BorderRadius.circular(card);
  static final BorderRadius roundedLg = BorderRadius.circular(lg);
  static final BorderRadius roundedXl = BorderRadius.circular(xl);
  static final BorderRadius roundedSheet = const BorderRadius.vertical(top: Radius.circular(sheet));
}

