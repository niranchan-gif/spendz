import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/transaction_tile.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_colors.dart';
import '../../utils/date_formatter.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

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
        title: const Text('All Transactions'),
        actions: [
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear filter',
              onPressed: _clearDateRange,
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by date',
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Import from Gmail',
            onPressed: () {
              Navigator.pushNamed(context, '/import-review');
            },
          ),
        ],
      ),
      body: Consumer2<TransactionProvider, CategoryProvider>(
        builder: (context, txProvider, catProvider, child) {
          var transactions = txProvider.transactions;

          // Apply date filter if set
          if (_startDate != null && _endDate != null) {
            transactions = transactions.where((tx) {
              return tx.date.isAfter(_startDate!.subtract(const Duration(seconds: 1))) && 
                     tx.date.isBefore(_endDate!.add(const Duration(seconds: 1)));
            }).toList();
          }

          if (txProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              if (_startDate != null && _endDate != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: AppColors.primary.withAlpha(20),
                  child: Text(
                    'Showing: ${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
                    textAlign: TextAlign.center,
                  ),
                ),
                
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey.withAlpha(100)),
                            const SizedBox(height: 16),
                            Text('No transactions found', style: AppTextStyles.heading3),
                            const SizedBox(height: 8),
                            Text(_startDate != null ? 'Try adjusting your date filter' : 'Tap + to add a transaction', style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 100, left: 16, right: 16),
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
                                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                                  child: Text(
                                    DateFormatter.formatFullDate(tx.date),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              TransactionTile(
                                transaction: tx,
                                category: category,
                              ),
                              const Divider(height: 1, indent: 72),
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
