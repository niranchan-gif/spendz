import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/gmail_import_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/imported_transaction.dart';
import '../../models/category_model.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_text_styles.dart';
import '../../utils/icon_mapper.dart';
import '../../services/category_engine.dart';
import '../../widgets/design_system/reusable_card.dart';
import '../../widgets/design_system/app_bottom_sheet.dart';
import '../../widgets/design_system/empty_state.dart';
import '../../widgets/design_system/loading_state.dart';
import '../../widgets/design_system/error_state.dart';

class ImportedTransactionsScreen extends StatelessWidget {
  const ImportedTransactionsScreen({super.key});

  void _showCategoryPicker(
    BuildContext context,
    ImportedTransaction tx,
    CategoryProvider categoryProvider,
    GmailImportProvider importProvider,
  ) {
    final categories = tx.type.toUpperCase() == 'CREDIT'
        ? categoryProvider.incomeCategories
        : categoryProvider.expenseCategories;

    AppBottomSheet.show(
      context: context,
      title: 'Select Category',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: AppColors.getBorder(context),
        ),
        itemBuilder: (ctx, index) {
          final cat = categories[index];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.xs + 2),
              decoration: BoxDecoration(
                color: Color(int.parse(cat.color)).withAlpha(25),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                IconMapper.getIcon(cat.icon),
                color: Color(int.parse(cat.color)),
                size: 20,
              ),
            ),
            title: Text(
              cat.name,
              style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              importProvider.updateCategory(tx.reference, cat.id);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textSecondary = AppColors.getTextSecondary(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                      SnackBar(
                        content: Text('Successfully added $added transactions!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'Approve All',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: Consumer3<GmailImportProvider, TransactionProvider, CategoryProvider>(
        builder: (context, importProvider, txProvider, categoryProvider, child) {
          if (importProvider.isLoading) {
            return const LoadingState(
              message: 'Processing Gmail HDFC transaction alerts...',
            );
          }

          if (importProvider.error != null) {
            return ErrorState(
              title: 'Gmail Sync Failed',
              message: importProvider.error!,
              onRetry: () => importProvider.reloadTransactions(categoryProvider),
            );
          }

          final txList = importProvider.newTransactions;

          if (txList.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: 'All Caught Up!',
                subtitle: 'No new unapproved transactions found in your Gmail inbox.',
                actionLabel: 'Check Activity',
                onActionPressed: () => Navigator.pop(context),
              ),
            );
          }

          final dateFormat = DateFormat('MMM d');
          final rangeStr = (importProvider.syncRangeStart != null && importProvider.syncRangeEnd != null)
              ? '${dateFormat.format(importProvider.syncRangeStart!)} - ${dateFormat.format(importProvider.syncRangeEnd!)}'
              : 'Recent Period';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Transactions from $rangeStr',
                      style: AppTextStyles.caption.copyWith(
                        color: textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  physics: const BouncingScrollPhysics(),
                  itemCount: txList.length,
                  itemBuilder: (context, index) {
                    final tx = txList[index];
                    final isExpense = tx.type.toUpperCase() == 'DEBIT';
                    final isParent = CategoryEngine.isParentTransfer(tx.name);

                    CategoryModel? category;
                    if (tx.suggestedCategoryId != null) {
                      category = categoryProvider.getCategoryById(tx.suggestedCategoryId!);
                    }

                    final amountColor = isParent
                        ? AppColors.info
                        : (isExpense ? AppColors.error : AppColors.success);
                    final amountPrefix = isParent ? '+' : (isExpense ? '-' : '+');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ReusableCard(
                        padding: const EdgeInsets.all(AppSpacing.card),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    tx.name,
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  '$amountPrefix ₹${tx.amount.toStringAsFixed(2)}',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: amountColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Icon(
                                  category != null ? IconMapper.getIcon(category.icon) : Icons.help_outline_rounded,
                                  size: 14,
                                  color: category != null ? Color(int.parse(category.color)) : textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  category?.name ?? 'Unknown Category',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: category != null ? Color(int.parse(category.color)) : textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                if (isParent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.info.withAlpha(25),
                                      borderRadius: BorderRadius.circular(AppRadius.xs),
                                    ),
                                    child: Text(
                                      'PARENT TRANSFER',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.info,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                Text(
                                  '${DateFormat('dd MMM yyyy').format(tx.date)} • ${tx.type.toUpperCase()}',
                                  style: AppTextStyles.caption.copyWith(color: textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ref: ${tx.reference} • Source: ${tx.source}',
                              style: AppTextStyles.caption.copyWith(color: textSecondary.withAlpha(140), fontSize: 10),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _showCategoryPicker(context, tx, categoryProvider, importProvider),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                  ),
                                  child: const Text('Change Category'),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                ElevatedButton(
                                  onPressed: () async {
                                    await importProvider.approveTransaction(tx.reference, txProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Transaction approved!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
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
