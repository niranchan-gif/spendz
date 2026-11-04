import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../providers/transaction_provider.dart';
import '../../database/database_helper.dart';
import '../categories/categories_screen.dart';
import '../../widgets/design_system/reusable_card.dart';
import '../../widgets/design_system/section_header.dart';
import '../../widgets/design_system/custom_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const BouncingScrollPhysics(),
        children: [
          SectionHeader(title: 'Recently Added'),
          const SizedBox(height: AppSpacing.xs),
          Consumer<TransactionProvider>(
            builder: (context, txProvider, child) {
              final transactions = txProvider.transactions;
              if (transactions.isEmpty) {
                return ReusableCard(
                  padding: const EdgeInsets.all(AppSpacing.card),
                  child: Center(
                    child: Text(
                      'No transactions yet.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                );
              }

              final sorted = List.of(transactions)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              final recent = sorted.first;

              return ReusableCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color:
                          (recent.type == 'expense'
                                  ? AppColors.error
                                  : AppColors.success)
                              .withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      recent.type == 'expense'
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: recent.type == 'expense'
                          ? AppColors.error
                          : AppColors.success,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    recent.merchant ?? 'Unknown Merchant',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    recent.description ?? '',
                    style: AppTextStyles.caption.copyWith(color: textSecondary),
                  ),
                  trailing: Text(
                    '₹${recent.amount.toStringAsFixed(2)}',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: recent.type == 'expense'
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: 'Preferences'),
          const SizedBox(height: AppSpacing.xs),
          ReusableCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(
                Icons.category_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                'Manage Categories',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Customize category labels, icons and colors',
                style: AppTextStyles.caption.copyWith(color: textSecondary),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoriesScreen(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: 'Data & Storage'),
          const SizedBox(height: AppSpacing.xs),
          ReusableCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              title: Text(
                'Clear All Data',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
              subtitle: Text(
                'Delete local database transactions and reset preferences',
                style: AppTextStyles.caption.copyWith(color: textSecondary),
              ),
              onTap: () async {
                final confirm = await CustomDialog.showConfirmation(
                  context: context,
                  title: 'Clear All Data?',
                  message:
                      'This will delete all your transactions and settings. This action cannot be undone.',
                  confirmLabel: 'Clear All Data',
                  isDestructive: true,
                  icon: Icons.warning_amber_rounded,
                );

                if (confirm == true && context.mounted) {
                  await DatabaseHelper.instance.clearAllTransactions();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (context.mounted) {
                    context.read<TransactionProvider>().loadTransactions();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All data cleared successfully.'),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
