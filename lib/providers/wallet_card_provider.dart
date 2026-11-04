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

  Future<void> setDefaultCard(String id) async {
    try {
      await _repository.setDefaultCard(id);
      await loadCards();
    } catch (e) {
      _error = 'Failed to set default card: $e';
      notifyListeners();
    }
  }

  Future<void> updateCardTheme(String id, String themeId) async {
    try {
      await _repository.updateThemeAndLayout(id, themeId: themeId);
      await loadCards();
    } catch (e) {
      _error = 'Failed to update theme: $e';
      notifyListeners();
    }
  }

  Future<void> updateCardLayout(String id, String layoutId) async {
    try {
      await _repository.updateThemeAndLayout(id, layoutId: layoutId);
      await loadCards();
    } catch (e) {
      _error = 'Failed to update layout: $e';
      notifyListeners();
    }
  }

  Future<void> reorderCards(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _cards.removeAt(oldIndex);
      _cards.insert(newIndex, item);
      notifyListeners();

      final ids = _cards.map((c) => c.id).toList();
      await _repository.updateOrder(ids);
      await loadCards();
    } catch (e) {
      _error = 'Failed to reorder cards: $e';
      notifyListeners();
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

