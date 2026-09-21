import 'package:flutter/material.dart';

// Import screens when created
// import '../../screens/home/home_screen.dart';
// import '../../screens/transactions/transactions_screen.dart';
// import '../../screens/transactions/add_transaction_screen.dart';
import '../../screens/transactions/import_review_screen.dart';
// import '../../screens/analytics/analytics_screen.dart';
// import '../../screens/categories/categories_screen.dart';
// import '../../screens/settings/settings_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String addTransaction = '/add-transaction';
  static const String transactionDetails = '/transaction-details';
  static const String importReview = '/import-review';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // home: (context) => const HomeScreen(), // Will replace with MainScreen for BottomNav
      // addTransaction: (context) => const AddTransactionScreen(),
      importReview: (context) => const ImportReviewScreen(),
    };
  }
}
