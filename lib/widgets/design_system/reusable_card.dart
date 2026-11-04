import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_shadows.dart';

/// Standardized Fintech Card container adhering to the Spendz design tokens.
class ReusableCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
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
        ? (border ?? Border.all(color: AppColors.getBorder(context), width: 1))
        : null;
    final cardColor = color ?? AppColors.getSurface(context);
    final cardShadows = shadows ?? AppShadows.card(context);

    Widget content = Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: gradient == null ? cardColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: cardBorder,
        boxShadow: gradient == null ? cardShadows : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: AppColors.getPrimary(context).withAlpha(15),
          highlightColor: AppColors.getPrimary(context).withAlpha(8),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.card),
            child: child,
          ),
        ),
      ),
    );

    return content;
  }
}

