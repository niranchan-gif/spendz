import 'package:flutter/material.dart';
import '../models/wallet_card_model.dart';
import '../models/wallet_document_model.dart';
import '../models/wallet_pass_model.dart';
import '../database/wallet_card_repository.dart';
import '../database/wallet_document_repository.dart';
import '../database/wallet_pass_repository.dart';

class WalletProvider with ChangeNotifier {
  final WalletCardRepository _cardRepo = WalletCardRepository();
  final WalletDocumentRepository _docRepo = WalletDocumentRepository();
  final WalletPassRepository _passRepo = WalletPassRepository();

  List<WalletCardModel> _cards = [];
  List<WalletDocumentModel> _documents = [];
  List<WalletPassModel> _passes = [];
  bool _isLoading = false;
  String? _error;

  List<WalletCardModel> get cards => _cards;
  List<WalletDocumentModel> get documents => _documents;
  List<WalletPassModel> get passes => _passes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<WalletCardModel> get favoriteCards =>
      _cards.where((c) => c.isFavorite).toList();
  List<WalletDocumentModel> get favoriteDocuments =>
      _documents.where((d) => d.isFavorite).toList();
  List<WalletPassModel> get favoritePasses =>
      _passes.where((p) => p.isFavorite).toList();

  List<WalletDocumentModel> get expiringDocuments =>
      _documents.where((d) => d.isExpiringSoon || d.isExpired).toList();

  WalletProvider() {
    loadWallet();
  }

  Future<void> loadWallet() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cards = await _cardRepo.getAllCards();
      _documents = await _docRepo.getAllDocuments();
      _passes = await _passRepo.getAllPasses();
    } catch (e) {
      _error = 'Failed to load wallet data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCard(WalletCardModel card) async {
    try {
      await _cardRepo.insert(card);
      await loadWallet();
    } catch (e) {
      _error = 'Failed to add card: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCard(WalletCardModel card) async {
    try {
      await _cardRepo.update(card);
      await loadWallet();
    } catch (e) {
      _error = 'Failed to update card: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCard(String id) async {
    try {
      await _cardRepo.delete(id);
      await loadWallet();
    } catch (e) {
      _error = 'Failed to delete card: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleCardFavorite(String id) async {
    try {
      final card = _cards.firstWhere((c) => c.id == id);
      await _cardRepo.toggleFavorite(id, !card.isFavorite);
      await loadWallet();
    } catch (e) {
      _error = 'Failed to toggle card favorite: $e';
      notifyListeners();
    }
  }

  Future<void> addDocument(WalletDocumentModel document) async {
    try {
      await _docRepo.insert(document);
      await loadWallet();
    } catch (e) {
      _error = 'Failed to add document: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateDocument(WalletDocumentModel document) async {
    try {
      await _docRepo.update(document);
      await loadWallet();
    } catch (e) {
      _error = 'Failed to update document: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      await _docRepo.delete(id);
      await loadWallet();
    } catch (e) {
      _error = 'Failed to delete document: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleDocumentFavorite(String id) async {
    try {
      final doc = _documents.firstWhere((d) => d.id == id);
      await _docRepo.toggleFavorite(id, !doc.isFavorite);
      await loadWallet();
    } catch (e) {
      _error = 'Failed to toggle document favorite: $e';
      notifyListeners();
    }
  }

  Future<void> addPass(WalletPassModel pass) async {
    try {
      await _passRepo.insert(pass);
      await loadWallet();
    } catch (e) {
      _error = 'Failed to add pass: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePass(WalletPassModel pass) async {
    try {
      await _passRepo.update(pass);
      await loadWallet();
    } catch (e) {
      _error = 'Failed to update pass: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePass(String id) async {
    try {
      await _passRepo.delete(id);
      await loadWallet();
    } catch (e) {
      _error = 'Failed to delete pass: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> togglePassFavorite(String id) async {
    try {
      final pass = _passes.firstWhere((p) => p.id == id);
      await _passRepo.toggleFavorite(id, !pass.isFavorite);
      await loadWallet();
    } catch (e) {
      _error = 'Failed to toggle pass favorite: $e';
      notifyListeners();
    }
  }

  List<WalletDocumentModel> getDocumentsByCategory(String category) {
    if (category.toLowerCase() == 'all') return _documents;
    return _documents
        .where((d) => d.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  WalletCardModel? getCardById(String id) {
    try {
      return _cards.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
