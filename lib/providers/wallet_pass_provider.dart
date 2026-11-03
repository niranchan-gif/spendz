import 'package:flutter/material.dart';
import '../models/wallet_pass_model.dart';
import '../database/wallet_pass_repository.dart';

class WalletPassProvider with ChangeNotifier {
  final WalletPassRepository _repository = WalletPassRepository();

  List<WalletPassModel> _passes = [];
  bool _isLoading = false;
  String? _error;

  List<WalletPassModel> get passes => _passes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<WalletPassModel> get favoritePasses => _passes.where((p) => p.isFavorite).toList();

  WalletPassProvider() {
    loadPasses();
  }

  Future<void> loadPasses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _passes = await _repository.getAllPasses();
    } catch (e) {
      _error = 'Failed to load passes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPass(WalletPassModel pass) async {
    try {
      await _repository.insert(pass);
      await loadPasses();
    } catch (e) {
      _error = 'Failed to add pass: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePass(WalletPassModel pass) async {
    try {
      await _repository.update(pass);
      await loadPasses();
    } catch (e) {
      _error = 'Failed to update pass: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePass(String id) async {
    try {
      await _repository.delete(id);
      await loadPasses();
    } catch (e) {
      _error = 'Failed to delete pass: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> togglePassFavorite(String id) async {
    try {
      final pass = _passes.firstWhere((p) => p.id == id);
      final newFav = !pass.isFavorite;
      await _repository.toggleFavorite(id, newFav);
      await loadPasses();
    } catch (e) {
      _error = 'Failed to toggle favorite: $e';
      notifyListeners();
    }
  }

  Future<List<WalletPassModel>> searchPasses(String query) async {
    if (query.trim().isEmpty) return _passes;
    try {
      return await _repository.searchPasses(query);
    } catch (e) {
      _error = 'Search failed: $e';
      notifyListeners();
      return [];
    }
  }

  Future<List<WalletPassModel>> getActivePasses() async {
    try {
      return await _repository.getActivePasses();
    } catch (e) {
      _error = 'Failed to get active passes: $e';
      return [];
    }
  }

  WalletPassModel? getPassById(String id) {
    try {
      return _passes.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

