import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

/// Solid clay surface used by legacy Glass* widgets.
///
/// The old glass API is retained for source compatibility, but its visual
/// treatment is intentionally opaque: no backdrop blur, translucent fills,
/// or frosted-glass gradients.
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
    final suppliedColor = color;
    final surfaceColor = suppliedColor == null
        ? AppColors.getSurface(context)
        : Color.alphaBlend(suppliedColor, AppColors.getSurface(context));
    final surfaceBorder = border ??
        Border.all(
          color: AppColors.getBorder(context),
          width: 1,
        );
    final surfaceShadows = shadows ??
        [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(48)
                : const Color(0xFF7A563D).withAlpha(18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.white.withAlpha(190),
              blurRadius: 2,
              offset: const Offset(-1, -1),
            ),
        ];

    Widget surface = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: surfaceBorder,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );

    surface = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: clipBehavior,
      child: surface,
    );

    if (onTap != null) {
      surface = Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: surface,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: surfaceShadows,
      ),
      child: surface,
    );
  }
}
