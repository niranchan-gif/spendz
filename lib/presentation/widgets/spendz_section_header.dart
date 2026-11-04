import 'package:flutter/material.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';
import '../../app/theme/spendz_typography.dart';

/// Clean editorial section header with title, badge count and action button.
class SpendzSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final int? count;
  final Widget? trailing;

  const SpendzSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.count,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpendzSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: SpendzTypography.headingSmall(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: SpendzSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: SpendzColors.primaryAccent(context).withAlpha(30),
                      borderRadius: BorderRadius.circular(
                        SpendzSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: SpendzColors.primaryAccent(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: SpendzSpacing.sm),
            trailing!,
          ] else if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: SpendzSpacing.sm),
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(SpendzSpacing.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: SpendzColors.primaryAccent(context),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
