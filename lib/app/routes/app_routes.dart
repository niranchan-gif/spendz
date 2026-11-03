import 'package:flutter/material.dart';

import '../../screens/main_navigation_screen.dart';
import '../../screens/transactions/add_transaction_screen.dart';
import '../../screens/transactions/transactions_screen.dart';
import '../../screens/transactions/imported_transactions_screen.dart';
import '../../screens/wallet/wallet_dashboard_screen.dart';
import '../../screens/wallet/cards_screen.dart';
import '../../screens/wallet/documents_screen.dart';
import '../../screens/wallet/passes_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/analytics/analytics_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String mainNav = '/main';
  static const String addTransaction = '/add-transaction';
  static const String activity = '/activity';
  static const String importReview = '/import-review';
  static const String wallet = '/wallet';
  static const String cards = '/cards';
  static const String documents = '/documents';
  static const String passes = '/passes';
  static const String profile = '/profile';
  static const String insights = '/insights';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      mainNav: (context) => const MainNavigationScreen(),
      addTransaction: (context) => const AddTransactionScreen(),
      activity: (context) => const TransactionsScreen(),
      importReview: (context) => const ImportedTransactionsScreen(),
      wallet: (context) => const WalletDashboardScreen(),
      cards: (context) => const CardsScreen(),
      documents: (context) => const DocumentsScreen(),
      passes: (context) => const PassesScreen(),
      profile: (context) => const ProfileScreen(),
      insights: (context) => const AnalyticsScreen(),
    };
  }
}
