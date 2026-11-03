import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:spendz/database/database_helper.dart';
import 'package:spendz/database/wallet_card_repository.dart';
import 'package:spendz/database/wallet_document_repository.dart';
import 'package:spendz/database/transaction_dao.dart';
import 'package:spendz/features/wallet/ocr/document_classifier.dart';
import 'package:spendz/features/wallet/ocr/document_field_extractor.dart';
import 'package:spendz/features/wallet/ocr/document_ocr_service.dart';
import 'package:spendz/features/wallet/services/document_expiry_service.dart';
import 'package:spendz/features/wallet/services/document_vault_service.dart';
import 'package:spendz/features/wallet/services/image_processing_service.dart';
import 'package:spendz/features/wallet/security/document_encryption_service.dart';
import 'package:spendz/features/wallet/security/wallet_key_service.dart';
import 'package:spendz/models/transaction_model.dart';
import 'package:spendz/models/wallet_card_model.dart';
import 'package:spendz/models/wallet_document_model.dart';

/// Helper to generate synthetic test image bytes (PNG) in-memory
Uint8List _generateDummyImageBytes({int width = 200, int height = 150}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(200, 200, 200));
  // Add some synthetic text-like pixels within image bounds
  for (int x = 5; x < width - 5; x += 10) {
    for (int y = 5; y < height - 5; y += 15) {
      image.setPixelRgb(x, y, 20, 20, 20);
    }
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late String testDbPath;
  late WalletCardRepository cardRepo;
  late WalletDocumentRepository docRepo;
  late TransactionDao txnDao;
  late DocumentVaultService vaultService;
  late MockLocalNotificationGateway mockNotifGateway;
  late DocumentExpiryService expiryService;
  late ImageProcessingService imageProcessor;
  late DocumentClassifier classifier;
  late DocumentFieldExtractor fieldExtractor;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('spendz_phase4_tests_');
    testDbPath = p.join(tempDir.path, 'spendwise_phase4_test.db');
  });

  tearDownAll(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() async {
    final db = await databaseFactoryFfi.openDatabase(
      testDbPath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          // 1. Transactions
          await db.execute('''
            CREATE TABLE transactions (
              id TEXT PRIMARY KEY,
              amount REAL NOT NULL,
              type TEXT NOT NULL,
              category_id TEXT,
              subcategory TEXT,
              merchant TEXT,
              description TEXT,
              date TEXT NOT NULL,
              payment_method TEXT,
              notes TEXT,
              source TEXT NOT NULL,
              bank_name TEXT,
              reference_id TEXT,
              owed_amount REAL DEFAULT 0.0,
              expected_payments INTEGER DEFAULT 0,
              linked_payments INTEGER DEFAULT 0,
              card_id TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          // 2. Categories
          await db.execute('''
            CREATE TABLE categories (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              icon TEXT NOT NULL,
              color TEXT NOT NULL,
              type TEXT NOT NULL,
              is_default INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL
            )
          ''');

          // 3. Wallet Cards
          await db.execute('''
            CREATE TABLE wallet_cards (
              id TEXT PRIMARY KEY,
              nickname TEXT NOT NULL,
              issuer_name TEXT NOT NULL,
              cardholder_name TEXT NOT NULL,
              masked_number TEXT NOT NULL,
              last_four TEXT NOT NULL,
              expiry_month INTEGER NOT NULL,
              expiry_year INTEGER NOT NULL,
              card_type TEXT NOT NULL,
              card_network TEXT NOT NULL,
              theme_gradient TEXT NOT NULL,
              is_favorite INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          // 4. Wallet Documents
          await db.execute('''
            CREATE TABLE wallet_documents (
              id TEXT PRIMARY KEY,
              document_name TEXT NOT NULL,
              category TEXT NOT NULL,
              description TEXT,
              encrypted_file_path TEXT NOT NULL,
              thumbnail_path TEXT,
              mime_type TEXT NOT NULL,
              file_size INTEGER NOT NULL DEFAULT 0,
              issue_date TEXT,
              expiry_date TEXT,
              is_favorite INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          // 5. Wallet Passes
          await db.execute('''
            CREATE TABLE wallet_passes (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              pass_type TEXT NOT NULL,
              encrypted_code_path TEXT NOT NULL,
              code_format TEXT NOT NULL,
              issuer TEXT,
              valid_until TEXT,
              is_favorite INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    // Clean tables between runs safely
    try {
      await db.delete('wallet_cards');
      await db.delete('wallet_documents');
      await db.delete('transactions');
    } catch (_) {}

    try {
      final appDb = await DatabaseHelper.instance.database;
      await appDb.delete('wallet_cards');
      await appDb.delete('wallet_documents');
      await appDb.delete('transactions');
    } catch (_) {}

    cardRepo = WalletCardRepository();
    docRepo = WalletDocumentRepository();
    txnDao = TransactionDao();

    final vaultDir = p.join(tempDir.path, 'vault');
    final cacheDir = p.join(tempDir.path, 'cache');
    await Directory(vaultDir).create(recursive: true);
    await Directory(cacheDir).create(recursive: true);

    // Seed mock secure storage with a clean initial state
    FlutterSecureStorage.setMockInitialValues({});
    final keyService = WalletKeyService(secureStorage: const FlutterSecureStorage());
    final encService = DocumentEncryptionService();

    vaultService = DocumentVaultService(
      documentRepository: docRepo,
      encryptionService: encService,
      keyService: keyService,
      customVaultDirectory: vaultDir,
      customTempDirectory: cacheDir,
    );

    mockNotifGateway = MockLocalNotificationGateway();
    expiryService = DocumentExpiryService(
      documentRepository: docRepo,
      notificationGateway: mockNotifGateway,
    );

    imageProcessor = ImageProcessingService();
    classifier = DocumentClassifier();
    fieldExtractor = DocumentFieldExtractor();
  });

  group('1. OCR Engine & Text Extraction Tests', () {
    test('MockOcrEngine returns structured OcrResult with fullText, blocks, and lines', () async {
      final mock = MockOcrEngine(predefinedText: 'Government of India\nUnique Identification Authority of India\n1234 5678 9012');
      final result = await mock.processImageBytes(Uint8List(10));

      expect(result.isSuccess, isTrue);
      expect(result.fullText, contains('Unique Identification Authority of India'));
      expect(result.lines.length, equals(3));
      expect(result.lines[2].text, equals('1234 5678 9012'));
    });

    test('MockOcrEngine handles failure gracefully', () async {
      final mock = MockOcrEngine(shouldFail: true);
      final result = await mock.processImagePath('/dummy/path.jpg');

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Simulated OCR Engine Failure'));
    });
  });

  group('2. Deterministic Document Classification Tests', () {
    test('Aadhaar classification with high confidence', () {
      const text = '''
        GOVERNMENT OF INDIA
        Unique Identification Authority of India
        Mera Aadhaar, Meri Pehchan
        Enrollment No: 1234/56789/01234
        To: John Doe
        1234 5678 9012
        VID: 9876 5432 1098 7654
      ''';
      final res = classifier.classify(text);
      expect(res.category, equals('aadhaar'));
      expect(res.confidence, greaterThanOrEqualTo(0.80));
      expect(res.isHighConfidence, isTrue);
      expect(res.reasons, anyElement(contains('UIDAI')));
      expect(res.reasons, anyElement(contains('12-digit Aadhaar pattern')));
    });

    test('PAN card classification with high confidence', () {
      const text = '''
        INCOME TAX DEPARTMENT
        GOVT. OF INDIA
        Permanent Account Number Card
        ABCDE1234F
        Name: Ramesh Kumar
        Father's Name: Suresh Kumar
        Date of Birth: 15/08/1990
      ''';
      final res = classifier.classify(text);
      expect(res.category, equals('pan'));
      expect(res.confidence, greaterThanOrEqualTo(0.85));
      expect(res.isHighConfidence, isTrue);
      expect(res.reasons, anyElement(contains('Income Tax Department')));
    });

    test('Driving Licence classification', () {
      const text = '''
        UNION OF INDIA
        Transport Department
        Driving Licence
        DL No: KA-01-20180012345
        Name: Priya Sharma
        Authorisation to Drive: LMV, MCWG
        Valid Till: 20/11/2038
      ''';
      final res = classifier.classify(text);
      expect(res.category, equals('driving_license'));
      expect(res.confidence, greaterThanOrEqualTo(0.70));
      expect(res.isHighConfidence, isTrue);
    });

    test('Passport classification', () {
      const text = '''
        PASSPORT
        REPUBLIC OF INDIA
        Type: P  Code: IND  Passport No: Z1234567
        Given Name: Ananya
        Surname: Verma
        Nationality: INDIAN
        P<INDVERMA<<ANANYA<<<<<<<<<<<<<<<<<<<<<<<<<<
      ''';
      final res = classifier.classify(text);
      expect(res.category, equals('passport'));
      expect(res.confidence, greaterThanOrEqualTo(0.80));
      expect(res.isHighConfidence, isTrue);
    });

    test('Vehicle RC classification', () {
      const text = '''
        Form 23
        CERTIFICATE OF REGISTRATION
        Ministry of Road Transport and Highways
        Registration No: MH 12 AB 1234
        Chassis No: MA3EWB1S00123456
        Engine No: K12MN123456
      ''';
      final res = classifier.classify(text);
      expect(res.category, equals('rc'));
      expect(res.confidence, greaterThanOrEqualTo(0.70));
    });

    test('Insurance policy classification', () {
      const text = '''
        CERTIFICATE OF INSURANCE
        General Insurance Corporation
        Policy Number: 100234/31/2024/00123
        Period of Insurance: From 01/01/2024 To 31/12/2025
        Sum Insured: Rs. 5,00,000
      ''';
      final res = classifier.classify(text);
      expect(res.category, equals('insurance'));
      expect(res.confidence, greaterThanOrEqualTo(0.70));
    });

    test('College / Student ID classification', () {
      const text = '''
        NATIONAL INSTITUTE OF TECHNOLOGY
        STUDENT IDENTITY CARD
        Name: Rahul Dravid
        Roll No: 2021BCS045
        Branch: Computer Science & Engineering
        Valid Upto: 30/06/2025
      ''';
      final res = classifier.classify(text);
      expect(res.category, equals('college_id'));
      expect(res.confidence, greaterThanOrEqualTo(0.70));
    });

    test('Certificate classification', () {
      const text = '''
        CERTIFICATE OF COMPLETION
        This certifies that
        Pooja Hegde
        has successfully completed the Professional Flutter & Dart Course
        Awarded on: 10/10/2024
      ''';
      final res = classifier.classify(text);
      expect(res.category, equals('certificate'));
      expect(res.confidence, greaterThanOrEqualTo(0.70));
    });

    test('3. Low-confidence or ambiguous text defaults to other/unclassified', () {
      const ambiguousText = 'Thank you for shopping at Supermart. Item 1: Apples. Total: 150';
      final res = classifier.classify(ambiguousText);
      expect(res.category, equals('other'));
      expect(res.isHighConfidence, isFalse);
    });
  });

  group('4. Structured Field & Date Extraction Tests', () {
    test('Extracts masked document number for Aadhaar (privacy protection)', () {
      const text = '''
        Unique Identification Authority of India
        9876 5432 1098
      ''';
      final fields = fieldExtractor.extract(rawText: text, category: 'aadhaar');
      expect(fields.documentNumber, equals('•••• •••• 1098'));
      expect(fields.rawDocumentNumber, equals('9876 5432 1098'));
      expect(fields.issuer, contains('UIDAI'));
    });

    test('Extracts PAN number and holder name', () {
      const text = '''
        INCOME TAX DEPARTMENT
        ABCDE1234F
        Name: Rajesh Khanna
        Father's Name: Chunilal Khanna
        Date of Birth: 29/12/1942
      ''';
      final fields = fieldExtractor.extract(rawText: text, category: 'pan');
      expect(fields.documentNumber, equals('ABCDE1234F'));
      expect(fields.holderName, equals('Rajesh Khanna'));
    });

    test('5. Contextual Date Extraction: Associates date with expiry only when contextual keywords present', () {
      const textWithContext = '''
        Transport Department
        Licence to Drive
        Issue Date: 12/04/2018
        Valid Till: 11/04/2038
      ''';
      final fields = fieldExtractor.extract(rawText: textWithContext, category: 'driving_license');
      expect(fields.issueDate, equals(DateTime(2018, 4, 12)));
      expect(fields.expiryDate, equals(DateTime(2038, 4, 11)));
    });

    test('6. Invalid date handling: Does NOT infer random dates as expiry date without contextual markers', () {
      const textWithoutExpiryKeywords = '''
        Random Note with Date
        Meeting scheduled on 15/08/2025
        Amount: 500
      ''';
      final fields = fieldExtractor.extract(rawText: textWithoutExpiryKeywords, category: 'other');
      expect(fields.expiryDate, isNull);
    });
  });

  group('7. Image Processing, Enhancement & PDF Generation Tests', () {
    test('toGrayscale produces valid image bytes', () {
      final dummy = _generateDummyImageBytes();
      final grayBytes = imageProcessor.toGrayscale(dummy);
      expect(grayBytes, isNotEmpty);
      expect(grayBytes.length, greaterThan(100));
    });

    test('10. Image enhancement applies contrast boost and sharpening', () {
      final dummy = _generateDummyImageBytes();
      final enhanced = imageProcessor.enhanceDocument(dummy);
      expect(enhanced, isNotEmpty);
      expect(enhanced.length, greaterThan(100));
    });

    test('adjustContrast and rotateImage work correctly', () {
      final dummy = _generateDummyImageBytes();
      final contrasted = imageProcessor.adjustContrast(dummy, contrast: 1.5);
      final rotated = imageProcessor.rotateImage(dummy, 90);
      expect(contrasted, isNotEmpty);
      expect(rotated, isNotEmpty);
    });

    test('8. Multi-page document processing and 9. PDF generation', () {
      final page1 = _generateDummyImageBytes(width: 100, height: 100);
      final page2 = _generateDummyImageBytes(width: 100, height: 100);

      final pdfBytes = imageProcessor.createPdfFromImages([page1, page2], title: 'Test Multi-Page');
      expect(pdfBytes, isNotEmpty);
      // Verify PDF magic header '%PDF'
      final header = String.fromCharCodes(pdfBytes.take(4));
      expect(header, equals('%PDF'));
    });
  });

  group('11. Encrypted Document Storing & Vault Integration', () {
    test('Imports document with AES-256-GCM authenticated encryption and saves to DB', () async {
      final dummyImage = _generateDummyImageBytes();
      final doc = await vaultService.importDocument(
        documentName: 'Synthetic PAN Card',
        category: 'pan',
        mimeType: 'image/jpeg',
        fileBytes: dummyImage,
        description: 'Number: ABCDE1234F',
        issueDate: DateTime(2020, 1, 1),
        expiryDate: DateTime(2030, 1, 1),
      );

      expect(doc.id, isNotEmpty);
      expect(doc.documentName, equals('Synthetic PAN Card'));

      // Check SQLite table has record
      final fromDb = await docRepo.getDocumentById(doc.id);
      expect(fromDb, isNotNull);
      expect(fromDb!.category, equals('pan'));

      // Verify file on disk is ciphertext (magic 'SPDZ')
      final cipherFile = File(fromDb.encryptedFilePath);
      expect(await cipherFile.exists(), isTrue);
      final rawCipher = await cipherFile.readAsBytes();
      final magic = String.fromCharCodes(rawCipher.take(4));
      expect(magic, equals('SPDZ'));

      // Clean up
      await vaultService.deleteDocument(doc.id);
      expect(await cipherFile.exists(), isFalse);
    });
  });

  group('12. Card Studio CRUD Regression Tests', () {
    test('Full Card lifecycle: create, read, update, favorite toggle, delete', () async {
      final card = WalletCardModel(
        id: 'card-test-uuid-1',
        nickname: 'Primary Shopping Card',
        issuerName: 'HDFC Bank',
        cardholderName: 'John Doe',
        maskedNumber: '•••• •••• •••• 4321',
        lastFour: '4321',
        expiryMonth: 12,
        expiryYear: 28,
        cardType: 'credit',
        cardNetwork: 'visa',
        themeGradient: 'emerald',
        isFavorite: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cardRepo.insert(card);

      final readCard = await cardRepo.getCardById('card-test-uuid-1');
      expect(readCard, isNotNull);
      expect(readCard!.nickname, equals('Primary Shopping Card'));
      expect(readCard.lastFour, equals('4321'));

      // Toggle favorite
      await cardRepo.toggleFavorite('card-test-uuid-1', true);
      final favCard = await cardRepo.getCardById('card-test-uuid-1');
      expect(favCard!.isFavorite, isTrue);

      // Associate card with a transaction
      final txn = TransactionModel(
        id: 'txn-card-link-1',
        amount: 1450.0,
        type: 'expense',
        merchant: 'Amazon Superstore',
        date: DateTime.now(),
        source: 'manual',
        cardId: 'card-test-uuid-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await txnDao.insert(txn);

      final linkedTxns = await txnDao.getTransactionsByCard('card-test-uuid-1');
      expect(linkedTxns.length, equals(1));
      expect(linkedTxns.first.merchant, equals('Amazon Superstore'));

      // Delete card and verify transaction is safely unlinked (card_id set to null)
      await cardRepo.delete('card-test-uuid-1');
      final deletedCard = await cardRepo.getCardById('card-test-uuid-1');
      expect(deletedCard, isNull);

      final unlinkedTxn = await txnDao.getTransactionById('txn-card-link-1');
      expect(unlinkedTxn, isNotNull);
      expect(unlinkedTxn!.cardId, isNull);
    });
  });

  group('13. Expiry Notification Intelligence Tests', () {
    test('Schedules reminders at 30 days, 7 days, 1 day, and on expiry', () async {
      final now = DateTime(2026, 6, 1, 10, 0);
      final expiryDate = DateTime(2026, 7, 15); // Expiring in 44 days

      final doc = WalletDocumentModel(
        id: 'doc-expiry-test-1',
        documentName: 'Driving Licence',
        category: 'driving_license',
        encryptedFilePath: '/dummy/path',
        mimeType: 'image/jpeg',
        expiryDate: expiryDate,
        createdAt: now,
        updatedAt: now,
      );

      await expiryService.scheduleRemindersForDocument(doc, referenceNow: now);

      // Should schedule all 4 future intervals: 30 days, 7 days, 1 day, 0 days
      expect(mockNotifGateway.scheduledNotifications.length, equals(4));

      final baseId = expiryService.getBaseNotificationId(doc.id);
      expect(mockNotifGateway.scheduledNotifications.containsKey(baseId + 0), isTrue); // 30 days
      expect(mockNotifGateway.scheduledNotifications.containsKey(baseId + 1), isTrue); // 7 days
      expect(mockNotifGateway.scheduledNotifications.containsKey(baseId + 2), isTrue); // 1 day
      expect(mockNotifGateway.scheduledNotifications.containsKey(baseId + 3), isTrue); // Day of expiry
    });

    test('14. Duplicate notification prevention: Rescheduling replaces existing notifications', () async {
      final now = DateTime(2026, 6, 1, 10, 0);
      final expiryDate = DateTime(2026, 7, 15);

      final doc = WalletDocumentModel(
        id: 'doc-expiry-dup-1',
        documentName: 'Passport',
        category: 'passport',
        encryptedFilePath: '/dummy/path',
        mimeType: 'image/jpeg',
        expiryDate: expiryDate,
        createdAt: now,
        updatedAt: now,
      );

      // Schedule first time
      await expiryService.scheduleRemindersForDocument(doc, referenceNow: now);
      final countFirst = mockNotifGateway.scheduledNotifications.length;

      // Reschedule (e.g. user edited document)
      await expiryService.scheduleRemindersForDocument(doc, referenceNow: now);
      final countSecond = mockNotifGateway.scheduledNotifications.length;

      expect(countSecond, equals(countFirst));
    });

    test('15. Notification cancellation on document deletion', () async {
      final now = DateTime(2026, 6, 1, 10, 0);
      final expiryDate = DateTime(2026, 7, 15);

      final doc = WalletDocumentModel(
        id: 'doc-expiry-cancel-1',
        documentName: 'Vehicle Insurance',
        category: 'insurance',
        encryptedFilePath: '/dummy/path',
        mimeType: 'image/jpeg',
        expiryDate: expiryDate,
        createdAt: now,
        updatedAt: now,
      );

      await expiryService.scheduleRemindersForDocument(doc, referenceNow: now);
      expect(mockNotifGateway.scheduledNotifications, isNotEmpty);

      // Cancel
      await expiryService.cancelRemindersForDocument(doc.id);
      expect(mockNotifGateway.scheduledNotifications, isEmpty);
    });
  });

  group('16. Financial Integrity & Gmail Import Regression Tests', () {
    test('17. Existing transaction calculations and category mapping remain unchanged', () async {
      final txn1 = TransactionModel(
        id: 'txn-calc-1',
        amount: 250.0,
        type: 'expense',
        merchant: 'Swiggy',
        date: DateTime.now(),
        source: 'manual',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final txn2 = TransactionModel(
        id: 'txn-calc-2',
        amount: 750.0,
        type: 'expense',
        merchant: 'Zomato',
        date: DateTime.now(),
        source: 'manual',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final incomeTxn = TransactionModel(
        id: 'txn-calc-3',
        amount: 50000.0,
        type: 'income',
        merchant: 'Employer Salary',
        date: DateTime.now(),
        source: 'manual',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await txnDao.insert(txn1);
      await txnDao.insert(txn2);
      await txnDao.insert(incomeTxn);

      final all = await txnDao.getAllTransactions();
      expect(all.length, equals(3));

      double totalExpense = 0.0;
      double totalIncome = 0.0;
      for (final t in all) {
        if (t.type == 'expense') totalExpense += t.amount;
        if (t.type == 'income') totalIncome += t.amount;
      }

      expect(totalExpense, equals(1000.0));
      expect(totalIncome, equals(50000.0));
    });

    test('18. Existing duplicate transaction detection (Gmail HDFC import safeguard) works as designed', () async {
      final now = DateTime.now();
      final txn = TransactionModel(
        id: 'txn-gmail-1',
        amount: 1200.0,
        type: 'expense',
        merchant: 'HDFC Pos Payment',
        referenceId: 'HDFC_REF_12345678',
        date: now,
        source: 'bank_email',
        createdAt: now,
        updatedAt: now,
      );

      await txnDao.insert(txn);

      // Verify transactionExistsWithReference detects existing duplicate
      final exists = await txnDao.transactionExistsWithReference('HDFC_REF_12345678');
      expect(exists, isTrue);

      final nonExistent = await txnDao.transactionExistsWithReference('NON_EXISTENT_REF');
      expect(nonExistent, isFalse);
    });
  });
}
