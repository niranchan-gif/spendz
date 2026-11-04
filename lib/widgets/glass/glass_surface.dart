import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

/// Primary Glass Surface widget for Spendz 2.0 Fintech UI.
///
/// Combines selective backdrop blur, specular highlight gradient, subtle
/// border, and optional high-performance non-blurred fallback for dense layouts.
class GlassSurface extends StatelessWidget {
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
  final List<BoxShadow>? shadows;
  final Clip clipBehavior;

  const GlassSurface({
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
    this.shadows,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final glassBg = color ?? AppColors.getGlassBackground(context);
    final glassBorder =
        border ??
        Border.all(color: AppColors.getGlassBorder(context), width: 1.0);

    final highlightGradient = showHighlight
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.getGlassHighlight(context),
              Colors.transparent,
              Colors.transparent,
              if (isDark)
                AppColors.getEmeraldAccent(context).withAlpha(10)
              else
                Colors.white.withAlpha(20),
            ],
            stops: const [0.0, 0.35, 0.80, 1.0],
          )
        : null;

    Widget surfaceBox = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: glassBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: glassBorder,
        gradient: highlightGradient,
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );

    // If blur is enabled and > 0, wrap in BackdropFilter
    if (!disableBlur && blur > 0) {
      surfaceBox = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: surfaceBox,
        ),
      );
    } else {
      surfaceBox = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: clipBehavior,
        child: surfaceBox,
      );
    }

    if (onTap != null) {
      surfaceBox = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: surfaceBox,
        ),
      );
    }

    if (margin != null || shadows != null) {
      surfaceBox = Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow:
              shadows ??
              [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withAlpha(50)
                      : const Color(0xFF174D3B).withAlpha(10),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
        ),
        child: surfaceBox,
      );
    }

    return surfaceBox;
  }
}
