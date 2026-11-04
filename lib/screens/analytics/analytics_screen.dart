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
import '../../widgets/design_system/reusable_card.dart';
import '../../widgets/design_system/empty_state.dart';
import '../../widgets/design_system/section_header.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  int _touchedIndex = -1;

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
              seedColor: AppColors.primary,
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
    final textSecondary = AppColors.getTextSecondary(context);
    final textPrimary = AppColors.getTextPrimary(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Analytics'),
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
          final dateString = '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Category Breakdown',
                  actionLabel: dateString,
                  onActionPressed: _selectDateRange,
                ),
                const SizedBox(height: AppSpacing.sm),

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
                  // Summary Banner Card
                  ReusableCard(
                    padding: const EdgeInsets.all(AppSpacing.card),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Spent This Period',
                              style: AppTextStyles.caption.copyWith(color: textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(totalSpent),
                              style: AppTextStyles.headingLarge.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: AppColors.primary.withAlpha(50)),
                          ),
                          child: Text(
                            '${sortedSpending.length} Categories',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Bar Chart Card
                  ReusableCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spending by Category',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          height: 230,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => AppColors.getSurface(context),
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final entry = sortedSpending[group.x];
                                    final category = catProvider.getCategoryById(entry.key);
                                    final pct = totalSpent > 0 ? (entry.value / totalSpent * 100).toStringAsFixed(1) : '0';
                                    return BarTooltipItem(
                                      '${category?.name ?? 'Unknown'}\n${CurrencyFormatter.format(rod.toY)} ($pct%)',
                                      TextStyle(
                                        color: AppColors.getTextPrimary(context),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= sortedSpending.length) return const SizedBox();
                                      final entry = sortedSpending[value.toInt()];
                                      final category = catProvider.getCategoryById(entry.key);
                                      final color = category != null
                                          ? Color(int.tryParse(category.color) ?? AppColors.primary.toARGB32())
                                          : textSecondary;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Icon(
                                          category != null ? IconMapper.getIcon(category.icon) : Icons.help_outline,
                                          color: color,
                                          size: 18,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                              barGroups: sortedSpending.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final category = catProvider.getCategoryById(item.key);
                                final color = category != null
                                    ? Color(int.tryParse(category.color) ?? AppColors.primary.toARGB32())
                                    : textSecondary;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: item.value,
                                      color: color,
                                      width: 20,
                                      borderRadius: BorderRadius.circular(AppRadius.xs),
                                      backDrawRodData: BackgroundBarChartRodData(
                                        show: true,
                                        toY: sortedSpending.isNotEmpty ? sortedSpending.first.value * 1.1 : 100,
                                        color: color.withAlpha(20),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Category Breakdown Detail List
                  SectionHeader(title: 'Category Breakdown'),
                  const SizedBox(height: AppSpacing.xs),

                  ReusableCard(
                    padding: EdgeInsets.zero,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedSpending.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        indent: 72,
                        color: AppColors.getBorder(context),
                      ),
                      itemBuilder: (context, index) {
                        final item = sortedSpending[index];
                        final category = catProvider.getCategoryById(item.key);
                        final color = category != null
                            ? Color(int.tryParse(category.color) ?? AppColors.primary.toARGB32())
                            : textSecondary;

                        final pct = totalSpent > 0 ? (item.value / totalSpent * 100).toStringAsFixed(1) : '0';
                        final isTouched = index == _touchedIndex;

                        return Material(
                          color: isTouched ? color.withAlpha(20) : Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color.withAlpha(25),
                                borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                                border: Border.all(color: color.withAlpha(50)),
                              ),
                              child: Icon(
                                category != null ? IconMapper.getIcon(category.icon) : Icons.help_outline,
                                color: color,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              category?.name ?? 'Unknown',
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '$pct% of total spending',
                              style: AppTextStyles.caption.copyWith(color: textSecondary),
                            ),
                            trailing: Text(
                              CurrencyFormatter.format(item.value),
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _touchedIndex = isTouched ? -1 : index;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }
}
