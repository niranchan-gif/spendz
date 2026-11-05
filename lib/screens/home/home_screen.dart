import '../transactions/imported_transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';
import '../../presentation/widgets/spendz_amount_text.dart';
import '../../presentation/widgets/spendz_empty_state.dart';
import '../../presentation/widgets/spendz_surface.dart';
import '../../presentation/widgets/spendz_top_bar.dart';
import '../../providers/category_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/icon_mapper.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transactions_screen.dart';
import '../wallet/wallet_dashboard_screen.dart';

/// Spendz Funky Claymorphism Home Screen.
///
/// Features inflated tactile hero balance, dual sunken cashflow pods,
/// 4 funky clay action buttons, weekly vibe bar chart, and recent treats stream.
/// Notice: Card Studio is strictly excluded from Home screen per user requirement.
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
          color: SpendzColors.tangerine,
          onRefresh: () async {
            await context.read<TransactionProvider>().loadTransactions();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: SpendzSpacing.lg,
              vertical: SpendzSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 0. Global Funky Clay Top Bar
                const SpendzTopBar(title: 'Home'),
                const SizedBox(height: SpendzSpacing.md),

                // 1. Sculpted Hero Total Balance Card
                _buildHeroBalanceCard(context),
                const SizedBox(height: SpendzSpacing.lg),

                // 2. 4 Funky Quick Action Clay Buttons
                _buildQuickActionButtons(context),
                const SizedBox(height: SpendzSpacing.lg),

                // 3. Top Spending Bucket
                _buildTopBucketCard(context),
                const SizedBox(height: SpendzSpacing.lg),

                // 4. Recent Treats Stream
                _buildRecentTreatsSection(context),
                const SizedBox(height: SpendzSpacing.hero),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 1. HERO TOTAL BALANCE CARD (YELLOW SPENT POD WITH CLAY POP) ─────────
  Widget _buildHeroBalanceCard(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final totalBalance = dashboard.totalBalance;
        final monthlyIncome = dashboard.monthlyIncome;
        final monthlyExpenses = dashboard.monthlyExpenses;

        return Container(
          padding: const EdgeInsets.all(SpendzSpacing.lg),
          decoration: BoxDecoration(
            color: const Color(0xFFE2F4EA),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withAlpha(20),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 4,
                offset: Offset(1, 1),
                blurStyle: BlurStyle.inner,
              ),
            ],
            border: Border.all(
              color: const Color(0xFFB8E6CE),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label & Eye Privacy Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: SpendzColors.tangerine,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total Balance',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: SpendzColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isBalanceVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 20,
                      color: SpendzColors.textSecondary(context),
                    ),
                    onPressed: () {
                      setState(() => _isBalanceVisible = !_isBalanceVisible);
                    },
                  ),
                ],
              ),
              const SizedBox(height: SpendzSpacing.sm),

              // Giant Bubbly Amount Display
              SpendzAmountText(
                amount: totalBalance,
                isVisible: _isBalanceVisible,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
              const SizedBox(height: SpendzSpacing.md),

              // Inflow & Outflow Dual Clay Pods
              Row(
                children: [
                  // Inflow Pod - Funky Fresh Green
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCEF1DE),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF70C99A).withAlpha(60),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                          const BoxShadow(
                            color: Colors.white,
                            blurRadius: 2,
                            offset: Offset(1, 1),
                            blurStyle: BlurStyle.inner,
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFA5DFC0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F5B38),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F5B38).withAlpha(60),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.south_west_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Inflow',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F5B38),
                                  ),
                                ),
                                SpendzAmountText(
                                  amount: monthlyIncome,
                                  variant: SpendzAmountVariant.income,
                                  isVisible: _isBalanceVisible,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  showSign: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Spent Pod - Exact Clay Yellow used in cards with tactile pop
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: SpendzColors.clayYellow,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: SpendzColors.clayYellow.withAlpha(100),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                          const BoxShadow(
                            color: Colors.white,
                            blurRadius: 2,
                            offset: Offset(1, 1),
                            blurStyle: BlurStyle.inner,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withAlpha(200),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF735500),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.north_east_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Spent',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF735500),
                                  ),
                                ),
                                SpendzAmountText(
                                  amount: monthlyExpenses,
                                  variant: SpendzAmountVariant.expense,
                                  isVisible: _isBalanceVisible,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  showSign: true,
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

  // ─── 2. QUICK ACTION CLAY BUTTONS ───────────────────────────────────────────
  Widget _buildQuickActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildClayActionPod(
            context: context,
            icon: Icons.add_rounded,
            label: 'Add',
            bgColor: SpendzColors.tangerine,
            iconColor: Colors.white,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
            ),
          ),
        ),
        Expanded(
          child: _buildClayActionPod(
            context: context,
            icon: Icons.sync_rounded,
            label: 'Sync to Bank',
            bgColor: SpendzColors.tertiarySky,
            iconColor: Colors.white,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ImportedTransactionsScreen(),
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildClayActionPod(
            context: context,
            icon: Icons.credit_card_rounded,
            label: 'Cards',
            bgColor: SpendzColors.sunshineYellow,
            iconColor: const Color(0xFF735500),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const WalletDashboardScreen(),
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildClayActionPod(
            context: context,
            icon: Icons.lock_outline_rounded,
            label: 'Vault',
            bgColor: const Color(0xFFDDD6FE),
            iconColor: const Color(0xFF4C1D95),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const WalletDashboardScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClayActionPod({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withAlpha(80),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withAlpha(160),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                  blurStyle: BlurStyle.inner,
                ),
              ],
            ),
            child: Icon(icon, color: SpendzColors.textSecondary(context), size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: SpendzColors.textPrimary(context),
          ),
        ),
      ],
    );
  }

  // ─── 3. TOP SPENDING BUCKET CARD ─────────────────────────────────────────────
  Widget _buildTopBucketCard(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final entries = dashboard.categorySpending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topEntry = entries.isNotEmpty ? entries.first : null;
        final cat = topEntry != null
            ? context.read<CategoryProvider>().getCategoryById(topEntry.key)
            : null;

        final hasExpenses = topEntry != null && topEntry.value > 0;
        final categoryName = hasExpenses ? (cat?.name ?? 'General Expense') : 'No expenses recorded';
        final totalSpent = topEntry?.value ?? 0.0;
        final totalBudget = dashboard.monthlyIncome > 0 ? (dashboard.monthlyIncome * 0.3) : 5000.0;
        final utilRatio = hasExpenses ? (totalSpent / totalBudget).clamp(0.05, 1.0) : 0.0;
        final utilPct = hasExpenses ? ((totalSpent / totalBudget) * 100).clamp(1.0, 100.0).toStringAsFixed(0) : '0';

        return SpendzSurface(
          color: SpendzColors.clayCream,
          padding: const EdgeInsets.all(SpendzSpacing.lg),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: SpendzColors.clayTangerine,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fastfood_rounded,
                          color: SpendzColors.tangerine,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Bucket',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: SpendzColors.textSecondary(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: SpendzColors.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SpendzAmountText(
                    amount: totalSpent,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    variant: SpendzAmountVariant.expense,
                  ),
                ],
              ),
              const SizedBox(height: SpendzSpacing.sm),

              // Puffy 3D Progress Capsule
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: SpendzColors.surfaceRecessed(context),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: utilRatio > 0 ? utilRatio : 0.04,
                  child: Container(
                    decoration: BoxDecoration(
                      color: hasExpenses ? SpendzColors.tangerine : SpendzColors.border(context),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: hasExpenses
                          ? [
                              BoxShadow(
                                color: SpendzColors.tangerine.withAlpha(80),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hasExpenses ? 'Budget track: Active' : 'Budget track: Inactive',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: SpendzColors.textSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$utilPct% Utilized',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: hasExpenses ? SpendzColors.tangerine : SpendzColors.textSecondary(context),
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

  // ─── 6. RECENT TREATS STREAM ─────────────────────────────────────────────────
  Widget _buildRecentTreatsSection(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, txProvider, _) {
        final recent = txProvider.transactions.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: SpendzColors.sunshineDeep,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: SpendzColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransactionsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: SpendzColors.tangerine,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpendzSpacing.sm),

            if (recent.isNotEmpty) ...[
              ...recent.map((tx) {
                final isIncome = tx.type == 'income';
                final category = context
                    .read<CategoryProvider>()
                    .getCategoryById(tx.categoryId ?? '');
                final iconData = IconMapper.getIcon(
                  category?.icon ?? 'category',
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: SpendzSurface(
                    color: SpendzColors.clayCream,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    borderRadius: 20,
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isIncome
                                ? SpendzColors.periwinkleLight
                                : SpendzColors.sunshineLight,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isIncome
                                            ? SpendzColors.periwinkle
                                            : SpendzColors.sunshineYellow)
                                        .withAlpha(40),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            iconData,
                            size: 20,
                            color: isIncome
                                ? SpendzColors.periwinkleDeep
                                : SpendzColors.sunshineDeep,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.merchant?.isNotEmpty == true
                                    ? tx.merchant!
                                    : (category?.name ?? 'Expense'),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: SpendzColors.textPrimary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat(
                                  'dd MMM • hh:mm a',
                                ).format(tx.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: SpendzColors.textSecondary(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SpendzAmountText(
                          amount: tx.amount,
                          variant: isIncome
                              ? SpendzAmountVariant.income
                              : SpendzAmountVariant.expense,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          showSign: true,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: SpendzSpacing.sm),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TransactionsScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: SpendzColors.surface(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: SpendzColors.border(context),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(
                          SpendzColors.isDark(context) ? 30 : 8,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View all ${txProvider.transactions.length} transactions',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: SpendzColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: SpendzColors.tangerine,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SpendzEmptyState(
                title: 'No recent transactions',
                message: 'Tap the + button to record your first flow',
                icon: Icons.savings_outlined,
              ),
            ],
          ],
        );
      },
    );
  }
}
