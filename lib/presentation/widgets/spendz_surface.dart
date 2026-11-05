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
    final radius = borderRadius ?? SpendzSpacing.radiusXl; // rounded-3xl (24px)

    // Base background color
    Color bgColor;
    Color shadowTint;
    Color topSheen;
    Color bottomShade;

    if (isSunken || tone == SpendzClayTone.sunken) {
      bgColor =
          color ?? (isDark ? const Color(0xFF131D2C) : SpendzColors.surfaceLow);
      shadowTint = Colors.transparent;
      topSheen = isDark
          ? Colors.black.withAlpha(40)
          : const Color(0xFF1E293B).withAlpha(15);
      bottomShade = isDark
          ? Colors.white.withAlpha(10)
          : Colors.white.withAlpha(220);
    } else {
      switch (tone) {
        case SpendzClayTone.tangerine:
          bgColor = color ?? SpendzColors.tangerine;
          shadowTint = SpendzColors.tangerine;
          topSheen = Colors.white.withAlpha(160);
          bottomShade = const Color(0xFF954A00).withAlpha(60);
          break;
        case SpendzClayTone.periwinkle:
          bgColor = color ?? SpendzColors.periwinkle;
          shadowTint = SpendzColors.periwinkleDeep;
          topSheen = Colors.white.withAlpha(180);
          bottomShade = const Color(0xFF2E6385).withAlpha(60);
          break;
        case SpendzClayTone.sunshine:
          bgColor = color ?? SpendzColors.sunshineYellow;
          shadowTint = SpendzColors.sunshineDeep;
          topSheen = Colors.white.withAlpha(190);
          bottomShade = const Color(0xFF795900).withAlpha(50);
          break;
        case SpendzClayTone.neutral:
        default:
          bgColor =
              color ??
              (isElevated
                  ? SpendzColors.surfaceElevated(context)
                  : SpendzColors.surface(context));
          shadowTint = isDark ? Colors.black : const Color(0xFF1E293B);
          topSheen = isDark ? Colors.white.withAlpha(35) : Colors.white;
          bottomShade = isDark
              ? Colors.black.withAlpha(50)
              : const Color(0xFF1E293B).withAlpha(15);
          break;
      }
    }

    // Every tile fill is composited onto an opaque base surface. This keeps
    // the clay palette vivid without allowing translucent card backgrounds.
    bgColor = Color.alphaBlend(
      bgColor,
      isDark ? SpendzColors.surfaceDark : SpendzColors.surfaceLowest,
    );

    // Outer chromatic shadows
    List<BoxShadow>? shadows;
    if (showShadow && !isSunken && tone != SpendzClayTone.sunken) {
      final alpha1 = isDark ? 60 : (tone == SpendzClayTone.neutral ? 20 : 65);
      final alpha2 = isDark ? 40 : (tone == SpendzClayTone.neutral ? 12 : 45);

      shadows = [
        BoxShadow(
          color: shadowTint.withAlpha(alpha1),
          blurRadius: isElevated ? 24 : 16,
          offset: Offset(0, isElevated ? 10 : 6),
          spreadRadius: -3,
        ),
        BoxShadow(
          color: shadowTint.withAlpha(alpha2),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (isSunken || tone == SpendzClayTone.sunken) {
      // Inverted sunken impression
      shadows = [
        BoxShadow(
          color: topSheen,
          blurRadius: 4,
          offset: const Offset(2, 2),
          spreadRadius: -1,
        ),
        BoxShadow(
          color: bottomShade,
          blurRadius: 4,
          offset: const Offset(-2, -2),
          spreadRadius: -1,
        ),
      ];
    }

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
        splashColor: SpendzColors.tangerine.withAlpha(25),
        highlightColor: SpendzColors.sunshineYellow.withAlpha(15),
        child: content,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isSunken
              ? (isDark
                    ? Colors.white.withAlpha(12)
                    : const Color(0xFF1E293B).withAlpha(12))
              : (borderColor ??
                    (isDark
                        ? Colors.white.withAlpha(20)
                        : Colors.white.withAlpha(180))),
          width: borderWidth,
        ),
        boxShadow: shadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
