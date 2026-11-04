import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Distinctive visual theme for financial cards in Spendz Card Studio 2.0.
class CardStudioTheme {
  final String id;
  final String name;
  final String description;
  final LinearGradient backgroundGradient;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color chipColor;
  final Color chipBorder;
  final Color textColor;
  final Color labelColor;
  final Color foilBorder;
  final CustomPainter Function()? backgroundPainter;

  const CardStudioTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundGradient,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.chipColor,
    required this.chipBorder,
    required this.textColor,
    required this.labelColor,
    required this.foilBorder,
    this.backgroundPainter,
  });

  static const List<CardStudioTheme> allThemes = [
    // A. Midnight Emerald
    CardStudioTheme(
      id: 'midnight_emerald',
      name: 'Midnight Emerald',
      description:
          'Deep forest green, emerald gradient & metallic gold detailing',
      backgroundGradient: LinearGradient(
        colors: [Color(0xFF071F14), Color(0xFF0F3E28), Color(0xFF165B3A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      primaryAccent: Color(0xFF10B981),
      secondaryAccent: Color(0xFFD4AF37),
      chipColor: Color(0xFFD4AF37),
      chipBorder: Color(0xFFFFDF79),
      textColor: Color(0xFFFFFFFF),
      labelColor: Color(0xFF86EFAC),
      foilBorder: Color(0x60D4AF37),
      backgroundPainter: _createEmeraldPainter,
    ),

    // B. Obsidian Black
    CardStudioTheme(
      id: 'obsidian_black',
      name: 'Obsidian Black',
      description:
          'Near-black surface, graphite gradients & polished silver accents',
      backgroundGradient: LinearGradient(
        colors: [Color(0xFF090A0F), Color(0xFF13141C), Color(0xFF222430)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
      primaryAccent: Color(0xFFE2E8F0),
      secondaryAccent: Color(0xFF94A3B8),
      chipColor: Color(0xFFCBD5E1),
      chipBorder: Color(0xFFFFFFFF),
      textColor: Color(0xFFF8FAFC),
      labelColor: Color(0xFF94A3B8),
      foilBorder: Color(0x50CBD5E1),
      backgroundPainter: _createObsidianPainter,
    ),

    // C. Royal Amethyst
    CardStudioTheme(
      id: 'royal_amethyst',
      name: 'Royal Amethyst',
      description:
          'Deep purple, rich violet gradients & subtle lavender highlights',
      backgroundGradient: LinearGradient(
        colors: [Color(0xFF1C0A35), Color(0xFF381467), Color(0xFF5A1E9E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      primaryAccent: Color(0xFFC084FC),
      secondaryAccent: Color(0xFFE9D5FF),
      chipColor: Color(0xFFE0C477),
      chipBorder: Color(0xFFFFECC4),
      textColor: Color(0xFFFFFFFF),
      labelColor: Color(0xFFD8B4FE),
      foilBorder: Color(0x50C084FC),
      backgroundPainter: _createAmethystPainter,
    ),

    // D. Ocean Sapphire
    CardStudioTheme(
      id: 'ocean_sapphire',
      name: 'Ocean Sapphire',
      description: 'Midnight blue, sapphire gradient & cool silver ice accents',
      backgroundGradient: LinearGradient(
        colors: [Color(0xFF06142E), Color(0xFF0F2B5C), Color(0xFF1D4ED8)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ),
      primaryAccent: Color(0xFF38BDF8),
      secondaryAccent: Color(0xFF93C5FD),
      chipColor: Color(0xFFE2E8F0),
      chipBorder: Color(0xFFF8FAFC),
      textColor: Color(0xFFFFFFFF),
      labelColor: Color(0xFF7DD3FC),
      foilBorder: Color(0x5038BDF8),
      backgroundPainter: _createSapphirePainter,
    ),

    // E. Champagne Gold
    CardStudioTheme(
      id: 'champagne_gold',
      name: 'Champagne Gold',
      description:
          'Warm charcoal, champagne highlights & elegant metallic finish',
      backgroundGradient: LinearGradient(
        colors: [Color(0xFF1A1817), Color(0xFF292524), Color(0xFF44403C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      primaryAccent: Color(0xFFF59E0B),
      secondaryAccent: Color(0xFFFDE68A),
      chipColor: Color(0xFFF59E0B),
      chipBorder: Color(0xFFFEF3C7),
      textColor: Color(0xFFFFFBEB),
      labelColor: Color(0xFFFCD34D),
      foilBorder: Color(0x60F59E0B),
      backgroundPainter: _createGoldPainter,
    ),

    // F. Crimson Luxe
    CardStudioTheme(
      id: 'crimson_luxe',
      name: 'Crimson Luxe',
      description:
          'Deep burgundy, muted crimson gradients & dark luxury detailing',
      backgroundGradient: LinearGradient(
        colors: [Color(0xFF26060D), Color(0xFF4F0C1B), Color(0xFF881337)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      primaryAccent: Color(0xFFFB7185),
      secondaryAccent: Color(0xFFFECDD3),
      chipColor: Color(0xFFD4AF37),
      chipBorder: Color(0xFFFFE082),
      textColor: Color(0xFFFFFFFF),
      labelColor: Color(0xFFFDA4AF),
      foilBorder: Color(0x50FB7185),
      backgroundPainter: _createCrimsonPainter,
    ),

    // G. Arctic Silver
    CardStudioTheme(
      id: 'arctic_silver',
      name: 'Arctic Silver',
      description: 'Cool silver, slate gradients & clean futuristic precision',
      backgroundGradient: LinearGradient(
        colors: [Color(0xFF111827), Color(0xFF1F2937), Color(0xFF374151)],
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
      ),
      primaryAccent: Color(0xFF38BDF8),
      secondaryAccent: Color(0xFFE2E8F0),
      chipColor: Color(0xFFE2E8F0),
      chipBorder: Color(0xFFFFFFFF),
      textColor: Color(0xFFF3F4F6),
      labelColor: Color(0xFF9CA3AF),
      foilBorder: Color(0x50E2E8F0),
      backgroundPainter: _createArcticPainter,
    ),

    // H. Aurora Mint
    CardStudioTheme(
      id: 'aurora_mint',
      name: 'Aurora Mint',
      description:
          'Deep emerald petrol, vibrant mint accents & atmospheric aurora aura',
      backgroundGradient: LinearGradient(
        colors: [Color(0xFF04201E), Color(0xFF0B3B38), Color(0xFF134E4A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      primaryAccent: Color(0xFF2DD4BF),
      secondaryAccent: Color(0xFF5EEAD4),
      chipColor: Color(0xFF5EEAD4),
      chipBorder: Color(0xFFCCFBF1),
      textColor: Color(0xFFF0FDFA),
      labelColor: Color(0xFF2DD4BF),
      foilBorder: Color(0x602DD4BF),
      backgroundPainter: _createAuroraPainter,
    ),
  ];

  static CardStudioTheme getTheme(String? id) {
    if (id == null) return allThemes.first;
    final normalized = id.toLowerCase().trim();

    // Direct match
    for (final t in allThemes) {
      if (t.id == normalized) return t;
    }

    // Legacy / alias match
    switch (normalized) {
      case 'emerald':
        return allThemes[0];
      case 'obsidian':
        return allThemes[1];
      case 'amethyst':
        return allThemes[2];
      case 'midnight':
      case 'sapphire':
        return allThemes[3];
      case 'amber':
      case 'gold':
        return allThemes[4];
      case 'crimson':
        return allThemes[5];
      case 'silver':
      case 'arctic':
        return allThemes[6];
      case 'mint':
      case 'aurora':
        return allThemes[7];
      default:
        return allThemes.first;
    }
  }

  // --- Background Geometry Painters ---
  static CustomPainter _createEmeraldPainter() => _EmeraldGeometryPainter();
  static CustomPainter _createObsidianPainter() => _ObsidianGeometryPainter();
  static CustomPainter _createAmethystPainter() => _AmethystGeometryPainter();
  static CustomPainter _createSapphirePainter() => _SapphireGeometryPainter();
  static CustomPainter _createGoldPainter() => _GoldGeometryPainter();
  static CustomPainter _createCrimsonPainter() => _CrimsonGeometryPainter();
  static CustomPainter _createArcticPainter() => _ArcticGeometryPainter();
  static CustomPainter _createAuroraPainter() => _AuroraGeometryPainter();
}

/// A. Emerald Geometry: Gold metallic micro foil lines and radial ambient glow
class _EmeraldGeometryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..color = const Color(0xFFD4AF37).withAlpha(35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Angled metallic pinstripes
    final path = Path();
    for (double i = -size.height; i < size.width + size.height; i += 28) {
      path.moveTo(i, 0);
      path.lineTo(i + size.height * 0.8, size.height);
    }
    canvas.drawPath(path, goldPaint);

    // Glowing corner orb
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF10B981).withAlpha(60),
              const Color(0xFF10B981).withAlpha(0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.85, size.height * 0.2),
              radius: 90,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.2),
      90,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// B. Obsidian Geometry: Sleek brushed carbon lines with silver highlight
class _ObsidianGeometryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final silverPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withAlpha(22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (double y = 0; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 8), silverPaint);
    }

    // Dynamic diagonal facet
    final facetPaint = Paint()
      ..color = Colors.white.withAlpha(12)
      ..style = PaintingStyle.fill;
    final facetPath = Path()
      ..moveTo(size.width * 0.45, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.7)
      ..close();
    canvas.drawPath(facetPath, facetPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// C. Amethyst Geometry: Concentric violet/lavender radial resonance rings
class _AmethystGeometryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width * 0.9, size.height * 0.9);
    for (int r = 30; r < 240; r += 32) {
      ringPaint.color = const Color(0xFFC084FC).withAlpha(25 - (r ~/ 10));
      canvas.drawCircle(center, r.toDouble(), ringPaint);
    }

    // Top left lavender glow
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [const Color(0xFFA855F7).withAlpha(45), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.15, size.height * 0.2),
              radius: 80,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.2),
      80,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// D. Sapphire Geometry: Fluid nautical contour waves
class _SapphireGeometryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final waveFill = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF38BDF8).withAlpha(20), Colors.transparent],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.4)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.2,
        size.width * 0.65,
        size.height * 0.9,
        size.width,
        size.height * 0.6,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, waveFill);

    wavePaint.color = const Color(0xFF38BDF8).withAlpha(40);
    final linePath = Path()
      ..moveTo(0, size.height * 0.35)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.15,
        size.width * 0.65,
        size.height * 0.85,
        size.width,
        size.height * 0.55,
      );
    canvas.drawPath(linePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// E. Gold Geometry: Art Deco chevron rays
class _GoldGeometryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..color = const Color(0xFFF59E0B).withAlpha(35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width * 0.5, size.height * 1.2);
    for (
      double angle = -math.pi * 0.75;
      angle <= -math.pi * 0.25;
      angle += 0.08
    ) {
      final x = center.dx + math.cos(angle) * 320;
      final y = center.dy + math.sin(angle) * 320;
      canvas.drawLine(center, Offset(x, y), goldPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// F. Crimson Luxe: Heraldic diamond lattice
class _CrimsonGeometryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final diamondPaint = Paint()
      ..color = const Color(0xFFFB7185).withAlpha(25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 32.0;
    for (double x = 0; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height, size.height),
        diamondPaint,
      );
      canvas.drawLine(
        Offset(x - size.height, 0),
        Offset(x, size.height),
        diamondPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// G. Arctic Silver: Technical futuristic hexagonal grid
class _ArcticGeometryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final techPaint = Paint()
      ..color = const Color(0xFF38BDF8).withAlpha(25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw horizontal dashed technical guide marks
    for (double y = 20; y < size.height; y += 24) {
      canvas.drawLine(
        Offset(size.width * 0.6, y),
        Offset(size.width - 20, y),
        techPaint,
      );
    }

    final cornerAccent = Paint()
      ..color = const Color(0xFFE2E8F0).withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width - 40, 20),
      Offset(size.width - 20, 20),
      cornerAccent,
    );
    canvas.drawLine(
      Offset(size.width - 20, 20),
      Offset(size.width - 20, 40),
      cornerAccent,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// H. Aurora Mint: Ethereal radiant ribbon sweeps
class _AuroraGeometryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ribbonPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF2DD4BF).withAlpha(45),
          const Color(0xFF14B8A6).withAlpha(15),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.1)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.8,
        size.width,
        size.height * 0.3,
      )
      ..lineTo(size.width, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 1.1,
        0,
        size.height * 0.4,
      )
      ..close();
    canvas.drawPath(path, ribbonPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
