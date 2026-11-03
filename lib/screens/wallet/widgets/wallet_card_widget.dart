import 'package:flutter/material.dart';
import '../../../models/wallet_card_model.dart';

class WalletCardWidget extends StatelessWidget {
  final WalletCardModel card;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isCompact;

  const WalletCardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.onFavoriteToggle,
    this.isCompact = false,
  });

  LinearGradient _getCardGradient(String theme) {
    switch (theme.toLowerCase()) {
      case 'emerald':
        return const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'midnight':
        return const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'obsidian':
        return const LinearGradient(
          colors: [Color(0xFF18181B), Color(0xFF27272A), Color(0xFF3F3F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'amethyst':
        return const LinearGradient(
          colors: [Color(0xFF3B0764), Color(0xFF581C87), Color(0xFF7E22CE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'crimson':
        return const LinearGradient(
          colors: [Color(0xFF450A0A), Color(0xFF7F1D1D), Color(0xFF991B1B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'amber':
        return const LinearGradient(
          colors: [Color(0xFF78350F), Color(0xFF92400E), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF1A2E1A), Color(0xFF2E4B2E), Color(0xFF446C44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = isCompact ? 280.0 : 320.0;
    final height = isCompact ? 170.0 : 195.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: _getCardGradient(card.themeGradient),
          border: Border.all(color: Colors.white.withAlpha(45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(70),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Ambient overlay texture/watermark
              Positioned(
                right: -40,
                bottom: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(12),
                  ),
                ),
              ),
              Positioned(
                right: 30,
                top: -50,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(8),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Issuer & Chip & Favorite
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withAlpha(40)),
                              ),
                              child: Text(
                                card.issuerName.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              card.cardType.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withAlpha(170),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        if (onFavoriteToggle != null)
                          GestureDetector(
                            onTap: onFavoriteToggle,
                            child: Icon(
                              card.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: card.isFavorite ? Colors.amber : Colors.white.withAlpha(150),
                              size: 22,
                            ),
                          ),
                      ],
                    ),

                    // Chip and Contactless
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withAlpha(180),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFE082), width: 0.8),
                          ),
                          child: Center(
                            child: Container(
                              width: 26,
                              height: 18,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black26),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.contactless,
                          color: Colors.white.withAlpha(180),
                          size: 24,
                        ),
                        const Spacer(),
                        Text(
                          card.nickname,
                          style: TextStyle(
                            color: Colors.white.withAlpha(190),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Card Number (Masked)
                    Text(
                      card.maskedNumber,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Row: Cardholder Name, Expiry & Network
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CARD HOLDER',
                              style: TextStyle(
                                color: Colors.white.withAlpha(140),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              card.cardholderName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXPIRES',
                              style: TextStyle(
                                color: Colors.white.withAlpha(140),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${card.expiryMonth.toString().padLeft(2, '0')}/${card.expiryYear.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            card.cardNetwork.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
