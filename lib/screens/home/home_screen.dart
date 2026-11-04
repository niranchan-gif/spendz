import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';
import '../../app/theme/spendz_typography.dart';
import '../../models/transaction_model.dart';
import '../../presentation/widgets/spendz_amount_text.dart';
import '../../presentation/widgets/spendz_empty_state.dart';
import '../../presentation/widgets/spendz_section_header.dart';
import '../../presentation/widgets/spendz_surface.dart';
import '../../providers/category_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/icon_mapper.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transactions_screen.dart';

/// Spendz 2.0 Home Financial Overview Screen.
/// Clean, editorial, modern fintech dashboard rebuilt from scratch.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpendzColors.background(context),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: SpendzColors.primaryAccent(context),
          onRefresh: () async {
            await context.read<TransactionProvider>().loadTransactions();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: SpendzSpacing.lg,
              vertical: SpendzSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Compact Editorial Header
                _buildHeader(context),
                const SizedBox(height: SpendzSpacing.lg),

                // 2. Main Balance Hero Section
                _buildBalanceHero(context),
                const SizedBox(height: SpendzSpacing.lg),

                // 3. Cash-Flow Visualization (Comparison Bar & Burn Rate)
                _buildCashflowVisualization(context),
                const SizedBox(height: SpendzSpacing.lg),

                // 4. Quick Actions Dock
                _buildQuickActions(context),
                const SizedBox(height: SpendzSpacing.xl),

                // 5. Monthly Spending Insights
                _buildMonthlyInsights(context),
                const SizedBox(height: SpendzSpacing.xl),

                // 6. Recent Transactions
                _buildRecentTransactions(context),
                const SizedBox(height: SpendzSpacing.hero),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 1. COMPACT HEADER ───────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    final accent = SpendzColors.primaryAccent(context);

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
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withAlpha(120),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: SpendzSpacing.xs + 2),
                  Text(
                    'SPENDZ',
                    style: SpendzTypography.labelTracked(
                      context,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                greeting,
                style: SpendzTypography.headingMedium(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Live Vault Security Status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: SpendzColors.surface(context),
            borderRadius: BorderRadius.circular(SpendzSpacing.radiusFull),
            border: Border.all(color: SpendzColors.border(context), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 13, color: accent),
              const SizedBox(width: 5),
              Text(
                'Live Vault',
                style: TextStyle(
                  color: SpendzColors.textPrimary(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 2. MAIN BALANCE SECTION ─────────────────────────────────────────────────
  Widget _buildBalanceHero(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final totalBalance = dashboard.totalBalance;
        final monthlyIncome = dashboard.monthlyIncome;
        final monthlyExpenses = dashboard.monthlyExpenses;

        final isDark = SpendzColors.isDark(context);

        return SpendzSurface(
          isElevated: true,
          padding: const EdgeInsets.all(SpendzSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label & Privacy Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'TOTAL AVAILABLE BALANCE',
                      style: SpendzTypography.labelTracked(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isBalanceVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: SpendzColors.textSecondary(context),
                    ),
                    onPressed: () {
                      setState(() => _isBalanceVisible = !_isBalanceVisible);
                    },
                  ),
                ],
              ),
              const SizedBox(height: SpendzSpacing.sm),

              // Hero Balance Display
              SpendzAmountText(
                amount: totalBalance,
                isVisible: _isBalanceVisible,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
              const SizedBox(height: SpendzSpacing.lg),

              // Hairline separator
              Divider(
                color: isDark
                    ? SpendzColors.borderDark
                    : SpendzColors.borderLight,
                height: 1,
              ),
              const SizedBox(height: SpendzSpacing.md),

              // Monthly Inflow & Outflow Metrics
              Row(
                children: [
                  // Monthly Income
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: SpendzColors.income.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                size: 11,
                                color: SpendzColors.income,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Inflow',
                              style: SpendzTypography.caption(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        SpendzAmountText(
                          amount: monthlyIncome,
                          variant: SpendzAmountVariant.income,
                          isVisible: _isBalanceVisible,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          showSign: true,
                        ),
                      ],
                    ),
                  ),
                  // Monthly Expenses
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: SpendzColors.expense.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                size: 11,
                                color: SpendzColors.expense,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Outflow',
                              style: SpendzTypography.caption(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        SpendzAmountText(
                          amount: monthlyExpenses,
                          variant: SpendzAmountVariant.expense,
                          isVisible: _isBalanceVisible,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          showSign: true,
                        ),
                      ],
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

  // ─── 3. CASH-FLOW VISUALIZATION ──────────────────────────────────────────────
  Widget _buildCashflowVisualization(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final income = dashboard.monthlyIncome;
        final expenses = dashboard.monthlyExpenses;
        final total = income + expenses;

        final incomeRatio = total > 0 ? (income / total) : 0.5;
        final expenseRatio = total > 0 ? (expenses / total) : 0.5;

        final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

        return SpendzSurface(
          padding: const EdgeInsets.all(SpendzSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CASHFLOW RATIO',
                    style: SpendzTypography.labelTracked(context),
                  ),
                  Text(currentMonth, style: SpendzTypography.caption(context)),
                ],
              ),
              const SizedBox(height: SpendzSpacing.md),

              // Visual split bar
              ClipRRect(
                borderRadius: BorderRadius.circular(SpendzSpacing.radiusFull),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (incomeRatio * 100).round().clamp(1, 99),
                        child: Container(color: SpendzColors.income),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: (expenseRatio * 100).round().clamp(1, 99),
                        child: Container(color: SpendzColors.expense),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: SpendzSpacing.sm),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: SpendzColors.income,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Income ${(incomeRatio * 100).toStringAsFixed(0)}%',
                        style: SpendzTypography.caption(context),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: SpendzColors.expense,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Expenses ${(expenseRatio * 100).toStringAsFixed(0)}%',
                        style: SpendzTypography.caption(context),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── 4. QUICK ACTIONS DOCK ───────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildActionButton(
            context: context,
            icon: Icons.add_rounded,
            label: 'Add Expense',
            accentColor: SpendzColors.expense,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
              );
            },
          ),
          const SizedBox(width: SpendzSpacing.sm),
          _buildActionButton(
            context: context,
            icon: Icons.arrow_downward_rounded,
            label: 'Add Income',
            accentColor: SpendzColors.income,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
              );
            },
          ),
          const SizedBox(width: SpendzSpacing.sm),
          _buildActionButton(
            context: context,
            icon: Icons.sync_rounded,
            label: 'HDFC Sync',
            accentColor: SpendzColors.info,
            onTap: () {
              Navigator.pushNamed(context, '/import-review');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return SpendzSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: SpendzSpacing.radiusFull,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: accentColor),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: SpendzColors.textPrimary(context),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 5. MONTHLY SPENDING INSIGHTS ────────────────────────────────────────────
  Widget _buildMonthlyInsights(BuildContext context) {
    return Consumer2<TransactionProvider, CategoryProvider>(
      builder: (context, txProvider, catProvider, _) {
        final now = DateTime.now();
        final monthlyExpenses = txProvider.transactions
            .where(
              (t) =>
                  t.type == 'expense' &&
                  t.date.year == now.year &&
                  t.date.month == now.month,
            )
            .toList();

        if (monthlyExpenses.isEmpty) {
          return const SizedBox.shrink();
        }

        // Group by category to find top spending category
        final Map<String, double> categorySums = {};
        for (final tx in monthlyExpenses) {
          final catId = tx.categoryId ?? 'other';
          categorySums[catId] = (categorySums[catId] ?? 0.0) + tx.amount;
        }

        String topCatId = '';
        double topAmount = 0.0;
        categorySums.forEach((catId, sum) {
          if (sum > topAmount) {
            topAmount = sum;
            topCatId = catId;
          }
        });

        final topCat = catProvider.getCategoryById(topCatId);
        final topCatName = topCat?.name ?? topCatId.toUpperCase();
        final totalExpense = categorySums.values.fold(0.0, (s, a) => s + a);
        final topCatPercent = totalExpense > 0
            ? ((topAmount / totalExpense) * 100).round()
            : 0;

        return SpendzSurface(
          padding: const EdgeInsets.all(SpendzSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SpendzColors.primaryAccent(context).withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: SpendzColors.primaryAccent(context),
                ),
              ),
              const SizedBox(width: SpendzSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOP SPENDING: $topCatName',
                      style: SpendzTypography.labelTracked(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$topCatPercent% of monthly expenses (₹${topAmount.toStringAsFixed(0)})',
                      style: SpendzTypography.headingSmall(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── 6. RECENT TRANSACTIONS ──────────────────────────────────────────────────
  Widget _buildRecentTransactions(BuildContext context) {
    return Consumer2<TransactionProvider, CategoryProvider>(
      builder: (context, txProvider, catProvider, _) {
        final transactions = txProvider.transactions;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SpendzSectionHeader(
              title: 'Recent Activity',
              count: transactions.length,
              actionLabel: 'See all',
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                );
              },
            ),
            const SizedBox(height: SpendzSpacing.xs),
            if (transactions.isEmpty)
              SpendzEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No Transactions Recorded',
                message:
                    'Tap "Add Expense" or sync your HDFC statements to view your activity.',
                actionLabel: 'Add Expense',
                onAction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(),
                    ),
                  );
                },
              )
            else
              SpendzSurface(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length.clamp(0, 5),
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: SpendzColors.border(context)),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return _buildTransactionItem(context, tx, catProvider);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionModel tx,
    CategoryProvider catProvider,
  ) {
    final cat = catProvider.getCategoryById(tx.categoryId ?? '');
    final isIncome = tx.type == 'income';
    final dateFormat = DateFormat('dd MMM');

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpendzSpacing.lg,
          vertical: SpendzSpacing.md,
        ),
        child: Row(
          children: [
            // Category Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isIncome
                    ? SpendzColors.income.withAlpha(20)
                    : SpendzColors.surfaceElevated(context),
                borderRadius: BorderRadius.circular(SpendzSpacing.radiusMd),
                border: Border.all(
                  color: SpendzColors.border(context),
                  width: 1,
                ),
              ),
              child: Icon(
                IconMapper.getIcon(cat?.icon ?? 'category'),
                size: 18,
                color: isIncome
                    ? SpendzColors.income
                    : SpendzColors.primaryAccent(context),
              ),
            ),
            const SizedBox(width: SpendzSpacing.md),

            // Merchant & Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (tx.merchant != null && tx.merchant!.isNotEmpty)
                        ? tx.merchant!
                        : (cat?.name ?? tx.categoryId ?? 'Expense'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: SpendzColors.textPrimary(context),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dateFormat.format(tx.date)} • ${tx.paymentMethod ?? "Cash"}',
                    style: SpendzTypography.caption(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: SpendzSpacing.sm),

            // Amount
            SpendzAmountText(
              amount: tx.amount,
              variant: isIncome
                  ? SpendzAmountVariant.income
                  : SpendzAmountVariant.expense,
              isVisible: _isBalanceVisible,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              showSign: true,
            ),
          ],
        ),
      ),
    );
  }
}
