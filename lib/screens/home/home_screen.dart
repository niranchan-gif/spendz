import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/gmail_import_provider.dart';
import '../../app/theme/app_text_styles.dart';
import '../../widgets/spending_summary_card.dart';
import '../../widgets/spending_chart.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/glass_container.dart';
import '../transactions/transactions_screen.dart';
import '../../app/theme/app_colors.dart';

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
              _buildSummaryCard(context),
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

  Widget _buildSummaryCard(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, child) {
        return SpendingSummaryCard(
          totalBalance: dashboard.monthlyIncome - dashboard.monthlyExpenses,
          income: dashboard.monthlyIncome,
          expenses: dashboard.monthlyExpenses,
        );
      },
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return Consumer2<TransactionProvider, CategoryProvider>(
      builder: (context, txProvider, catProvider, child) {
        final recentTransactions = txProvider.getRecentTransactions(count: 5);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Transactions', style: AppTextStyles.heading3),
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
            if (recentTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text('No recent transactions', style: AppTextStyles.bodyMedium),
                ),
              )
            else
              GlassContainer(
                child: Column(
                  children: recentTransactions.map((tx) {
                    final category = tx.categoryId != null 
                        ? catProvider.getCategoryById(tx.categoryId!) 
                        : null;
                        
                    return Column(
                      children: [
                        TransactionTile(
                          transaction: tx,
                          category: category,
                        ),
                        if (tx != recentTransactions.last)
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

  void _triggerSync(GmailImportProvider importProvider, TransactionProvider txProvider) async {
    final addedCount = await importProvider.autoSync(txProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync Complete! Added $addedCount new transaction(s).')),
      );
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

        return Consumer2<GmailImportProvider, TransactionProvider>(
          builder: (context, importProvider, txProvider, child) {
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
                        _triggerSync(importProvider, txProvider);
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

