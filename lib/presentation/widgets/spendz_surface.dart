import 'package:flutter/material.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';

/// Spendz 2.0 Adaptive Surface Container.
/// Replaces generic glass boxes and nested cards with a clean, high-contrast
/// editorial surface adhering to the forest green & emerald design system.
class SpendzSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final bool isElevated;
  final bool showShadow;
  final double? width;
  final double? height;

  const SpendzSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.isElevated = false,
    this.showShadow = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = SpendzColors.isDark(context);
    final radius = borderRadius ?? SpendzSpacing.radiusLg;

    final bgColor =
        color ??
        (isElevated
            ? SpendzColors.surfaceElevated(context)
            : SpendzColors.surface(context));

    final effectiveBorderColor =
        borderColor ??
        (isDark ? SpendzColors.borderDark : SpendzColors.borderLight);

    final boxDecoration = BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: effectiveBorderColor, width: borderWidth),
      boxShadow: showShadow
          ? [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(50)
                    : Colors.black.withAlpha(10),
                blurRadius: isElevated ? 16 : 8,
                offset: Offset(0, isElevated ? 4 : 2),
                spreadRadius: 0,
              ),
            ]
          : null,
    );

    Widget content = Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(SpendzSpacing.lg),
        child: child,
      ),
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: SpendzColors.primaryAccent(context).withAlpha(20),
        highlightColor: SpendzColors.primaryAccent(context).withAlpha(10),
        child: content,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: boxDecoration,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
