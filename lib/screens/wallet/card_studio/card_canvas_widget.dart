import 'package:flutter/material.dart';
import '../../../models/wallet_card_model.dart';
import '../../../widgets/design_system/secure_protected_field.dart';
import '../../../features/wallet/security/secure_number_service.dart';
import 'card_studio_theme.dart';
import 'card_studio_layout.dart';

/// Luxury Financial Card Canvas Renderer for Spendz Card Studio 2.0.
/// Renders authentic physical card aesthetics combining custom theme geometry
/// and independent layout templates.
class CardCanvasWidget extends StatelessWidget {
  final WalletCardModel card;
  final CardStudioTheme? themeOverride;
  final CardStudioLayout? layoutOverride;
  final bool isCompact;
  final bool allowReveal;
  final String? revealedNumber;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const CardCanvasWidget({
    super.key,
    required this.card,
    this.themeOverride,
    this.layoutOverride,
    this.isCompact = false,
    this.allowReveal = false,
    this.revealedNumber,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = themeOverride ?? CardStudioTheme.getTheme(card.themeGradient);
    final layout =
        layoutOverride ?? CardStudioLayout.getLayout(card.cardLayoutId);

    final displayMasked =
        revealedNumber ??
        (card.lastFour.isNotEmpty
            ? '•••• •••• •••• ${card.lastFour}'
            : card.maskedNumber);

    return Center(
      child: AspectRatio(
        // Authentic physical card standard ID-1 aspect ratio: 85.60 mm / 53.98 mm = 1.586
        aspectRatio: 1.586,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: theme.backgroundGradient,
              border: Border.all(color: theme.foilBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(70),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
                BoxShadow(
                  color: theme.primaryAccent.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // 1. Custom Geometry / Texture from Theme
                  if (theme.backgroundPainter != null)
                    Positioned.fill(
                      child: CustomPaint(painter: theme.backgroundPainter!()),
                    ),

                  // 2. Metallic Specular Ambient Highlight
                  Positioned(
                    top: -60,
                    right: -60,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withAlpha(30),
                            Colors.white.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Layout Content
                  Padding(
                    padding: EdgeInsets.all(isCompact ? 12.0 : 18.0),
                    child: _buildLayoutContent(
                      context,
                      theme,
                      layout,
                      displayMasked,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutContent(
    BuildContext context,
    CardStudioTheme theme,
    CardStudioLayout layout,
    String displayMasked,
  ) {
    switch (layout.id) {
      case 'bold_gradient':
        return _buildBoldGradientLayout(theme, displayMasked);
      case 'metallic_premium':
        return _buildMetallicPremiumLayout(theme, displayMasked);
      case 'modern_geometric':
        return _buildModernGeometricLayout(theme, displayMasked);
      case 'dark_minimal':
        return _buildDarkMinimalLayout(theme, displayMasked);
      case 'minimal_luxury':
      default:
        return _buildMinimalLuxuryLayout(theme, displayMasked);
    }
  }

  // ==========================================
  // TEMPLATE 1: MINIMAL LUXURY
  // ==========================================
  Widget _buildMinimalLuxuryLayout(
    CardStudioTheme theme,
    String displayMasked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.foilBorder),
                  ),
                  child: Text(
                    card.issuerName.toUpperCase(),
                    style: TextStyle(
                      color: theme.textColor,
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
                    color: theme.labelColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.contactless,
                  color: theme.textColor.withAlpha(190),
                  size: 18,
                ),
                if (onFavoriteToggle != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Icon(
                      card.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: card.isFavorite
                          ? Colors.amber
                          : theme.textColor.withAlpha(140),
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),

        // Middle Section: Chip + Card Number
        Row(
          children: [
            _buildSmartChip(theme),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNumberDisplay(theme, displayMasked, fontSize: 15),
            ),
          ],
        ),

        // Bottom Row: Holder, Expiry & Network
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARD HOLDER',
                    style: TextStyle(
                      color: theme.labelColor.withAlpha(160),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    card.cardholderName.toUpperCase(),
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXPIRES',
                      style: TextStyle(
                        color: theme.labelColor.withAlpha(160),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${card.expiryMonth.toString().padLeft(2, '0')}/${(card.expiryYear % 100).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                _buildNetworkBadge(card.cardNetwork, theme),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // TEMPLATE 2: BOLD GRADIENT
  // ==========================================
  Widget _buildBoldGradientLayout(CardStudioTheme theme, String displayMasked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top Row: Bold Issuer & Network Brand Top Right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.issuerName.toUpperCase(),
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  card.cardType.toUpperCase(),
                  style: TextStyle(
                    color: theme.primaryAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            _buildNetworkBadge(card.cardNetwork, theme, scale: 1.2),
          ],
        ),

        // Middle Section: Large Number with accent line
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSmartChip(theme, compact: true),
                const SizedBox(width: 8),
                Icon(
                  Icons.contactless,
                  color: theme.primaryAccent.withAlpha(200),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildNumberDisplay(
              theme,
              displayMasked,
              fontSize: 16.5,
              bold: true,
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 50,
              decoration: BoxDecoration(
                color: theme.primaryAccent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),

        // Bottom Row: Cardholder & Expiry
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                card.cardholderName.toUpperCase(),
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${card.expiryMonth.toString().padLeft(2, '0')}/${(card.expiryYear % 100).toString().padLeft(2, '0')}',
              style: TextStyle(
                color: theme.labelColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // TEMPLATE 3: METALLIC PREMIUM
  // ==========================================
  Widget _buildMetallicPremiumLayout(
    CardStudioTheme theme,
    String displayMasked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top: Ultra-refined minimal micro-typography
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              card.issuerName.toUpperCase(),
              style: TextStyle(
                color: theme.textColor.withAlpha(220),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.5,
              ),
            ),
            Icon(
              Icons.contactless,
              color: theme.textColor.withAlpha(160),
              size: 16,
            ),
          ],
        ),

        // Center: Elegant Chip & Card Number
        Center(
          child: Column(
            children: [
              _buildSmartChip(theme),
              const SizedBox(height: 10),
              _buildNumberDisplay(
                theme,
                displayMasked,
                fontSize: 15.5,
                letterSpacing: 2.2,
              ),
            ],
          ),
        ),

        // Bottom: Single baseline footer alignment
        Container(
          padding: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white.withAlpha(20))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  card.cardholderName.toUpperCase(),
                  style: TextStyle(
                    color: theme.textColor.withAlpha(200),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'VALID THRU ${(card.expiryMonth).toString().padLeft(2, '0')}/${card.expiryYear % 100}',
                style: TextStyle(
                  color: theme.labelColor.withAlpha(180),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 12),
              _buildNetworkBadge(card.cardNetwork, theme),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TEMPLATE 4: MODERN GEOMETRIC
  // ==========================================
  Widget _buildModernGeometricLayout(
    CardStudioTheme theme,
    String displayMasked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top: Geometric Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryAccent.withAlpha(35),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: theme.primaryAccent.withAlpha(80)),
              ),
              child: Text(
                '${card.issuerName.toUpperCase()} · ${card.cardType.toUpperCase()}',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            _buildNetworkBadge(card.cardNetwork, theme),
          ],
        ),

        // Middle: Left-rail chip and large monospace number
        Row(
          children: [
            _buildSmartChip(theme),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNumberDisplay(
                theme,
                displayMasked,
                fontSize: 15,
                bold: true,
              ),
            ),
          ],
        ),

        // Bottom: Cardholder & Expiry with geometric accent bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(40),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withAlpha(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.cardholderName.toUpperCase(),
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'EXP ${card.expiryMonth.toString().padLeft(2, '0')}/${card.expiryYear % 100}',
                style: TextStyle(
                  color: theme.primaryAccent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TEMPLATE 5: DARK MINIMAL
  // ==========================================
  Widget _buildDarkMinimalLayout(CardStudioTheme theme, String displayMasked) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.primaryAccent.withAlpha(40),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top: Ultra-clean header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.issuerName.toUpperCase(),
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              Icon(
                Icons.fingerprint,
                color: theme.primaryAccent.withAlpha(180),
                size: 18,
              ),
            ],
          ),

          // Center: Minimalist Card Number
          _buildNumberDisplay(
            theme,
            displayMasked,
            fontSize: 14.5,
            letterSpacing: 2.0,
          ),

          // Bottom: Monochromatic baseline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.cardholderName.toUpperCase(),
                    style: TextStyle(
                      color: theme.textColor.withAlpha(220),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${card.expiryMonth.toString().padLeft(2, '0')}/${card.expiryYear % 100}',
                    style: TextStyle(
                      color: theme.labelColor.withAlpha(180),
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
              _buildNetworkBadge(card.cardNetwork, theme),
            ],
          ),
        ],
      ),
    );
  }

  // --- Reusable Component Helpers ---

  Widget _buildNumberDisplay(
    CardStudioTheme theme,
    String masked, {
    double fontSize = 15,
    bool bold = false,
    double letterSpacing = 1.8,
  }) {
    if (allowReveal) {
      return SecureProtectedField(
        maskedValue: masked,
        label: 'Card Number',
        onRetrieveProtectedValue: () async {
          final service = SecureNumberService();
          final full = await service.getCardFullNumber(card.id);
          if (full != null && full.isNotEmpty) {
            return SecureNumberService.formatCardNumber(full);
          }
          return masked;
        },
      );
    }

    return Text(
      masked,
      style: TextStyle(
        fontFamily: 'monospace',
        color: theme.textColor,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
        letterSpacing: letterSpacing,
        shadows: const [
          Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
    );
  }

  Widget _buildSmartChip(CardStudioTheme theme, {bool compact = false}) {
    final width = compact ? 28.0 : 34.0;
    final height = compact ? 22.0 : 26.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.chipColor.withAlpha(210),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: theme.chipBorder, width: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: width * 0.65,
          height: height * 0.62,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkBadge(
    String network,
    CardStudioTheme theme, {
    double scale = 1.0,
  }) {
    final net = network.toLowerCase().trim();

    if (net == 'visa') {
      return Text(
        'VISA',
        style: TextStyle(
          color: theme.textColor,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w900,
          fontSize: 16 * scale,
          letterSpacing: 1.2,
        ),
      );
    } else if (net == 'mastercard') {
      return SizedBox(
        width: 32 * scale,
        height: 20 * scale,
        child: Stack(
          children: [
            Container(
              width: 18 * scale,
              height: 18 * scale,
              decoration: const BoxDecoration(
                color: Color(0xFFEB001B),
                shape: BoxShape.circle,
              ),
            ),
            Positioned(
              right: 0,
              child: Container(
                width: 18 * scale,
                height: 18 * scale,
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
      return Text(
        'RuPay ▶',
        style: TextStyle(
          color: theme.textColor,
          fontWeight: FontWeight.w800,
          fontSize: 13 * scale,
          letterSpacing: 0.5,
        ),
      );
    } else if (net == 'amex') {
      return Text(
        'AMEX',
        style: TextStyle(
          color: theme.textColor,
          fontWeight: FontWeight.w900,
          fontSize: 12 * scale,
          letterSpacing: 1.0,
        ),
      );
    }

    return Text(
      network.toUpperCase(),
      style: TextStyle(
        color: theme.labelColor,
        fontWeight: FontWeight.w700,
        fontSize: 11 * scale,
      ),
    );
  }
}
