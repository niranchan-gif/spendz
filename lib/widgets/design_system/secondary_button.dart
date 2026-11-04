import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../glass/glass_button.dart';

/// Secondary / Outlined button adhering to fintech standards,
/// styled with the Spendz 2.0 minimal glassmorphism theme.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final Color? customTextColor;
  final Color? customBorderColor;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 48.0,
    this.customTextColor,
    this.customBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      label: label,
      iconData: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      isFullWidth: width == null,
      width: width,
      height: height,
      color: customTextColor ?? AppColors.getTextPrimary(context),
      variant: customBorderColor != null
          ? GlassButtonVariant.outline
          : GlassButtonVariant.secondary,
      borderRadius: AppRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    );
  }
}
