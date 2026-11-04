import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// Standardized Fintech Dialog with clear action hierarchy.
class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool isDestructive;

  const CustomDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.iconColor,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel = 'Cancel',
    this.onSecondaryAction,
    this.isDestructive = false,
  });

  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => CustomDialog(
        title: title,
        message: message,
        icon: icon,
        primaryActionLabel: confirmLabel,
        isDestructive: isDestructive,
        onPrimaryAction: () => Navigator.pop(ctx, true),
        secondaryActionLabel: cancelLabel,
        onSecondaryAction: () => Navigator.pop(ctx, false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.getSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.roundedLg,
        side: BorderSide(color: AppColors.getBorder(context), width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.getPrimary(context)).withAlpha(20),
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.getPrimary(context),
                  size: 22,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              title,
              style: AppTextStyles.getHeading3(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTextStyles.getBodyMedium(context).copyWith(
                color: AppColors.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                if (secondaryActionLabel != null) ...[
                  Expanded(
                    child: SecondaryButton(
                      label: secondaryActionLabel!,
                      onPressed: onSecondaryAction ?? () => Navigator.pop(context),
                      height: 44,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: PrimaryButton(
                    label: primaryActionLabel,
                    onPressed: onPrimaryAction,
                    isDestructive: isDestructive,
                    height: 44,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

