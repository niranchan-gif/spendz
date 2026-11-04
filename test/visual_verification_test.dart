import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:spendz/app/theme/app_theme.dart';
import 'package:spendz/database/database_helper.dart';
import 'package:spendz/database/wallet_card_repository.dart';
import 'package:spendz/database/wallet_document_repository.dart';
import 'package:spendz/database/wallet_pass_repository.dart';
import 'package:spendz/features/wallet/security/wallet_auth_service.dart';
import 'package:spendz/features/wallet/security/wallet_key_service.dart';
import 'package:spendz/models/transaction_model.dart';
import 'package:spendz/models/wallet_card_model.dart';
import 'package:spendz/models/wallet_document_model.dart';
import 'package:spendz/models/wallet_pass_model.dart';
import 'package:spendz/providers/category_provider.dart';
import 'package:spendz/providers/dashboard_provider.dart';
import 'package:spendz/providers/gmail_import_provider.dart';
import 'package:spendz/providers/theme_provider.dart';
import 'package:spendz/providers/transaction_provider.dart';
import 'package:spendz/providers/wallet_card_provider.dart';
import 'package:spendz/providers/wallet_document_provider.dart';
import 'package:spendz/providers/wallet_pass_provider.dart';
import 'package:spendz/providers/wallet_provider.dart';

import 'package:spendz/screens/analytics/analytics_screen.dart';
import 'package:spendz/screens/home/home_screen.dart';
import 'package:spendz/screens/profile/profile_screen.dart';
import 'package:spendz/screens/transactions/transactions_screen.dart';
import 'package:spendz/screens/wallet/card_detail_screen.dart';
import 'package:spendz/screens/wallet/cards_screen.dart';
import 'package:spendz/screens/wallet/document_attachment_scanner_screen.dart';
import 'package:spendz/screens/wallet/document_creation_screen.dart';
import 'package:spendz/screens/wallet/document_preview_screen.dart';
import 'package:spendz/screens/wallet/wallet_dashboard_screen.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  GoogleFonts.config.allowRuntimeFetching = false;

  late WalletKeyService keyService;
  late WalletDocumentRepository docRepo;
  late WalletCardRepository cardRepo;
  late WalletPassRepository passRepo;
  late WalletProvider walletProvider;
  late WalletDocumentProvider docProvider;
  late WalletCardProvider cardProvider;
  late WalletPassProvider passProvider;
  late CategoryProvider categoryProvider;
  late TransactionProvider transactionProvider;
  late DashboardProvider dashboardProvider;
  late GmailImportProvider gmailImportProvider;
  late ThemeProvider themeProvider;
  late WalletAuthService authService;

  const screenshotDir =
      'C:/Users/gpk00/.gemini/antigravity/brain/274b8f6a-c2af-42be-a932-638c501feab6/screenshots';

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    docRepo = WalletDocumentRepository();
    cardRepo = WalletCardRepository();
    passRepo = WalletPassRepository();

    final db = await DatabaseHelper.instance.database;
    await db.delete('wallet_documents');
    await db.delete('wallet_cards');
    await db.delete('wallet_passes');
    await db.delete('transactions');

    keyService = WalletKeyService(secureStorage: const FlutterSecureStorage());
    await keyService.getOrCreateMasterKey(
      hasExistingVaultDocuments: () => false,
    );

    authService = WalletAuthService();
    walletProvider = WalletProvider();
    docProvider = WalletDocumentProvider();
    cardProvider = WalletCardProvider();
    passProvider = WalletPassProvider();
    categoryProvider = CategoryProvider();
    transactionProvider = TransactionProvider();
    dashboardProvider = DashboardProvider();
    gmailImportProvider = GmailImportProvider();
    themeProvider = ThemeProvider();

    // Seed dummy transactions for rich UI preview
    final now = DateTime.now();
    final demoTxs = [
      TransactionModel(
        id: 'tx_1',
        amount: 850.0,
        type: 'expense',
        categoryId: 'food',
        merchant: 'Blue Tokai Coffee',
        description: 'Cold brew and brunch',
        date: now.subtract(const Duration(hours: 2)),
        paymentMethod: 'UPI',
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      ),
      TransactionModel(
        id: 'tx_2',
        amount: 2400.0,
        type: 'expense',
        categoryId: 'shopping',
        merchant: 'Zara Fashion',
        description: 'Autumn essentials',
        date: now.subtract(const Duration(days: 1)),
        paymentMethod: 'Card',
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      ),
      TransactionModel(
        id: 'tx_3',
        amount: 85000.0,
        type: 'income',
        categoryId: 'salary',
        merchant: 'Antigravity Technologies',
        description: 'Monthly compensation',
        date: now.subtract(const Duration(days: 3)),
        paymentMethod: 'Bank Transfer',
        source: 'manual',
        createdAt: now,
        updatedAt: now,
      ),
    ];
    for (final tx in demoTxs) {
      await db.insert('transactions', tx.toMap());
    }

    // Seed dummy payment card
    final demoCard = WalletCardModel(
      id: 'card_demo_1',
      issuerName: 'HDFC Bank',
      cardType: 'credit',
      cardNetwork: 'visa',
      cardholderName: 'ALEXANDER REED',
      maskedNumber: '•••• •••• •••• 8842',
      lastFour: '8842',
      expiryMonth: 11,
      expiryYear: 28,
      nickname: 'HDFC Regalia Gold',
      themeGradient: 'midnight_emerald',
      cardLayoutId: 'obsidian_fintech',
      isFavorite: true,
      createdAt: now,
      updatedAt: now,
    );
    await cardRepo.insert(demoCard);

    // Seed dummy Aadhaar document
    final demoDoc = WalletDocumentModel(
      id: 'doc_demo_1',
      documentName: 'Aadhaar Card',
      category: 'aadhaar',
      holderName: 'Alexander Reed',
      maskedIdentifier: '•••• •••• 4291',
      description:
          'DOB: 14/08/1996\nFather Name: Arthur Reed\nAddress: 42 Emerald Way, Indiranagar, Bengaluru, KA 560038\nNotes: Primary digital ID verified via UIDAI portal.',
      createdAt: now,
      updatedAt: now,
    );
    await docRepo.insert(demoDoc);

    // Seed dummy digital pass
    final demoPass = WalletPassModel(
      id: 'pass_demo_1',
      title: 'Bengaluru Metro Pass',
      passType: 'qr_code',
      issuer: 'BMRCL Transit',
      encryptedCodePath: 'BMRCL-METRO-PASS-998822',
      validUntil: now.add(const Duration(days: 180)),
      createdAt: now,
      updatedAt: now,
    );
    await passRepo.insert(demoPass);

    await walletProvider.loadWallet();
    await transactionProvider.loadTransactions();
    dashboardProvider.update(transactionProvider.transactions);
  });

  Widget buildScreenHarness({
    required Widget screen,
    required bool isDark,
    required GlobalKey key,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: categoryProvider),
        ChangeNotifierProvider.value(value: transactionProvider),
        ChangeNotifierProvider.value(value: dashboardProvider),
        ChangeNotifierProvider.value(value: gmailImportProvider),
        ChangeNotifierProvider.value(value: walletProvider),
        ChangeNotifierProvider.value(value: docProvider),
        ChangeNotifierProvider.value(value: cardProvider),
        ChangeNotifierProvider.value(value: passProvider),
      ],
      child: MaterialApp(
        theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: SizedBox(width: 390, height: 844, child: screen),
          ),
        ),
      ),
    );
  }

  Future<void> captureScreenShot(
    WidgetTester tester,
    GlobalKey key,
    String fileName,
  ) async {
    await tester.runAsync(() async {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = File('$screenshotDir/$fileName');
          await file.writeAsBytes(byteData.buffer.asUint8List());
          print('Successfully saved screenshot: $fileName');
        }
      }
    });
  }

  group('Visual Verification Suite - 10 Screens (Dark & Light)', () {
    testWidgets('1. Home Dashboard (Dark & Light)', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;

      // Dark Mode
      final keyDark = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: const HomeScreen(),
          isDark: true,
          key: keyDark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyDark, '01_home_dark.png');

      // Light Mode
      final keyLight = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: const HomeScreen(),
          isDark: false,
          key: keyLight,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyLight, '01_home_light.png');
    });

    testWidgets('2. Activity Feed (Dark & Light)', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;

      // Dark Mode
      final keyDark = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: const TransactionsScreen(),
          isDark: true,
          key: keyDark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyDark, '02_activity_dark.png');

      // Light Mode
      final keyLight = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: const TransactionsScreen(),
          isDark: false,
          key: keyLight,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyLight, '02_activity_light.png');
    });

    testWidgets('3. Insights & Analytics (Dark & Light)', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;

      // Dark Mode
      final keyDark = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: const AnalyticsScreen(),
          isDark: true,
          key: keyDark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyDark, '03_insights_dark.png');

      // Light Mode
      final keyLight = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: const AnalyticsScreen(),
          isDark: false,
          key: keyLight,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyLight, '03_insights_light.png');
    });

    testWidgets('4. Profile & Preferences Center (Dark & Light)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;

      // Dark Mode
      final keyDark = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: const ProfileScreen(),
          isDark: true,
          key: keyDark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyDark, '04_profile_dark.png');

      // Light Mode
      final keyLight = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: const ProfileScreen(),
          isDark: false,
          key: keyLight,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyLight, '04_profile_light.png');
    });

    testWidgets('5. Wallet Hub Dashboard (Dark & Light)', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;

      // Dark Mode
      final keyDark = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: const WalletDashboardScreen(),
          isDark: true,
          key: keyDark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyDark, '05_wallet_dark.png');

      // Light Mode
      final keyLight = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: const WalletDashboardScreen(),
          isDark: false,
          key: keyLight,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyLight, '05_wallet_light.png');
    });

    testWidgets('6. Card Studio 2.0 Stack (Dark & Light)', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;

      // Dark Mode
      final keyDark = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: const CardsScreen(),
          isDark: true,
          key: keyDark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyDark, '06_card_studio_dark.png');

      // Light Mode
      final keyLight = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: const CardsScreen(),
          isDark: false,
          key: keyLight,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyLight, '06_card_studio_light.png');
    });

    testWidgets('7. Card Detail View (Dark & Light)', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;

      late WalletCardModel card;
      await tester.runAsync(() async {
        card = (await cardRepo.getAllCards()).first;
      });

      // Dark Mode
      final keyDark = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: CardDetailScreen(card: card),
          isDark: true,
          key: keyDark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyDark, '07_card_detail_dark.png');

      // Light Mode
      final keyLight = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: CardDetailScreen(card: card),
          isDark: false,
          key: keyLight,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyLight, '07_card_detail_light.png');
    });

    testWidgets('8. Document Detail & Vault Preview (Dark & Light)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;

      late WalletDocumentModel doc;
      await tester.runAsync(() async {
        doc = (await docRepo.getAllDocuments()).first;
      });

      // Dark Mode
      final keyDark = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: DocumentPreviewScreen(document: doc),
          isDark: true,
          key: keyDark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyDark, '08_doc_detail_dark.png');

      // Light Mode
      final keyLight = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: DocumentPreviewScreen(document: doc),
          isDark: false,
          key: keyLight,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyLight, '08_doc_detail_light.png');
    });

    testWidgets('9. Document Creation Workflow (Dark & Light)', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;

      // Dark Mode
      final keyDark = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: const DocumentCreationScreen(initialCategory: 'aadhaar'),
          isDark: true,
          key: keyDark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyDark, '09_doc_creation_dark.png');

      // Light Mode
      final keyLight = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: const DocumentCreationScreen(initialCategory: 'aadhaar'),
          isDark: false,
          key: keyLight,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyLight, '09_doc_creation_light.png');
    });

    testWidgets('10. Multi-Page PDF Scanner Review (Dark & Light)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;

      // Dark Mode
      final keyDark = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: const DocumentAttachmentScannerScreen(
            category: 'aadhaar',
            suggestedTitle: 'Aadhaar Card',
          ),
          isDark: true,
          key: keyDark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyDark, '10_scanner_review_dark.png');

      // Light Mode
      final keyLight = GlobalKey();
      await tester.pumpWidget(
        buildScreenHarness(
          screen: const DocumentAttachmentScannerScreen(
            category: 'aadhaar',
            suggestedTitle: 'Aadhaar Card',
          ),
          isDark: false,
          key: keyLight,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreenShot(tester, keyLight, '10_scanner_review_light.png');
    });
  });
}
