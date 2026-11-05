import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/wallet/security/wallet_auth_service.dart';
import '../features/wallet/services/document_vault_service.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/gmail_import_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/wallet_card_provider.dart';
import '../providers/wallet_document_provider.dart';
import '../providers/wallet_pass_provider.dart';
import '../providers/theme_provider.dart';

import 'theme/spendz_theme.dart';
import 'routes/app_routes.dart';
import '../screens/splash/splash_screen.dart';

class SpendzApp extends StatefulWidget {
  const SpendzApp({super.key});

  @override
  State<SpendzApp> createState() => _SpendzAppState();
}

class _SpendzAppState extends State<SpendzApp> with WidgetsBindingObserver {
  late final WalletAuthService _authService;
  final DocumentVaultService _vaultService = DocumentVaultService();

  @override
  void initState() {
    super.initState();
    _authService = WalletAuthService();
    WidgetsBinding.instance.addObserver(this);
    _vaultService.cleanupAllTemporaryFiles();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _authService.onAppPaused();
      _vaultService.cleanupAllTemporaryFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authService),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => GmailImportProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => WalletCardProvider()),
        ChangeNotifierProvider(create: (_) => WalletDocumentProvider()),
        ChangeNotifierProvider(create: (_) => WalletPassProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<TransactionProvider, DashboardProvider>(
          create: (_) => DashboardProvider(),
          update: (_, txProvider, dashboardProvider) {
            dashboardProvider?.update(txProvider.transactions);
            return dashboardProvider!;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Spendz',
            debugShowCheckedModeBanner: false,
            theme: SpendzTheme.lightTheme,
            darkTheme: SpendzTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            routes: AppRoutes.getRoutes(),
          );
        },
      ),
    );
  }
}
