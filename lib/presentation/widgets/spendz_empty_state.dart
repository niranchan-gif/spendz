import 'package:flutter/material.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';
import '../../app/theme/spendz_typography.dart';
import 'spendz_button.dart';

/// Clean minimalist empty state for lists, searches, and vaults.
class SpendzEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SpendzEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpendzSpacing.xxl,
          vertical: SpendzSpacing.hero,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SpendzColors.surface(context),
              ),
              child: Icon(
                icon,
                size: 26,
                color: SpendzColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: SpendzSpacing.lg),
            Text(
              title,
              style: SpendzTypography.headingSmall(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpendzSpacing.xs),
            Text(
              message,
              style: SpendzTypography.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: SpendzSpacing.lg),
              SpendzButton.tonal(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
