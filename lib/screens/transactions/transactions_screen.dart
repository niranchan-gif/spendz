import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/transaction_tile.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_colors.dart';
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

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear date filter',
              onPressed: _clearDateRange,
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
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
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add),
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search merchant, note, amount...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              // Category Filter Bar
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: catProvider.categories.length + 1,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedCategoryId == 'all';
                      return ChoiceChip(
                        showCheckmark: false,
                        label: const Text('All Categories'),
                        selected: isSelected,
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.background : Colors.white70,
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
                        color: isSelected ? AppColors.background : Color(int.tryParse(cat.color) ?? AppColors.primary.toARGB32()),
                      ),
                      label: Text(cat.name),
                      selected: isSelected,
                      backgroundColor: AppColors.surface,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.background : Colors.white70,
                      ),
                      onSelected: (_) => setState(() => _selectedCategoryId = cat.id),
                    );
                  },
                ),
              ),

              // Active Date Range Pill
              if (_startDate != null && _endDate != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withAlpha(50)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.date_range, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _clearDateRange,
                          child: const Icon(Icons.close, size: 14, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Transaction List
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 60, color: Colors.grey.withAlpha(90)),
                            const SizedBox(height: 16),
                            Text('No transactions match', style: AppTextStyles.heading3),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty || _selectedCategoryId != 'all' || _startDate != null
                                  ? 'Try adjusting your search or filters'
                                  : 'Tap "+ Add Expense" to record a transaction',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 90, left: 16, right: 16),
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
                                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                                  child: Text(
                                    DateFormatter.formatFullDate(tx.date),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
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
