import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme/spendz_colors.dart';
import '../../models/transaction_model.dart';
import '../../presentation/widgets/spendz_amount_text.dart';
import '../../presentation/widgets/spendz_empty_state.dart';
import '../../presentation/widgets/spendz_top_bar.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/icon_mapper.dart';

/// Spendz Funky Claymorphism Financial Intelligence & Analytics Screen.
/// Playful tactile money playground with 3-capsule scorecard, donut split,
/// chunky 6-month trend bars, and ranked category modules.
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
              seedColor: SpendzColors.tangerine,
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
    return Scaffold(
      backgroundColor: SpendzColors.background(context),
      body: SafeArea(
        child: Consumer2<TransactionProvider, CategoryProvider>(
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

            final savingsRate = totalIncome > 0
                ? (((totalIncome - totalSpent) / totalIncome) * 100).clamp(
                    0.0,
                    100.0,
                  )
                : 0.0;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 0. Global Top Bar
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: SpendzTopBar(title: 'Insights', category: 'OVERVIEW'),
                  ),
                ),

                // 1. Header with Month Selector
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: _buildHeader(context),
                  ),
                ),

                // 2. Three Puffy Clay Scorecard Capsules
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildThreeCapsules(
                      context,
                      totalIncome,
                      totalSpent,
                      savingsRate,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                if (totalSpent == 0 && totalIncome == 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 32,
                      ),
                      child: SpendzEmptyState(
                        icon: Icons.pie_chart_outline_rounded,
                        title: 'No Flows in Period',
                        message:
                            'No transactions between ${DateFormat('dd MMM').format(_startDate)} and ${DateFormat('dd MMM').format(_endDate)}.',
                        actionLabel: 'Select Another Range',
                        onAction: _selectDateRange,
                      ),
                    ),
                  )
                else ...[
                  // 3. Interactive Expense Donut Clay Section
                  if (sortedSpending.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildDonutSection(
                          context,
                          sortedSpending,
                          totalSpent,
                          catProvider,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // 4. 6-Month Spending Trend with Chunky Clay Bars
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildTrendSection(context, txs),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // 5. Ranked Category Breakdown Bars
                  if (sortedSpending.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      sliver: SliverToBoxAdapter(
                        child: _buildCategoryRankList(
                          context,
                          sortedSpending,
                          totalSpent,
                          catProvider,
                        ),
                      ),
                    ),

                  // 6. Smart Insight Card matching Image 5
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      child: _buildSmartInsightCard(context),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  // 1. Header with Month Toggle & Compare Button
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Insights & Analytics',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: SpendzColors.textPrimary(context),
                        letterSpacing: -0.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('📊', style: TextStyle(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Your tactile money playground',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: SpendzColors.textSecondary(context),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Month selector clay pill
        GestureDetector(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: SpendzColors.surface(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: SpendzColors.clayDropShadow(context),
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('MMM yyyy').format(_startDate),
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: SpendzColors.textPrimary(context),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: SpendzColors.tangerine,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 2. Financial Scorecard Pods (3 Puffy Clay Capsules)
  Widget _buildThreeCapsules(
    BuildContext context,
    double income,
    double spent,
    double savingsRate,
  ) {
    return Row(
      children: [
        // Income Capsule
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: SpendzColors.surface(context),
              borderRadius: BorderRadius.circular(22),
              boxShadow: SpendzColors.clayDropShadow(context),
            ),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SpendzColors.tertiarySky.withAlpha(40),
                    boxShadow: [
                      BoxShadow(
                        color: SpendzColors.tertiarySky.withAlpha(60),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.white.withAlpha(200),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                        blurStyle: BlurStyle.inner,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.south_west_rounded,
                    size: 16,
                    color: SpendzColors.tertiarySky,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Income',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: SpendzColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+₹${income.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: SpendzColors.tertiarySky,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Spent Capsule
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: SpendzColors.surface(context),
              borderRadius: BorderRadius.circular(22),
              boxShadow: SpendzColors.clayDropShadow(context),
            ),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SpendzColors.tangerineLight,
                    boxShadow: [
                      BoxShadow(
                        color: SpendzColors.tangerine.withAlpha(60),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.white.withAlpha(200),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                        blurStyle: BlurStyle.inner,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.north_east_rounded,
                    size: 16,
                    color: SpendzColors.tangerine,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Spent',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: SpendzColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${spent.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: SpendzColors.textPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Saved Capsule (Sunshine Yellow highlight)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: SpendzColors.sunshineYellow,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: SpendzColors.sunshineYellow.withAlpha(90),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.white.withAlpha(200),
                  blurRadius: 3,
                  offset: const Offset(2, 2),
                  blurStyle: BlurStyle.inner,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(180),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.savings_rounded,
                    size: 16,
                    color: Color(0xFF735500),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Saved',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF735500),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${savingsRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF735500),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. Interactive Expense Donut Clay Section
  Widget _buildDonutSection(
    BuildContext context,
    List<MapEntry<String, double>> sortedSpending,
    double totalSpent,
    CategoryProvider catProvider,
  ) {
    final colors = [
      SpendzColors.tangerine,
      SpendzColors.tertiarySky,
      SpendzColors.sunshineYellow,
      SpendzColors.periwinkle,
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF82B4DA),
      const Color(0xFFFFDCC6),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SpendzColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: SpendzColors.clayDropShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.donut_large_rounded,
                    size: 18,
                    color: SpendzColors.tangerine,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Category Split',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: SpendzColors.textPrimary(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SpendzColors.surfaceContainerHigh(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${DateFormat('d MMM').format(_startDate)} - ${DateFormat('d MMM').format(_endDate)}',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: SpendzColors.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tactile Donut Chart with Center Hub
          Center(
            child: SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
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
                            _touchedPieIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 4,
                      centerSpaceRadius: 58,
                      sections: sortedSpending.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isTouched = index == _touchedPieIndex;
                        final color = colors[index % colors.length];

                        return PieChartSectionData(
                          color: color,
                          value: item.value,
                          title: '',
                          radius: isTouched ? 26 : 20,
                        );
                      }).toList(),
                    ),
                  ),

                  // Center Hub Clay Disc
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SpendzColors.surfaceContainerLow(context),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                          blurStyle: BlurStyle.inner,
                        ),
                        BoxShadow(
                          color: Colors.white.withAlpha(220),
                          blurRadius: 4,
                          offset: const Offset(-2, -2),
                          blurStyle: BlurStyle.inner,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'TOTAL SPENT',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: SpendzColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${totalSpent.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: SpendzColors.textPrimary(context),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Playful Legend 2-Column Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedSpending.take(6).length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, idx) {
              final item = sortedSpending[idx];
              final category = catProvider.getCategoryById(item.key);
              final pct = totalSpent > 0
                  ? (item.value / totalSpent * 100)
                  : 0.0;
              final color = colors[idx % colors.length];

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: SpendzColors.surfaceContainerLow(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withAlpha(100),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category?.name ?? item.key,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: SpendzColors.textPrimary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: SpendzColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 4. 6-Month Spending Trend with Chunky Bulbous Clay Bars
  Widget _buildTrendSection(
    BuildContext context,
    List<TransactionModel> allTxs,
  ) {
    final monthlyTrend = _calculateMonthlyTrend(allTxs);
    final maxMonthAmount = monthlyTrend.fold(
      0.0,
      (max, m) => (m['amount'] as double) > max ? (m['amount'] as double) : max,
    );
    final avgAmount = monthlyTrend.isEmpty
        ? 0.0
        : (monthlyTrend.fold(0.0, (sum, m) => sum + (m['amount'] as double)) /
              monthlyTrend.length);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SpendzColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: SpendzColors.clayDropShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '6-Month Trend',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: SpendzColors.textPrimary(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Monthly velocity and baseline',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: SpendzColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: SpendzColors.sunshineYellow.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      size: 13,
                      color: Color(0xFF735500),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Avg ₹${avgAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF735500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bulbous Bars
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxMonthAmount * 1.25).clamp(100.0, double.infinity),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: SpendzColors.border(context).withAlpha(80),
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
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11,
                                fontWeight: isCurrent
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isCurrent
                                    ? SpendzColors.tangerine
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
                            ? SpendzColors.tangerine
                            : SpendzColors.surfaceContainerHighest(context),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                          bottom: Radius.circular(8),
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

  // 5. Ranked Category Breakdown Bars
  Widget _buildCategoryRankList(
    BuildContext context,
    List<MapEntry<String, double>> sortedSpending,
    double totalSpent,
    CategoryProvider catProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ranked Spending Breakdown',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: SpendzColors.textPrimary(context),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        ...sortedSpending.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final category = catProvider.getCategoryById(item.key);
          final pct = totalSpent > 0 ? (item.value / totalSpent * 100) : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SpendzColors.surface(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: SpendzColors.clayDropShadow(context),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Rank number chip
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == 0
                              ? SpendzColors.tangerine
                              : SpendzColors.surfaceContainerHigh(context),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: index == 0
                                ? Colors.white
                                : SpendzColors.textSecondary(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Icon
                      Icon(
                        category != null
                            ? IconMapper.getIcon(category.icon)
                            : Icons.category_outlined,
                        size: 18,
                        color: SpendzColors.tangerine,
                      ),
                      const SizedBox(width: 8),

                      // Name
                      Expanded(
                        child: Text(
                          category?.name ?? item.key,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: SpendzColors.textPrimary(context),
                          ),
                        ),
                      ),

                      // Amount & Pct
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SpendzAmountText(
                            amount: item.value,
                            variant: SpendzAmountVariant.expense,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: SpendzColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tactile Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        backgroundColor: SpendzColors.surfaceContainerHigh(
                          context,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          index == 0
                              ? SpendzColors.tangerine
                              : index == 1
                              ? SpendzColors.tertiarySky
                              : SpendzColors.sunshineYellow,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // 6. Smart Insight Card matching Image 5
  Widget _buildSmartInsightCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6), // Warm butter/sunshine
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFED7AA),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withAlpha(40),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withAlpha(200),
            blurRadius: 3,
            offset: const Offset(1, 1),
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🌱',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Insight',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF78350F),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You spent \$142 less on dining out on weekends compared to last month!',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF92400E).withAlpha(220),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
