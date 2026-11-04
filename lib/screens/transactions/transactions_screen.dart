import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/design_system/empty_state.dart';
import '../../widgets/glass/glass.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../utils/date_formatter.dart';
import '../../utils/icon_mapper.dart';
import '../../utils/currency_formatter.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  String _selectedCategoryId = 'all';

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.getPrimary(context),
              brightness: Theme.of(context).brightness,
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
    final emerald = AppColors.getEmeraldAccent(context);
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity',
              style: AppTextStyles.getHeading2(
                context,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Transactions & Financial Feed',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.getTextSecondary(context),
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle, color: emerald, size: 26),
            tooltip: 'Add Expense',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
              );
            },
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              tooltip: 'Clear date filter',
              onPressed: _clearDateRange,
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            tooltip: 'Filter by date',
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            tooltip: 'Import from Gmail',
            onPressed: () {
              Navigator.pushNamed(context, '/import-review');
            },
          ),
        ],
      ),
      body: Consumer2<TransactionProvider, CategoryProvider>(
        builder: (context, txProvider, catProvider, child) {
          var transactions = txProvider.transactions;

          // 1. Search Query Filter
          if (_searchQuery.trim().isNotEmpty) {
            final query = _searchQuery.toLowerCase().trim();
            transactions = transactions.where((tx) {
              final merchantMatch = (tx.merchant ?? '').toLowerCase().contains(
                query,
              );
              final descMatch = (tx.description ?? '').toLowerCase().contains(
                query,
              );
              final amountMatch = tx.amount.toString().contains(query);
              final refMatch = (tx.referenceId ?? '').toLowerCase().contains(
                query,
              );
              final methodMatch = (tx.paymentMethod ?? '')
                  .toLowerCase()
                  .contains(query);
              return merchantMatch ||
                  descMatch ||
                  amountMatch ||
                  refMatch ||
                  methodMatch;
            }).toList();
          }

          // 2. Category Filter
          if (_selectedCategoryId != 'all') {
            transactions = transactions
                .where((tx) => tx.categoryId == _selectedCategoryId)
                .toList();
          }

          // 3. Date Range Filter
          if (_startDate != null && _endDate != null) {
            transactions = transactions.where((tx) {
              return tx.date.isAfter(
                    _startDate!.subtract(const Duration(seconds: 1)),
                  ) &&
                  tx.date.isBefore(_endDate!.add(const Duration(seconds: 1)));
            }).toList();
          }

          if (txProvider.isLoading) {
            return Center(child: CircularProgressIndicator(color: emerald));
          }

          final totalFilteredSpent = transactions
              .where((t) => t.type == 'expense')
              .fold(0.0, (sum, t) => sum + t.amount);

          return Column(
            children: [
              // Search & Metric Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search merchant, note, amount...',
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: emerald,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF14231B).withAlpha(190)
                              : Colors.white.withAlpha(220),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withAlpha(20)
                                  : AppColors.getBorder(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withAlpha(20)
                                  : AppColors.getBorder(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            borderSide: BorderSide(color: emerald, width: 1.6),
                          ),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                  ],
                ),
              ),

              // Category Filter Bar
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: catProvider.categories.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedCategoryId == 'all';
                      return ChoiceChip(
                        showCheckmark: false,
                        label: Text('All (${txProvider.transactions.length})'),
                        selected: isSelected,
                        backgroundColor: isDark
                            ? const Color(0xFF14231B)
                            : Colors.white,
                        selectedColor: emerald.withAlpha(40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          side: BorderSide(
                            color: isSelected
                                ? emerald
                                : AppColors.getBorder(context),
                          ),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? emerald
                              : AppColors.getTextSecondary(context),
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedCategoryId = 'all'),
                      );
                    }

                    final cat = catProvider.categories[index - 1];
                    final isSelected = _selectedCategoryId == cat.id;

                    return ChoiceChip(
                      showCheckmark: false,
                      avatar: Icon(
                        IconMapper.getIcon(cat.icon),
                        size: 14,
                        color: isSelected
                            ? emerald
                            : Color(
                                int.tryParse(cat.color) ?? emerald.toARGB32(),
                              ),
                      ),
                      label: Text(cat.name),
                      selected: isSelected,
                      backgroundColor: isDark
                          ? const Color(0xFF14231B)
                          : Colors.white,
                      selectedColor: emerald.withAlpha(40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        side: BorderSide(
                          color: isSelected
                              ? emerald
                              : AppColors.getBorder(context),
                        ),
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? emerald
                            : AppColors.getTextSecondary(context),
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedCategoryId = cat.id),
                    );
                  },
                ),
              ),

              // Active Date Range / Total Filtered Spent Strip
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${transactions.length} Transactions',
                      style: TextStyle(
                        color: AppColors.getTextSecondary(context),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Total: ${CurrencyFormatter.format(totalFilteredSpent)}',
                      style: TextStyle(
                        color: AppColors.getTextPrimary(context),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              // Transaction List
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No Transactions Found',
                          subtitle:
                              _searchQuery.isNotEmpty ||
                                  _selectedCategoryId != 'all' ||
                                  _startDate != null
                              ? 'Try adjusting your search keywords, category or date range.'
                              : 'Tap "+ Add Expense" below to record your first transaction.',
                          actionLabel:
                              _searchQuery.isEmpty &&
                                  _selectedCategoryId == 'all' &&
                                  _startDate == null
                              ? 'Add Expense'
                              : 'Reset Filters',
                          onActionPressed: () {
                            if (_searchQuery.isNotEmpty ||
                                _selectedCategoryId != 'all' ||
                                _startDate != null) {
                              setState(() {
                                _searchQuery = '';
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
                      )
                    : Builder(
                        builder: (context) {
                          // Group transactions by formatted date string
                          final Map<String, List<dynamic>> dateGroupMap = {};
                          for (final tx in transactions) {
                            final key = DateFormatter.formatFullDate(tx.date);
                            dateGroupMap.putIfAbsent(key, () => []).add(tx);
                          }
                          final groupEntries = dateGroupMap.entries.toList();

                          return ListView.builder(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.xs,
                              bottom: 90,
                              left: AppSpacing.lg,
                              right: AppSpacing.lg,
                            ),
                            physics: const BouncingScrollPhysics(),
                            itemCount: groupEntries.length,
                            itemBuilder: (context, groupIndex) {
                              final entry = groupEntries[groupIndex];
                              final dateKey = entry.key;
                              final groupTxs = entry.value;

                              final daySpent = groupTxs
                                  .where((t) => t.type == 'expense')
                                  .fold(
                                    0.0,
                                    (sum, t) => sum + (t.amount as double),
                                  );
                              final dayIncome = groupTxs
                                  .where((t) => t.type == 'income')
                                  .fold(
                                    0.0,
                                    (sum, t) => sum + (t.amount as double),
                                  );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      4,
                                      AppSpacing.md,
                                      4,
                                      AppSpacing.xs,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: emerald,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              dateKey,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    AppColors.getTextSecondary(
                                                      context,
                                                    ),
                                                fontSize: 11.5,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (daySpent > 0 || dayIncome > 0)
                                          Text(
                                            daySpent > 0
                                                ? '- ${CurrencyFormatter.format(daySpent)}'
                                                : '+ ${CurrencyFormatter.format(dayIncome)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: daySpent > 0
                                                  ? AppColors.getTextSecondary(
                                                      context,
                                                    )
                                                  : AppColors.getSuccess(
                                                      context,
                                                    ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  GlassCard(
                                    padding: EdgeInsets.zero,
                                    margin: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: Column(
                                      children: List.generate(groupTxs.length, (
                                        txIndex,
                                      ) {
                                        final tx = groupTxs[txIndex];
                                        final category = tx.categoryId != null
                                            ? catProvider.getCategoryById(
                                                tx.categoryId!,
                                              )
                                            : null;
                                        final isLast =
                                            txIndex == groupTxs.length - 1;

                                        return Column(
                                          children: [
                                            TransactionTile(
                                              transaction: tx,
                                              category: category,
                                              isCard: false,
                                            ),
                                            if (!isLast)
                                              Divider(
                                                height: 1,
                                                thickness: 0.5,
                                                indent: 64,
                                                endIndent: 16,
                                                color: isDark
                                                    ? Colors.white.withAlpha(12)
                                                    : AppColors.getBorder(
                                                        context,
                                                      ).withAlpha(120),
                                              ),
                                          ],
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
