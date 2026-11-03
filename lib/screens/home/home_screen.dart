import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/gmail_import_provider.dart';
import '../../app/theme/app_text_styles.dart';
import '../../widgets/spending_summary_card.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/glass_container.dart';
import '../transactions/transactions_screen.dart';
import '../transactions/imported_transactions_screen.dart';
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildTotalSpentBox(context),
              const SizedBox(height: 32),
              _buildRecentTransactions(context),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildHeader(BuildContext context) {
    return const SlideToSyncBanner();
  }

  Widget _buildTotalSpentBox(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, txProvider, child) {
        final actualSpent = txProvider.transactions
            .where((t) => t.type == 'expense')
            .fold(0.0, (sum, t) => sum + t.amount);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface, // Solid clean surface
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
            ),
            title: Text('Total Spent', style: AppTextStyles.labelLarge),
            trailing: Text(
              CurrencyFormatter.format(actualSpent),
              style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
            ),
          ),
        );
      },
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
                      Tab(text: 'Pending Splits (${pendingSplits.length})'),
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
        // Banner aspect ratio is exactly 3:1 (1024x341)
        // If height is 48, width must be exactly 144 to prevent any letterboxing or cropping
        final bannerWidth = 144.0;
        _maxDrag = constraints.maxWidth - bannerWidth - 8; // account for margin

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
                      
                      // Snap back animation
                      _snapAnimation = Tween<double>(begin: _dragOffset, end: 0.0)
                          .animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOutBack));
                      _snapController.forward(from: 0.0);
                    },
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Premium Track background
                  Container(
                    height: 56, // taller than banner so it frames it completely
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16), // smooth rounded rectangle
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
                  
                  // Slidable Banner Thumb
                  Transform.translate(
                    offset: Offset(_dragOffset, 0),
                    child: Container(
                      height: 48, // perfectly fits inside 56 track with 4px padding
                      width: bannerWidth, // exactly 144px to match 3:1 ratio
                      margin: const EdgeInsets.only(left: 4), // 4px margin from edge
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12), // rounded rectangle box
                        boxShadow: [
                          // Drop shadow only, removed local glow
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

