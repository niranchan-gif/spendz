import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/transaction_model.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/icon_mapper.dart';
import '../../widgets/glass_container.dart';

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
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.background,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
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
      if (tx.type == 'expense' && tx.date.isAfter(_startDate.subtract(const Duration(seconds: 1))) && tx.date.isBefore(_endDate.add(const Duration(seconds: 1)))) {
        if (tx.categoryId != null) {
          spending[tx.categoryId!] = (spending[tx.categoryId!] ?? 0) + tx.amount;
        }
      }
    }
    return spending;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: Consumer2<TransactionProvider, CategoryProvider>(
        builder: (context, txProvider, catProvider, child) {
          final spending = _calculateCategorySpending(txProvider.transactions);
          final sortedSpending = spending.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
            
          final dateString = '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Category Breakdown', style: AppTextStyles.heading3),
                  TextButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(dateString, style: AppTextStyles.bodyMedium),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (spending.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.withAlpha(100)),
                      const SizedBox(height: 16),
                      Text('No expenses for this period', style: AppTextStyles.heading3),
                      const SizedBox(height: 60),
                    ],
                  ),
                )
              else ...[
                // Bar Chart
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 24,
                  child: SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => AppColors.background.withAlpha(200),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final entry = sortedSpending[group.x];
                              final category = catProvider.getCategoryById(entry.key);
                              return BarTooltipItem(
                                '${category?.name ?? 'Unknown'}\n${CurrencyFormatter.format(rod.toY)}',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= sortedSpending.length) return const SizedBox();
                                final entry = sortedSpending[value.toInt()];
                                final category = catProvider.getCategoryById(entry.key);
                                final color = category != null 
                                    ? Color(int.tryParse(category.color) ?? AppColors.primary.value)
                                    : AppColors.textHint;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Icon(category != null ? IconMapper.getIcon(category.icon) : Icons.help_outline, color: color, size: 20),
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
                              ? Color(int.tryParse(category.color) ?? AppColors.primary.value)
                              : AppColors.textHint;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: item.value,
                                color: color,
                                width: 22,
                                borderRadius: BorderRadius.circular(6),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: sortedSpending.isNotEmpty ? sortedSpending.first.value * 1.1 : 100, // Background max height based on highest spend
                                  color: color.withAlpha(20),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Legend / List
                GlassContainer(
                  borderRadius: 24,
                  child: Column(
                    children: sortedSpending.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final category = catProvider.getCategoryById(item.key);
                      final color = category != null 
                          ? Color(int.tryParse(category.color) ?? AppColors.primary.value)
                          : AppColors.textHint;
                          
                      final isTouched = index == _touchedIndex;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        color: isTouched ? color.withAlpha(20) : Colors.transparent,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              category != null ? IconMapper.getIcon(category.icon) : Icons.help_outline, 
                              color: color,
                              size: 20,
                            ),
                          ),
                          title: Text(category?.name ?? 'Unknown', style: AppTextStyles.labelLarge),
                          trailing: Text(
                            CurrencyFormatter.format(item.value),
                            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            setState(() {
                              _touchedIndex = isTouched ? -1 : index;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 100), // padding for bottom nav
            ],
          );
        },
      ),
    );
  }


}
