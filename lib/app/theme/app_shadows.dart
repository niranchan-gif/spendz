import 'package:flutter/material.dart';

/// Central shadow and elevation tokens for Spendz 2.0.
class AppShadows {
  /// Subtle card elevation (Light mode)
  static final List<BoxShadow> lightCard = [
    BoxShadow(
      color: Colors.black.withAlpha(10),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  /// Elevated card / feature banner (Light mode)
  static final List<BoxShadow> lightElevated = [
    BoxShadow(
      color: Colors.black.withAlpha(16),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  /// Floating Action Button / Quick wallet trigger
  static final List<BoxShadow> floating = [
    BoxShadow(
      color: Colors.black.withAlpha(45),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  /// Subtle glow for Dark mode cards
  static final List<BoxShadow> darkCard = [
    BoxShadow(
      color: Colors.black.withAlpha(70),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  /// Deep ambient shadow for modal bottom sheets
  static final List<BoxShadow> sheet = [
    BoxShadow(
      color: Colors.black.withAlpha(90),
      blurRadius: 28,
      offset: const Offset(0, -6),
    ),
  ];

  static List<BoxShadow> card(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : lightCard;
  }
}
