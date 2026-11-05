import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

/// Matte, borderless surface behind legacy Glass* components.
/// Legacy blur/highlight parameters remain for API compatibility only.
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
    final base = AppColors.getSurface(context);
    final surfaceColor = color == null ? base : Color.alphaBlend(color!, base);

    Widget surface = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );

    if (onTap != null) {
      surface = Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.getEmeraldAccent(context).withAlpha(16),
          child: surface,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 34 : 12),
                blurRadius: 14,
                offset: const Offset(0, 5),
                spreadRadius: -3,
              ),
            ],
      ),
      clipBehavior: clipBehavior,
      child: surface,
    );
  }
}
