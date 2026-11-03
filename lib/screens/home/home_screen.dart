import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/gmail_import_provider.dart';
import '../../app/theme/app_text_styles.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/glass_container.dart';
import '../transactions/transactions_screen.dart';
import '../transactions/imported_transactions_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../wallet/widgets/spendz_pop_sheet.dart';
import '../../app/theme/app_colors.dart';
import '../../utils/currency_formatter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Slide To Sync (HDFC Gmail)
              const SlideToSyncBanner(),
              const SizedBox(height: 20),

              // 2. Financial Overview & Monthly Expenses
              _buildMonthlyOverview(context),
              const SizedBox(height: 20),

              // 3. Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // 4. Recent Transactions & Pending Splits
              _buildRecentTransactions(context),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyOverview(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, child) {
        final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

        return GlassContainer(
          padding: const EdgeInsets.all(22),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Month badge and balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withAlpha(50)),
                    ),
                    child: Text(
                      currentMonth,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        'Net Balance: ${CurrencyFormatter.format(dashboard.totalBalance)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: dashboard.totalBalance >= 0 ? Colors.white70 : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Main Expense Amount
              Text(
                'This Month\'s Expenses',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(dashboard.monthlyExpenses),
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 20),

              // Secondary metrics: Received vs Owed
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(40),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_downward, color: AppColors.success, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Received', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(dashboard.monthlyIncome),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(40),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.people_alt_outlined, color: Colors.orange, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Owed to Me', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(dashboard.totalOwed),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionItem(
          context: context,
          icon: Icons.add_circle_outline,
          label: 'Add Expense',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
        _buildActionItem(
          context: context,
          icon: Icons.sync_rounded,
          label: 'HDFC Sync',
          onTap: () {
            Navigator.pushNamed(context, '/import-review');
          },
        ),
        const SizedBox(width: 8),
        _buildActionItem(
          context: context,
          icon: Icons.bolt_rounded,
          label: 'POP Wallet',
          onTap: () => SpendzPopSheet.show(context),
        ),
        const SizedBox(width: 8),
        _buildActionItem(
          context: context,
          icon: Icons.receipt_long_outlined,
          label: 'Activity',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return const _RecentTransactionsTabs();
  }
}

class _RecentTransactionsTabs extends StatefulWidget {
  const _RecentTransactionsTabs();

  @override
  State<_RecentTransactionsTabs> createState() => _RecentTransactionsTabsState();
}

class _RecentTransactionsTabsState extends State<_RecentTransactionsTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, CategoryProvider>(
      builder: (context, txProvider, catProvider, child) {
        final pendingSplits = txProvider.transactions.where((t) => t.owedAmount > 0).toList();
        final totalOwed = pendingSplits.fold(0.0, (sum, t) => sum + t.owedAmount);
        final recentTransactions = txProvider.transactions
            .where((t) => t.owedAmount == 0) // Exclude pending splits
            .take(5) // Limit to 5
            .toList();
        
        final currentList = _tabController.index == 0 ? recentTransactions : pendingSplits;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerColor: Colors.transparent,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.white54,
                    tabs: [
                      const Tab(text: 'Recent'),
                      Tab(
                        text: totalOwed > 0
                            ? 'Pending Splits (${pendingSplits.length} • ₹${totalOwed.toStringAsFixed(0)})'
                            : 'Pending Splits (${pendingSplits.length})',
                      ),
                    ],
                  ),
                ),
                if (_tabController.index == 0)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TransactionsScreen()),
                      );
                    },
                    child: const Text('See All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (currentList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    _tabController.index == 0 ? 'No recent transactions' : 'No pending splits', 
                    style: AppTextStyles.bodyMedium
                  ),
                ),
              )
            else
              GlassContainer(
                child: Column(
                  children: currentList.map((tx) {
                    final category = tx.categoryId != null 
                        ? catProvider.getCategoryById(tx.categoryId!) 
                        : null;
                        
                    return Column(
                      children: [
                        TransactionTile(
                          transaction: tx,
                          category: category,
                        ),
                        if (tx != currentList.last)
                          const Divider(height: 1, indent: 72),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }
}

class SlideToSyncBanner extends StatefulWidget {
  const SlideToSyncBanner({super.key});

  @override
  State<SlideToSyncBanner> createState() => _SlideToSyncBannerState();
}

class _SlideToSyncBannerState extends State<SlideToSyncBanner> with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  late double _maxDrag;
  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _snapController.addListener(() {
      setState(() {
        _dragOffset = _snapAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _triggerSync(GmailImportProvider importProvider, CategoryProvider categoryProvider) async {
    await importProvider.reloadTransactions(categoryProvider);
    if (mounted) {
      if (importProvider.error == null) {
        if (importProvider.newTransactions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No new transactions found today.')),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ImportedTransactionsScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Failed: ${importProvider.error}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bannerWidth = 144.0;
        _maxDrag = constraints.maxWidth - bannerWidth - 8;

        return Consumer2<GmailImportProvider, CategoryProvider>(
          builder: (context, importProvider, categoryProvider, child) {
            final isSyncing = importProvider.isLoading;
            
            return GestureDetector(
              onHorizontalDragUpdate: isSyncing
                  ? null
                  : (details) {
                      setState(() {
                        _dragOffset += details.primaryDelta!;
                        if (_dragOffset < 0) _dragOffset = 0;
                        if (_dragOffset > _maxDrag) _dragOffset = _maxDrag;
                      });
                    },
              onHorizontalDragEnd: isSyncing
                  ? null
                  : (details) {
                      if (_dragOffset > _maxDrag * 0.7) {
                        _triggerSync(importProvider, categoryProvider);
                      }
                      
                      _snapAnimation = Tween<double>(begin: _dragOffset, end: 0.0)
                          .animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOutBack));
                      _snapController.forward(from: 0.0);
                    },
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryDark.withAlpha(20),
                          AppColors.primaryDark.withAlpha(60),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      border: Border.all(color: Colors.white.withAlpha(30), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Opacity(
                      opacity: isSyncing ? 1.0 : (_dragOffset / (_maxDrag * 0.7)).clamp(0.0, 1.0),
                      child: isSyncing
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
                            )
                          : Text(
                              'Release to Sync', 
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary, 
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: AppColors.primary.withAlpha(100),
                                    blurRadius: 10,
                                  )
                                ],
                              ),
                            ),
                    ),
                  ),
                  
                  Transform.translate(
                    offset: Offset(_dragOffset, 0),
                    child: Container(
                      height: 48,
                      width: bannerWidth,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isSyncing ? 10 : 30),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/banner.png',
                          fit: BoxFit.contain,
                        ),
                      ),
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
