import 'package:flutter/material.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';

enum SpendzClayTone { neutral, tangerine, periwinkle, sunshine, sunken }

/// Reusable tactile surface: one soft lift, a fine rim and a restrained inner bevel.
/// Avoid stacking these around every row; reserve elevation for meaningful groups.
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
    super.key, required this.child, this.padding, this.margin,
    this.borderRadius, this.onTap, this.color, this.borderColor,
    this.borderWidth = 1, this.isElevated = false, this.showShadow = true,
    this.isSunken = false, this.tone = SpendzClayTone.neutral,
    this.width, this.height,
  });

  const SpendzSurface.sunken({
    super.key, required this.child, this.padding, this.margin,
    this.borderRadius, this.onTap, this.color, this.borderColor,
    this.borderWidth = 1, this.isElevated = false, this.showShadow = false,
    this.isSunken = true, this.tone = SpendzClayTone.sunken,
    this.width, this.height,
  });

  const SpendzSurface.tangerine({
    super.key, required this.child, this.padding, this.margin,
    this.borderRadius, this.onTap, this.color, this.borderColor,
    this.borderWidth = 1, this.isElevated = true, this.showShadow = true,
    this.isSunken = false, this.tone = SpendzClayTone.tangerine,
    this.width, this.height,
  });

  const SpendzSurface.periwinkle({
    super.key, required this.child, this.padding, this.margin,
    this.borderRadius, this.onTap, this.color, this.borderColor,
    this.borderWidth = 1, this.isElevated = true, this.showShadow = true,
    this.isSunken = false, this.tone = SpendzClayTone.periwinkle,
    this.width, this.height,
  });

  const SpendzSurface.sunshine({
    super.key, required this.child, this.padding, this.margin,
    this.borderRadius, this.onTap, this.color, this.borderColor,
    this.borderWidth = 1, this.isElevated = true, this.showShadow = true,
    this.isSunken = false, this.tone = SpendzClayTone.sunshine,
    this.width, this.height,
  });

  @override
  Widget build(BuildContext context) {
    final dark = SpendzColors.isDark(context);
    final radius = borderRadius ?? SpendzSpacing.radiusXl;
    final sunken = isSunken || tone == SpendzClayTone.sunken;

    final Color fill;
    final Color rim;
    final Color shadowTint;
    switch (tone) {
      case SpendzClayTone.tangerine:
        fill = color ?? SpendzColors.clayTangerine;
        rim = const Color(0xFFFFD5B7);
        shadowTint = SpendzColors.tangerineDeep;
        break;
      case SpendzClayTone.periwinkle:
        fill = color ?? SpendzColors.clayPeriwinkle;
        rim = const Color(0xFFD3E5F1);
        shadowTint = SpendzColors.periwinkleDeep;
        break;
      case SpendzClayTone.sunshine:
        fill = color ?? SpendzColors.clayYellow;
        rim = const Color(0xFFFFE5A0);
        shadowTint = SpendzColors.sunshineDeep;
        break;
      case SpendzClayTone.sunken:
        fill = color ?? SpendzColors.surfaceRecessed(context);
        rim = dark ? Colors.white.withAlpha(12) : const Color(0xFFE4D9CC);
        shadowTint = Colors.transparent;
        break;
      case SpendzClayTone.neutral:
        fill = color ?? (isElevated
            ? SpendzColors.surface(context)
            : SpendzColors.surfaceElevated(context));
        rim = dark ? Colors.white.withAlpha(18) : Colors.white.withAlpha(230);
        shadowTint = dark ? Colors.black : const Color(0xFF80664E);
        break;
    }

    final shadows = <BoxShadow>[];
    if (sunken) {
      shadows.addAll([
        BoxShadow(
          color: dark ? Colors.black.withAlpha(55) : const Color(0xFF8B725A).withAlpha(22),
          offset: const Offset(2, 3), blurRadius: 6,
          blurStyle: BlurStyle.inner,
        ),
        BoxShadow(
          color: dark ? Colors.white.withAlpha(8) : Colors.white.withAlpha(220),
          offset: const Offset(-2, -2), blurRadius: 5,
          blurStyle: BlurStyle.inner,
        ),
      ]);
    } else if (showShadow) {
      shadows.add(
        BoxShadow(
          color: shadowTint.withAlpha(dark ? 62 : (isElevated ? 42 : 26)),
          offset: Offset(0, isElevated ? 11 : 7),
          blurRadius: isElevated ? 26 : 18,
          spreadRadius: -4,
        ),
      );
      shadows.add(
        BoxShadow(
          color: dark ? Colors.white.withAlpha(10) : Colors.white.withAlpha(245),
          offset: const Offset(-2, -2),
          blurRadius: 5,
          spreadRadius: 0,
        ),
      );
    }

    final content = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: SpendzColors.tangerine.withAlpha(24),
        highlightColor: SpendzColors.tangerine.withAlpha(10),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(SpendzSpacing.lg),
          child: child,
        ),
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: sunken
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(fill, Colors.white, dark ? 0.035 : 0.34)!,
                  fill,
                  Color.lerp(fill, shadowTint, dark ? 0.12 : 0.055)!,
                ],
                stops: const [0, 0.48, 1],
              ),
        color: sunken ? fill : null,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? rim, width: borderWidth),
        boxShadow: shadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
