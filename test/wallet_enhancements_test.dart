import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:spendz/database/database_helper.dart';
import 'package:spendz/database/wallet_document_repository.dart';
import 'package:spendz/database/wallet_card_repository.dart';
import 'package:spendz/features/wallet/security/wallet_auth_service.dart';
import 'package:spendz/features/wallet/security/wallet_key_service.dart';
import 'package:spendz/models/wallet_document_model.dart';
import 'package:spendz/models/wallet_card_model.dart';
import 'package:spendz/providers/wallet_document_provider.dart';
import 'package:spendz/providers/wallet_card_provider.dart';
import 'package:spendz/providers/wallet_provider.dart';
import 'package:spendz/screens/wallet/document_preview_screen.dart';
import 'package:spendz/screens/wallet/wallet_dashboard_screen.dart';
import 'package:spendz/screens/wallet/cards_screen.dart';
import 'package:spendz/screens/wallet/widgets/stitch_spotlight_card.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late WalletKeyService keyService;
  late WalletDocumentRepository docRepo;
  late WalletCardRepository cardRepo;
  late WalletProvider walletProvider;
  late WalletDocumentProvider docProvider;
  late WalletCardProvider cardProvider;

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() async {
    docRepo = WalletDocumentRepository();
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

  test('Payment document categories map to payment spotlight cards', () {
    final now = DateTime.now();
    final debitDocument = WalletDocumentModel(
      id: 'debit_doc',
      documentName: 'HDFC Debit Card',
      category: 'debit_card',
      holderName: 'Riya Sen',
      maskedIdentifier: '•••• 2841',
      createdAt: now,
      updatedAt: now,
    );
    final creditDocument = WalletDocumentModel(
      id: 'credit_doc',
      documentName: 'ICICI Credit Card',
      category: 'credit_card',
      holderName: 'Riya Sen',
      maskedIdentifier: '•••• 6128',
      createdAt: now,
      updatedAt: now,
    );

    expect(
      StitchSpotlightCard.fromDocument(document: debitDocument).cardType,
      StitchCardType.debit,
    );
    expect(
      StitchSpotlightCard.fromDocument(document: creditDocument).cardType,
      StitchCardType.credit,
    );
  });

  Widget buildTestHarness(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletAuthService()),
        ChangeNotifierProvider.value(value: docProvider),
        ChangeNotifierProvider.value(value: cardProvider),
        ChangeNotifierProvider.value(value: walletProvider),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('1. Document Details Unified Action Buttons Tests', () {
    testWidgets(
      'Renders Open, Save to Phone, Share, Edit with no repeated action row',
      (tester) async {
        final doc = WalletDocumentModel(
          id: 'aadhaar_test_1',
          documentName: 'Aadhaar Card',
          category: 'aadhaar',
          holderName: 'Aarav Sharma',
          maskedIdentifier: '•••• •••• 1234',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );

        await tester.pumpWidget(
          buildTestHarness(DocumentPreviewScreen(document: doc)),
        );
        await tester.pumpAndSettle();

        // Check Unified Actions
        expect(find.text('Open'), findsOneWidget);
        expect(find.text('Save to Phone'), findsOneWidget);
        expect(find.text('Share'), findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);

        // Verify no duplicate actions exist
        expect(find.text('Download'), findsNothing);
        expect(find.text('Export PDF'), findsNothing);
        expect(find.text('View PDF'), findsNothing);
      },
    );
  });

  group('2. Category Direct Navigation Tests', () {
    testWidgets(
      'Tapping Aadhaar opens Aadhaar preview directly when 1 doc exists',
      (tester) async {
        // Seed 1 Aadhaar doc
        final doc = WalletDocumentModel(
          id: 'seed_aadhaar_1',
          documentName: 'Aadhaar Card',
          category: 'aadhaar',
          holderName: 'Priya Patel',
          maskedIdentifier: '•••• •••• 5678',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.runAsync(() async {
          await docRepo.insert(doc);
          await docProvider.loadDocuments();
        });

        await tester.pumpWidget(
          buildTestHarness(const WalletDashboardScreen()),
        );
        await tester.pumpAndSettle();

        // Find Aadhaar tile in grid
        final aadhaarTile = find.text('Aadhaar Card');
        expect(aadhaarTile, findsOneWidget);

        await tester.tap(aadhaarTile);
        await tester.pumpAndSettle();

        // Must be on DocumentPreviewScreen for Priya Patel's Aadhaar!
        expect(find.byType(DocumentPreviewScreen), findsOneWidget);
        expect(find.text('Priya Patel'), findsWidgets);
      },
    );

    testWidgets('Spotlight and directory follow card add and delete', (
      tester,
    ) async {
      final card = WalletCardModel(
        id: 'live_debit_card',
        nickname: 'Live debit card',
        issuerName: 'Spendz Bank',
        cardholderName: 'Riya Sen',
        maskedNumber: '•••• •••• 2841',
        lastFour: '2841',
        expiryMonth: 8,
        expiryYear: 29,
        cardType: 'debit',
        cardNetwork: 'visa',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestHarness(const WalletDashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Live debit card'), findsNothing);

      await tester.runAsync(() => cardProvider.addCard(card));
      await tester.pumpAndSettle();
      expect(find.text('Live debit card'), findsOneWidget);
      expect(find.textContaining('2841'), findsWidgets);

      await tester.runAsync(() => cardProvider.deleteCard(card.id));
      await tester.pumpAndSettle();
      expect(find.text('Live debit card'), findsNothing);
    });
  });

  group('3. Wallet Card and Document List Tests', () {
    testWidgets('CardsScreen lists payment cards without a Card Studio deck', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Seed 2 cards
      final card1 = WalletCardModel(
        id: 'card_1',
        nickname: 'HDFC Regalia',
        issuerName: 'HDFC Bank',
        cardholderName: 'Rahul Mehra',
        maskedNumber: '•••• •••• •••• 4321',
        lastFour: '4321',
        expiryMonth: 10,
        expiryYear: 28,
        cardType: 'credit',
        cardNetwork: 'visa',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final card2 = WalletCardModel(
        id: 'card_2',
        nickname: 'ICICI Coral',
        issuerName: 'ICICI Bank',
        cardholderName: 'Rahul Mehra',
        maskedNumber: '•••• •••• •••• 8765',
        lastFour: '8765',
        expiryMonth: 12,
        expiryYear: 29,
        cardType: 'credit',
        cardNetwork: 'mastercard',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        await cardRepo.insert(card1);
        await cardRepo.insert(card2);
        await walletProvider.loadWallet();
      });

      await tester.pumpWidget(buildTestHarness(const CardsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Payment Cards'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(find.text('Card Studio'), findsNothing);
      expect(find.text('HDFC Regalia'), findsOneWidget);
      expect(find.text('ICICI Coral'), findsOneWidget);
    });

    testWidgets('CardsScreen filters payment cards and official documents', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Seed 1 payment card and 2 govt documents (Aadhaar and PAN)
      final paymentCard = WalletCardModel(
        id: 'credit_1',
        nickname: 'HDFC Regalia',
        issuerName: 'HDFC Bank',
        cardholderName: 'Kunal Sharma',
        maskedNumber: '•••• •••• •••• 1234',
        lastFour: '1234',
        expiryMonth: 5,
        expiryYear: 28,
        cardType: 'credit',
        cardNetwork: 'visa',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final aadhaarDoc = WalletDocumentModel(
        id: 'aadhaar_1',
        documentName: 'My Aadhaar',
        category: 'aadhaar',
        holderName: 'Kunal Sharma',
        maskedIdentifier: '•••• •••• 9988',
        description: 'Holder: Kunal Sharma\nNumber: •••• •••• 9988',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final panDoc = WalletDocumentModel(
        id: 'pan_1',
        documentName: 'Income Tax PAN',
        category: 'pan',
        holderName: 'Kunal Sharma',
        maskedIdentifier: 'ABCDE••••F',
        description: 'Holder: Kunal Sharma\nNumber: ABCDE••••F',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('wallet_cards');
        await db.delete('wallet_documents');

        await cardRepo.insert(paymentCard);
        await docRepo.insert(aadhaarDoc);
        await docRepo.insert(panDoc);
        await walletProvider.loadWallet();
      });

      await tester.pumpWidget(buildTestHarness(const CardsScreen()));
      await tester.pumpAndSettle();

      // All saved records are listed together.
      expect(find.text('All Cards (3)'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);

      // Verify both payment cards and documents appear in list/stack
      expect(find.text('HDFC Regalia'), findsWidgets);
      expect(find.text('My Aadhaar'), findsWidgets);
      expect(find.text('Income Tax PAN'), findsWidgets);

      // Filter by Govt IDs
      final govtChip = find.text('Govt IDs');
      expect(govtChip, findsOneWidget);
      await tester.tap(govtChip);
      await tester.pumpAndSettle();

      expect(find.text('HDFC Regalia'), findsNothing);
      expect(find.text('My Aadhaar'), findsOneWidget);
      expect(find.text('Income Tax PAN'), findsOneWidget);

      // Filter by Payment Cards
      final paymentChip = find.text('Payment Cards');
      expect(paymentChip, findsOneWidget);
      await tester.tap(paymentChip);
      await tester.pumpAndSettle();

      expect(find.text('HDFC Regalia'), findsOneWidget);
      expect(find.text('My Aadhaar'), findsNothing);
      expect(find.text('Income Tax PAN'), findsNothing);
    });
  });
}
