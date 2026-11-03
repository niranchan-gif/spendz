import 'package:flutter/material.dart';
import '../models/wallet_card_model.dart';
import '../models/wallet_document_model.dart';
import '../models/wallet_pass_model.dart';

class WalletProvider with ChangeNotifier {
  List<WalletCardModel> _cards = [];
  List<WalletDocumentModel> _documents = [];
  List<WalletPassModel> _passes = [];
  bool _isLoading = false;

  List<WalletCardModel> get cards => _cards;
  List<WalletDocumentModel> get documents => _documents;
  List<WalletPassModel> get passes => _passes;
  bool get isLoading => _isLoading;

  List<WalletCardModel> get favoriteCards => _cards.where((c) => c.isFavorite).toList();
  List<WalletDocumentModel> get favoriteDocuments => _documents.where((d) => d.isFavorite).toList();
  List<WalletPassModel> get favoritePasses => _passes.where((p) => p.isFavorite).toList();

  List<WalletDocumentModel> get expiringDocuments => _documents.where((d) => d.isExpiringSoon || d.isExpired).toList();

  WalletProvider() {
    _initSampleDataIfEmpty();
  }

  void _initSampleDataIfEmpty() {
    if (_cards.isEmpty && _documents.isEmpty && _passes.isEmpty) {
      final now = DateTime.now();
      _cards = [
        WalletCardModel(
          id: 'card-1',
          nickname: 'HDFC Millennia',
          issuerName: 'HDFC Bank',
          cardholderName: 'MUTHUKUMAR',
          maskedNumber: '•••• •••• •••• 4291',
          lastFour: '4291',
          expiryMonth: 8,
          expiryYear: 28,
          cardType: 'credit',
          cardNetwork: 'visa',
          themeGradient: 'emerald',
          isFavorite: true,
          createdAt: now,
          updatedAt: now,
        ),
        WalletCardModel(
          id: 'card-2',
          nickname: 'SBI Platinum Debit',
          issuerName: 'State Bank of India',
          cardholderName: 'MUTHUKUMAR',
          maskedNumber: '•••• •••• •••• 8192',
          lastFour: '8192',
          expiryMonth: 11,
          expiryYear: 29,
          cardType: 'debit',
          cardNetwork: 'rupay',
          themeGradient: 'midnight',
          isFavorite: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      _documents = [
        WalletDocumentModel(
          id: 'doc-1',
          documentName: 'Aadhaar Card',
          category: 'aadhaar',
          description: 'UIDAI National Identity',
          encryptedFilePath: 'vault/aadhaar_encrypted.dat',
          mimeType: 'image/jpeg',
          fileSize: 1024 * 240,
          issueDate: DateTime(2021, 5, 10),
          isFavorite: true,
          createdAt: now,
          updatedAt: now,
        ),
        WalletDocumentModel(
          id: 'doc-2',
          documentName: 'PAN Card',
          category: 'pan',
          description: 'Income Tax Department',
          encryptedFilePath: 'vault/pan_encrypted.dat',
          mimeType: 'image/jpeg',
          fileSize: 1024 * 180,
          issueDate: DateTime(2020, 1, 15),
          isFavorite: true,
          createdAt: now,
          updatedAt: now,
        ),
        WalletDocumentModel(
          id: 'doc-3',
          documentName: 'Driving Licence',
          category: 'driving_license',
          description: 'Motor Vehicles Department',
          encryptedFilePath: 'vault/dl_encrypted.dat',
          mimeType: 'image/jpeg',
          fileSize: 1024 * 320,
          issueDate: DateTime(2022, 6, 20),
          expiryDate: DateTime.now().add(const Duration(days: 25)), // Expiring soon reminder!
          isFavorite: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      _passes = [
        WalletPassModel(
          id: 'pass-1',
          title: 'Metro Smart QR',
          passType: 'qr_code',
          codeData: 'CMRL-METRO-TICKET-2026-X992',
          codeFormat: 'QR_CODE',
          issuer: 'Chennai Metro Rail',
          validUntil: now.add(const Duration(hours: 3)),
          isFavorite: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    }
  }

  Future<void> loadWallet() async {
    _isLoading = true;
    notifyListeners();
    // Phase 2 will load from Database
    _isLoading = false;
    notifyListeners();
  }

  void addCard(WalletCardModel card) {
    _cards.insert(0, card);
    notifyListeners();
  }

  void updateCard(WalletCardModel card) {
    final index = _cards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      _cards[index] = card;
      notifyListeners();
    }
  }

  void deleteCard(String id) {
    _cards.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  void toggleCardFavorite(String id) {
    final index = _cards.indexWhere((c) => c.id == id);
    if (index != -1) {
      final item = _cards[index];
      _cards[index] = item.copyWith(isFavorite: !item.isFavorite);
      notifyListeners();
    }
  }

  void addDocument(WalletDocumentModel document) {
    _documents.insert(0, document);
    notifyListeners();
  }

  void updateDocument(WalletDocumentModel document) {
    final index = _documents.indexWhere((d) => d.id == document.id);
    if (index != -1) {
      _documents[index] = document;
      notifyListeners();
    }
  }

  void deleteDocument(String id) {
    _documents.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  void toggleDocumentFavorite(String id) {
    final index = _documents.indexWhere((d) => d.id == id);
    if (index != -1) {
      final item = _documents[index];
      _documents[index] = item.copyWith(isFavorite: !item.isFavorite);
      notifyListeners();
    }
  }

  void addPass(WalletPassModel pass) {
    _passes.insert(0, pass);
    notifyListeners();
  }

  void updatePass(WalletPassModel pass) {
    final index = _passes.indexWhere((p) => p.id == pass.id);
    if (index != -1) {
      _passes[index] = pass;
      notifyListeners();
    }
  }

  void deletePass(String id) {
    _passes.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void togglePassFavorite(String id) {
    final index = _passes.indexWhere((p) => p.id == id);
    if (index != -1) {
      final item = _passes[index];
      _passes[index] = item.copyWith(isFavorite: !item.isFavorite);
      notifyListeners();
    }
  }

  List<WalletDocumentModel> getDocumentsByCategory(String category) {
    if (category.toLowerCase() == 'all') return _documents;
    return _documents.where((d) => d.category.toLowerCase() == category.toLowerCase()).toList();
  }

  WalletCardModel? getCardById(String id) {
    try {
      return _cards.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

