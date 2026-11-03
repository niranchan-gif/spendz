import 'package:flutter/material.dart';
import '../models/wallet_card_model.dart';
import '../database/wallet_card_repository.dart';

class WalletCardProvider with ChangeNotifier {
  final WalletCardRepository _repository = WalletCardRepository();

  List<WalletCardModel> _cards = [];
  bool _isLoading = false;
  String? _error;

  List<WalletCardModel> get cards => _cards;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<WalletCardModel> get favoriteCards => _cards.where((c) => c.isFavorite).toList();

  WalletCardProvider() {
    loadCards();
  }

  Future<void> loadCards() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cards = await _repository.getAllCards();
    } catch (e) {
      _error = 'Failed to load cards: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCard(WalletCardModel card) async {
    try {
      await _repository.insert(card);
      await loadCards();
    } catch (e) {
      _error = 'Failed to add card: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCard(WalletCardModel card) async {
    try {
      await _repository.update(card);
      await loadCards();
    } catch (e) {
      _error = 'Failed to update card: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCard(String id) async {
    try {
      await _repository.delete(id);
      await loadCards();
    } catch (e) {
      _error = 'Failed to delete card: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleCardFavorite(String id) async {
    try {
      final card = _cards.firstWhere((c) => c.id == id);
      final newFav = !card.isFavorite;
      await _repository.toggleFavorite(id, newFav);
      await loadCards();
    } catch (e) {
      _error = 'Failed to toggle favorite: $e';
      notifyListeners();
    }
  }

  Future<List<WalletCardModel>> searchCards(String query) async {
    if (query.trim().isEmpty) return _cards;
    try {
      return await _repository.searchCards(query);
    } catch (e) {
      _error = 'Search failed: $e';
      notifyListeners();
      return [];
    }
  }

  WalletCardModel? getCardById(String id) {
    try {
      return _cards.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

