import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../utils/currency_formatter.dart';

/// Premium Glassmorphism Financial Overview Hero Card with privacy toggle,
/// directional cashflow indicators, and ambient emerald glow.
class FinancialSummaryCard extends StatefulWidget {
  final double netBalance;
  final double income;
  final double expenses;
  final double owedToMe;
  final VoidCallback? onAnalyticsTap;
  final List<double>? weeklyTrend;

  const FinancialSummaryCard({
    super.key,
    required this.netBalance,
    required this.income,
    required this.expenses,
    this.owedToMe = 0.0,
    this.onAnalyticsTap,
    this.weeklyTrend,
  });

  @override
  State<FinancialSummaryCard> createState() => _FinancialSummaryCardState();
}

class _FinancialSummaryCardState extends State<FinancialSummaryCard> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emerald = AppColors.getEmeraldAccent(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.card + 2),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF14231B).withAlpha(210)
                : const Color(0xFFFFFFFF).withAlpha(225),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                emerald.withAlpha(isDark ? 28 : 20),
                Colors.transparent,
                emerald.withAlpha(isDark ? 12 : 8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: emerald.withAlpha(isDark ? 35 : 20),
                blurRadius: 28,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 70 : 16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Month Capsule & Privacy Eye Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: emerald.withAlpha(isDark ? 35 : 22),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: emerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              currentMonth.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? emerald
                                    : AppColors.primaryLightMode,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          _isBalanceVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppColors.getTextSecondary(context),
                        ),
                        tooltip: _isBalanceVisible
                            ? 'Hide Balance'
                            : 'Show Balance',
                        onPressed: () => setState(
                          () => _isBalanceVisible = !_isBalanceVisible,
                        ),
                      ),
                      if (widget.onAnalyticsTap != null) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: widget.onAnalyticsTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Insights',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: emerald,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: emerald,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Net Balance Label & Prominent Figure
              Text(
                'Net Balance',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.getTextSecondary(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _isBalanceVisible
                      ? CurrencyFormatter.format(widget.netBalance)
                      : '••••••••',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Hairline Divider
              Divider(
                height: 1,
                thickness: 0.6,
                color: isDark
                    ? Colors.white.withAlpha(20)
                    : AppColors.getBorder(context),
              ),

              const SizedBox(height: AppSpacing.md),

              // Clean Inflow & Outflow Metrics Strip (Directly Integrated)
              Row(
                children: [
                  // Monthly Inflow (Income)
                  Expanded(
                    child: _buildCashflowItem(
                      context: context,
                      icon: Icons.arrow_downward_rounded,
                      iconBg: AppColors.getSuccess(context).withAlpha(28),
                      iconColor: AppColors.getSuccess(context),
                      label: 'Income',
                      amount: _isBalanceVisible
                          ? CurrencyFormatter.format(widget.income)
                          : '••••',
                    ),
                  ),

                  Container(
                    width: 0.6,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: isDark
                        ? Colors.white.withAlpha(25)
                        : AppColors.getBorder(context),
                  ),

                  // Monthly Outflow (Expense)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _buildCashflowItem(
                        context: context,
                        icon: Icons.arrow_upward_rounded,
                        iconBg: AppColors.getError(context).withAlpha(28),
                        iconColor: AppColors.getError(context),
                        label: 'Total Outflow',
                        amount: _isBalanceVisible
                            ? CurrencyFormatter.format(widget.expenses)
                            : '••••',
                      ),
                    ),
                  ),

                  // Owed back if any
                  if (widget.owedToMe > 0) ...[
                    Container(
                      width: 0.6,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isDark
                          ? Colors.white.withAlpha(25)
                          : AppColors.getBorder(context),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _buildCashflowItem(
                          context: context,
                          icon: Icons.hourglass_top_rounded,
                          iconBg: AppColors.getWarning(context).withAlpha(28),
                          iconColor: AppColors.getWarning(context),
                          label: 'Owed Back',
                          amount: _isBalanceVisible
                              ? CurrencyFormatter.format(widget.owedToMe)
                              : '••••',
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // 7-Day Financial Spending Trend Preview
              if (widget.weeklyTrend != null &&
                  widget.weeklyTrend!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildTrendPreview(context, widget.weeklyTrend!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendPreview(BuildContext context, List<double> trend) {
    final maxVal = trend.fold<double>(0.0, (m, v) => v > m ? v : m);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emerald = AppColors.getEmeraldAccent(context);
    final now = DateTime.now();
    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2, right: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(trend.length, (i) {
          final val = trend[i];
          final heightRatio = maxVal > 0
              ? (val / maxVal).clamp(0.12, 1.0)
              : 0.12;
          final date = now.subtract(Duration(days: trend.length - 1 - i));
          final isToday = i == trend.length - 1;
          final dayLetter = dayNames[(date.weekday - 1) % 7];

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 20,
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 20 * heightRatio,
                  decoration: BoxDecoration(
                    color: isToday
                        ? emerald
                        : (isDark ? Colors.white24 : Colors.black26),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                dayLetter,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: isToday
                      ? emerald
                      : AppColors.getTextSecondary(context),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCashflowItem({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String amount,
  }) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.getTextSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
