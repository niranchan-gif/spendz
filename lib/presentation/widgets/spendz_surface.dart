import 'package:flutter/material.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';

enum SpendzClayTone { neutral, tangerine, periwinkle, sunshine, sunken }

/// Spendz Funky Claymorphism Adaptive Surface Container.
///
/// Implements dual chromatic outer drop shadows paired with pillowy inner highlight
/// sheens to create physical, inflated clay volume.
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
  final bool isSunken;
  final SpendzClayTone tone;
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
    this.isSunken = false,
    this.tone = SpendzClayTone.neutral,
    this.width,
    this.height,
  });

  const SpendzSurface.sunken({
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
    this.showShadow = false,
    this.isSunken = true,
    this.tone = SpendzClayTone.sunken,
    this.width,
    this.height,
  });

  const SpendzSurface.tangerine({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.isElevated = true,
    this.showShadow = true,
    this.isSunken = false,
    this.tone = SpendzClayTone.tangerine,
    this.width,
    this.height,
  });

  const SpendzSurface.periwinkle({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.isElevated = true,
    this.showShadow = true,
    this.isSunken = false,
    this.tone = SpendzClayTone.periwinkle,
    this.width,
    this.height,
  });

  const SpendzSurface.sunshine({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.isElevated = true,
    this.showShadow = true,
    this.isSunken = false,
    this.tone = SpendzClayTone.sunshine,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = SpendzColors.isDark(context);
    final radius = borderRadius ?? SpendzSpacing.radiusXl;
    final isRecessed = isSunken || tone == SpendzClayTone.sunken;

    // Keep the established Spendz palette, but use its matte neutral surface
    // layers for every tile. Accent colours stay in icons, charts and data.
    final surfaceColor = isRecessed
        ? SpendzColors.surfaceRecessed(context)
        : switch (tone) {
            SpendzClayTone.tangerine => SpendzColors.matteTangerine,
            SpendzClayTone.periwinkle => SpendzColors.mattePeriwinkle,
            SpendzClayTone.sunshine => SpendzColors.matteSunshine,
            SpendzClayTone.neutral => isDark
                ? (isElevated
                    ? SpendzColors.surfaceElevated(context)
                    : SpendzColors.surface(context))
                : SpendzColors.surface(context),
            SpendzClayTone.sunken => SpendzColors.surfaceRecessed(context),
          };

    final defaultBorderColor = switch (tone) {
      SpendzClayTone.tangerine => const Color(0xFFD9835E),
      SpendzClayTone.sunshine => const Color(0xFFBFCC85),
      SpendzClayTone.periwinkle => const Color(0xFFB5CCA7),
      SpendzClayTone.neutral => isElevated ? const Color(0xFFB5CCA7) : const Color(0xFFE2E0BD),
      SpendzClayTone.sunken => const Color(0xFFD8D2AA),
    };

    final effectiveBorder = Border.all(
      color: borderColor ?? defaultBorderColor,
      width: borderWidth,
    );

    final shadows = showShadow && !isRecessed
        ? <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF2C221E).withAlpha(16),
              blurRadius: isElevated ? 8 : 5,
              offset: Offset(2, isElevated ? 4 : 2.5),
              spreadRadius: 0,
            ),
            const BoxShadow(
              color: Color(0xFFFFFFFF),
              blurRadius: 2,
              offset: Offset(-1, -1),
              spreadRadius: 0.5,
            ),
          ]
        : <BoxShadow>[];

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
        splashColor: SpendzColors.primaryAccent(context).withAlpha(18),
        highlightColor: SpendzColors.primaryAccent(context).withAlpha(8),
        child: content,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? surfaceColor,
        borderRadius: BorderRadius.circular(radius),
        border: effectiveBorder,
        boxShadow: shadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
