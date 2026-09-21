import 'dart:ui';
import 'package:flutter/material.dart';

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
    this.blur = 30.0, // Increased blur for premium feel
    this.color,
    this.border,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      constraints: constraints,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              // Default to a subtle white frost if no color is provided
              color: color ?? Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(borderRadius),
              // Use a gradient border for a more premium glass edge
              border: border ?? Border.all(color: Colors.white.withAlpha(30), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
