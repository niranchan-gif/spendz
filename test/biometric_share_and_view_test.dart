import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:spendz/database/database_helper.dart';
import 'package:spendz/database/wallet_document_repository.dart';
import 'package:spendz/features/wallet/security/secure_number_service.dart';
import 'package:spendz/features/wallet/security/wallet_auth_service.dart';
import 'package:spendz/features/wallet/security/wallet_key_service.dart';
import 'package:spendz/features/wallet/services/document_vault_service.dart';
import 'package:spendz/models/wallet_document_model.dart';
import 'package:spendz/providers/wallet_card_provider.dart';
import 'package:spendz/providers/wallet_document_provider.dart';
import 'package:spendz/providers/wallet_provider.dart';
import 'package:spendz/screens/wallet/document_preview_screen.dart';
import 'package:spendz/screens/wallet/widgets/virtual_document_card.dart';
import 'package:spendz/widgets/design_system/secure_protected_field.dart';

class FakeWalletAuthService extends WalletAuthService {
  bool shouldSucceed = true;
  int authenticateCallCount = 0;
  String? lastReason;

  @override
  Future<bool> authenticate({String localizedReason = 'Unlock Spendz Vault'}) async {
    authenticateCallCount++;
    lastReason = localizedReason;
    if (shouldSucceed) {
      recordActivity();
      return true;
    } else {
      return false;
    }
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempVaultDir;
  late Directory tempCacheDir;
  late WalletDocumentRepository docRepo;
  late DocumentVaultService vaultService;
  late SecureNumberService secureNumberService;
  late WalletKeyService keyService;
  late FakeWalletAuthService authService;

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() async {
    tempVaultDir = await Directory.systemTemp.createTemp('spendz_biometric_vault_');
    tempCacheDir = await Directory.systemTemp.createTemp('spendz_biometric_cache_');

    docRepo = WalletDocumentRepository();
    vaultService = DocumentVaultService(
      documentRepository: docRepo,
      customVaultDirectory: tempVaultDir.path,
      customTempDirectory: tempCacheDir.path,
    );
    secureNumberService = SecureNumberService();
    authService = FakeWalletAuthService();

    final db = await DatabaseHelper.instance.database;
    await db.delete('wallet_documents');
    await db.delete('wallet_cards');

    keyService = WalletKeyService(secureStorage: const FlutterSecureStorage());
    await keyService.getOrCreateMasterKey(hasExistingVaultDocuments: () => false);
  });

  tearDown(() {
    try {
      tempVaultDir.deleteSync(recursive: true);
      tempCacheDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  Widget buildTestHarness({
    required Widget child,
    WalletProvider? walletProvider,
    WalletAuthService? customAuth,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WalletAuthService>.value(value: customAuth ?? authService),
        ChangeNotifierProvider(create: (_) => WalletDocumentProvider()),
        ChangeNotifierProvider(create: (_) => WalletCardProvider()),
        ChangeNotifierProvider<WalletProvider>.value(value: walletProvider ?? WalletProvider()),
      ],
      child: MaterialApp(
        home: Material(
          child: child,
        ),
      ),
    );
  }

  group('1. Biometric Guard for Viewing Private Numbers', () {
    testWidgets('SecureProtectedField masks number by default and reveals only with biometric authentication', (tester) async {
      authService.shouldSucceed = true;

      await tester.pumpWidget(
        buildTestHarness(
          child: SecureProtectedField(
            label: 'Aadhaar Number',
            maskedValue: '•••• •••• 9012',
            onRetrieveProtectedValue: () async => '123456789012',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially masked
      expect(find.text('•••• •••• 9012'), findsOneWidget);
      expect(find.text('123456789012'), findsNothing);

      // Tap reveal button
      final revealBtn = find.byIcon(Icons.visibility_outlined);
      expect(revealBtn, findsOneWidget);
      await tester.tap(revealBtn);
      await tester.pumpAndSettle();

      // Biometrics called and succeeded
      expect(authService.authenticateCallCount, equals(1));
      expect(find.text('123456789012'), findsOneWidget);

      // Tap again to re-mask
      final hideBtn = find.byIcon(Icons.visibility_off_outlined);
      expect(hideBtn, findsOneWidget);
      await tester.tap(hideBtn);
      await tester.pumpAndSettle();

      expect(find.text('•••• •••• 9012'), findsOneWidget);
      expect(find.text('123456789012'), findsNothing);
    });

    testWidgets('Failed biometric authentication keeps private number securely masked', (tester) async {
      authService.shouldSucceed = false;

      await tester.pumpWidget(
        buildTestHarness(
          child: SecureProtectedField(
            label: 'PAN Number',
            maskedValue: 'ABCDE••••F',
            onRetrieveProtectedValue: () async => 'ABCDE1234F',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ABCDE••••F'), findsOneWidget);

      // Tap reveal
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      // Authentication failed
      expect(authService.authenticateCallCount, equals(1));
      // Must stay masked!
      expect(find.text('ABCDE••••F'), findsOneWidget);
      expect(find.text('ABCDE1234F'), findsNothing);
    });

    testWidgets('VirtualDocumentCard tap-to-reveal prompts biometrics and reveals unmasked number', (tester) async {
      late WalletDocumentModel doc;
      await tester.runAsync(() async {
        doc = await vaultService.saveManualDocument(
          documentName: 'My Aadhaar',
          category: 'aadhaar',
          holderName: 'Vikram Seth',
          maskedIdentifier: '•••• •••• 4455',
          unmaskedIdentifier: '112233444455',
        );
      });

      authService.shouldSucceed = true;

      await tester.pumpWidget(
        buildTestHarness(
          child: VirtualDocumentCard(
            document: doc,
            allowReveal: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially shows masked number
      expect(find.text('•••• •••• 4455'), findsOneWidget);

      // Tap on the biometric lock/number area
      final numberArea = find.text('•••• •••• 4455');
      await tester.tap(numberArea);
      await tester.pumpAndSettle();

      // Biometrics called
      expect(authService.authenticateCallCount, equals(1));
      // Full number is revealed!
      expect(find.text('1122 3344 4455'), findsOneWidget);
    });
  });

  group('2. Biometric Guard for Sharing Documents', () {
    testWidgets('DocumentPreviewScreen requires biometric authentication when tapping Share', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      late WalletDocumentModel doc;
      await tester.runAsync(() async {
        doc = await vaultService.saveManualDocument(
          documentName: 'Official Passport',
          category: 'passport',
          holderName: 'Rohan Joshi',
          maskedIdentifier: 'P••••999',
          unmaskedIdentifier: 'P1234999',
        );
      });

      // Simulate biometric rejection / cancellation
      authService.shouldSucceed = false;

      await tester.pumpWidget(
        buildTestHarness(
          child: DocumentPreviewScreen(document: doc),
        ),
      );
      await tester.pumpAndSettle();

      // Find Share button in the unified 4-action row
      final shareBtn = find.text('Share');
      expect(shareBtn, findsOneWidget);

      await tester.tap(shareBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog pops up: "Share Document?"
      expect(find.text('Share Document?'), findsOneWidget);

      // Tap "Proceed & Share"
      final proceedBtn = find.text('Proceed & Share');
      expect(proceedBtn, findsOneWidget);
      await tester.tap(proceedBtn);
      await tester.pumpAndSettle();

      // Biometric authentication was prompted!
      expect(authService.authenticateCallCount, equals(1));
      expect(authService.lastReason, contains('Authenticate with biometrics to share'));

      // Since auth failed, sharing was blocked and error snackbar shown
      expect(find.textContaining('Biometric authentication is required to share documents'), findsOneWidget);
    });

    testWidgets('DocumentPreviewScreen proceeds with sharing when biometrics succeed', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      late WalletDocumentModel doc;
      await tester.runAsync(() async {
        doc = await vaultService.saveManualDocument(
          documentName: 'Driving Licence',
          category: 'driving_license',
          holderName: 'Karan Johar',
          maskedIdentifier: 'DL-••••8888',
          unmaskedIdentifier: 'DL-1420110008888',
        );
      });

      authService.shouldSucceed = true;

      await tester.pumpWidget(
        buildTestHarness(
          child: DocumentPreviewScreen(document: doc),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Share
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();

      // Confirm proceed
      await tester.tap(find.text('Proceed & Share'));
      await tester.pumpAndSettle();

      // Biometrics was verified
      expect(authService.authenticateCallCount, equals(1));
      // No failure snackbar
      expect(find.textContaining('Biometric authentication is required to share documents'), findsNothing);
    });
  });
}
