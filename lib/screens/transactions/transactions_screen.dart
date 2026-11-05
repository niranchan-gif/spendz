import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme/spendz_colors.dart';
import '../../models/transaction_model.dart';
import '../../presentation/widgets/spendz_amount_text.dart';
import '../../presentation/widgets/spendz_empty_state.dart';
import '../../presentation/widgets/spendz_top_bar.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/icon_mapper.dart';
import 'add_transaction_screen.dart';
import 'imported_transactions_screen.dart';

/// Spendz Funky Claymorphism Activity & Transactions Feed Screen.
/// Bulbous tactile clay modules, sunken search wells, dual pods, and live feed.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  String _selectedType = 'all'; // 'all', 'expense', 'income'
  String _selectedCategoryId = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        final isDark = SpendzColors.isDark(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: SpendzColors.tangerine,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end.add(
          const Duration(hours: 23, minutes: 59, seconds: 59),
        );
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpendzColors.background(context),
      body: SafeArea(
        child: Consumer2<TransactionProvider, CategoryProvider>(
          builder: (context, txProvider, catProvider, _) {
            final allTransactions = txProvider.transactions;

            // Calculate totals for Dual Pods
            double totalSpent = 0;
            double totalReceived = 0;
            int expenseCount = 0;
            int incomeCount = 0;

            for (final t in allTransactions) {
              if (t.type == 'income') {
                totalReceived += t.amount;
                incomeCount++;
              } else {
                totalSpent += t.amount;
                expenseCount++;
              }
            }

            // Apply filters
            final filtered = allTransactions.where((t) {
              if (_selectedType != 'all' && t.type != _selectedType) {
                return false;
              }
              if (_selectedCategoryId != 'all' &&
                  t.categoryId != _selectedCategoryId) {
                return false;
              }
              if (_startDate != null && t.date.isBefore(_startDate!)) {
                return false;
              }
              if (_endDate != null && t.date.isAfter(_endDate!)) {
                return false;
              }
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                final matchesMerchant =
                    t.merchant?.toLowerCase().contains(q) ?? false;
                final matchesDesc =
                    t.description?.toLowerCase().contains(q) ?? false;
                final cat = catProvider.getCategoryById(t.categoryId ?? '');
                final matchesCat = cat?.name.toLowerCase().contains(q) ?? false;
                if (!matchesMerchant && !matchesDesc && !matchesCat) {
                  return false;
                }
              }
              return true;
            }).toList();

            // Group by Date
            final Map<String, List<TransactionModel>> grouped = {};
            for (final t in filtered) {
              final key = _formatDateGroupKey(t.date);
              grouped.putIfAbsent(key, () => []).add(t);
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 0. Global Top Bar
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: SpendzTopBar(title: 'Activity'),
                  ),
                ),

                // 1. Funky Clay Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: _buildHeader(context, filtered.length),
                  ),
                ),

                // 2. Dual Inflow/Spent Clay Pods
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildDualPods(
                      context,
                      totalSpent,
                      totalReceived,
                      expenseCount,
                      incomeCount,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 3. Sunken Clay Search Well
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSunkenSearch(context),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // 4. Segmented Clay Filter Pills
                SliverToBoxAdapter(
                  child: _buildFilterPills(context, incomeCount, expenseCount),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // 5. Category Bubble Chips
                SliverToBoxAdapter(
                  child: _buildCategoryBubbles(
                    context,
                    catProvider,
                    allTransactions,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 6. Date-Grouped Transaction Stream or Empty State
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 32,
                      ),
                      child: SpendzEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No Matching Flows',
                        message:
                            _searchQuery.isNotEmpty ||
                                _selectedCategoryId != 'all' ||
                                _selectedType != 'all' ||
                                _startDate != null
                            ? 'Try clearing active filters to reveal all activity.'
                            : 'Tap "+" to record your first transaction.',
                        actionLabel:
                            _searchQuery.isNotEmpty ||
                                _selectedCategoryId != 'all' ||
                                _selectedType != 'all' ||
                                _startDate != null
                            ? 'Reset Filters'
                            : 'Add Transaction',
                        onAction: () {
                          if (_searchQuery.isNotEmpty ||
                              _selectedCategoryId != 'all' ||
                              _selectedType != 'all' ||
                              _startDate != null) {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _selectedType = 'all';
                              _selectedCategoryId = 'all';
                              _startDate = null;
                              _endDate = null;
                            });
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddTransactionScreen(),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((
                        context,
                        groupIndex,
                      ) {
                        final dateKey = grouped.keys.elementAt(groupIndex);
                        final items = grouped[dateKey]!;

                        double dayNet = 0;
                        for (final i in items) {
                          if (i.type == 'income') {
                            dayNet += i.amount;
                          } else {
                            dayNet -= i.amount;
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Group Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        dateKey.split(',')[0],
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: SpendzColors.textPrimary(
                                            context,
                                          ),
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: dayNet >= 0
                                              ? SpendzColors.tertiarySky
                                              : SpendzColors.tangerine,
                                        ),
                                      ),
                                      if (dateKey.contains(',')) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          dateKey.split(',')[1].trim(),
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: SpendzColors.textSecondary(
                                              context,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: SpendzColors.surfaceContainerHigh(
                                        context,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(8),
                                          offset: const Offset(1, 1),
                                          blurRadius: 2,
                                          blurStyle: BlurStyle.inner,
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withAlpha(180),
                                          offset: const Offset(-1, -1),
                                          blurRadius: 2,
                                          blurStyle: BlurStyle.inner,
                                        ),
                                      ],
                                    ),
                                    child: SpendzAmountText(
                                      amount: dayNet,
                                      variant: dayNet >= 0
                                          ? SpendzAmountVariant.income
                                          : SpendzAmountVariant.expense,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      showSign: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Transaction items list
                              ...items.map(
                                (tx) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildClayTransactionCard(
                                    context,
                                    tx,
                                    catProvider,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }, childCount: grouped.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 1. Header with Bank Sync and Add Button
  Widget _buildHeader(BuildContext context, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity & Flows',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: SpendzColors.textPrimary(context),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: SpendzColors.clayYellow,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: SpendzColors.clayYellow.withAlpha(90),
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
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF735500),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$count transactions',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF735500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Action Buttons: Bank Sync + Add Transaction
        Row(
          children: [
            // Bank Sync from Google Scripts Button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ImportedTransactionsScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: SpendzColors.clayPeriwinkle,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: SpendzColors.periwinkle.withAlpha(60),
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
                    color: SpendzColors.periwinkle.withAlpha(90),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 16,
                      color: SpendzColors.periwinkleDark,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Bank Sync',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: SpendzColors.periwinkleDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Floating Puffy Add Button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SpendzColors.tangerine,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SpendzColors.tangerine.withAlpha(110),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 2,
                      offset: Offset(1, 1),
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Dual Inflow / Spent Clay Pods
  Widget _buildDualPods(
    BuildContext context,
    double spent,
    double received,
    int expenseCount,
    int incomeCount,
  ) {
    return Row(
      children: [
        // Spent Pod (Clay Yellow #FECA55)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SpendzColors.clayYellow,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFE5B23A),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD49E1E).withAlpha(120),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
                const BoxShadow(
                  color: Colors.white,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                  blurStyle: BlurStyle.inner,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SPENT',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF735500),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(220),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF735500).withAlpha(40),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        size: 15,
                        color: Color(0xFF735500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '₹${spent.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4A3700),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(160),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$expenseCount flows',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF735500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Received Pod (Clay Periwinkle #EAF2F9)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SpendzColors.clayPeriwinkle,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFD4E3F1),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB5CCE0).withAlpha(110),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
                const BoxShadow(
                  color: Colors.white,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                  blurStyle: BlurStyle.inner,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RECEIVED',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF4A657E),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(220),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A657E).withAlpha(40),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        size: 15,
                        color: Color(0xFF2C5070),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '+₹${received.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E4265),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(160),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+$incomeCount inflows',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4A657E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. Sunken Clay Search Well
  Widget _buildSunkenSearch(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: SpendzColors.surfaceContainerLow(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            offset: const Offset(2, 2),
            blurRadius: 5,
            blurStyle: BlurStyle.inner,
          ),
          BoxShadow(
            color: Colors.white.withAlpha(220),
            offset: const Offset(-2, -2),
            blurRadius: 4,
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 20,
            color: SpendzColors.textSecondary(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SpendzColors.textPrimary(context),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search flows, merchants, notes...',
                hintStyle: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: SpendzColors.textSecondary(context).withAlpha(160),
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SpendzColors.surfaceContainerHighest(context),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: SpendzColors.textSecondary(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 4. Segmented Clay Filter Pills
  Widget _buildFilterPills(
    BuildContext context,
    int incomeCount,
    int expenseCount,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // All Flows
          _buildPillButton(
            label: 'All Flows',
            isSelected: _selectedType == 'all',
            activeColor: SpendzColors.tangerine,
            textColor: Colors.white,
            onTap: () => setState(() => _selectedType = 'all'),
          ),
          const SizedBox(width: 8),

          // Inflows
          _buildPillButton(
            label: 'Inflows (+$incomeCount)',
            isSelected: _selectedType == 'income',
            activeColor: SpendzColors.tertiarySky,
            textColor: Colors.white,
            onTap: () => setState(() => _selectedType = 'income'),
          ),
          const SizedBox(width: 8),

          // Expenses
          _buildPillButton(
            label: 'Expenses ($expenseCount)',
            isSelected: _selectedType == 'expense',
            activeColor: SpendzColors.sunshineYellow,
            textColor: const Color(0xFF735500),
            onTap: () => setState(() => _selectedType = 'expense'),
          ),
          const SizedBox(width: 8),

          // Date Range
          GestureDetector(
            onTap: () {
              if (_startDate != null) {
                _clearDateRange();
              } else {
                _selectDateRange();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _startDate != null
                    ? SpendzColors.periwinkle
                    : SpendzColors.surface(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: _startDate != null
                    ? [
                        BoxShadow(
                          color: SpendzColors.periwinkle.withAlpha(90),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : SpendzColors.clayDropShadow(context),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: _startDate != null
                        ? Colors.white
                        : SpendzColors.textSecondary(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _startDate != null && _endDate != null
                        ? '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}'
                        : 'Date Range',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _startDate != null
                          ? Colors.white
                          : SpendzColors.textSecondary(context),
                    ),
                  ),
                  if (_startDate != null) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : SpendzColors.surface(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withAlpha(90),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withAlpha(180),
                    blurRadius: 3,
                    offset: const Offset(1, 1),
                    blurStyle: BlurStyle.inner,
                  ),
                ]
              : SpendzColors.clayDropShadow(context),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? textColor : SpendzColors.textPrimary(context),
          ),
        ),
      ),
    );
  }

  // 5. Category Bubble Chips
  Widget _buildCategoryBubbles(
    BuildContext context,
    CategoryProvider catProvider,
    List<TransactionModel> allTransactions,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: catProvider.categories.map((c) {
          final isSelected = _selectedCategoryId == c.id;
          final count = allTransactions
              .where((t) => t.categoryId == c.id)
              .length;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryId = isSelected ? 'all' : c.id;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? SpendzColors.tangerine
                      : SpendzColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: SpendzColors.tangerine.withAlpha(80),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Icon(
                      IconMapper.getIcon(c.icon),
                      size: 13,
                      color: isSelected
                          ? Colors.white
                          : SpendzColors.textSecondary(context),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      c.name,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : SpendzColors.textSecondary(context),
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : SpendzColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 6. Sculpted Funky Clay Transaction Card
  Widget _buildClayTransactionCard(
    BuildContext context,
    TransactionModel tx,
    CategoryProvider catProvider,
  ) {
    final cat = catProvider.getCategoryById(tx.categoryId ?? '');
    final isIncome = tx.type == 'income';
    final timeFormat = DateFormat('hh:mm a');

    // Funky badge colors
    final badgeColor = isIncome
        ? SpendzColors.tertiarySky
        : (tx.categoryId?.contains('food') == true ||
              tx.categoryId?.contains('dining') == true)
        ? SpendzColors.tangerine
        : (tx.categoryId?.contains('tech') == true ||
              tx.categoryId?.contains('tool') == true)
        ? SpendzColors.periwinkle
        : SpendzColors.sunshineYellow;

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: SpendzColors.error,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        final title = (tx.merchant != null && tx.merchant!.isNotEmpty)
            ? tx.merchant!
            : (cat?.name ?? tx.categoryId ?? 'Transaction');
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: SpendzColors.surface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text('Delete Flow?'),
            content: Text(
              'Remove "$title" of ₹${tx.amount.toStringAsFixed(2)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: SpendzColors.error),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<TransactionProvider>().deleteTransaction(tx.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Flow deleted')));
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SpendzColors.clayCream,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFF0EBE1),
              width: 1,
            ),
            boxShadow: SpendzColors.clayDropShadow(context),
          ),
          child: Row(
            children: [
              // Icon Badge Clay
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withAlpha(50),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.white.withAlpha(200),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
                ),
                child: Icon(
                  IconMapper.getIcon(cat?.icon ?? 'category'),
                  size: 20,
                  color: badgeColor,
                ),
              ),
              const SizedBox(width: 12),

              // Title & Category info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (tx.merchant != null && tx.merchant!.isNotEmpty)
                          ? tx.merchant!
                          : (cat?.name ?? tx.categoryId ?? 'Transaction'),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: SpendzColors.textPrimary(context),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          cat?.name ?? tx.categoryId ?? 'General',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: SpendzColors.textSecondary(context),
                          ),
                        ),
                        if (tx.paymentMethod != null &&
                            tx.paymentMethod!.isNotEmpty) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: SpendzColors.textSecondary(context),
                            ),
                          ),
                          Text(
                            tx.paymentMethod!,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: SpendzColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Amount & Timestamp
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}₹${tx.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isIncome
                          ? SpendzColors.tertiarySky
                          : SpendzColors.textPrimary(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeFormat.format(tx.date),
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: SpendzColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) {
      return 'Today, ${DateFormat('dd MMM').format(date)}';
    } else if (txDate == yesterday) {
      return 'Yesterday, ${DateFormat('dd MMM').format(date)}';
    } else if (txDate.year == now.year) {
      return '${DateFormat('dd MMMM').format(date)}, ${DateFormat('EEEE').format(date)}';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }
}
