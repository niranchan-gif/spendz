import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category_model.dart';
import '../../utils/icon_mapper.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import 'glass_container.dart';

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
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        borderRadius: 20,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onTap: onTap ?? () => _showTransactionDetails(context),
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
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _getScrubbedName(),
              style: AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isIncome ? AppColors.success : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormatter.formatTime(transaction.date),
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
              ),
            ],
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
            return Column(
              children: [
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
                      final color = Color(int.tryParse(cat.color) ?? AppColors.primary.value);
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
}
