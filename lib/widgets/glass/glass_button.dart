import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

enum GlassButtonVariant { primary, secondary, glass, outline, icon }

/// Unified button component for Spendz 2.0 Fintech UI.
///
/// Supports primary gradient, secondary sage, frosted glass pill, hairline outline,
/// and icon button presentations with tactile haptic feedback and loading indicators.
class GlassButton extends StatelessWidget {
  final String? label;
  final Widget? icon;
  final IconData? iconData;
  final VoidCallback? onPressed;
  final bool isLoading;
  final GlassButtonVariant variant;
  final bool isFullWidth;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final String? tooltip;
  final double borderRadius;

  const GlassButton({
    super.key,
    this.label,
    this.icon,
    this.iconData,
    this.onPressed,
    this.isLoading = false,
    this.variant = GlassButtonVariant.primary,
    this.isFullWidth = false,
    this.height,
    this.width,
    this.padding,
    this.color,
    this.tooltip,
    this.borderRadius = AppRadius.md,
  });

  const GlassButton.primary({
    super.key,
    required String this.label,
    this.icon,
    this.iconData,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 50.0,
    this.width,
    this.padding,
    this.color,
    this.tooltip,
    this.borderRadius = AppRadius.md,
  }) : variant = GlassButtonVariant.primary;

  const GlassButton.secondary({
    super.key,
    required String this.label,
    this.icon,
    this.iconData,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
    this.width,
    this.padding,
    this.color,
    this.tooltip,
    this.borderRadius = AppRadius.md,
  }) : variant = GlassButtonVariant.secondary;

  const GlassButton.glass({
    super.key,
    this.label,
    this.icon,
    this.iconData,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 44.0,
    this.width,
    this.padding,
    this.color,
    this.tooltip,
    this.borderRadius = AppRadius.full,
  }) : variant = GlassButtonVariant.glass;

  const GlassButton.outline({
    super.key,
    required String this.label,
    this.icon,
    this.iconData,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
    this.width,
    this.padding,
    this.color,
    this.tooltip,
    this.borderRadius = AppRadius.md,
  }) : variant = GlassButtonVariant.outline;

  const GlassButton.icon({
    super.key,
    required IconData this.iconData,
    this.onPressed,
    this.isLoading = false,
    this.height = 40.0,
    this.width = 40.0,
    this.color,
    this.tooltip,
    this.borderRadius = AppRadius.sm + 2,
  }) : label = null,
       icon = null,
       isFullWidth = false,
       padding = EdgeInsets.zero,
       variant = GlassButtonVariant.icon;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final emerald = AppColors.getEmeraldAccent(context);
    final primary = AppColors.getPrimary(context);

    Decoration decoration;
    TextStyle textStyle;
    Color iconColor;

    switch (variant) {
      case GlassButtonVariant.primary:
        final btnColor = color ?? primary;
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              btnColor,
              Color.lerp(btnColor, emerald, isDark ? 0.35 : 0.25)!,
            ],
          ),
          border: Border.all(
            color: Colors.white.withAlpha(isDark ? 40 : 60),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: btnColor.withAlpha(isDark ? 90 : 50),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        );
        textStyle = const TextStyle(
          color: Colors.white,
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        );
        iconColor = Colors.white;
        break;

      case GlassButtonVariant.secondary:
        final secSurface = AppColors.getSecondarySurface(context);
        decoration = BoxDecoration(
          color: secSurface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.getBorder(context), width: 1.0),
        );
        textStyle = TextStyle(
          color: AppColors.getTextPrimary(context),
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
        );
        iconColor = primary;
        break;

      case GlassButtonVariant.glass:
        decoration = BoxDecoration(
          color: color ?? AppColors.getGlassBackground(context),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppColors.getGlassBorder(context),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 10),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        );
        textStyle = TextStyle(
          color: AppColors.getTextPrimary(context),
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
        );
        iconColor = emerald;
        break;

      case GlassButtonVariant.outline:
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: color ?? AppColors.getBorder(context),
            width: 1.2,
          ),
        );
        textStyle = TextStyle(
          color: color ?? primary,
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
        );
        iconColor = color ?? primary;
        break;

      case GlassButtonVariant.icon:
        decoration = BoxDecoration(
          color: color != null
              ? color!.withAlpha(isDark ? 30 : 20)
              : (isDark
                    ? const Color(0xFF14231B).withAlpha(190)
                    : Colors.white.withAlpha(210)),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: color != null
                ? color!.withAlpha(60)
                : (isDark
                      ? Colors.white.withAlpha(25)
                      : Colors.white.withAlpha(220)),
            width: 1.0,
          ),
        );
        textStyle = const TextStyle();
        iconColor = color ?? AppColors.getTextPrimary(context);
        break;
    }

    Widget resolvedIcon =
        icon ??
        (iconData != null
            ? Icon(
                iconData,
                size: variant == GlassButtonVariant.icon ? 20 : 18,
                color: iconColor,
              )
            : const SizedBox.shrink());

    Widget content;
    if (isLoading) {
      content = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (variant == GlassButtonVariant.icon) {
      content = resolvedIcon;
    } else {
      content = Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null || iconData != null) ...[
            resolvedIcon,
            const SizedBox(width: 8),
          ],
          if (label != null)
            Text(label!, style: textStyle, textAlign: TextAlign.center),
        ],
      );
    }

    Widget button = Container(
      width: isFullWidth ? double.infinity : width,
      height: height,
      padding:
          padding ??
          (variant == GlassButtonVariant.icon
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0)),
      decoration: decoration,
      child: Center(child: content),
    );

    if (variant == GlassButtonVariant.glass ||
        variant == GlassButtonVariant.icon) {
      button = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: button,
        ),
      );
    }

    button = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onPressed != null && !isLoading
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        child: button,
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
