import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/transaction_model.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/icon_mapper.dart';
import '../../widgets/glass/glass.dart';
import '../../widgets/design_system/empty_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.getPrimary(context),
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
      });
    }
  }

  Map<String, double> _calculateCategorySpending(List<TransactionModel> transactions) {
    Map<String, double> spending = {};
    for (var tx in transactions) {
      if (tx.type == 'expense' &&
          tx.date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(_endDate.add(const Duration(seconds: 1)))) {
        if (tx.categoryId != null) {
          spending[tx.categoryId!] = (spending[tx.categoryId!] ?? 0) + tx.amount;
        }
      }
    }
    return spending;
  }

  @override
  Widget build(BuildContext context) {
    final emerald = AppColors.getEmeraldAccent(context);
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Insights', style: AppTextStyles.getHeading2(context).copyWith(fontWeight: FontWeight.bold)),
            Text(
              'Financial Analytics & Trends',
              style: AppTextStyles.caption.copyWith(color: AppColors.getTextSecondary(context), fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            tooltip: 'Filter date range',
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: Consumer2<TransactionProvider, CategoryProvider>(
        builder: (context, txProvider, catProvider, child) {
          final spending = _calculateCategorySpending(txProvider.transactions);
          final sortedSpending = spending.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final totalSpent = sortedSpending.fold(0.0, (sum, e) => sum + e.value);
          final totalIncome = txProvider.transactions
              .where((tx) =>
                  tx.type == 'income' &&
                  tx.date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
                  tx.date.isBefore(_endDate.add(const Duration(seconds: 1))))
              .fold(0.0, (sum, tx) => sum + tx.amount);

          final dateString = '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Date Range Capsule
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: emerald.withAlpha(isDark ? 30 : 20),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: emerald.withAlpha(50)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 14, color: emerald),
                        const SizedBox(width: 6),
                        Text(
                          dateString,
                          style: TextStyle(
                            color: isDark ? emerald : AppColors.primaryLightMode,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: emerald),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (spending.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Center(
                      child: EmptyState(
                        icon: Icons.pie_chart_outline_rounded,
                        title: 'No Expenses Recorded',
                        subtitle: 'No expense transactions found for $dateString.',
                        actionLabel: 'Change Period',
                        onActionPressed: _selectDateRange,
                      ),
                    ),
                  )
                else ...[
                  // 2. Summary Hero Panel
                  GlassPanel(
                    padding: const EdgeInsets.all(AppSpacing.card),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Outflow Breakdown',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: emerald.withAlpha(30),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                '${sortedSpending.length} Categories',
                                style: TextStyle(
                                  color: emerald,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CurrencyFormatter.format(totalSpent),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        if (totalIncome > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.arrow_downward_rounded, size: 12, color: AppColors.getSuccess(context)),
                              const SizedBox(width: 4),
                              Text(
                                'Inflow: ${CurrencyFormatter.format(totalIncome)}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.getTextSecondary(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 3. Donut Distribution Chart
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category Distribution',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      _touchedPieIndex = -1;
                                      return;
                                    }
                                    _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 3,
                              centerSpaceRadius: 55,
                              sections: sortedSpending.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final isTouched = index == _touchedPieIndex;
                                final category = catProvider.getCategoryById(item.key);
                                final color = category != null
                                    ? Color(int.tryParse(category.color) ?? emerald.toARGB32())
                                    : emerald;

                                return PieChartSectionData(
                                  color: color,
                                  value: item.value,
                                  title: '',
                                  radius: isTouched ? 28 : 22,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 4. Detailed Category Breakdown Bars
                  GlassSection(
                    title: 'Category Details',
                    subtitle: 'Ranked by highest expense',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedSpending.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 16,
                        thickness: 0.8,
                        color: AppColors.getBorder(context).withAlpha(80),
                      ),
                      itemBuilder: (context, index) {
                        final item = sortedSpending[index];
                        final category = catProvider.getCategoryById(item.key);
                        final pct = totalSpent > 0 ? (item.value / totalSpent * 100) : 0.0;
                        final color = category != null
                            ? Color(int.tryParse(category.color) ?? emerald.toARGB32())
                            : emerald;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: color.withAlpha(25),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        category != null ? IconMapper.getIcon(category.icon) : Icons.category_outlined,
                                        size: 16,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      category?.name ?? 'Uncategorized',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.getTextPrimary(context),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(item.value),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.getTextPrimary(context),
                                      ),
                                    ),
                                    Text(
                                      '${pct.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (pct / 100).clamp(0.0, 1.0),
                                backgroundColor: isDark ? Colors.white.withAlpha(15) : AppColors.getBorder(context),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
