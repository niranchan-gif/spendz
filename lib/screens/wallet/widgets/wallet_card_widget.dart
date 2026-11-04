import 'package:flutter/material.dart';
import '../../../models/wallet_card_model.dart';
import '../../../features/wallet/security/secure_number_service.dart';
import '../../../widgets/design_system/secure_protected_field.dart';

/// Production-quality Fintech Card Widget with responsive sizing,
/// biometric-guarded number reveal, and authentic financial card aesthetics.
class WalletCardWidget extends StatelessWidget {
  final WalletCardModel card;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isCompact;
  final bool allowReveal;

  const WalletCardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.onFavoriteToggle,
    this.isCompact = false,
    this.allowReveal = false,
  });

  LinearGradient _getCardGradient(String theme) {
    switch (theme.toLowerCase()) {
      case 'emerald':
        return const LinearGradient(
          colors: [Color(0xFF1E3F20), Color(0xFF28562B), Color(0xFF3B7A3F)],
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
          colors: [Color(0xFF223820), Color(0xFF2E4E2B), Color(0xFF406C3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Widget _buildNetworkBadge(String network) {
    final net = network.toLowerCase().trim();
    if (net == 'visa') {
      return const Text(
        'VISA',
        style: TextStyle(
          color: Colors.white,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: 1.2,
        ),
      );
    } else if (net == 'mastercard') {
      return SizedBox(
        width: 32,
        height: 20,
        child: Stack(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFEB001B),
                shape: BoxShape.circle,
              ),
            ),
            Positioned(
              right: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFF79E1B).withAlpha(220),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (net == 'rupay') {
      return const Text(
        'RuPay ▶',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      );
    } else if (net == 'amex') {
      return const Text(
        'AMEX',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      );
    }

    return Text(
      network.toUpperCase(),
      style: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final standardMasked = card.lastFour.isNotEmpty
        ? '•••• •••• •••• ${card.lastFour}'
        : card.maskedNumber;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapt card width to container while respecting credit card aspect ratio ~1.58
        final maxW = isCompact ? 290.0 : 340.0;
        final cardWidth = constraints.maxWidth < maxW ? constraints.maxWidth : maxW;
        final cardHeight = cardWidth / 1.62;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: cardWidth,
            height: cardHeight,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: _getCardGradient(card.themeGradient),
              border: Border.all(color: Colors.white.withAlpha(35), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(65),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Metallic ambient specular shine
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

                  Padding(
                    padding: EdgeInsets.all(isCompact ? 14.0 : 18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Row: Issuer & Type & Favorite
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white.withAlpha(40)),
                                  ),
                                  child: Text(
                                    card.issuerName.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  card.cardType.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(180),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (card.nickname.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Text(
                                      card.nickname,
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(170),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if (onFavoriteToggle != null)
                                  GestureDetector(
                                    onTap: onFavoriteToggle,
                                    child: Icon(
                                      card.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: card.isFavorite ? Colors.amber : Colors.white60,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        // Middle Section: Chip + Contactless OR Biometric Reveal Field
                        if (allowReveal)
                          SecureProtectedField(
                            maskedValue: standardMasked,
                            label: 'Card Number',
                            onRetrieveProtectedValue: () async {
                              final service = SecureNumberService();
                              final full = await service.getCardFullNumber(card.id);
                              if (full != null && full.isNotEmpty) {
                                return SecureNumberService.formatCardNumber(full);
                              }
                              return standardMasked;
                            },
                          )
                        else
                          Row(
                            children: [
                              // Metallic Smart Chip
                              Container(
                                width: 34,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withAlpha(190),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: const Color(0xFFFFE082), width: 0.8),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 22,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black26),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.contactless,
                                color: Colors.white.withAlpha(190),
                                size: 22,
                              ),
                              const Spacer(),
                              Text(
                                standardMasked,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  card.cardholderName.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'EXPIRES',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(140),
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '${card.expiryMonth.toString().padLeft(2, '0')}/${(card.expiryYear % 100).toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                _buildNetworkBadge(card.cardNetwork),
                              ],
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
      },
    );
  }
}
