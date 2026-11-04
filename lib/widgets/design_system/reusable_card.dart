import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../glass/glass_surface.dart';

/// Standardized Fintech Card container built on the Spendz 2.0 GlassSurface.
///
/// Provides backward-compatible properties while rendering refined minimal
/// glassmorphism styling, subtle specular sheens, and soft elevation.
class ReusableCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final BoxBorder? border;
  final double? borderRadius;
  final List<BoxShadow>? shadows;
  final bool hasBorder;
  final Gradient? gradient;

  const ReusableCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.border,
    this.borderRadius,
    this.shadows,
    this.hasBorder = true,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.card;
    final cardBorder = hasBorder
        ? (border ??
              Border.all(color: AppColors.getGlassBorder(context), width: 1.0))
        : null;

    return GlassSurface(
      padding: padding ?? const EdgeInsets.all(AppSpacing.card),
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.sm),
      borderRadius: radius,
      color: color,
      border: cardBorder,
      shadows: shadows,
      onTap: onTap,
      child: child,
    );
  }
}
