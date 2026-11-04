import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/category_model.dart';
import '../../utils/icon_mapper.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    
    // Parse color or use default
    Color iconColor = AppColors.primary;
    if (category != null && category!.color.isNotEmpty) {
      try {
        iconColor = Color(int.parse(category!.color));
      } catch (_) {}
    }

    // Default icon
    IconData iconData = isIncome ? Icons.arrow_downward : Icons.shopping_bag;
    if (category != null) {
      iconData = IconMapper.getIcon(category!.icon);
    }

    return GestureDetector(
      onDoubleTap: () => _showCategoryPicker(context),
      onLongPress: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Transaction?'),
            content: const Text('Are you sure you want to delete this transaction?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  context.read<TransactionProvider>().deleteTransaction(transaction.id);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction deleted')),
                  );
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            onTap: onTap ?? () => _showTransactionDetails(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            title: Text(
              category?.name ?? 'Uncategorized',
              style: AppTextStyles.labelLarge,
            ),
            subtitle: Consumer<WalletProvider>(
              builder: (context, wallet, _) {
                final card = transaction.cardId != null ? wallet.getCardById(transaction.cardId!) : null;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getScrubbedName(),
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (card != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primary.withAlpha(40)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.credit_card, size: 10, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    '${card.issuerName} • ${card.lastFour}',
                                    style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Amount row — badge above if present, amount always shown
                if (transaction.expectedPayments > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: transaction.linkedPayments >= transaction.expectedPayments
                          ? Colors.green.withAlpha(30)
                          : Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: transaction.linkedPayments >= transaction.expectedPayments
                            ? Colors.green.withAlpha(50)
                            : Colors.orange.withAlpha(50),
                      ),
                    ),
                    child: Text(
                      transaction.linkedPayments >= transaction.expectedPayments
                          ? 'Settled'
                          : '${transaction.linkedPayments}/${transaction.expectedPayments} paid',
                      style: TextStyle(
                        fontSize: 9,
                        color: transaction.linkedPayments >= transaction.expectedPayments
                            ? Colors.green
                            : Colors.orange,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else if (transaction.owedAmount > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withAlpha(50)),
                    ),
                    child: Text(
                      'Owed ${CurrencyFormatter.format(transaction.owedAmount)}',
                      style: const TextStyle(fontSize: 9, color: Colors.orange),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Text(
                  '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isIncome ? AppColors.success : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.formatTime(transaction.date),
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  void _showCategoryPicker(BuildContext context) {
    final catProvider = context.read<CategoryProvider>();
    final isIncome = transaction.type == 'income';
    final categories = isIncome ? catProvider.incomeCategories : catProvider.expenseCategories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Column(
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Assign Category', style: AppTextStyles.heading3),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: categories.length,
                      itemBuilder: (ctx, index) {
                        final cat = categories[index];
                        final color = Color(int.tryParse(cat.color) ?? AppColors.primary.toARGB32());
                        return ListTile(
                          leading: Icon(IconMapper.getIcon(cat.icon), color: color),
                          title: Text(cat.name, style: AppTextStyles.bodyMedium),
                          onTap: () {
                            final updatedTx = transaction.copyWith(categoryId: cat.id);
                            context.read<TransactionProvider>().updateTransaction(updatedTx);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getScrubbedName() {
    String? rawName = transaction.merchant;
    if (rawName == null || rawName.isEmpty || rawName == 'Unknown Merchant') {
      rawName = transaction.description;
    }
    rawName ??= 'Unknown';

    if (transaction.type == 'income') {
      // Try to extract a standard UPI ID / VPA (e.g. username@bank)
      final upiMatch = RegExp(r'[a-zA-Z0-9.\-_]+@[a-zA-Z0-9]+').firstMatch(rawName);
      if (upiMatch != null) {
        return upiMatch.group(0)!;
      }
    }

    String scrubbed = rawName.replaceAll(RegExp(r'\d{5,}'), ''); // Remove 5+ digits (account numbers, phone numbers)
    scrubbed = scrubbed.replaceAll(RegExp(r'@[a-zA-Z0-9.]+'), ''); // Remove @bank extensions
    scrubbed = scrubbed.replaceAll(RegExp(r'UPI-?'), ''); // Remove UPI prefix
    // Clean up extra spaces or punctuation
    scrubbed = scrubbed.replaceAll(RegExp(r'[^\w\s]'), ' ').trim();
    if (scrubbed.isEmpty) scrubbed = 'Unknown';
    
    final lower = scrubbed.toLowerCase();
    if (lower.contains('tamilnadu state transpo')) {
      return 'Tamilnadu State Transport Corporation';
    }
    if (lower.contains('metropolitan transpo')) {
      return 'Metropolitan Transport Corporation';
    }
    
    return scrubbed;
  }

  void _showTransactionDetails(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final scrubbed = _getScrubbedName();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIncome ? 'Source of Income' : 'Payment Destination'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scrubbed,
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            Text(
              'Amount: ${CurrencyFormatter.format(transaction.amount)}',
              style: AppTextStyles.bodyLarge.copyWith(
                color: isIncome ? AppColors.success : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${DateFormatter.formatShortDate(transaction.date)}',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
        actions: [
          if (isIncome)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showExpensePicker(context);
              },
              child: const Text('Link to Expense', style: TextStyle(color: Colors.blue)),
            )
          else if (transaction.type == 'expense')
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showSplitDialog(context);
              },
              child: const Text('Mark as Split', style: TextStyle(color: Colors.orange)),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showCategoryPicker(context);
            },
            child: const Text('Change Category'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  void _showSplitDialog(BuildContext context) {
    final TextEditingController peopleController = TextEditingController(
      text: transaction.expectedPayments > 0 ? transaction.expectedPayments.toString() : '',
    );
    final TextEditingController amountController = TextEditingController(
      text: transaction.owedAmount > 0 ? transaction.owedAmount.toString() : '',
    );

    final txProvider = context.read<TransactionProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Split Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Original Amount: ${CurrencyFormatter.format(transaction.amount)}'),
            const SizedBox(height: 16),
            TextField(
              controller: peopleController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of people paying you',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total Amount Owed to you',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final peopleStr = peopleController.text.trim();
              int expected = 0;
              if (peopleStr.isNotEmpty) {
                expected = int.tryParse(peopleStr) ?? 0;
              }

              final amountStr = amountController.text.trim();
              double owed = 0.0;
              if (amountStr.isNotEmpty) {
                owed = double.tryParse(amountStr) ?? 0.0;
              }

              if (owed > transaction.amount) {
                owed = transaction.amount;
              }

              final updatedTx = transaction.copyWith(
                owedAmount: owed,
                expectedPayments: expected,
                linkedPayments: 0,
              );
              txProvider.updateTransaction(updatedTx);
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Expense marked as split. Expected refund: ${CurrencyFormatter.format(owed)} from $expected people')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showExpensePicker(BuildContext context) {
    final txProvider = context.read<TransactionProvider>();
    final recentExpenses = txProvider.transactions
        .where((t) => t.type == 'expense' && t.owedAmount > 0 && t.id != transaction.id)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Column(
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Select Expense to Offset', style: AppTextStyles.heading3),
                  ),
                  Expanded(
                    child: recentExpenses.isEmpty
                        ? const Center(child: Text('No recent expenses found.'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: recentExpenses.length,
                            itemBuilder: (ctx, index) {
                              final expense = recentExpenses[index];
                              return ListTile(
                                title: Text(expense.merchant ?? expense.description ?? 'Unknown Expense', style: AppTextStyles.bodyMedium),
                                subtitle: Text(DateFormatter.formatShortDate(expense.date), style: AppTextStyles.bodySmall),
                                trailing: Text(
                                  CurrencyFormatter.format(expense.amount),
                                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                                ),
                                onTap: () {
                                  final newExpenseAmount = (expense.amount - transaction.amount).clamp(0.0, double.infinity);
                                  final newOwedAmount = (expense.owedAmount - transaction.amount).clamp(0.0, double.infinity);
                                  final newLinkedPayments = expense.linkedPayments + 1;
                                  final updatedExpense = expense.copyWith(
                                    amount: newExpenseAmount,
                                    owedAmount: newOwedAmount,
                                    linkedPayments: newLinkedPayments,
                                    description: '${expense.description ?? ''} (Refunded ${CurrencyFormatter.format(transaction.amount)} from ${transaction.merchant ?? 'Income'})',
                                  );
                                  txProvider.updateTransaction(updatedExpense);
                                  final updatedIncome = transaction.copyWith(
                                    type: 'refund',
                                    description: 'Linked refund to ${expense.merchant ?? expense.description ?? 'expense'}',
                                  );
                                  txProvider.updateTransaction(updatedIncome);
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Linked to expense! Amount reduced to ${CurrencyFormatter.format(newExpenseAmount)}.')),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

