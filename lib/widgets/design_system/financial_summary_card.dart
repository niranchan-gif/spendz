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

  const FinancialSummaryCard({
    super.key,
    required this.netBalance,
    required this.income,
    required this.expenses,
    this.owedToMe = 0.0,
    this.onAnalyticsTap,
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
            border: Border.all(
              color: isDark ? emerald.withAlpha(45) : Colors.white.withAlpha(230),
              width: 1.2,
            ),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: emerald.withAlpha(isDark ? 35 : 22),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: emerald.withAlpha(60)),
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
                        Text(
                          currentMonth.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? emerald : AppColors.primaryLightMode,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isBalanceVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppColors.getTextSecondary(context),
                        ),
                        tooltip: _isBalanceVisible ? 'Hide Balance' : 'Show Balance',
                        onPressed: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                      ),
                      if (widget.onAnalyticsTap != null)
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: widget.onAnalyticsTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: emerald),
                              ],
                            ),
                          ),
                        ),
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
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _isBalanceVisible ? CurrencyFormatter.format(widget.netBalance) : '••••••••',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Glass Inflow & Outflow Metrics Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B3025).withAlpha(160)
                      : const Color(0xFFE8F0E9).withAlpha(190),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: isDark ? Colors.white.withAlpha(20) : AppColors.getBorder(context),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Monthly Inflow (Income)
                    Expanded(
                      child: _buildCashflowItem(
                        context: context,
                        icon: Icons.arrow_downward_rounded,
                        iconBg: AppColors.getSuccess(context).withAlpha(28),
                        iconColor: AppColors.getSuccess(context),
                        label: 'Income',
                        amount: _isBalanceVisible ? CurrencyFormatter.format(widget.income) : '••••',
                      ),
                    ),

                    Container(
                      width: 1,
                      height: 30,
                      color: isDark ? Colors.white.withAlpha(25) : AppColors.getBorder(context),
                    ),

                    // Monthly Outflow (Expense)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _buildCashflowItem(
                          context: context,
                          icon: Icons.arrow_upward_rounded,
                          iconBg: AppColors.getError(context).withAlpha(28),
                          iconColor: AppColors.getError(context),
                          label: 'Total Outflow',
                          amount: _isBalanceVisible ? CurrencyFormatter.format(widget.expenses) : '••••',
                        ),
                      ),
                    ),

                    // Owed back if any
                    if (widget.owedToMe > 0) ...[
                      Container(
                        width: 1,
                        height: 30,
                        color: isDark ? Colors.white.withAlpha(25) : AppColors.getBorder(context),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: _buildCashflowItem(
                            context: context,
                            icon: Icons.hourglass_top_rounded,
                            iconBg: AppColors.getWarning(context).withAlpha(28),
                            iconColor: AppColors.getWarning(context),
                            label: 'Owed Back',
                            amount: _isBalanceVisible ? CurrencyFormatter.format(widget.owedToMe) : '••••',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
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
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
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
