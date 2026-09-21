import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../providers/gmail_import_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/imported_transaction.dart';
import '../../models/transaction_model.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class ImportReviewScreen extends StatefulWidget {
  const ImportReviewScreen({super.key});

  @override
  State<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends State<ImportReviewScreen> {
  @override
  void initState() {
    super.initState();
    // Start fetching when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GmailImportProvider>().reloadTransactions();
    });
  }

  void _handleAdd(ImportedTransaction tx) async {
    final txProvider = context.read<TransactionProvider>();
    final importProvider = context.read<GmailImportProvider>();

    final isExpense = tx.type.toUpperCase() == 'DEBIT';

    final transaction = TransactionModel(
      id: const Uuid().v4(),
      amount: tx.amount,
      type: isExpense ? 'expense' : 'income',
      merchant: tx.name,
      description: 'Imported from Gmail',
      date: tx.date,
      source: 'bank_email',
      bankName: tx.source,
      referenceId: tx.reference,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await txProvider.addTransaction(transaction);
    if (!mounted) return;
    
    importProvider.removeTransaction(tx);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction added successfully!')),
    );
  }

  void _handleIgnore(ImportedTransaction tx) {
    context.read<GmailImportProvider>().removeTransaction(tx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from Gmail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload from Gmail',
            onPressed: () {
              context.read<GmailImportProvider>().reloadTransactions();
            },
          ),
        ],
      ),
      body: Consumer<GmailImportProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Checking Gmail...', style: AppTextStyles.bodyMedium),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Failed to import', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    Text(provider.error!, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.reloadTransactions(),
                      child: const Text('Try Again'),
                    )
                  ],
                ),
              ),
            );
          }

          final newTxList = provider.newTransactions;

          if (newTxList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
                  const SizedBox(height: 16),
                  Text('All caught up!', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  Text('No new transactions found.', style: AppTextStyles.bodyMedium),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: AppColors.primary.withAlpha(20),
                child: Text(
                  '${newTxList.length} new transactions found',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: newTxList.length,
                  itemBuilder: (context, index) {
                    final tx = newTxList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
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
                                  '₹${tx.amount.toStringAsFixed(2)}',
                                  style: AppTextStyles.heading3.copyWith(
                                    color: tx.type.toUpperCase() == 'DEBIT' ? AppColors.error : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('dd MMM yyyy').format(tx.date)} • ${tx.type.toUpperCase()}',
                              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ref: ${tx.reference} • Source: ${tx.source}',
                              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _handleIgnore(tx),
                                  style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                                  child: const Text('Ignore'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _handleAdd(tx),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.background,
                                  ),
                                  child: const Text('Add / Confirm'),
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
