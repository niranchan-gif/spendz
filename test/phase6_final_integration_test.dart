import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'package:spendz/database/database_helper.dart';
import 'package:spendz/database/transaction_dao.dart';
import 'package:spendz/database/wallet_card_repository.dart';
import 'package:spendz/database/wallet_document_repository.dart';
import 'package:spendz/database/wallet_pass_repository.dart';
import 'package:spendz/models/transaction_model.dart';
import 'package:spendz/models/wallet_card_model.dart';
import 'package:spendz/models/wallet_document_model.dart';
import 'package:spendz/models/wallet_pass_model.dart';
import 'package:spendz/providers/dashboard_provider.dart';
import 'package:spendz/services/category_engine.dart';
import 'package:spendz/features/wallet/security/document_encryption_service.dart';
import 'package:spendz/features/wallet/ocr/document_classifier.dart';
import 'package:spendz/features/wallet/ocr/document_field_extractor.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late TransactionDao txDao;
  late WalletCardRepository cardRepo;
  late WalletDocumentRepository docRepo;
  late WalletPassRepository passRepo;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('spendz_phase6_test_');
    final dbFile = p.join(tempDir.path, 'spendwise_phase6.db');
    db = await databaseFactoryFfi.openDatabase(dbFile);

    // Create v4 schema
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        type TEXT NOT NULL,
        is_default INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS wallet_cards (
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS wallet_documents (
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS wallet_passes (
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS wallet_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    DatabaseHelper.setTestDatabase(db);

    txDao = TransactionDao();
    cardRepo = WalletCardRepository();
    docRepo = WalletDocumentRepository();
    passRepo = WalletPassRepository();
  });

  tearDownAll(() async {
    DatabaseHelper.setTestDatabase(null);
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('1. Finance Regression & Financial Engine Integrity', () {
    test('Transaction CRUD and persistence preserves finance schema', () async {
      final tx = TransactionModel(
        id: const Uuid().v4(),
        amount: 350.50,
        type: 'expense',
        merchant: 'Swiggy',
        description: 'Dinner delivery',
        date: DateTime.now(),
        source: 'manual',
        owedAmount: 50.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await txDao.insert(tx);
      final retrieved = await txDao.getTransactionById(tx.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.amount, equals(350.50));
      expect(retrieved.owedAmount, equals(50.0));
      expect(retrieved.merchant, equals('Swiggy'));

      // Update
      final updatedTx = retrieved.copyWith(amount: 400.00, merchant: 'Swiggy Gourmet');
      await txDao.update(updatedTx);
      final fetchedAfterUpdate = await txDao.getTransactionById(tx.id);
      expect(fetchedAfterUpdate!.amount, equals(400.00));
      expect(fetchedAfterUpdate.merchant, equals('Swiggy Gourmet'));

      // Delete
      await txDao.delete(tx.id);
      final fetchedAfterDelete = await txDao.getTransactionById(tx.id);
      expect(fetchedAfterDelete, isNull);
    });

    test('DashboardProvider correctly aggregates income, expense, transfers, and refunds', () {
      final now = DateTime.now();
      final currentMonthDate = DateTime(now.year, now.month, 10);
      final prevMonthDate = DateTime(now.year, now.month == 1 ? 12 : now.month - 1, 15);

      final transactions = [
        // Current month
        TransactionModel(
          id: '1',
          amount: 50000.0,
          type: 'income',
          date: currentMonthDate,
          source: 'salary',
          createdAt: now,
          updatedAt: now,
        ),
        TransactionModel(
          id: '2',
          amount: 12000.0,
          type: 'expense',
          date: currentMonthDate,
          source: 'card',
          owedAmount: 2000.0,
          createdAt: now,
          updatedAt: now,
        ),
        TransactionModel(
          id: '3',
          amount: 8000.0,
          type: 'transfer',
          date: currentMonthDate,
          source: 'bank',
          createdAt: now,
          updatedAt: now,
        ),
        TransactionModel(
          id: '4',
          amount: 1500.0,
          type: 'refund',
          date: currentMonthDate,
          source: 'upi',
          createdAt: now,
          updatedAt: now,
        ),
        // Previous month
        TransactionModel(
          id: '5',
          amount: 45000.0,
          type: 'income',
          date: prevMonthDate,
          source: 'salary',
          createdAt: now,
          updatedAt: now,
        ),
        TransactionModel(
          id: '6',
          amount: 10000.0,
          type: 'expense',
          date: prevMonthDate,
          source: 'card',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final dashboard = DashboardProvider();
      dashboard.update(transactions);

      // Total balance: income(50k) - expense(12k) + transfer(8k) + prevIncome(45k) - prevExpense(10k) = 81k
      expect(dashboard.totalBalance, equals(81000.0));
      expect(dashboard.monthlyIncome, equals(50000.0));
      expect(dashboard.monthlyExpenses, equals(12000.0));
      expect(dashboard.monthlyTransfers, equals(8000.0));
      expect(dashboard.monthlyRefunds, equals(1500.0));
      expect(dashboard.totalOwed, equals(2000.0));

      // Month-over-month growth checks
      // incomeChange: (50000 - 45000) / 45000 * 100 = 11.11%
      expect(dashboard.incomeChange, closeTo(11.11, 0.05));
      // expenseChange: (12000 - 10000) / 10000 * 100 = 20%
      expect(dashboard.expenseChange, closeTo(20.0, 0.05));
    });

    test('Gmail HDFC deduplication and parent transfer identification', () async {
      final now = DateTime.now();
      const refNumber = 'HDFC-UPI-994821';

      // Insert transaction with reference
      final initialTx = TransactionModel(
        id: const Uuid().v4(),
        amount: 2500.0,
        type: 'expense',
        merchant: 'BookMyShow',
        date: now,
        source: 'bank_email',
        referenceId: refNumber,
        createdAt: now,
        updatedAt: now,
      );
      await txDao.insert(initialTx);

      // Test duplicate detection check
      final exists = await txDao.transactionExistsWithReference(refNumber, amount: 2500.0, date: now);
      expect(exists, isTrue);

      final nonExistent = await txDao.transactionExistsWithReference('HDFC-UPI-000000', amount: 50.0, date: now);
      expect(nonExistent, isFalse);

      // Verify Parent Transfer detector (HDFC account rules)
      expect(CategoryEngine.isParentTransfer('UPI-VIJAYALAKSHMI MUTHUKUMAR-PAY'), isTrue);
      expect(CategoryEngine.isParentTransfer('TRANSFER TO MUTHUKUMAR'), isTrue);
      expect(CategoryEngine.isParentTransfer('STARBUCKS COFFEE'), isFalse);

      // Clean up
      await txDao.delete(initialTx.id);
    });
  });

  group('2. Database Integrity & Card-Transaction Safety', () {
    test('Card deletion safely sets card_id to null on associated transactions', () async {
      final card = WalletCardModel(
        id: const Uuid().v4(),
        nickname: 'HDFC Regalia Gold',
        issuerName: 'HDFC Bank',
        cardholderName: 'Kishan Patel',
        maskedNumber: '•••• •••• •••• 8844',
        lastFour: '8844',
        expiryMonth: 10,
        expiryYear: 2029,
        cardType: 'credit',
        cardNetwork: 'visa',
        themeGradient: 'midnight',
        isFavorite: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await cardRepo.insert(card);

      final tx1 = TransactionModel(
        id: const Uuid().v4(),
        amount: 1450.0,
        type: 'expense',
        merchant: 'Zara',
        cardId: card.id,
        date: DateTime.now(),
        source: 'card',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await txDao.insert(tx1);

      // Verify link
      final linkedTxBefore = await txDao.getTransactionById(tx1.id);
      expect(linkedTxBefore!.cardId, equals(card.id));

      // Safe deletion of card
      await cardRepo.delete(card.id);

      // Card is deleted
      final cardAfter = await cardRepo.getCardById(card.id);
      expect(cardAfter, isNull);

      // Associated transaction is NOT deleted, its card_id is nullified
      final linkedTxAfter = await txDao.getTransactionById(tx1.id);
      expect(linkedTxAfter, isNotNull);
      expect(linkedTxAfter!.cardId, isNull);
      expect(linkedTxAfter.amount, equals(1450.0));

      // Clean up
      await txDao.delete(tx1.id);
    });
  });

  group('3. Wallet Document Vault & AES-256-GCM Security Audit', () {
    final encService = DocumentEncryptionService();
    final testKey = Uint8List.fromList(List.generate(32, (i) => i * 3 + 1));

    test('Zero plaintext leakage: AES-256-GCM authenticated envelope structure', () async {
      final sampleDoc = 'CONFIDENTIAL PASSPORT DATA: A99887766'.codeUnits;

      final encrypted1 = await encService.encryptBytes(sampleDoc, keyBytes: testKey);
      final encrypted2 = await encService.encryptBytes(sampleDoc, keyBytes: testKey);

      // Magic bytes 'SPDZ' (0x53, 0x50, 0x44, 0x5A)
      expect(encrypted1.sublist(0, 4), equals(DocumentEncryptionService.magicBytes));
      expect(encrypted1[4], equals(DocumentEncryptionService.currentVersion));
      expect(encrypted1[5], equals(DocumentEncryptionService.algorithmAes256Gcm));

      // Nonce uniqueness: encrypting identical plaintext twice produces different nonces and ciphertexts
      final nonce1 = encrypted1.sublist(6, 18);
      final nonce2 = encrypted2.sublist(6, 18);
      expect(nonce1, isNot(equals(nonce2)));
      expect(encrypted1, isNot(equals(encrypted2)));

      // Plaintext is completely obscured
      expect(String.fromCharCodes(encrypted1).contains('PASSPORT'), isFalse);

      // Successful decryption
      final decrypted = await encService.decryptBytes(encrypted1, keyBytes: testKey);
      expect(decrypted, equals(sampleDoc));
    });

    test('Cryptographic tamper rejection: single-byte modification invalidates tag', () async {
      final sampleDoc = 'SENSITIVE TAX ID NUMBER: 12345'.codeUnits;
      final encrypted = await encService.encryptBytes(sampleDoc, keyBytes: testKey);

      // Corrupt a byte in the ciphertext payload
      final tamperedCiphertext = Uint8List.fromList(encrypted);
      tamperedCiphertext[tamperedCiphertext.length - 1] ^= 0xFF;

      expect(
        () async => await encService.decryptBytes(tamperedCiphertext, keyBytes: testKey),
        throwsA(isA<DecryptionAuthenticationException>()),
      );

      // Corrupt a byte in the authentication tag (bytes 18..34)
      final tamperedTag = Uint8List.fromList(encrypted);
      tamperedTag[20] ^= 0x01;

      expect(
        () async => await encService.decryptBytes(tamperedTag, keyBytes: testKey),
        throwsA(isA<DecryptionAuthenticationException>()),
      );

      // Corrupt magic header byte
      final tamperedMagic = Uint8List.fromList(encrypted);
      tamperedMagic[0] = 0x00;

      expect(
        () async => await encService.decryptBytes(tamperedMagic, keyBytes: testKey),
        throwsA(isA<InvalidFileHeaderException>()),
      );
    });

    test('Wrong decryption key fails authentication without leaking plaintext', () async {
      final sampleDoc = 'HEALTH INSURANCE CARD 987654321'.codeUnits;
      final encrypted = await encService.encryptBytes(sampleDoc, keyBytes: testKey);

      final wrongKey = Uint8List.fromList(List.generate(32, (i) => i * 7 + 2));

      expect(
        () async => await encService.decryptBytes(encrypted, keyBytes: wrongKey),
        throwsA(isA<DecryptionAuthenticationException>()),
      );
    });
  });

  group('4. Smart Scanner, OCR Classification & Expiry Intelligence', () {
    final classifier = DocumentClassifier();
    final extractor = DocumentFieldExtractor();

    test('Deterministic classification with regex and contextual keywords', () {
      const aadhaarSample = '''
        GOVERNMENT OF INDIA
        Mera Aadhaar, Meri Pehchan
        Rajesh Kumar
        DOB: 12/04/1992
        Male
        9876 5432 1098
      ''';
      final aadhaarResult = classifier.classify(aadhaarSample);
      expect(aadhaarResult.category, equals('aadhaar'));
      expect(aadhaarResult.confidence, greaterThanOrEqualTo(0.70));

      const panSample = '''
        INCOME TAX DEPARTMENT
        GOVT. OF INDIA
        Permanent Account Number
        ABCDE1234F
        Name: PRIYA SHARMA
      ''';
      final panResult = classifier.classify(panSample);
      expect(panResult.category, equals('pan'));
      expect(panResult.confidence, greaterThanOrEqualTo(0.70));

      const passportSample = '''
        REPUBLIC OF INDIA
        PASSPORT
        Type P Code IND Passport No Z1234567
        Surname PATEL Given Names KISHAN
        Date of Expiry 14/09/2034
      ''';
      final passportResult = classifier.classify(passportSample);
      expect(passportResult.category, equals('passport'));
      expect(passportResult.confidence, greaterThanOrEqualTo(0.85));
    });

    test('Field extractor masks Aadhaar and extracts contextual dates accurately', () {
      const aadhaarText = 'Rajesh Kumar DOB: 15/06/1990 Aadhaar 9876 5432 1098';
      final aadhaarFields = extractor.extract(rawText: aadhaarText, category: 'aadhaar');
      // Masking first 8 digits
      expect(aadhaarFields.documentNumber, equals('•••• •••• 1098'));

      const dlText = '''
        INDIAN UNION DRIVING LICENCE
        DL NO: KA0120150001234
        NAME: AMIT VERMA
        VALID TILL: 25/12/2030
      ''';
      final dlFields = extractor.extract(rawText: dlText, category: 'driving_license');
      expect(dlFields.documentNumber, equals('KA0120150001234'));
      expect(dlFields.holderName, equals('AMIT VERMA'));
      expect(dlFields.expiryDate, isNotNull);
      expect(dlFields.expiryDate!.year, equals(2030));
      expect(dlFields.expiryDate!.month, equals(12));
      expect(dlFields.expiryDate!.day, equals(25));
    });

    test('Digital Pass model and repository CRUD', () async {
      final pass = WalletPassModel(
        id: const Uuid().v4(),
        title: 'Mumbai Metro 1 Smart Card',
        passType: 'transit',
        encryptedCodePath: 'METRO:MM01-99881122',
        codeFormat: 'QR_CODE',
        issuer: 'Mumbai Metro Rail',
        validUntil: DateTime.now().add(const Duration(days: 90)),
        isFavorite: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await passRepo.insert(pass);
      final retrieved = await passRepo.getPassById(pass.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Mumbai Metro 1 Smart Card'));
      expect(retrieved.codeData, equals('METRO:MM01-99881122'));
      expect(retrieved.isFavorite, isTrue);

      await passRepo.toggleFavorite(pass.id, false);
      final updated = await passRepo.getPassById(pass.id);
      expect(updated!.isFavorite, isFalse);

      await passRepo.delete(pass.id);
      final deleted = await passRepo.getPassById(pass.id);
      expect(deleted, isNull);
    });

    test('WalletDocument metadata repository CRUD', () async {
      final doc = WalletDocumentModel(
        id: const Uuid().v4(),
        documentName: 'Health Insurance Policy',
        category: 'insurance',
        encryptedFilePath: '/fake/vault/insurance.enc',
        mimeType: 'application/pdf',
        fileSize: 102400,
        expiryDate: DateTime.now().add(const Duration(days: 180)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRepo.insert(doc);
      final retrieved = await docRepo.getDocumentById(doc.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.documentName, equals('Health Insurance Policy'));
      expect(retrieved.category, equals('insurance'));

      await docRepo.delete(doc.id);
      expect(await docRepo.getDocumentById(doc.id), isNull);
    });
  });
}
