import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/gmail_import_provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_text_styles.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/design_system/reusable_card.dart';
import '../../widgets/design_system/empty_state.dart';
import '../../widgets/design_system/financial_summary_card.dart';
import '../transactions/transactions_screen.dart';
import '../transactions/imported_transactions_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../wallet/widgets/spendz_pop_sheet.dart';
import '../../utils/currency_formatter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await context.read<TransactionProvider>().loadTransactions();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header greeting & sync status
                _buildHeader(context),
                const SizedBox(height: AppSpacing.lg),

                // 2. Slide To Sync (HDFC Gmail)
                const SlideToSyncBanner(),
                const SizedBox(height: AppSpacing.lg),

                // 3. Financial Overview & Monthly Expenses
                _buildMonthlyOverview(context),
                const SizedBox(height: AppSpacing.xl),

                // 4. Quick Actions
                _buildQuickActions(context),
                const SizedBox(height: AppSpacing.xl),

                // 5. Recent Transactions & Pending Splits
                _buildRecentTransactions(context),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.getTextSecondary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Spendz Overview',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.getTextPrimary(context),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withAlpha(35)
                : AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: AppColors.primary.withAlpha(60),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Live Vault',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyOverview(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, child) {
        return FinancialSummaryCard(
          netBalance: dashboard.totalBalance,
          income: dashboard.monthlyIncome,
          expenses: dashboard.monthlyExpenses,
          owedToMe: dashboard.totalOwed,
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionItem(
          context: context,
          icon: Icons.add_rounded,
          label: 'Add Expense',
          color: AppColors.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
            );
          },
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildActionItem(
          context: context,
          icon: Icons.sync_rounded,
          label: 'HDFC Sync',
          color: AppColors.accent,
          onTap: () {
            Navigator.pushNamed(context, '/import-review');
          },
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildActionItem(
          context: context,
          icon: Icons.bolt_rounded,
          label: 'POP Wallet',
          color: AppColors.warning,
          onTap: () => SpendzPopSheet.show(context),
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildActionItem(
          context: context,
          icon: Icons.receipt_long_rounded,
          label: 'Activity',
          color: AppColors.info,
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
    required Color color,
    required VoidCallback onTap,
  }) {
    final surfaceColor = AppColors.getSurface(context);
    final borderColor = AppColors.getBorder(context);
    final textColor = AppColors.getTextPrimary(context);

    return Expanded(
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: color.withAlpha(28),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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

class _RecentTransactionsTabsState extends State<_RecentTransactionsTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
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
            .where((t) => t.owedAmount == 0)
            .take(5)
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
                    indicatorWeight: 3,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.getTextSecondary(context),
                    labelStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                    unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w500),
                    tabs: [
                      const Tab(text: 'Recent'),
                      Tab(
                        text: totalOwed > 0
                            ? 'Pending Splits (${pendingSplits.length} • ${CurrencyFormatter.format(totalOwed)})'
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
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    child: const Text('See All'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (currentList.isEmpty)
              EmptyState(
                icon: _tabController.index == 0
                    ? Icons.receipt_long_outlined
                    : Icons.people_outline_rounded,
                title: _tabController.index == 0
                    ? 'No Recent Transactions'
                    : 'No Pending Splits',
                subtitle: _tabController.index == 0
                    ? 'Add an expense or sync your Gmail HDFC alerts to see your recent transactions.'
                    : 'Split expenses with friends and track reimbursements directly from Spendz.',
                actionLabel: _tabController.index == 0 ? 'Add Transaction' : null,
                onActionPressed: _tabController.index == 0
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                        );
                      }
                    : null,
              )
            else
              ReusableCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentList.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    indent: 72,
                    color: AppColors.getBorder(context),
                  ),
                  itemBuilder: (context, index) {
                    final tx = currentList[index];
                    final category = tx.categoryId != null
                        ? catProvider.getCategoryById(tx.categoryId!)
                        : null;

                    return TransactionTile(
                      transaction: tx,
                      category: category,
                    );
                  },
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

class _SlideToSyncBannerState extends State<SlideToSyncBanner>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  late double _maxDrag;
  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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
          SnackBar(
            content: Text('Sync Failed: ${importProvider.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const bannerWidth = 144.0;
        _maxDrag = (constraints.maxWidth - bannerWidth - 8).clamp(0.0, double.infinity);

        return Consumer2<GmailImportProvider, CategoryProvider>(
          builder: (context, importProvider, categoryProvider, child) {
            final isSyncing = importProvider.isLoading;
            final isDark = Theme.of(context).brightness == Brightness.dark;

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

                      _snapAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
                        CurvedAnimation(parent: _snapController, curve: Curves.easeOutBack),
                      );
                      _snapController.forward(from: 0.0);
                    },
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                AppColors.primary.withAlpha(25),
                                AppColors.primary.withAlpha(55),
                              ]
                            : [
                                AppColors.primary.withAlpha(15),
                                AppColors.primary.withAlpha(35),
                              ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      border: Border.all(
                        color: AppColors.getBorder(context),
                        width: 1,
                      ),
                      boxShadow: AppShadows.card(context),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    child: Opacity(
                      opacity: isSyncing ? 1.0 : (_maxDrag > 0 ? (_dragOffset / (_maxDrag * 0.7)).clamp(0.0, 1.0) : 1.0),
                      child: isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : Text(
                              'Release to Sync',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
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
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isSyncing ? 10 : 35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
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
