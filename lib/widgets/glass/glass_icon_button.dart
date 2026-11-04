import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

/// Refined Translucent Glass Icon Button with backdrop filter.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;
  final double size;
  final double iconSize;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color,
    this.size = 40.0,
    this.iconSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final iconColor = color ?? AppColors.getTextPrimary(context);

    Widget button = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF14231B).withAlpha(190)
                : const Color(0xFFFFFFFF).withAlpha(210),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(25)
                  : Colors.white.withAlpha(220),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 30 : 10),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: iconColor, size: iconSize),
          ),
        ),
      ),
    );

    button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: button,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

