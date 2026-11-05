import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';
import '../../presentation/widgets/spendz_amount_text.dart';
import '../../presentation/widgets/spendz_empty_state.dart';
import '../../presentation/widgets/spendz_surface.dart';
import '../../providers/category_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/icon_mapper.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transactions_screen.dart';
import '../wallet/cards_screen.dart';
import '../wallet/documents_screen.dart';
import '../wallet/widgets/spendz_pop_sheet.dart';

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
                // 1. Top Greeting Bar with PRO SAVER Badge
                _buildGreetingHeader(context),
                const SizedBox(height: SpendzSpacing.md),

                // 2. Sculpted Hero Total Balance Card
                _buildHeroBalanceCard(context),
                const SizedBox(height: SpendzSpacing.lg),

                // 3. 4 Funky Quick Action Clay Buttons
                _buildQuickActionButtons(context),
                const SizedBox(height: SpendzSpacing.lg),

                // 4. Weekly Vibes & Flow Clay Chart
                _buildWeeklyVibesCard(context),
                const SizedBox(height: SpendzSpacing.lg),

                // 5. Top Spending Bucket
                _buildTopBucketCard(context),
                const SizedBox(height: SpendzSpacing.lg),

                // 6. Recent Treats & Drops Stream
                _buildRecentTreatsSection(context),
                const SizedBox(height: SpendzSpacing.hero),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 1. TOP GREETING HEADER ───────────────────────────────────────────────────
  Widget _buildGreetingHeader(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning ☀️'
        : hour < 17
        ? 'Good afternoon 🌤'
        : 'Good evening 🌙';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: SpendzColors.textPrimary(context),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Your stash is vibing strong today',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: SpendzColors.textSecondary(context),
              ),
            ),
          ],
        ),

        // Puffy PRO SAVER Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: SpendzColors.sunshineYellow,
            borderRadius: BorderRadius.circular(SpendzSpacing.radiusFull),
            boxShadow: [
              BoxShadow(
                color: SpendzColors.sunshineDeep.withAlpha(60),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white.withAlpha(180), width: 1.2),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 15,
                color: Color(0xFF735500),
              ),
              SizedBox(width: 4),
              Text(
                'PRO SAVER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF735500),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 2. HERO TOTAL BALANCE CARD ──────────────────────────────────────────────
  Widget _buildHeroBalanceCard(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final totalBalance = dashboard.totalBalance;
        final monthlyIncome = dashboard.monthlyIncome;
        final monthlyExpenses = dashboard.monthlyExpenses;

        return SpendzSurface(
          isElevated: true,
          padding: const EdgeInsets.all(SpendzSpacing.lg),
          borderRadius: 28,
          child: Stack(
            children: [
              // Decorative background clay blobs
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SpendzColors.sunshineYellow.withAlpha(25),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SpendzColors.tangerine.withAlpha(18),
                  ),
                ),
              ),

              Column(
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
                            'TOTAL LIQUID STASH',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
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
                          size: 19,
                          color: SpendzColors.textSecondary(context),
                        ),
                        onPressed: () {
                          setState(
                            () => _isBalanceVisible = !_isBalanceVisible,
                          );
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
                  const SizedBox(height: SpendzSpacing.xs),

                  // Growth Pill Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: SpendzColors.periwinkleLight,
                          borderRadius: BorderRadius.circular(
                            SpendzSpacing.radiusFull,
                          ),
                          border: Border.all(
                            color: SpendzColors.periwinkle.withAlpha(60),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              size: 14,
                              color: SpendzColors.periwinkleDark,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '+14.2% this cycle 🚀',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: SpendzColors.periwinkleDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'vs. last cycle',
                        style: TextStyle(
                          fontSize: 11,
                          color: SpendzColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpendzSpacing.md),

                  // Inflow & Outflow Dual Sunken Clay Pods
                  Row(
                    children: [
                      // Inflow Pod
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: SpendzColors.surfaceRecessed(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: SpendzColors.border(context),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: SpendzColors.periwinkle,
                                  borderRadius: BorderRadius.circular(10),
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
                                    Text(
                                      'Inflow',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: SpendzColors.textSecondary(
                                          context,
                                        ),
                                      ),
                                    ),
                                    SpendzAmountText(
                                      amount: monthlyIncome,
                                      variant: SpendzAmountVariant.income,
                                      isVisible: _isBalanceVisible,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
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

                      // Spent Pod
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: SpendzColors.surfaceRecessed(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: SpendzColors.border(context),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: SpendzColors.tangerine,
                                  borderRadius: BorderRadius.circular(10),
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
                                    Text(
                                      'Spent',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: SpendzColors.textSecondary(
                                          context,
                                        ),
                                      ),
                                    ),
                                    SpendzAmountText(
                                      amount: monthlyExpenses,
                                      variant: SpendzAmountVariant.expense,
                                      isVisible: _isBalanceVisible,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
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
            ],
          ),
        );
      },
    );
  }

  // ─── 3. 4 FUNKY QUICK ACTION CLAY BUTTONS ──────────────────────────────────
  Widget _buildQuickActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. Add
        _buildClayActionTile(
          context: context,
          label: 'Add',
          icon: Icons.add_circle_outline_rounded,
          bgColor: SpendzColors.tangerine,
          fgColor: Colors.white,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
            );
          },
        ),

        // 2. Transfer
        _buildClayActionTile(
          context: context,
          label: 'Transfer',
          icon: Icons.swap_horiz_rounded,
          bgColor: SpendzColors.periwinkle,
          fgColor: Colors.white,
          onTap: () {
            SpendzPopSheet.show(context);
          },
        ),

        // 3. Cards
        _buildClayActionTile(
          context: context,
          label: 'Cards',
          icon: Icons.credit_card_rounded,
          bgColor: SpendzColors.sunshineYellow,
          fgColor: const Color(0xFF735500),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CardsScreen()),
            );
          },
        ),

        // 4. Vault
        _buildClayActionTile(
          context: context,
          label: 'Vault',
          icon: Icons.shield_rounded,
          bgColor: SpendzColors.surfaceHigh,
          fgColor: SpendzColors.textPrimary(context),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DocumentsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildClayActionTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color fgColor,
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
                  color: bgColor.withAlpha(70),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: Colors.white.withAlpha(160),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: fgColor, size: 26),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: SpendzColors.textPrimary(context),
          ),
        ),
      ],
    );
  }

  // ─── 4. WEEKLY VIBES & FLOW CLAY CHART ──────────────────────────────────────
  Widget _buildWeeklyVibesCard(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final currentMonth = DateFormat('MMM yyyy').format(DateTime.now());

        return SpendzSurface(
          padding: const EdgeInsets.all(SpendzSpacing.lg),
          borderRadius: 26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        color: SpendzColors.tangerine,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Weekly Vibes & Flow',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: SpendzColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: SpendzColors.surfaceRecessed(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentMonth,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: SpendzColors.textSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SpendzSpacing.md),

              // 4 Puffy Clay Pill Bars
              Container(
                height: 120,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: SpendzColors.surfaceRecessed(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildPillBar(
                      label: 'W1',
                      amount: '₹4.2k',
                      fillPercent: 0.48,
                      color: SpendzColors.sunshineYellow,
                    ),
                    _buildPillBar(
                      label: 'W2',
                      amount: '₹6.8k',
                      fillPercent: 0.72,
                      color: SpendzColors.tangerine,
                    ),
                    _buildPillBar(
                      label: 'W3',
                      amount: '₹9.4k',
                      fillPercent: 0.95,
                      color: SpendzColors.periwinkle,
                      isPeak: true,
                    ),
                    _buildPillBar(
                      label: 'W4',
                      amount: '₹5.1k',
                      fillPercent: 0.58,
                      color: SpendzColors.sunshineYellow,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SpendzSpacing.sm),

              // Bahamas Goal Pill
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SpendzColors.softButter.withAlpha(90),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: SpendzColors.sunshineDeep.withAlpha(30),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🌴', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Goa Holiday Stash',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: SpendzColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            '🔥 68% saved (₹17,000 of ₹25,000)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF735500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF735500),
                      size: 20,
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

  Widget _buildPillBar({
    required String label,
    required String amount,
    required double fillPercent,
    required Color color,
    bool isPeak = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isPeak)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: SpendzColors.periwinkleDeep,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'PEAK',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        Container(
          width: 38,
          height: 60 * fillPercent,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(60),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: isPeak
                ? SpendzColors.periwinkleDeep
                : SpendzColors.textSecondary(context),
          ),
        ),
      ],
    );
  }

  // ─── 5. TOP SPENDING BUCKET CARD ─────────────────────────────────────────────
  Widget _buildTopBucketCard(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final entries = dashboard.categorySpending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topEntry = entries.isNotEmpty ? entries.first : null;
        final cat = topEntry != null
            ? context.read<CategoryProvider>().getCategoryById(topEntry.key)
            : null;

        final categoryName = cat?.name ?? 'Food & Dining';
        final totalSpent = topEntry?.value ?? 0.0;

        return SpendzSurface(
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
                          color: SpendzColors.tangerine.withAlpha(25),
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
                  widthFactor: 0.65,
                  child: Container(
                    decoration: BoxDecoration(
                      color: SpendzColors.tangerine,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: SpendzColors.tangerine.withAlpha(80),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget track: Healthy',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: SpendzColors.textSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    '65% Utilized',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: SpendzColors.tangerine,
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
                      'Recent Treats & Drops',
                      style: TextStyle(
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

            if (recent.isNotEmpty)
              Column(
                children: recent.map((tx) {
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
                }).toList(),
              )
            else
              const SpendzEmptyState(
                title: 'No recent transactions',
                message: 'Tap the + button to record your first flow',
                icon: Icons.savings_outlined,
              ),
          ],
        );
      },
    );
  }
}
