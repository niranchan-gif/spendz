import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import 'secondary_button.dart';

/// Clean fintech error state widget.
class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.retryLabel = 'Try Again',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.getError(context).withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.getError(context).withAlpha(50),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 28,
                  color: AppColors.getError(context),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.getHeading3(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTextStyles.getBodySmall(context),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SecondaryButton(
                label: retryLabel ?? 'Try Again',
                onPressed: onRetry,
                width: 160,
                height: 40,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
