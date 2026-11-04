// ignore_for_file: avoid_print, dangling_library_doc_comments, unnecessary_import
/// WalletProvider unit tests
///
/// The WalletProvider now delegates to SQLite repositories. We initialise the
/// sqflite FFI factory so the DatabaseHelper can open an in-memory database
/// during tests without a real device.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:spendz/database/database_helper.dart';
import 'package:spendz/providers/wallet_provider.dart';
import 'package:spendz/models/wallet_card_model.dart';
import 'package:spendz/models/wallet_document_model.dart';
import 'package:spendz/models/wallet_pass_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WalletProvider & Models Test', () {
    late WalletProvider wallet;

    setUp(() async {
      final db = await DatabaseHelper.instance.database;
      await db.delete('wallet_documents');
      await db.delete('wallet_cards');
      await db.delete('wallet_passes');
      wallet = WalletProvider();
      await wallet.loadWallet(); // loads from (empty) in-memory DB
    });

    // ── 1. Initial state ───────────────────────────────────────────────────
    test('Initializes with empty wallet on fresh DB', () {
      expect(wallet.cards, isEmpty);
      expect(wallet.documents, isEmpty);
      expect(wallet.passes, isEmpty);
    });

    // ── 2. Card CRUD ──────────────────────────────────────────────────────
    test('Card CRUD and favorite toggle operations', () async {
      final now = DateTime.now();
      final newCard = WalletCardModel(
        id: 'test-card-1',
        nickname: 'Test ICICI Card',
        issuerName: 'ICICI Bank',
        cardholderName: 'MUTHUKUMAR',
        maskedNumber: '•••• •••• •••• 9999',
        lastFour: '9999',
        expiryMonth: 12,
        expiryYear: 30,
        cardType: 'credit',
        cardNetwork: 'visa',
        themeGradient: 'obsidian',
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
      );

      await wallet.addCard(newCard);
      expect(wallet.cards.any((c) => c.id == 'test-card-1'), true);

      // Toggle favorite
      await wallet.toggleCardFavorite('test-card-1');
      expect(wallet.favoriteCards.any((c) => c.id == 'test-card-1'), true);

      // Toggle back
      await wallet.toggleCardFavorite('test-card-1');
      expect(wallet.favoriteCards.any((c) => c.id == 'test-card-1'), false);

      // Delete card
      await wallet.deleteCard('test-card-1');
      expect(wallet.cards.any((c) => c.id == 'test-card-1'), false);
    });

    // ── 3. Document CRUD + model helpers ──────────────────────────────────
    test('Document expiry detection and category filtering', () async {
      final now = DateTime.now();
      final expiringDoc = WalletDocumentModel(
        id: 'test-expiring-doc',
        documentName: 'Expiring Passport',
        category: 'passport',
        encryptedFilePath: 'vault/passport.dat',
        mimeType: 'image/jpeg',
        issueDate: now.subtract(const Duration(days: 365 * 9)),
        expiryDate: now.add(const Duration(days: 15)), // expiring in 15 days
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
      );

      // Model helpers work without DB
      expect(expiringDoc.isExpiringSoon, true);
      expect(expiringDoc.isExpired, false);

      await wallet.addDocument(expiringDoc);
      expect(wallet.expiringDocuments.any((d) => d.id == 'test-expiring-doc'), true);

      final passportDocs = wallet.getDocumentsByCategory('passport');
      expect(passportDocs.any((d) => d.id == 'test-expiring-doc'), true);

      await wallet.deleteDocument('test-expiring-doc');
      expect(wallet.documents.any((d) => d.id == 'test-expiring-doc'), false);
    });

    // ── 4. Pass CRUD ──────────────────────────────────────────────────────
    test('Pass CRUD and favorite toggle operations', () async {
      final now = DateTime.now();
      final newPass = WalletPassModel(
        id: 'test-pass-1',
        title: 'Movie Ticket',
        passType: 'event_ticket',
        encryptedCodePath: 'BMS-AVATAR-ROW-A',
        codeFormat: 'QR_CODE',
        issuer: 'BookMyShow',
        isFavorite: true,
        createdAt: now,
        updatedAt: now,
      );

      await wallet.addPass(newPass);
      expect(wallet.favoritePasses.any((p) => p.id == 'test-pass-1'), true);

      // Toggle favorite off
      await wallet.togglePassFavorite('test-pass-1');
      expect(wallet.favoritePasses.any((p) => p.id == 'test-pass-1'), false);

      await wallet.deletePass('test-pass-1');
      expect(wallet.passes.any((p) => p.id == 'test-pass-1'), false);
    });

    // ── 5. Pass model backward-compat getter ──────────────────────────────
    test('WalletPassModel.codeData getter returns encryptedCodePath value', () {
      final pass = WalletPassModel(
        id: 'p',
        title: 'T',
        encryptedCodePath: 'RAW_CODE_123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(pass.codeData, 'RAW_CODE_123');
    });
  });
}
