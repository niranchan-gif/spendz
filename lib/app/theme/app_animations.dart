import 'package:flutter/material.dart';

/// Central animation duration and curve design tokens for Spendz 2.0.
class AppAnimations {
  /// 150ms — Micro-interactions, button presses, switch toggles
  static const Duration fast = Duration(milliseconds: 150);

  /// 250ms — Card expansions, tab switching, small view state changes
  static const Duration standard = Duration(milliseconds: 250);

  /// 400ms — Modal presentations, bottom sheet reveals, chart renders
  static const Duration smooth = Duration(milliseconds: 400);

  /// 600ms — Full screen cross-fades, hero transitions
  static const Duration pageTransition = Duration(milliseconds: 600);

  // ─── CURVES ─────────────────────────────────────────────────────────────────
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve snappy = Curves.easeOutQuad;
  static const Curve bounce = Curves.elasticOut;
  static const Curve standardCurve = Curves.easeInOutCubic;
}
