import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/spendz_colors.dart';
import '../presentation/widgets/spendz_bottom_navigation.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';

import 'home/home_screen.dart';
import 'transactions/transactions_screen.dart';
import 'wallet/wallet_dashboard_screen.dart';
import 'analytics/analytics_screen.dart';
import 'profile/profile_screen.dart';

/// Spendz 2.0 Main Navigation Screen.
/// Seamlessly anchors the five core fintech experiences:
/// Home, Activity, Wallet, Insights, Profile with a custom floating dock.
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
      backgroundColor: SpendzColors.background(context),
      extendBody: false,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: SpendzBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        destinations: const [
          SpendzNavigationDestination(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'Home',
          ),
          SpendzNavigationDestination(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: 'Activity',
          ),
          SpendzNavigationDestination(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet_rounded,
            label: 'Wallet',
          ),
          SpendzNavigationDestination(
            icon: Icons.insights_outlined,
            activeIcon: Icons.insights_rounded,
            label: 'Insights',
          ),
          SpendzNavigationDestination(
            icon: Icons.face_outlined,
            activeIcon: Icons.face_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
