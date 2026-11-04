import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../database/category_dao.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryDao _categoryDao = CategoryDao();
  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;

  List<CategoryModel> get expenseCategories => _categories
      .where((c) => c.type == 'expense' || c.type == 'both')
      .toList();

  List<CategoryModel> get incomeCategories =>
      _categories.where((c) => c.type == 'income' || c.type == 'both').toList();

  CategoryProvider() {
    loadCategories();
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    _categories = await _categoryDao.getAllCategories();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(CategoryModel category) async {
    await _categoryDao.insert(category);
    await loadCategories();
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _categoryDao.update(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _categoryDao.delete(id);
    await loadCategories();
  }

  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }
}
