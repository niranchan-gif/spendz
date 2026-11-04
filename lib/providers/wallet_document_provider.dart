import 'package:flutter/material.dart';
import '../models/wallet_document_model.dart';
import '../database/wallet_document_repository.dart';

class WalletDocumentProvider with ChangeNotifier {
  final WalletDocumentRepository _repository = WalletDocumentRepository();

  List<WalletDocumentModel> _documents = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'all';

  List<WalletDocumentModel> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;

  List<WalletDocumentModel> get favoriteDocuments =>
      _documents.where((d) => d.isFavorite).toList();

  List<WalletDocumentModel> get expiringDocuments =>
      _documents.where((d) => d.isExpiringSoon || d.isExpired).toList();

  WalletDocumentProvider() {
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_selectedCategory == 'all') {
        _documents = await _repository.getAllDocuments();
      } else {
        _documents = await _repository.getDocumentsByCategory(
          _selectedCategory,
        );
      }
    } catch (e) {
      _error = 'Failed to load documents: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCategoryFilter(String category) async {
    _selectedCategory = category;
    await loadDocuments();
  }

  Future<void> addDocument(WalletDocumentModel document) async {
    try {
      await _repository.insert(document);
      await loadDocuments();
    } catch (e) {
      _error = 'Failed to add document: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateDocument(WalletDocumentModel document) async {
    try {
      await _repository.update(document);
      await loadDocuments();
    } catch (e) {
      _error = 'Failed to update document: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      await _repository.delete(id);
      await loadDocuments();
    } catch (e) {
      _error = 'Failed to delete document: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleDocumentFavorite(String id) async {
    try {
      final doc = _documents.firstWhere((d) => d.id == id);
      final newFav = !doc.isFavorite;
      await _repository.toggleFavorite(id, newFav);
      await loadDocuments();
    } catch (e) {
      _error = 'Failed to toggle favorite: $e';
      notifyListeners();
    }
  }

  Future<List<WalletDocumentModel>> searchDocuments(String query) async {
    if (query.trim().isEmpty) return _documents;
    try {
      return await _repository.searchDocuments(query);
    } catch (e) {
      _error = 'Search failed: $e';
      notifyListeners();
      return [];
    }
  }

  Future<List<WalletDocumentModel>> fetchExpiringDocuments({
    int days = 30,
  }) async {
    try {
      return await _repository.getExpiringDocuments(daysThreshold: days);
    } catch (e) {
      _error = 'Failed to fetch expiring documents: $e';
      return [];
    }
  }

  WalletDocumentModel? getDocumentById(String id) {
    try {
      return _documents.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
