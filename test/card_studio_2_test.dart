import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:spendz/database/database_helper.dart';
import 'package:spendz/database/wallet_card_repository.dart';
import 'package:spendz/features/wallet/security/wallet_auth_service.dart';
import 'package:spendz/features/wallet/security/wallet_key_service.dart';
import 'package:spendz/models/wallet_card_model.dart';
import 'package:spendz/providers/wallet_card_provider.dart';
import 'package:spendz/providers/wallet_document_provider.dart';
import 'package:spendz/providers/wallet_provider.dart';
import 'package:spendz/screens/wallet/card_studio/card_canvas_widget.dart';
import 'package:spendz/screens/wallet/card_studio/card_layout_sheet.dart';
import 'package:spendz/screens/wallet/card_studio/card_studio_layout.dart';
import 'package:spendz/screens/wallet/card_studio/card_studio_theme.dart';
import 'package:spendz/screens/wallet/card_studio/card_theme_sheet.dart';
import 'package:spendz/screens/wallet/card_studio/manage_cards_screen.dart';
import 'package:spendz/screens/wallet/cards_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late WalletKeyService keyService;
  late WalletCardRepository cardRepo;
  late WalletProvider walletProvider;
  late WalletDocumentProvider docProvider;
  late WalletCardProvider cardProvider;

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() async {
    cardRepo = WalletCardRepository();

    final db = await DatabaseHelper.instance.database;
    await db.delete('wallet_documents');
    await db.delete('wallet_cards');

    keyService = WalletKeyService(secureStorage: const FlutterSecureStorage());
    await keyService.getOrCreateMasterKey(
      hasExistingVaultDocuments: () => false,
    );

    walletProvider = WalletProvider();
    docProvider = WalletDocumentProvider();
    cardProvider = WalletCardProvider();
  });

  tearDown(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('wallet_documents');
    await db.delete('wallet_cards');
  });

  Widget buildTestHarness(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletAuthService()),
        ChangeNotifierProvider.value(value: docProvider),
        ChangeNotifierProvider.value(value: cardProvider),
        ChangeNotifierProvider.value(value: walletProvider),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('1. Card Studio 2.0 Themes & Layout System Tests', () {
    test('All 8 required themes are registered with unique styling', () {
      expect(CardStudioTheme.allThemes.length, equals(8));
      final ids = CardStudioTheme.allThemes.map((t) => t.id).toSet();
      expect(ids.contains('midnight_emerald'), isTrue);
      expect(ids.contains('obsidian_black'), isTrue);
      expect(ids.contains('royal_amethyst'), isTrue);
      expect(ids.contains('ocean_sapphire'), isTrue);
      expect(ids.contains('champagne_gold'), isTrue);
      expect(ids.contains('crimson_luxe'), isTrue);
      expect(ids.contains('arctic_silver'), isTrue);
      expect(ids.contains('aurora_mint'), isTrue);

      // Verify each theme has distinct custom geometry painters
      for (final theme in CardStudioTheme.allThemes) {
        expect(theme.backgroundPainter, isNotNull);
        expect(theme.backgroundGradient.colors.length, greaterThanOrEqualTo(2));
      }
    });

    test('All 5 required layout templates are registered', () {
      expect(CardStudioLayout.allLayouts.length, equals(5));
      final layoutIds = CardStudioLayout.allLayouts.map((l) => l.id).toSet();
      expect(layoutIds.contains('minimal_luxury'), isTrue);
      expect(layoutIds.contains('bold_gradient'), isTrue);
      expect(layoutIds.contains('metallic_premium'), isTrue);
      expect(layoutIds.contains('modern_geometric'), isTrue);
      expect(layoutIds.contains('dark_minimal'), isTrue);
    });

    testWidgets(
      'CardCanvasWidget renders card across different themes and layouts',
      (tester) async {
        final card = WalletCardModel(
          id: 'canvas_card_1',
          nickname: 'Sapphire Metal',
          issuerName: 'Chase Sapphire',
          cardholderName: 'Aarav Patel',
          maskedNumber: '•••• •••• •••• 9876',
          lastFour: '9876',
          expiryMonth: 8,
          expiryYear: 29,
          cardType: 'credit',
          cardNetwork: 'visa',
          themeGradient: 'ocean_sapphire',
          cardLayoutId: 'bold_gradient',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: CardCanvasWidget(card: card)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('CHASE SAPPHIRE'), findsOneWidget);
        expect(find.text('AARAV PATEL'), findsOneWidget);
        expect(find.text('08/29'), findsOneWidget);
        expect(find.text('VISA'), findsOneWidget);
      },
    );
  });

  group('2. Stacked Card Collection & Carousel Tests', () {
    testWidgets(
      'Renders layered stacked cards, indicators, controls and active card info',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final card1 = WalletCardModel(
          id: 'c1',
          nickname: 'Regalia Gold',
          issuerName: 'HDFC Bank',
          cardholderName: 'Kunal Verma',
          maskedNumber: '•••• •••• •••• 1111',
          lastFour: '1111',
          expiryMonth: 11,
          expiryYear: 28,
          themeGradient: 'midnight_emerald',
          cardLayoutId: 'minimal_luxury',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final card2 = WalletCardModel(
          id: 'c2',
          nickname: 'Coral Metal',
          issuerName: 'ICICI Bank',
          cardholderName: 'Kunal Verma',
          maskedNumber: '•••• •••• •••• 2222',
          lastFour: '2222',
          expiryMonth: 5,
          expiryYear: 29,
          themeGradient: 'royal_amethyst',
          cardLayoutId: 'bold_gradient',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final card3 = WalletCardModel(
          id: 'c3',
          nickname: 'Magnus Prime',
          issuerName: 'Axis Bank',
          cardholderName: 'Kunal Verma',
          maskedNumber: '•••• •••• •••• 3333',
          lastFour: '3333',
          expiryMonth: 9,
          expiryYear: 30,
          themeGradient: 'obsidian_black',
          cardLayoutId: 'dark_minimal',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.runAsync(() async {
          await cardRepo.insert(card1);
          await cardRepo.insert(card2);
          await cardRepo.insert(card3);
          await walletProvider.loadWallet();
        });

        await tester.pumpWidget(buildTestHarness(const CardsScreen()));
        await tester.pumpAndSettle();

        // Header checks
        expect(find.text('Card Studio'), findsOneWidget);
        expect(find.text('Premium Cards · Your Collection'), findsOneWidget);

        // Stack navigation indicators
        expect(find.text('Card 1 of 3'), findsOneWidget);
        expect(find.text('Cards in Deck (3)'), findsOneWidget);

        // Active card information panel
        expect(find.text('Regalia Gold'), findsWidgets);
        expect(find.text('Change Theme'), findsOneWidget);
        expect(find.text('Change Layout'), findsOneWidget);
        expect(find.text('Secure Reveal'), findsOneWidget);
        expect(find.text('Copy Number'), findsOneWidget);

        // Swipe left on the PageView to navigate to card 2
        await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
        await tester.pumpAndSettle();

        expect(find.text('Card 2 of 3'), findsOneWidget);
        expect(find.text('Coral Metal'), findsWidgets);

        // Next control button tap to navigate to card 3
        final nextBtn = find.byTooltip('Next Card');
        expect(nextBtn, findsOneWidget);
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();

        expect(find.text('Card 3 of 3'), findsOneWidget);
        expect(find.text('Magnus Prime'), findsWidgets);
      },
    );
  });

  group('3. Theme & Layout Selectors Bottom Sheet Tests', () {
    testWidgets('CardThemeSheet displays all 8 themes and applies selection', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final card = WalletCardModel(
        id: 'theme_test_card',
        nickname: 'Daily Debit',
        issuerName: 'Kotak Bank',
        cardholderName: 'Simran Kaur',
        maskedNumber: '•••• •••• •••• 5555',
        lastFour: '5555',
        expiryMonth: 4,
        expiryYear: 28,
        themeGradient: 'midnight_emerald',
        cardLayoutId: 'minimal_luxury',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        await cardRepo.insert(card);
        await cardProvider.loadCards();
      });

      await tester.pumpWidget(buildTestHarness(CardThemeSheet(card: card)));
      await tester.pumpAndSettle();

      expect(find.text('Change Card Theme'), findsOneWidget);
      expect(find.text('Available Luxury Themes (8)'), findsOneWidget);
      expect(find.text('Crimson Luxe'), findsOneWidget);
      expect(find.text('Aurora Mint'), findsOneWidget);

      // Tap on Crimson Luxe
      await tester.ensureVisible(find.text('Crimson Luxe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crimson Luxe'));
      await tester.pumpAndSettle();

      // Tap Apply Theme inside runAsync for SQLite FFI
      await tester.ensureVisible(find.text('Apply Theme'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Apply Theme'));
      });
      await tester.pumpAndSettle();

      // Verify theme updated in database
      WalletCardModel? updated;
      await tester.runAsync(() async {
        updated = await cardRepo.getCardById(card.id);
      });
      expect(updated?.themeGradient, equals('crimson_luxe'));
    });

    testWidgets(
      'CardLayoutSheet displays all 5 layouts and applies selection',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final card = WalletCardModel(
          id: 'layout_test_card',
          nickname: 'Travel Card',
          issuerName: 'SBI Card',
          cardholderName: 'Simran Kaur',
          maskedNumber: '•••• •••• •••• 7777',
          lastFour: '7777',
          expiryMonth: 6,
          expiryYear: 29,
          themeGradient: 'champagne_gold',
          cardLayoutId: 'minimal_luxury',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.runAsync(() async {
          await cardRepo.insert(card);
          await cardProvider.loadCards();
        });

        await tester.pumpWidget(buildTestHarness(CardLayoutSheet(card: card)));
        await tester.pumpAndSettle();

        expect(find.text('Change Card Layout'), findsOneWidget);
        expect(find.text('Available Design Layouts (5)'), findsOneWidget);

        // Tap Metallic Premium
        await tester.ensureVisible(find.text('Metallic Premium'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Metallic Premium'));
        await tester.pumpAndSettle();

        // Tap Apply Layout inside runAsync for SQLite FFI
        await tester.ensureVisible(find.text('Apply Layout'));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await tester.tap(find.text('Apply Layout'));
        });
        await tester.pumpAndSettle();

        // Verify layout updated in database
        WalletCardModel? updated;
        await tester.runAsync(() async {
          updated = await cardRepo.getCardById(card.id);
        });
        expect(updated?.cardLayoutId, equals('metallic_premium'));
      },
    );
  });

  group('4. Manage Cards Screen Tests', () {
    testWidgets(
      'ManageCardsScreen lists saved cards, allows setting default and reordering',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final card1 = WalletCardModel(
          id: 'mc1',
          nickname: 'Primary Spender',
          issuerName: 'HDFC Bank',
          cardholderName: 'Nisha Roy',
          maskedNumber: '•••• •••• •••• 4444',
          lastFour: '4444',
          expiryMonth: 1,
          expiryYear: 27,
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final card2 = WalletCardModel(
          id: 'mc2',
          nickname: 'Backup Card',
          issuerName: 'ICICI Bank',
          cardholderName: 'Nisha Roy',
          maskedNumber: '•••• •••• •••• 8888',
          lastFour: '8888',
          expiryMonth: 2,
          expiryYear: 28,
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.runAsync(() async {
          await cardRepo.insert(card1);
          await cardRepo.insert(card2);
          await cardProvider.loadCards();
        });

        await tester.pumpWidget(buildTestHarness(const ManageCardsScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Manage Cards'), findsOneWidget);
        expect(find.text('Saved Collection (2)'), findsOneWidget);
        expect(find.text('Primary Spender'), findsOneWidget);
        expect(find.text('Backup Card'), findsOneWidget);

        // Set Primary Spender as Default
        final setDefaultButtons = find.byTooltip('Set as Default Card');
        expect(setDefaultButtons, findsWidgets);
        await tester.runAsync(() async {
          await tester.tap(setDefaultButtons.first);
        });
        await tester.pumpAndSettle();

        WalletCardModel? updatedCard;
        await tester.runAsync(() async {
          updatedCard = await cardRepo.getCardById(card1.id);
        });
        expect(updatedCard?.isDefault, isTrue);
      },
    );
  });
}
