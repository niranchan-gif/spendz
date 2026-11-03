import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/gmail_import_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/imported_transaction.dart';
import '../../models/category_model.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../utils/icon_mapper.dart';
import '../../services/category_engine.dart';

class ImportedTransactionsScreen extends StatelessWidget {
  const ImportedTransactionsScreen({super.key});

  void _showCategoryPicker(BuildContext context, ImportedTransaction tx, CategoryProvider categoryProvider, GmailImportProvider importProvider) {
    final categories = tx.type.toUpperCase() == 'CREDIT' 
        ? categoryProvider.incomeCategories 
        : categoryProvider.expenseCategories;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Select Category', style: AppTextStyles.heading3),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (ctx, index) {
                  final cat = categories[index];
                  return ListTile(
                    leading: Icon(
                      IconMapper.getIcon(cat.icon),
                      color: Color(int.parse(cat.color)),
                    ),
                    title: Text(cat.name, style: AppTextStyles.bodyLarge),
                    onTap: () {
                      importProvider.updateCategory(tx.reference, cat.id);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Transactions'),
        actions: [
          Consumer2<GmailImportProvider, TransactionProvider>(
            builder: (context, importProvider, txProvider, child) {
              if (importProvider.newTransactions.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () async {
                  final added = await importProvider.approveAll(txProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Successfully added $added transactions!')),
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text('Approve All', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
              );
            },
          )
        ],
      ),
      body: Consumer3<GmailImportProvider, TransactionProvider, CategoryProvider>(
        builder: (context, importProvider, txProvider, categoryProvider, child) {
          if (importProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text('Processing transactions...', style: AppTextStyles.bodyMedium),
                ],
              ),
            );
          }

          if (importProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Sync Failed', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    Text(importProvider.error!, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => importProvider.reloadTransactions(categoryProvider),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      child: const Text('Try Again'),
                    )
                  ],
                ),
              ),
            );
          }

          final txList = importProvider.newTransactions;

          if (txList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
                  const SizedBox(height: 16),
                  Text('All caught up!', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  Text('No new transactions for today.', style: AppTextStyles.bodyMedium),
                ],
              ),
            );
          }

          final dateFormat = DateFormat('MMM d');
          final rangeStr = (importProvider.syncRangeStart != null && importProvider.syncRangeEnd != null)
              ? '${dateFormat.format(importProvider.syncRangeStart!)} - ${dateFormat.format(importProvider.syncRangeEnd!)}'
              : 'Unknown Range';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Transactions from $rangeStr',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600], fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: txList.length,
                  itemBuilder: (context, index) {
                    final tx = txList[index];
                    final isExpense = tx.type.toUpperCase() == 'DEBIT';
                    final isParent = CategoryEngine.isParentTransfer(tx.name);
                    
                    CategoryModel? category;
                    if (tx.suggestedCategoryId != null) {
                      category = categoryProvider.getCategoryById(tx.suggestedCategoryId!);
                    }

                    Color amountColor = isParent ? Colors.blue : (isExpense ? AppColors.error : AppColors.success);
                    String amountPrefix = isParent ? '+' : (isExpense ? '-' : '+');

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    tx.name,
                                    style: AppTextStyles.heading3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '$amountPrefix ₹${tx.amount.toStringAsFixed(2)}',
                                  style: AppTextStyles.heading3.copyWith(
                                    color: amountColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  category != null ? IconMapper.getIcon(category.icon) : Icons.help_outline,
                                  size: 16,
                                  color: category != null ? Color(int.parse(category.color)) : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  category?.name ?? 'Unknown Category',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: category != null ? Color(int.parse(category.color)) : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (isParent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withAlpha(40),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'PARENT TRANSFER',
                                      style: AppTextStyles.bodySmall.copyWith(color: Colors.blue, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                Text(
                                  '${DateFormat('dd MMM yyyy').format(tx.date)} • ${tx.type.toUpperCase()}',
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                      Text(
                        'Ref: ${tx.reference} • Source: ${tx.source}',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _showCategoryPicker(context, tx, categoryProvider, importProvider),
                            child: const Text('Change Category'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              await importProvider.approveTransaction(tx.reference, txProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Transaction added!')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
