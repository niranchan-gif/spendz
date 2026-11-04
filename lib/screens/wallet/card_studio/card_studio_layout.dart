import 'package:flutter/material.dart';

/// Layout template definitions for Spendz Card Studio 2.0.
class CardStudioLayout {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const CardStudioLayout({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  static const List<CardStudioLayout> allLayouts = [
    CardStudioLayout(
      id: 'minimal_luxury',
      name: 'Minimal Luxury',
      description: 'Clean balanced layout: Bank top, chip, spaced number, holder & expiry bottom',
      icon: Icons.dashboard_outlined,
    ),
    CardStudioLayout(
      id: 'bold_gradient',
      name: 'Bold Gradient',
      description: 'Dynamic composition: Prominent network badge top-right, bold typography, underline accents',
      icon: Icons.auto_awesome_motion_outlined,
    ),
    CardStudioLayout(
      id: 'metallic_premium',
      name: 'Metallic Premium',
      description: 'Ultra-refined micro-typography, centered chip, single baseline footer alignment',
      icon: Icons.view_compact_outlined,
    ),
    CardStudioLayout(
      id: 'modern_geometric',
      name: 'Modern Geometric',
      description: 'Layered vertical layout, prominent issuer crest, crisp numbers with strong contrast',
      icon: Icons.widgets_outlined,
    ),
    CardStudioLayout(
      id: 'dark_minimal',
      name: 'Dark Minimal',
      description: 'Subtle stealth aesthetic, glowing perimeter accents, razor-sharp sans-serif typography',
      icon: Icons.crop_square_rounded,
    ),
  ];

  static CardStudioLayout getLayout(String? id) {
    if (id == null) return allLayouts.first;
    final normalized = id.toLowerCase().trim();
    for (final l in allLayouts) {
      if (l.id == normalized) return l;
    }
    return allLayouts.first;
  }
}
