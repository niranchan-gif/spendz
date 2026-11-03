import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/gmail_import_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/wallet_card_provider.dart';
import '../providers/wallet_document_provider.dart';
import '../providers/wallet_pass_provider.dart';

import 'theme/app_theme.dart';
import 'routes/app_routes.dart';

// Import main navigation screen when created
// import '../screens/main_navigation_screen.dart';
import '../screens/splash/splash_screen.dart';

class SpendzApp extends StatelessWidget {
  const SpendzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => GmailImportProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => WalletCardProvider()),
        ChangeNotifierProvider(create: (_) => WalletDocumentProvider()),
        ChangeNotifierProvider(create: (_) => WalletPassProvider()),
        ChangeNotifierProxyProvider<TransactionProvider, DashboardProvider>(
          create: (_) => DashboardProvider(),
          update: (_, txProvider, dashboardProvider) {
            dashboardProvider?.update(txProvider.transactions);
            return dashboardProvider!;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Spendz',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Replace with actual routes or home screen
        home: const SplashScreen(),
        routes: AppRoutes.getRoutes(),
      ),
    );
  }
}
