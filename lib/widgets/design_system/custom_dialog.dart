import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../glass/glass_dialog.dart';
import '../glass/glass_button.dart';

/// Standardized Fintech Dialog with clear action hierarchy,
/// built on the Spendz 2.0 GlassDialog component.
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
    return GlassDialog.show<bool>(
      context: context,
      title: title,
      icon: icon != null
          ? Icon(
              icon,
              size: 28,
              color: isDestructive
                  ? AppColors.getError(context)
                  : AppColors.getPrimary(context),
            )
          : null,
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                cancelLabel,
                style: TextStyle(
                  color: AppColors.getTextSecondary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GlassButton(
              label: confirmLabel,
              onPressed: () => Navigator.pop(context, true),
              color: isDestructive ? AppColors.getError(context) : null,
              variant: GlassButtonVariant.primary,
              height: 42.0,
            ),
          ],
        ),
      ],
      child: Text(
        message,
        style: TextStyle(
          color: AppColors.getTextSecondary(context),
          fontSize: 13.5,
          height: 1.45,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: title,
      icon: icon != null
          ? Icon(
              icon,
              size: 28,
              color:
                  iconColor ??
                  (isDestructive
                      ? AppColors.getError(context)
                      : AppColors.getPrimary(context)),
            )
          : null,
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (secondaryActionLabel != null)
              TextButton(
                onPressed: onSecondaryAction ?? () => Navigator.pop(context),
                child: Text(
                  secondaryActionLabel!,
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            GlassButton(
              label: primaryActionLabel,
              onPressed: onPrimaryAction,
              color: isDestructive ? AppColors.getError(context) : null,
              variant: GlassButtonVariant.primary,
              height: 42.0,
            ),
          ],
        ),
      ],
      child: Text(
        message,
        style: TextStyle(
          color: AppColors.getTextSecondary(context),
          fontSize: 13.5,
          height: 1.45,
        ),
      ),
    );
  }
}
