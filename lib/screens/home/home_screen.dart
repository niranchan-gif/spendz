import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/gmail_import_provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../widgets/glass/glass.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/design_system/empty_state.dart';
import '../../widgets/design_system/financial_summary_card.dart';
import '../transactions/transactions_screen.dart';
import '../transactions/imported_transactions_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../wallet/cards_screen.dart';
import '../wallet/widgets/spendz_pop_sheet.dart';
import '../../utils/currency_formatter.dart';

/// Spendz 2.0 Editorial Glassmorphism Dashboard.
/// Rebuilt from scratch with minimal glassmorphism, clear visual hierarchy,
/// emerald cashflow indicators, and responsive whitespace.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.getEmeraldAccent(context),
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
                // 1. Editorial Header (Branding, Greeting, Vault Status)
                _buildEditorialHeader(context),
                const SizedBox(height: AppSpacing.lg),

                // 2. Financial Hero Glass Panel
                _buildFinancialHero(context),
                const SizedBox(height: AppSpacing.lg),

                // 3. Floating Glass Quick Actions Dock
                _buildQuickActionDock(context),
                const SizedBox(height: AppSpacing.lg),

                // 4. Slide To Sync (HDFC Gmail Live Ingestion)
                const SlideToSyncBanner(),
                const SizedBox(height: AppSpacing.xl),

                // 5. Recent Activity & Pending Splits
                _buildRecentTransactionsSection(context),
                const SizedBox(height: 100), // Spacing for floating bottom bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorialHeader(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    final isDark = AppColors.isDark(context);
    final emerald = AppColors.getEmeraldAccent(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: emerald,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: emerald.withAlpha(140),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SPENDZ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
                      color: emerald,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                greeting,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getTextPrimary(context),
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // Live Vault Security Status Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1B3025).withAlpha(160)
                : Colors.white.withAlpha(200),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: isDark
                  ? emerald.withAlpha(50)
                  : AppColors.getBorder(context),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 30 : 10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 14, color: emerald),
              const SizedBox(width: 5),
              Text(
                'Live Vault',
                style: TextStyle(
                  color: isDark ? emerald : AppColors.primaryLightMode,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialHero(BuildContext context) {
    return Consumer2<DashboardProvider, TransactionProvider>(
      builder: (context, dashboard, txProvider, child) {
        final now = DateTime.now();
        final days = List.generate(
          7,
          (i) => now.subtract(Duration(days: 6 - i)),
        );
        final trend = days.map((d) {
          return txProvider.transactions
              .where(
                (t) =>
                    t.type == 'expense' &&
                    t.date.year == d.year &&
                    t.date.month == d.month &&
                    t.date.day == d.day,
              )
              .fold(0.0, (sum, t) => sum + t.amount);
        }).toList();

        return FinancialSummaryCard(
          netBalance: dashboard.totalBalance,
          income: dashboard.monthlyIncome,
          expenses: dashboard.monthlyExpenses,
          owedToMe: dashboard.totalOwed,
          weeklyTrend: trend,
          onAnalyticsTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionsScreen()),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActionDock(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          GlassActionButton(
            icon: Icons.add_rounded,
            label: 'Add Expense',
            color: AppColors.getEmeraldAccent(context),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
          GlassActionButton(
            icon: Icons.sync_rounded,
            label: 'HDFC Sync',
            color: AppColors.getInfo(context),
            onTap: () {
              Navigator.pushNamed(context, '/import-review');
            },
          ),
          const SizedBox(width: 8),
          GlassActionButton(
            icon: Icons.bolt_rounded,
            label: 'POP Wallet',
            color: AppColors.getChampagne(context),
            onTap: () => SpendzPopSheet.show(context),
          ),
          const SizedBox(width: 8),
          GlassActionButton(
            icon: Icons.style_rounded,
            label: 'Card Studio',
            color: AppColors.getSage(context),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CardsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context) {
    return const _RecentTransactionsTabs();
  }
}

class _RecentTransactionsTabs extends StatefulWidget {
  const _RecentTransactionsTabs();

  @override
  State<_RecentTransactionsTabs> createState() =>
      _RecentTransactionsTabsState();
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
    final emerald = AppColors.getEmeraldAccent(context);

    return Consumer2<TransactionProvider, CategoryProvider>(
      builder: (context, txProvider, catProvider, child) {
        final pendingSplits = txProvider.transactions
            .where((t) => t.owedAmount > 0)
            .toList();
        final totalOwed = pendingSplits.fold(
          0.0,
          (sum, t) => sum + t.owedAmount,
        );
        final recentTransactions = txProvider.transactions
            .where((t) => t.owedAmount == 0)
            .take(5)
            .toList();

        final currentList = _tabController.index == 0
            ? recentTransactions
            : pendingSplits;

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
                    indicatorColor: emerald,
                    indicatorWeight: 2.5,
                    labelColor: emerald,
                    unselectedLabelColor: AppColors.getTextSecondary(context),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13.5,
                    ),
                    tabs: [
                      const Tab(text: 'Recent Activity'),
                      Tab(
                        text: totalOwed > 0
                            ? 'Pending Splits (${pendingSplits.length} · ${CurrencyFormatter.format(totalOwed)})'
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
                        MaterialPageRoute(
                          builder: (context) => const TransactionsScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: emerald,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    child: const Text('See All'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
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
                actionLabel: _tabController.index == 0
                    ? 'Add Transaction'
                    : null,
                onActionPressed: _tabController.index == 0
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddTransactionScreen(),
                          ),
                        );
                      }
                    : null,
              )
            else
              GlassCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentList.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 0.8,
                    indent: 68,
                    color: AppColors.getBorder(context).withAlpha(80),
                  ),
                  itemBuilder: (context, index) {
                    final tx = currentList[index];
                    final category = tx.categoryId != null
                        ? catProvider.getCategoryById(tx.categoryId!)
                        : null;

                    return TransactionTile(transaction: tx, category: category);
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

  void _triggerSync(
    GmailImportProvider importProvider,
    CategoryProvider categoryProvider,
  ) async {
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
            MaterialPageRoute(
              builder: (context) => const ImportedTransactionsScreen(),
            ),
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
        const handleWidth = 56.0;
        _maxDrag = (constraints.maxWidth - handleWidth - 8).clamp(
          0.0,
          double.infinity,
        );

        return Consumer2<GmailImportProvider, CategoryProvider>(
          builder: (context, importProvider, categoryProvider, child) {
            final isSyncing = importProvider.isLoading;
            final isDark = AppColors.isDark(context);
            final emerald = AppColors.getEmeraldAccent(context);

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

                      _snapAnimation =
                          Tween<double>(begin: _dragOffset, end: 0.0).animate(
                            CurvedAnimation(
                              parent: _snapController,
                              curve: Curves.easeOutBack,
                            ),
                          );
                      _snapController.forward(from: 0.0);
                    },
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Track
                  Container(
                    height: 52,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      color: isDark
                          ? const Color(0xFF101C16).withAlpha(200)
                          : const Color(0xFFFFFFFF).withAlpha(220),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withAlpha(25)
                            : AppColors.getBorder(context),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 50 : 15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Opacity(
                      opacity: isSyncing
                          ? 1.0
                          : (_maxDrag > 0
                                ? (1.0 - (_dragOffset / (_maxDrag * 0.7)))
                                      .clamp(0.0, 1.0)
                                : 1.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: isSyncing
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: emerald,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Syncing HDFC Alerts...',
                                    style: TextStyle(
                                      color: emerald,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Slide to Sync HDFC alerts',
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFFA2B3A7)
                                          : AppColors.getTextSecondary(context),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: emerald.withAlpha(160),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  // Draggable Glowing Handle
                  Transform.translate(
                    offset: Offset(_dragOffset, 0),
                    child: Container(
                      height: 44,
                      width: handleWidth,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        gradient: LinearGradient(
                          colors: [emerald, const Color(0xFF059669)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: emerald.withAlpha(90),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.sync_rounded,
                          color: Colors.white,
                          size: 20,
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
