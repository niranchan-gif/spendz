import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

/// Featured Glass Panel with an ambient emerald halo and frosted backdrop blur.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? glowColor;
  final VoidCallback? onTap;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.xl,
    this.blur = 20.0,
    this.glowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = glowColor ?? AppColors.getEmeraldAccent(context);

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF14231B).withAlpha(210)
                : const Color(0xFFFFFFFF).withAlpha(225),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? accent.withAlpha(50)
                  : Colors.white.withAlpha(230),
              width: 1.2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withAlpha(isDark ? 30 : 25),
                Colors.transparent,
                accent.withAlpha(isDark ? 15 : 10),
              ],
            ),
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20.0),
            child: child,
          ),
        ),
      ),
    );

    content = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(isDark ? 40 : 25),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 70 : 18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: content,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

