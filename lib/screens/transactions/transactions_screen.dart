import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';
import '../../app/theme/spendz_typography.dart';
import '../../models/transaction_model.dart';
import '../../presentation/widgets/spendz_amount_text.dart';
import '../../presentation/widgets/spendz_app_bar.dart';
import '../../presentation/widgets/spendz_empty_state.dart';
import '../../presentation/widgets/spendz_surface.dart';
import '../../presentation/widgets/spendz_text_field.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/icon_mapper.dart';
import 'add_transaction_screen.dart';

/// Spendz 2.0 Activity & Transactions Feed Screen.
/// Clean editorial timeline with search, category filters, and date-grouping.
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
              seedColor: SpendzColors.emerald,
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
      appBar: SpendzAppBar(
        title: 'Activity',
        subtitle: 'Transactions & cashflow timeline',
        actions: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SpendzColors.surface(context),
              border: Border.all(color: SpendzColors.border(context), width: 1),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.add_rounded,
                size: 20,
                color: SpendzColors.primaryAccent(context),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer2<TransactionProvider, CategoryProvider>(
        builder: (context, txProvider, catProvider, _) {
          final allTransactions = txProvider.transactions;

          // Apply filters
          final filtered = allTransactions.where((t) {
            // Type filter
            if (_selectedType != 'all' && t.type != _selectedType) {
              return false;
            }

            // Category filter
            if (_selectedCategoryId != 'all' &&
                t.categoryId != _selectedCategoryId) {
              return false;
            }

            // Date range filter
            if (_startDate != null && t.date.isBefore(_startDate!)) {
              return false;
            }
            if (_endDate != null && t.date.isAfter(_endDate!)) {
              return false;
            }

            // Search filter
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

          return Column(
            children: [
              // Search & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpendzSpacing.lg,
                  vertical: SpendzSpacing.sm,
                ),
                child: SpendzTextField(
                  controller: _searchController,
                  hintText: 'Search merchant, category, or note...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: SpendzColors.textSecondary(context),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                ),
              ),

              // Filter Chips Carousel
              _buildFilterChips(catProvider),
              const SizedBox(height: SpendzSpacing.xs),

              // Transaction Feed
              Expanded(
                child: filtered.isEmpty
                    ? SpendzEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No Matching Transactions',
                        message:
                            _searchQuery.isNotEmpty ||
                                _selectedCategoryId != 'all' ||
                                _selectedType != 'all' ||
                                _startDate != null
                            ? 'Try clearing active filters to see all transactions.'
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
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpendzSpacing.lg,
                          vertical: SpendzSpacing.sm,
                        ),
                        itemCount: grouped.length,
                        itemBuilder: (context, groupIndex) {
                          final dateKey = grouped.keys.elementAt(groupIndex);
                          final items = grouped[dateKey]!;

                          // Calculate daily net
                          double dayNet = 0;
                          for (final i in items) {
                            if (i.type == 'income') {
                              dayNet += i.amount;
                            } else {
                              dayNet -= i.amount;
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Group Header
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: SpendzSpacing.sm,
                                  horizontal: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateKey,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: SpendzColors.textSecondary(
                                          context,
                                        ),
                                      ),
                                    ),
                                    SpendzAmountText(
                                      amount: dayNet,
                                      variant: dayNet >= 0
                                          ? SpendzAmountVariant.income
                                          : SpendzAmountVariant.expense,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      showSign: true,
                                    ),
                                  ],
                                ),
                              ),

                              // Grouped Surface List
                              SpendzSurface(
                                padding: EdgeInsets.zero,
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: items.length,
                                  separatorBuilder: (context, i) => Divider(
                                    height: 1,
                                    color: SpendzColors.border(context),
                                  ),
                                  itemBuilder: (context, i) {
                                    final tx = items[i];
                                    return _buildTransactionRow(
                                      context,
                                      tx,
                                      catProvider,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: SpendzSpacing.md),
                            ],
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

  Widget _buildFilterChips(CategoryProvider catProvider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: SpendzSpacing.lg),
      child: Row(
        children: [
          // Date Range Chip
          FilterChip(
            label: Text(
              _startDate != null && _endDate != null
                  ? '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}'
                  : 'Date Range',
            ),
            selected: _startDate != null,
            onSelected: (_) {
              if (_startDate != null) {
                _clearDateRange();
              } else {
                _selectDateRange();
              }
            },
            avatar: Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: SpendzColors.textPrimary(context),
            ),
          ),
          const SizedBox(width: SpendzSpacing.xs),

          // Type: All
          ChoiceChip(
            label: const Text('All'),
            selected: _selectedType == 'all',
            onSelected: (selected) {
              if (selected) setState(() => _selectedType = 'all');
            },
          ),
          const SizedBox(width: SpendzSpacing.xs),

          // Type: Expense
          ChoiceChip(
            label: const Text('Expenses'),
            selected: _selectedType == 'expense',
            onSelected: (selected) {
              if (selected) setState(() => _selectedType = 'expense');
            },
          ),
          const SizedBox(width: SpendzSpacing.xs),

          // Type: Income
          ChoiceChip(
            label: const Text('Inflow'),
            selected: _selectedType == 'income',
            onSelected: (selected) {
              if (selected) setState(() => _selectedType = 'income');
            },
          ),
          const SizedBox(width: SpendzSpacing.xs),

          // Category Chips
          ...catProvider.categories.map((c) {
            final isSelected = _selectedCategoryId == c.id;
            return Padding(
              padding: const EdgeInsets.only(right: SpendzSpacing.xs),
              child: ChoiceChip(
                label: Text(c.name),
                selected: isSelected,
                avatar: Icon(
                  IconMapper.getIcon(c.icon),
                  size: 14,
                  color: isSelected
                      ? SpendzColors.primaryAccent(context)
                      : SpendzColors.textSecondary(context),
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedCategoryId = selected ? c.id : 'all';
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(
    BuildContext context,
    TransactionModel tx,
    CategoryProvider catProvider,
  ) {
    final cat = catProvider.getCategoryById(tx.categoryId ?? '');
    final isIncome = tx.type == 'income';
    final timeFormat = DateFormat('hh:mm a');

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: SpendzColors.expense,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: SpendzSpacing.xl),
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
            title: const Text('Delete Transaction?'),
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
                  style: TextStyle(color: SpendzColors.expense),
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
        ).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
      },
      child: InkWell(
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
              // Icon
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

              // Title & Category details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (tx.merchant != null && tx.merchant!.isNotEmpty)
                          ? tx.merchant!
                          : (cat?.name ?? tx.categoryId ?? 'Transaction'),
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
                      '${cat?.name ?? tx.categoryId ?? "General"} • ${tx.paymentMethod ?? "Cash"} • ${timeFormat.format(tx.date)}',
                      style: SpendzTypography.caption(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                fontSize: 15,
                fontWeight: FontWeight.w700,
                showSign: true,
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
      return DateFormat('EEEE, dd MMMM').format(date);
    } else {
      return DateFormat('EEEE, dd MMM yyyy').format(date);
    }
  }
}
