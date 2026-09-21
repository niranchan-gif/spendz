import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/transaction_provider.dart';
import '../../database/database_helper.dart';
import '../categories/categories_screen.dart';
import '../../widgets/glass_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
              Text('Recently Added', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              Consumer<TransactionProvider>(
                builder: (context, txProvider, child) {
                  final transactions = txProvider.transactions;
                  if (transactions.isEmpty) {
                    return GlassContainer(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('No transactions yet.', style: AppTextStyles.bodyMedium),
                      ),
                    );
                  }
                  
                  // Sort by createdAt descending to get the most recently added one
                  final sorted = List.of(transactions)
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  final recent = sorted.first;
                  
                  return GlassContainer(
                    child: ListTile(
                      leading: Icon(
                        recent.type == 'expense' ? Icons.arrow_downward : Icons.arrow_upward,
                        color: recent.type == 'expense' ? AppColors.error : AppColors.success,
                      ),
                      title: Text(recent.merchant ?? 'Unknown Merchant', style: AppTextStyles.bodyLarge),
                      subtitle: Text(recent.description ?? '', style: AppTextStyles.bodySmall),
                      trailing: Text(
                        '₹${recent.amount.toStringAsFixed(2)}',
                        style: AppTextStyles.heading3.copyWith(
                          color: recent.type == 'expense' ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              Text('Preferences', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              GlassContainer(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.category_outlined, color: AppColors.primary),
                      title: const Text('Manage Categories'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CategoriesScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text('Data & Export', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              GlassContainer(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                      title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Clear All Data?'),
                            content: const Text('This will delete all your transactions and settings. This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await DatabaseHelper.instance.clearAllTransactions();
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.clear();
                                  if (context.mounted) {
                                    context.read<TransactionProvider>().loadTransactions();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('All data cleared successfully.')),
                                    );
                                  }
                                },
                                child: const Text('Clear', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              Center(
                child: Text(
                  'Spendz v1.0.0\nMade with Flutter',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
    );
  }



}
