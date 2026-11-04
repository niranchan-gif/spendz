import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

/// Luxury Translucent Glass Card with backdrop filter, specular sheen,
/// and soft elevation shadows for Spendz 2.0 Fintech UI.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Border? border;
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
    this.color,
    this.border,
    this.onTap,
    this.width,
    this.height,
    this.showHighlight = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final glassBg = color ?? AppColors.getGlassBackground(context);
    final glassBorder = border ?? Border.all(
      color: AppColors.getGlassBorder(context),
      width: 1.0,
    );

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: glassBg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: glassBorder,
            gradient: showHighlight
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withAlpha(isDark ? 28 : 170),
                      Colors.white.withAlpha(isDark ? 8 : 45),
                    ],
                  )
                : null,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );

    // Soft elevation drop shadow
    content = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 55 : 18),
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

