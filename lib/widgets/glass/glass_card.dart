import 'package:flutter/material.dart';
import '../../app/theme/app_radius.dart';
import 'glass_surface.dart';

/// Translucent Glass Card built on the core GlassSurface primitive.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final bool disableBlur;
  final Color? color;
  final BoxBorder? border;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final bool showHighlight;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.lg,
    this.blur = 16.0,
    this.disableBlur = false,
    this.color,
    this.border,
    this.onTap,
    this.width,
    this.height,
    this.showHighlight = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      blur: blur,
      disableBlur: disableBlur,
      color: color,
      border: border,
      onTap: onTap,
      width: width,
      height: height,
      showHighlight: showHighlight,
      child: child,
    );
  }
}
