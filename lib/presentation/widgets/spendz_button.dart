import 'package:flutter/material.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';

enum SpendzButtonVariant { primary, secondary, ghost, tonal }

/// Spendz 2.0 Editorial Action Button.
class SpendzButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SpendzButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final double? height;
  final Color? customColor;
  final Color? customTextColor;

  const SpendzButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = SpendzButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48,
    this.customColor,
    this.customTextColor,
  });

  const SpendzButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48,
    this.customColor,
    this.customTextColor,
  }) : variant = SpendzButtonVariant.primary;

  const SpendzButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48,
    this.customColor,
    this.customTextColor,
  }) : variant = SpendzButtonVariant.secondary;

  const SpendzButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48,
    this.customColor,
    this.customTextColor,
  }) : variant = SpendzButtonVariant.ghost;

  const SpendzButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48,
    this.customColor,
    this.customTextColor,
  }) : variant = SpendzButtonVariant.tonal;

  @override
  Widget build(BuildContext context) {
    final isDark = SpendzColors.isDark(context);

    Color bgColor;
    Color fgColor;
    Border? border;

    switch (variant) {
      case SpendzButtonVariant.primary:
        bgColor =
            customColor ??
            (isDark ? SpendzColors.mint : SpendzColors.forestGreen);
        fgColor =
            customTextColor ??
            (isDark ? SpendzColors.backgroundDark : Colors.white);
        border = null;
        break;

      case SpendzButtonVariant.secondary:
        bgColor = customColor ?? SpendzColors.surface(context);
        fgColor = customTextColor ?? SpendzColors.textPrimary(context);
        border = Border.all(
          color: isDark ? SpendzColors.borderDark : SpendzColors.borderLight,
          width: 1.0,
        );
        break;

      case SpendzButtonVariant.tonal:
        bgColor =
            customColor ??
            (isDark
                ? SpendzColors.emerald.withAlpha(50)
                : SpendzColors.sage.withAlpha(50));
        fgColor =
            customTextColor ??
            (isDark ? SpendzColors.mint : SpendzColors.forestGreen);
        border = null;
        break;

      case SpendzButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = customTextColor ?? SpendzColors.primaryAccent(context);
        border = null;
        break;
    }

    final content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 18, color: fgColor),
            const SizedBox(width: SpendzSpacing.sm),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: fgColor,
            ),
          ),
        ],
      ],
    );

    return Container(
      height: height,
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(SpendzSpacing.radiusFull),
        border: border,
        boxShadow: variant == SpendzButtonVariant.primary
            ? [
                BoxShadow(
                  color: isDark
                      ? SpendzColors.mint.withAlpha(40)
                      : SpendzColors.forestGreen.withAlpha(30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(SpendzSpacing.radiusFull),
          onTap: isLoading ? null : onPressed,
          splashColor: fgColor.withAlpha(30),
          highlightColor: fgColor.withAlpha(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SpendzSpacing.xl,
              vertical: 8,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
