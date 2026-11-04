import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/design_system/empty_state.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../utils/date_formatter.dart';
import '../../utils/icon_mapper.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  String _selectedCategoryId = 'all';

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
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

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textSecondary = AppColors.getTextSecondary(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              tooltip: 'Clear date filter',
              onPressed: _clearDateRange,
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            tooltip: 'Filter by date',
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            tooltip: 'Import from Gmail',
            onPressed: () {
              Navigator.pushNamed(context, '/import-review');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'activity_add_tx_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
      ),
      body: Consumer2<TransactionProvider, CategoryProvider>(
        builder: (context, txProvider, catProvider, child) {
          var transactions = txProvider.transactions;

          // 1. Search Query Filter
          if (_searchQuery.trim().isNotEmpty) {
            final query = _searchQuery.toLowerCase().trim();
            transactions = transactions.where((tx) {
              final merchantMatch = (tx.merchant ?? '').toLowerCase().contains(query);
              final descMatch = (tx.description ?? '').toLowerCase().contains(query);
              final amountMatch = tx.amount.toString().contains(query);
              final refMatch = (tx.referenceId ?? '').toLowerCase().contains(query);
              final methodMatch = (tx.paymentMethod ?? '').toLowerCase().contains(query);
              return merchantMatch || descMatch || amountMatch || refMatch || methodMatch;
            }).toList();
          }

          // 2. Category Filter
          if (_selectedCategoryId != 'all') {
            transactions = transactions.where((tx) => tx.categoryId == _selectedCategoryId).toList();
          }

          // 3. Date Range Filter
          if (_startDate != null && _endDate != null) {
            transactions = transactions.where((tx) {
              return tx.date.isAfter(_startDate!.subtract(const Duration(seconds: 1))) &&
                  tx.date.isBefore(_endDate!.add(const Duration(seconds: 1)));
            }).toList();
          }

          if (txProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search merchant, note, amount...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              // Category Filter Bar
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: catProvider.categories.length + 1,
                  separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final surfaceColor = AppColors.getSurface(context);
                    final borderColor = AppColors.getBorder(context);

                    if (index == 0) {
                      final isSelected = _selectedCategoryId == 'all';
                      return ChoiceChip(
                        showCheckmark: false,
                        label: const Text('All Categories'),
                        selected: isSelected,
                        backgroundColor: surfaceColor,
                        selectedColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          side: BorderSide(color: isSelected ? AppColors.primary : borderColor),
                        ),
                        labelStyle: AppTextStyles.labelSmall.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : textSecondary,
                        ),
                        onSelected: (_) => setState(() => _selectedCategoryId = 'all'),
                      );
                    }

                    final cat = catProvider.categories[index - 1];
                    final isSelected = _selectedCategoryId == cat.id;

                    return ChoiceChip(
                      showCheckmark: false,
                      avatar: Icon(
                        IconMapper.getIcon(cat.icon),
                        size: 14,
                        color: isSelected ? Colors.white : Color(int.tryParse(cat.color) ?? AppColors.primary.toARGB32()),
                      ),
                      label: Text(cat.name),
                      selected: isSelected,
                      backgroundColor: surfaceColor,
                      selectedColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        side: BorderSide(color: isSelected ? AppColors.primary : borderColor),
                      ),
                      labelStyle: AppTextStyles.labelSmall.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : textSecondary,
                      ),
                      onSelected: (_) => setState(() => _selectedCategoryId = cat.id),
                    );
                  },
                ),
              ),

              // Active Date Range Pill
              if (_startDate != null && _endDate != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.primary.withAlpha(50)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.date_range_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        GestureDetector(
                          onTap: _clearDateRange,
                          child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.xs),

              // Transaction List
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No Transactions Found',
                          subtitle: _searchQuery.isNotEmpty || _selectedCategoryId != 'all' || _startDate != null
                              ? 'Try adjusting your search keywords, category or date range.'
                              : 'Tap "+ Add Expense" below to record your first transaction.',
                          actionLabel: _searchQuery.isEmpty && _selectedCategoryId == 'all' && _startDate == null
                              ? 'Add Expense'
                              : 'Reset Filters',
                          onActionPressed: () {
                            if (_searchQuery.isNotEmpty || _selectedCategoryId != 'all' || _startDate != null) {
                              setState(() {
                                _searchQuery = '';
                                _selectedCategoryId = 'all';
                                _startDate = null;
                                _endDate = null;
                              });
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                              );
                            }
                          },
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: 90, left: AppSpacing.lg, right: AppSpacing.lg),
                        physics: const BouncingScrollPhysics(),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final category = tx.categoryId != null
                              ? catProvider.getCategoryById(tx.categoryId!)
                              : null;

                          bool showHeader = false;
                          if (index == 0) {
                            showHeader = true;
                          } else {
                            final prevTx = transactions[index - 1];
                            if (DateFormatter.formatFullDate(tx.date) != DateFormatter.formatFullDate(prevTx.date)) {
                              showHeader = true;
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showHeader)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(4, AppSpacing.md, 4, AppSpacing.xs),
                                  child: Text(
                                    DateFormatter.formatFullDate(tx.date),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              TransactionTile(
                                transaction: tx,
                                category: category,
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
