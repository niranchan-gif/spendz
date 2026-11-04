import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../glass/glass_button.dart';

/// Primary call-to-action button adhering to fintech 48px touch standards,
/// styled with the Spendz 2.0 minimal glassmorphism emerald gradient.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isDestructive;
  final double? width;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isDestructive = false,
    this.width,
    this.height = 48.0,
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
      color: isDestructive ? AppColors.getError(context) : null,
      variant: GlassButtonVariant.primary,
      borderRadius: AppRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    );
  }
}
