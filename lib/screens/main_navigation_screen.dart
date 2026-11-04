import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../app/theme/app_colors.dart';
import '../widgets/glass/glass.dart';

import 'home/home_screen.dart';
import 'transactions/transactions_screen.dart';
import 'wallet/wallet_dashboard_screen.dart';
import 'analytics/analytics_screen.dart';
import 'profile/profile_screen.dart';
import 'wallet/widgets/spendz_pop_sheet.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransactionProvider>().loadTransactions();
        context.read<WalletProvider>().loadWallet();
      }
    });
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    TransactionsScreen(),
    WalletDashboardScreen(),
    AnalyticsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84.0),
        child: FloatingActionButton(
          heroTag: 'spendz_pop_fab',
          mini: true,
          backgroundColor: AppColors.getPrimary(context),
          foregroundColor: Colors.white,
          elevation: 6,
          tooltip: 'Spendz POP Quick Wallet',
          onPressed: () => SpendzPopSheet.show(context),
          child: const Icon(Icons.bolt_rounded, size: 22),
        ),
      ),
      bottomNavigationBar: GlassNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          GlassNavigationItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          GlassNavigationItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: 'Activity',
          ),
          GlassNavigationItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet_rounded,
            label: 'Wallet',
          ),
          GlassNavigationItem(
            icon: Icons.insights_outlined,
            activeIcon: Icons.insights_rounded,
            label: 'Insights',
          ),
          GlassNavigationItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
