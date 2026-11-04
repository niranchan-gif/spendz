import 'package:flutter/material.dart';
import '../../../models/wallet_card_model.dart';
import '../card_studio/card_canvas_widget.dart';
import '../card_studio/card_studio_theme.dart';
import '../card_studio/card_studio_layout.dart';

/// Production-quality Fintech Card Widget with responsive sizing,
/// biometric-guarded number reveal, and authentic financial card aesthetics.
class WalletCardWidget extends StatelessWidget {
  final WalletCardModel card;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isCompact;
  final bool allowReveal;
  final String? revealedNumber;
  final CardStudioTheme? themeOverride;
  final CardStudioLayout? layoutOverride;

  const WalletCardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.onFavoriteToggle,
    this.isCompact = false,
    this.allowReveal = false,
    this.revealedNumber,
    this.themeOverride,
    this.layoutOverride,
  });

  @override
  Widget build(BuildContext context) {
    return CardCanvasWidget(
      card: card,
      themeOverride: themeOverride,
      layoutOverride: layoutOverride,
      isCompact: isCompact,
      allowReveal: allowReveal,
      revealedNumber: revealedNumber,
      onTap: onTap,
      onFavoriteToggle: onFavoriteToggle,
    );
  }
}
