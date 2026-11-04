import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import 'primary_button.dart';

/// Clean fintech empty state widget with icon, message, and optional action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onActionPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.onActionPressed,
  });

  String get _effectiveMessage => subtitle ?? message ?? '';
  VoidCallback? get _effectiveAction => onActionPressed ?? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.getPrimary(context).withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.getPrimary(context).withAlpha(45),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 32,
                  color: AppColors.getPrimary(context),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.getHeading3(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (_effectiveMessage.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                _effectiveMessage,
                style: AppTextStyles.getBodySmall(context),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && _effectiveAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: actionLabel!,
                onPressed: _effectiveAction,
                width: 180,
                height: 42,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
