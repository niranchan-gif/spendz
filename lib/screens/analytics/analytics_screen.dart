import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';
import '../../app/theme/spendz_typography.dart';
import '../../models/transaction_model.dart';
import '../../presentation/widgets/spendz_amount_text.dart';
import '../../presentation/widgets/spendz_app_bar.dart';
import '../../presentation/widgets/spendz_empty_state.dart';
import '../../presentation/widgets/spendz_section_header.dart';
import '../../presentation/widgets/spendz_surface.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/icon_mapper.dart';

/// Spendz 2.0 Financial Intelligence & Analytics Screen.
/// Clean editorial visualisations for Cashflow, Spending Trend, and Categories.
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
        final isDark = SpendzColors.isDark(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: SpendzColors.emerald,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end.add(
          const Duration(hours: 23, minutes: 59, seconds: 59),
        );
      });
    }
  }

  List<Map<String, dynamic>> _calculateMonthlyTrend(
    List<TransactionModel> transactions,
  ) {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final monthOffset = 5 - i;
      final targetYear = now.year - ((now.month - 1 - monthOffset) < 0 ? 1 : 0);
      final targetMonth = ((now.month - 1 - monthOffset) % 12) + 1;

      final startOfMonth = DateTime(targetYear, targetMonth, 1);
      final endOfMonth = DateTime(targetYear, targetMonth + 1, 0, 23, 59, 59);

      final monthSpent = transactions
          .where(
            (tx) =>
                tx.type == 'expense' &&
                tx.date.isAfter(
                  startOfMonth.subtract(const Duration(seconds: 1)),
                ) &&
                tx.date.isBefore(endOfMonth.add(const Duration(seconds: 1))),
          )
          .fold(0.0, (sum, tx) => sum + tx.amount);

      return {
        'label': DateFormat('MMM').format(startOfMonth),
        'amount': monthSpent,
        'isCurrent': targetMonth == now.month && targetYear == now.year,
      };
    });
  }

  Map<String, double> _calculateCategorySpending(
    List<TransactionModel> transactions,
  ) {
    Map<String, double> spending = {};
    for (var tx in transactions) {
      if (tx.type == 'expense' &&
          tx.date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(_endDate.add(const Duration(seconds: 1)))) {
        final catId = tx.categoryId ?? 'other';
        spending[catId] = (spending[catId] ?? 0) + tx.amount;
      }
    }
    return spending;
  }

  @override
  Widget build(BuildContext context) {
    final accent = SpendzColors.primaryAccent(context);

    return Scaffold(
      backgroundColor: SpendzColors.background(context),
      appBar: SpendzAppBar(
        title: 'Insights',
        subtitle: 'Cashflow analytics & spending trends',
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: SpendzColors.surface(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SpendzSpacing.radiusFull),
                side: BorderSide(color: SpendzColors.border(context)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            icon: Icon(Icons.calendar_today_rounded, size: 14, color: accent),
            label: Text(
              DateFormat('MMM yyyy').format(_startDate),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SpendzColors.textPrimary(context),
              ),
            ),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: Consumer2<TransactionProvider, CategoryProvider>(
        builder: (context, txProvider, catProvider, _) {
          final txs = txProvider.transactions;
          final categorySpending = _calculateCategorySpending(txs);
          final sortedSpending = categorySpending.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          double totalSpent = 0;
          for (var item in sortedSpending) {
            totalSpent += item.value;
          }

          double totalIncome = 0;
          for (var tx in txs) {
            if (tx.type == 'income' &&
                tx.date.isAfter(
                  _startDate.subtract(const Duration(seconds: 1)),
                ) &&
                tx.date.isBefore(_endDate.add(const Duration(seconds: 1)))) {
              totalIncome += tx.amount;
            }
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: SpendzSpacing.lg,
              vertical: SpendzSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Cashflow Comparison Hero
                _buildCashflowHero(
                  context,
                  totalSpent,
                  totalIncome,
                  sortedSpending.length,
                ),
                const SizedBox(height: SpendzSpacing.xl),

                if (totalSpent == 0 && totalIncome == 0)
                  SpendzEmptyState(
                    icon: Icons.pie_chart_outline_rounded,
                    title: 'No Activity in Selected Period',
                    message:
                        'No transactions found between ${DateFormat('dd MMM').format(_startDate)} and ${DateFormat('dd MMM').format(_endDate)}.',
                    actionLabel: 'Select Another Range',
                    onAction: _selectDateRange,
                  )
                else ...[
                  // 2. Category Distribution Donut
                  if (sortedSpending.isNotEmpty) ...[
                    _buildDonutSection(
                      context,
                      sortedSpending,
                      totalSpent,
                      catProvider,
                    ),
                    const SizedBox(height: SpendzSpacing.xl),
                  ],

                  // 3. 6-Month Spending Trend
                  _buildTrendSection(context, txProvider.transactions),
                  const SizedBox(height: SpendzSpacing.xl),

                  // 4. Ranked Category Breakdown Bars
                  if (sortedSpending.isNotEmpty) ...[
                    _buildCategoryRankList(
                      context,
                      sortedSpending,
                      totalSpent,
                      catProvider,
                    ),
                    const SizedBox(height: SpendzSpacing.hero),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── 1. CASHFLOW HERO ────────────────────────────────────────────────────────
  Widget _buildCashflowHero(
    BuildContext context,
    double totalSpent,
    double totalIncome,
    int categoryCount,
  ) {
    final netSavings = totalIncome - totalSpent;
    final totalFlow = totalIncome + totalSpent;
    final expenseRatio = totalFlow > 0 ? (totalSpent / totalFlow) : 0.5;
    final incomeRatio = totalFlow > 0 ? (totalIncome / totalFlow) : 0.5;

    return SpendzSurface(
      isElevated: true,
      padding: const EdgeInsets.all(SpendzSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'CASHFLOW COMPARISON',
                  style: SpendzTypography.labelTracked(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SpendzColors.primaryAccent(context).withAlpha(25),
                  borderRadius: BorderRadius.circular(SpendzSpacing.radiusFull),
                ),
                child: Text(
                  '$categoryCount Categories',
                  style: TextStyle(
                    color: SpendzColors.primaryAccent(context),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpendzSpacing.md),

          Row(
            children: [
              // Outflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_upward_rounded,
                          size: 13,
                          color: SpendzColors.expense,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Total Outflow',
                            style: SpendzTypography.caption(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    SpendzAmountText(
                      amount: totalSpent,
                      variant: SpendzAmountVariant.expense,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: SpendzColors.border(context),
              ),
              const SizedBox(width: SpendzSpacing.md),
              // Inflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_downward_rounded,
                          size: 13,
                          color: SpendzColors.income,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Total Inflow',
                            style: SpendzTypography.caption(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    SpendzAmountText(
                      amount: totalIncome,
                      variant: SpendzAmountVariant.income,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: SpendzSpacing.md),

          // Visual Progress Ratio Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(SpendzSpacing.radiusFull),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: (expenseRatio * 100).round().clamp(1, 99),
                    child: Container(color: SpendzColors.expense),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (incomeRatio * 100).round().clamp(1, 99),
                    child: Container(color: SpendzColors.income),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: SpendzSpacing.sm),

          // Net Savings Note
          Text(
            netSavings >= 0
                ? 'Net Surplus: +₹${netSavings.toStringAsFixed(0)} retained this period'
                : 'Net Deficit: -₹${(-netSavings).toStringAsFixed(0)} beyond inflow',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: netSavings >= 0
                  ? SpendzColors.income
                  : SpendzColors.expense,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. DONUT DISTRIBUTION CHART ───────────────────────────────────────────
  Widget _buildDonutSection(
    BuildContext context,
    List<MapEntry<String, double>> sortedSpending,
    double totalSpent,
    CategoryProvider catProvider,
  ) {
    final accent = SpendzColors.primaryAccent(context);

    return SpendzSurface(
      padding: const EdgeInsets.all(SpendzSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpendzSectionHeader(
            title: 'Category Distribution',
            count: sortedSpending.length,
          ),
          const SizedBox(height: SpendzSpacing.md),

          SizedBox(
            height: 180,
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
                      _touchedPieIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 3,
                centerSpaceRadius: 50,
                sections: sortedSpending.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isTouched = index == _touchedPieIndex;
                  final category = catProvider.getCategoryById(item.key);
                  final color = category != null
                      ? Color(int.tryParse(category.color) ?? accent.toARGB32())
                      : accent;

                  return PieChartSectionData(
                    color: color,
                    value: item.value,
                    title: '',
                    radius: isTouched ? 26 : 20,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. 6-MONTH SPENDING TREND ──────────────────────────────────────────────
  Widget _buildTrendSection(
    BuildContext context,
    List<TransactionModel> allTxs,
  ) {
    final monthlyTrend = _calculateMonthlyTrend(allTxs);
    final accent = SpendzColors.primaryAccent(context);
    final isDark = SpendzColors.isDark(context);

    final maxMonthAmount = monthlyTrend.fold(
      0.0,
      (max, m) => (m['amount'] as double) > max ? (m['amount'] as double) : max,
    );

    return SpendzSurface(
      padding: const EdgeInsets.all(SpendzSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpendzSectionHeader(
            title: 'Monthly Spending Trend',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withAlpha(25),
                borderRadius: BorderRadius.circular(SpendzSpacing.radiusFull),
              ),
              child: Text(
                '6 Months',
                style: TextStyle(
                  color: accent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: SpendzSpacing.lg),

          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxMonthAmount * 1.2).clamp(100.0, double.infinity),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: SpendzColors.border(context).withAlpha(100),
                    strokeWidth: 0.8,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < monthlyTrend.length) {
                          final isCurrent =
                              monthlyTrend[idx]['isCurrent'] as bool;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              monthlyTrend[idx]['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isCurrent
                                    ? accent
                                    : SpendzColors.textSecondary(context),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                barGroups: monthlyTrend.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final amount = item['amount'] as double;
                  final isCurrent = item['isCurrent'] as bool;

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: amount,
                        color: isCurrent
                            ? accent
                            : (isDark
                                  ? accent.withAlpha(90)
                                  : accent.withAlpha(130)),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
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
    );
  }

  // ─── 4. CATEGORY BREAKDOWN LIST ─────────────────────────────────────────────
  Widget _buildCategoryRankList(
    BuildContext context,
    List<MapEntry<String, double>> sortedSpending,
    double totalSpent,
    CategoryProvider catProvider,
  ) {
    final accent = SpendzColors.primaryAccent(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SpendzSectionHeader(title: 'Highest Spending Categories'),
        const SizedBox(height: SpendzSpacing.xs),
        SpendzSurface(
          padding: const EdgeInsets.all(SpendzSpacing.md),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedSpending.length,
            separatorBuilder: (_, _) =>
                Divider(height: 16, color: SpendzColors.border(context)),
            itemBuilder: (context, index) {
              final item = sortedSpending[index];
              final category = catProvider.getCategoryById(item.key);
              final pct = totalSpent > 0
                  ? (item.value / totalSpent * 100)
                  : 0.0;
              final color = category != null
                  ? Color(int.tryParse(category.color) ?? accent.toARGB32())
                  : accent;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: BorderRadius.circular(
                            SpendzSpacing.radiusSm,
                          ),
                        ),
                        child: Icon(
                          category != null
                              ? IconMapper.getIcon(category.icon)
                              : Icons.category_outlined,
                          size: 16,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: SpendzSpacing.sm + 2),

                      // Category Name
                      Expanded(
                        child: Text(
                          category?.name ?? 'Uncategorized',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: SpendzColors.textPrimary(context),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: SpendzSpacing.sm),

                      // Amount & Pct
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SpendzAmountText(
                            amount: item.value,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: SpendzTypography.caption(context),
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
                      backgroundColor: SpendzColors.border(context),
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
    );
  }
}
