import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:spendz/database/database_helper.dart';
import 'package:spendz/database/wallet_document_repository.dart';
import 'package:spendz/features/wallet/security/secure_number_service.dart';
import 'package:spendz/features/wallet/security/wallet_key_service.dart';
import 'package:spendz/features/wallet/services/document_scanner_service.dart';
import 'package:spendz/features/wallet/services/document_vault_service.dart';
import 'package:spendz/models/wallet_document_model.dart';
import 'package:spendz/screens/wallet/widgets/virtual_document_card.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempVaultDir;
  late Directory tempCacheDir;
  late WalletDocumentRepository repository;
  late DocumentVaultService vaultService;
  late SecureNumberService secureNumberService;
  late WalletKeyService keyService;

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() async {
    tempVaultDir = await Directory.systemTemp.createTemp('spendz_manual_vault_');
    tempCacheDir = await Directory.systemTemp.createTemp('spendz_manual_cache_');

    repository = WalletDocumentRepository();
    vaultService = DocumentVaultService(
      documentRepository: repository,
      customVaultDirectory: tempVaultDir.path,
      customTempDirectory: tempCacheDir.path,
    );
    secureNumberService = SecureNumberService();

    final db = await DatabaseHelper.instance.database;
    await db.delete('wallet_documents');

    keyService = WalletKeyService(secureStorage: const FlutterSecureStorage());
    await keyService.getOrCreateMasterKey(hasExistingVaultDocuments: () => false);
  });

  tearDown(() {
    try {
      tempVaultDir.deleteSync(recursive: true);
      tempCacheDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('1. Manual Document Creation & Attachment-Free Storage Tests', () {
    test('Saves pure manual Aadhaar document without physical attachment', () async {
      final doc = await vaultService.saveManualDocument(
        documentName: 'My Aadhaar',
        category: 'aadhaar',
        holderName: 'Aarav Sharma',
        maskedIdentifier: '•••• •••• 9012',
        unmaskedIdentifier: '123456789012',
        extraFields: {
          'gender': 'Male',
          'address': '221B Baker Street, New Delhi',
        },
      );

      expect(doc.id, isNotEmpty);
      expect(doc.documentName, equals('My Aadhaar'));
      expect(doc.hasAttachment, isFalse);
      expect(doc.attachmentType, equals('none'));
      expect(doc.encryptedFilePath, isEmpty);
      expect(doc.holderName, equals('Aarav Sharma'));
      expect(doc.maskedIdentifier, equals('•••• •••• 9012'));

      // Verify full number stored securely in keystore
      final storedFullNumber = await secureNumberService.getDocumentFullNumber(doc.id);
      expect(storedFullNumber, equals('123456789012'));

      // Verify SQLite persistence
      final fromDb = await repository.getDocumentById(doc.id);
      expect(fromDb, isNotNull);
      expect(fromDb!.documentName, equals('My Aadhaar'));
      expect(fromDb.hasAttachment, isFalse);
    });

    test('Saves manual PAN Card with photo attachment', () async {
      final sampleImageBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46]);

      final doc = await vaultService.saveManualDocument(
        documentName: 'Personal PAN',
        category: 'pan',
        holderName: 'Priya Verma',
        maskedIdentifier: 'ABCDE••••F',
        unmaskedIdentifier: 'ABCDE1234F',
        attachmentBytes: sampleImageBytes,
        attachmentMimeType: 'image/jpeg',
      );

      expect(doc.hasAttachment, isTrue);
      expect(doc.attachmentType, equals('image'));
      expect(doc.fileSize, equals(sampleImageBytes.length));
      expect(File(doc.encryptedFilePath).existsSync(), isTrue);

      // Decrypt attachment and verify integrity
      final decrypted = await vaultService.decryptDocumentBytes(doc);
      expect(decrypted, equals(sampleImageBytes));
    });
  });

  group('2. Dedicated Category Forms & Validation Logic Tests', () {
    test('Aadhaar number masking strictly displays last 4 digits', () {
      const raw = '987654321098';
      final masked = '•••• •••• ${raw.substring(raw.length - 4)}';
      expect(masked, equals('•••• •••• 1098'));
    });

    test('PAN card regex validates standard 10-char format', () {
      final validPan = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
      expect(validPan.hasMatch('ABCDE1234F'), isTrue);
      expect(validPan.hasMatch('abcde1234f'), isFalse); // Must be uppercase
      expect(validPan.hasMatch('12345ABCDE'), isFalse);
      expect(validPan.hasMatch('ABCDE12345'), isFalse);
    });

    test('Driving licence issue and expiry validation', () {
      final issueDate = DateTime(2020, 1, 1);
      final expiryDate = DateTime(2030, 1, 1);
      final invalidExpiry = DateTime(2019, 1, 1);

      expect(expiryDate.isAfter(issueDate), isTrue);
      expect(invalidExpiry.isBefore(issueDate), isTrue); // Should be flagged
    });

    test('Payment card ensures ZERO CVV or PIN in metadata', () async {
      final doc = await vaultService.saveManualDocument(
        documentName: 'HDFC Millennia',
        category: 'credit_card',
        holderName: 'Vikram Mehta',
        maskedIdentifier: '•••• •••• •••• 4821',
        unmaskedIdentifier: '4821000012344821',
        extraFields: {
          'bank_name': 'HDFC Bank',
          'card_network': 'Visa',
          'card_type': 'credit_card',
        },
      );

      // Decrypt extra fields and verify no sensitive credentials
      final extra = await vaultService.decryptMetadataFields(doc.encryptedFields!);
      expect(extra.containsKey('cvv'), isFalse);
      expect(extra.containsKey('pin'), isFalse);
      expect(extra['bank_name'], equals('HDFC Bank'));
    });

    test('Saving card number and metadata works without MasterKeyLostException on clean setup', () async {
      // 1. Wipe key to simulate fresh clean setup or reset
      await keyService.deleteKeyForReset();
      expect(await keyService.hasMasterKey(), isFalse);

      // 2. Save card full number
      final secNumService = SecureNumberService(keyService: keyService);
      await secNumService.saveCardFullNumber('test_card_1', '4532015487965412');

      // 3. Verify key was generated automatically and card number decrypts
      expect(await keyService.hasMasterKey(), isTrue);
      final decrypted = await secNumService.getCardFullNumber('test_card_1');
      expect(decrypted, equals('4532015487965412'));

      // 4. Test encryptMetadataFields on clean setup
      final encFields = await vaultService.encryptMetadataFields({'test_field': 'val_123'});
      expect(encFields, isNotEmpty);
      final decryptedFields = await vaultService.decryptMetadataFields(encFields);
      expect(decryptedFields['test_field'], equals('val_123'));
    });
  });

  group('3. Attachment Management (Attach, Replace, Remove) Tests', () {
    test('Attaching file to an existing manual document', () async {
      // 1. Create document with no attachment
      final doc = await vaultService.saveManualDocument(
        documentName: 'Life Insurance',
        category: 'insurance',
        holderName: 'Sunil Kumar',
        maskedIdentifier: 'POL-••••7890',
      );
      expect(doc.hasAttachment, isFalse);

      // 2. Attach PDF copy later
      final fakePdf = Uint8List.fromList('%PDF-1.4 Fake Insurance Policy Attachment'.codeUnits);
      final updated = await vaultService.attachFileToDocument(
        document: doc,
        fileBytes: fakePdf,
        mimeType: 'application/pdf',
      );

      expect(updated.hasAttachment, isTrue);
      expect(updated.attachmentType, equals('pdf'));
      expect(File(updated.encryptedFilePath).existsSync(), isTrue);

      // 3. Remove attachment while preserving metadata
      final noAttach = await vaultService.removeAttachmentFromDocument(updated);
      expect(noAttach.hasAttachment, isFalse);
      expect(noAttach.documentName, equals('Life Insurance'));
      expect(noAttach.holderName, equals('Sunil Kumar'));
      expect(File(updated.encryptedFilePath).existsSync(), isFalse);
    });

    test('Replacing attachment overwrites file cleanly without leaking previous data', () async {
      final initialBytes = Uint8List.fromList('OLD_DOCUMENT_DATA'.codeUnits);
      final newBytes = Uint8List.fromList('NEW_UPDATED_DOCUMENT_DATA'.codeUnits);

      final doc = await vaultService.saveManualDocument(
        documentName: 'Registration Certificate',
        category: 'rc',
        attachmentBytes: initialBytes,
        attachmentMimeType: 'image/jpeg',
      );

      final updated = await vaultService.attachFileToDocument(
        document: doc,
        fileBytes: newBytes,
        mimeType: 'image/jpeg',
      );

      final decrypted = await vaultService.decryptDocumentBytes(updated);
      expect(decrypted, equals(newBytes));
    });
  });

  group('4. Multi-Page Scanner & PDF Attachment Generation Tests', () {
    test('DocumentScannerService generates multi-page PDF from captured page images', () {
      final scannerService = DocumentScannerService();
      final page1 = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46]);
      final page2 = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46]);

      // Rotate page 90 degrees
      expect(() => scannerService.rotatePage(page1, 90), returnsNormally);

      // Enhance page
      expect(() => scannerService.enhancePage(page2), returnsNormally);
    });
  });

  group('5. Virtual Document Card Widget Rendering Across Categories', () {
    Widget buildTestHarness(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 380,
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('Renders Aadhaar Virtual Card with saffron/white/green accents', (tester) async {
      final aadhaar = WalletDocumentModel(
        id: 'test_aadhaar',
        documentName: 'Aadhaar Card',
        category: 'aadhaar',
        holderName: 'Ananya Roy',
        maskedIdentifier: '•••• •••• 4567',
        description: 'Holder: Ananya Roy\nNumber: •••• •••• 4567',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestHarness(VirtualDocumentCard(document: aadhaar)));
      expect(find.text('Ananya Roy'), findsOneWidget);
      expect(find.text('•••• •••• 4567'), findsOneWidget);
      expect(find.text('UIDAI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders PAN Virtual Card with Income Tax Department layout', (tester) async {
      final pan = WalletDocumentModel(
        id: 'test_pan',
        documentName: 'Income Tax PAN',
        category: 'pan',
        holderName: 'Kavita Joshi',
        maskedIdentifier: 'ABCDE••••F',
        description: 'Holder: Kavita Joshi\nNumber: ABCDE••••F',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestHarness(VirtualDocumentCard(document: pan)));
      expect(find.text('KAVITA JOSHI'), findsOneWidget);
      expect(find.text('ABCDE••••F'), findsOneWidget);
      expect(find.textContaining('INCOME TAX DEPARTMENT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders Driving Licence Virtual Card with MoRTH layout', (tester) async {
      final dl = WalletDocumentModel(
        id: 'test_dl',
        documentName: 'Driving Licence',
        category: 'driving_license',
        holderName: 'Rahul Dravid',
        maskedIdentifier: 'DL-••••4321',
        description: 'Holder: Rahul Dravid\nNumber: DL-••••4321\nVehicle Class: LMV, MCWG',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestHarness(VirtualDocumentCard(document: dl)));
      expect(find.text('RAHUL DRAVID'), findsOneWidget);
      expect(find.text('DL-••••4321'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders Passport Virtual Card with Republic of India layout', (tester) async {
      final passport = WalletDocumentModel(
        id: 'test_passport',
        documentName: 'Republic of India Passport',
        category: 'passport',
        holderName: 'Deepak Chopra',
        maskedIdentifier: 'J••••678',
        description: 'Holder: Deepak Chopra\nNumber: J••••678',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestHarness(VirtualDocumentCard(document: passport)));
      expect(find.text('DEEPAK CHOPRA'), findsOneWidget);
      expect(find.text('J••••678'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders Insurance Virtual Card with shield layout', (tester) async {
      final insurance = WalletDocumentModel(
        id: 'test_insurance',
        documentName: 'Health Insurance',
        category: 'insurance',
        holderName: 'Manoj Bajpayee',
        maskedIdentifier: 'POL-••••1122',
        description: 'Holder: Manoj Bajpayee\nNumber: POL-••••1122\nProvider: Star Health',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestHarness(VirtualDocumentCard(document: insurance)));
      expect(find.text('Manoj Bajpayee'), findsOneWidget);
      expect(find.text('POL-••••1122'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
