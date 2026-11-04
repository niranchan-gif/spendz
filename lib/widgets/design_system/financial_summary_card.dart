import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../utils/currency_formatter.dart';
import 'reusable_card.dart';

/// Premium Fintech Financial Overview Card with responsive metrics and currency formatting.
class FinancialSummaryCard extends StatelessWidget {
  final double netBalance;
  final double income;
  final double expenses;
  final double owedToMe;
  final VoidCallback? onAnalyticsTap;

  const FinancialSummaryCard({
    super.key,
    required this.netBalance,
    required this.income,
    required this.expenses,
    this.owedToMe = 0.0,
    this.onAnalyticsTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ReusableCard(
      padding: const EdgeInsets.all(AppSpacing.card),
      borderRadius: AppRadius.xl,
      gradient: isDark
          ? const LinearGradient(
              colors: [Color(0xFF1E2B1B), Color(0xFF162114), Color(0xFF131A11)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF6FAF3), Color(0xFFEFF5EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Month Badge & Net Balance Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(context).withAlpha(isDark ? 35 : 20),
                  borderRadius: AppRadius.roundedSm,
                  border: Border.all(color: AppColors.getPrimary(context).withAlpha(45)),
                ),
                child: Text(
                  currentMonth.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.getPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onAnalyticsTap != null)
                GestureDetector(
                  onTap: onAnalyticsTap,
                  child: Row(
                    children: [
                      Text(
                        'Insights',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.getPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.getPrimary(context)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Total Spent / Expense Focus
          Text(
            'Total Outflow',
            style: AppTextStyles.getBodySmall(context).copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(expenses),
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.getTextPrimary(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Bottom Metrics: Income Received | Net Balance | Owed
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context).withAlpha(isDark ? 70 : 180),
              borderRadius: AppRadius.roundedCard,
              border: Border.all(color: AppColors.getBorder(context).withAlpha(80)),
            ),
            child: Row(
              children: [
                // Income
                Expanded(
                  child: _buildMetricItem(
                    context: context,
                    icon: Icons.south_west_rounded,
                    iconColor: AppColors.getSuccess(context),
                    label: 'Income',
                    amount: CurrencyFormatter.format(income),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.getDivider(context),
                ),
                // Net Balance
                Expanded(
                  child: _buildMetricItem(
                    context: context,
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: netBalance >= 0 ? AppColors.getSuccess(context) : AppColors.getError(context),
                    label: 'Net Balance',
                    amount: CurrencyFormatter.format(netBalance),
                  ),
                ),
                if (owedToMe > 0) ...[
                  Container(
                    width: 1,
                    height: 32,
                    color: AppColors.getDivider(context),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      context: context,
                      icon: Icons.hourglass_top_rounded,
                      iconColor: AppColors.getWarning(context),
                      label: 'Owed Back',
                      amount: CurrencyFormatter.format(owedToMe),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String amount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.getTextSecondary(context),
                    fontSize: 9,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.getTextPrimary(context),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

