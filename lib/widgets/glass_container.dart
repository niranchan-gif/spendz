import 'package:flutter/material.dart';

/// Matte Clay container replacing legacy translucent glass containers.
/// Provides defined opaque surfaces, tactile borders, and matte drop shadows.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Border? border;
  final BoxConstraints? constraints;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 24.0,
    this.blur = 0.0,
    this.color,
    this.border,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      constraints: constraints,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFCBDFBD), // Pale Pistachio Clay
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: const Color(0xFFB5CCA7), // Defined tactile border
              width: 1.2,
            ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x222C221E), // Soft matte warm shadow
            blurRadius: 6,
            offset: Offset(2, 3),
          ),
          BoxShadow(
            color: Colors.white, // Matte highlight
            blurRadius: 2,
            offset: Offset(-1, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
