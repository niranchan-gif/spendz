import 'package:flutter_test/flutter_test.dart';
import 'package:spendz/providers/wallet_provider.dart';
import 'package:spendz/models/wallet_card_model.dart';
import 'package:spendz/models/wallet_document_model.dart';
import 'package:spendz/models/wallet_pass_model.dart';

void main() {
  group('WalletProvider & Models Test', () {
    late WalletProvider wallet;

    setUp(() {
      wallet = WalletProvider();
    });

    test('Initializes with default wallet items', () {
      expect(wallet.cards.isNotEmpty, true);
      expect(wallet.documents.isNotEmpty, true);
      expect(wallet.passes.isNotEmpty, true);
    });

    test('Card CRUD and favorite toggle operations', () {
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

      wallet.addCard(newCard);
      expect(wallet.cards.first.id, 'test-card-1');

      // Toggle favorite
      wallet.toggleCardFavorite('test-card-1');
      expect(wallet.favoriteCards.any((c) => c.id == 'test-card-1'), true);

      // Delete card
      wallet.deleteCard('test-card-1');
      expect(wallet.cards.any((c) => c.id == 'test-card-1'), false);
    });

    test('Document expiry detection and category filtering', () {
      final now = DateTime.now();
      final expiringDoc = WalletDocumentModel(
        id: 'test-expiring-doc',
        documentName: 'Expiring Passport',
        category: 'passport',
        encryptedFilePath: 'vault/passport.dat',
        mimeType: 'image/jpeg',
        issueDate: now.subtract(const Duration(days: 365 * 9)),
        expiryDate: now.add(const Duration(days: 15)), // Expiring in 15 days
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(expiringDoc.isExpiringSoon, true);
      expect(expiringDoc.isExpired, false);

      wallet.addDocument(expiringDoc);
      expect(wallet.expiringDocuments.any((d) => d.id == 'test-expiring-doc'), true);

      final passportDocs = wallet.getDocumentsByCategory('passport');
      expect(passportDocs.any((d) => d.id == 'test-expiring-doc'), true);
    });

    test('Pass CRUD and favorite toggle operations', () {
      final now = DateTime.now();
      final newPass = WalletPassModel(
        id: 'test-pass-1',
        title: 'Movie Ticket',
        passType: 'event_ticket',
        codeData: 'BMS-AVATAR-ROW-A',
        codeFormat: 'QR_CODE',
        issuer: 'BookMyShow',
        isFavorite: true,
        createdAt: now,
        updatedAt: now,
      );

      wallet.addPass(newPass);
      expect(wallet.favoritePasses.any((p) => p.id == 'test-pass-1'), true);

      wallet.togglePassFavorite('test-pass-1');
      expect(wallet.favoritePasses.any((p) => p.id == 'test-pass-1'), false);

      wallet.deletePass('test-pass-1');
      expect(wallet.passes.any((p) => p.id == 'test-pass-1'), false);
    });
  });
}

