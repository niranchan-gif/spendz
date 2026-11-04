import 'package:flutter/material.dart';

/// Central 4-point spacing grid tokens for Spendz 2.0.
class AppSpacing {
  /// 4 px — Micro spacing (tags, badge padding, tight icon margins)
  static const double xs = 4.0;

  /// 8 px — Compact spacing (chips, between icon and label, list tile elements)
  static const double sm = 8.0;

  /// 12 px — Internal component spacing (card interior items, compact cards)
  static const double md = 12.0;

  /// 16 px — Standard screen horizontal/vertical padding
  static const double lg = 16.0;

  /// 20 px — Card padding & comfortable container spacing
  static const double card = 20.0;

  /// 24 px — Section separation & header spacing
  static const double section = 24.0;

  /// 32 px — Major section separation
  static const double xl = 32.0;

  /// 48 px — Large banner or empty state top separation
  static const double xxl = 48.0;

  // ─── CONVENIENCE INSETS ──────────────────────────────────────────────────────
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets cardPadding = EdgeInsets.all(card);
  static const EdgeInsets compactCardPadding = EdgeInsets.all(md);
  static const EdgeInsets modalPadding = EdgeInsets.fromLTRB(card, lg, card, card);
  static const EdgeInsets horizontalScreen = EdgeInsets.symmetric(horizontal: lg);
}

