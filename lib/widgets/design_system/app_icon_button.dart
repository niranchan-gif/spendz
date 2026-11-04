import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

/// Standardized square/circle Icon Button with 44px minimum touch target.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;
  final bool hasBorder;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.size = 44.0,
    this.iconSize = 20.0,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = color ?? AppColors.getTextPrimary(context);
    final bgColor = backgroundColor ?? AppColors.getSurfaceVariant(context);
    final borderColor = hasBorder
        ? AppColors.getBorder(context)
        : Colors.transparent;

    Widget button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.roundedSm,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.roundedSm,
          child: Center(
            child: Icon(icon, color: fgColor, size: iconSize),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
