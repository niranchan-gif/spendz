// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures
import 'dart:core';

class CategoryModel {
  final String id;
  final String name;
  final String type;
  CategoryModel({required this.id, required this.name, required this.type});
}

class CategoryProvider {
  final List<CategoryModel> _categories = [
    CategoryModel(id: '1', name: 'Food & Dining', type: 'expense'),
    CategoryModel(id: '2', name: 'Transport', type: 'expense'),
    CategoryModel(id: '3', name: 'Other', type: 'expense'),
    CategoryModel(id: '4', name: 'Other Income', type: 'income'),
  ];
  
  List<CategoryModel> get expenseCategories => _categories.where((c) => c.type == 'expense').toList();
  List<CategoryModel> get incomeCategories => _categories.where((c) => c.type == 'income').toList();
}

void main() {
  final provider = CategoryProvider();
  
  String? suggestCategoryId(String merchant, String type) {
    if (merchant.isEmpty) return 'empty';
    
    final normalized = merchant.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(RegExp(r'\s+'), ' ');
    print('Normalized: $normalized');
    
    String? suggestedName;
    if (type.toUpperCase() == 'CREDIT') {
      if (normalized.contains('salary') || normalized.contains('payroll')) suggestedName = 'Salary';
      else if (normalized.contains('refund') || normalized.contains('cashback') || normalized.contains('reversal')) suggestedName = 'Refund';
      else if (normalized.contains('interest')) suggestedName = 'Interest';
      else suggestedName = 'Other Income';
    } else {
      if (normalized.contains('blasis corner')) suggestedName = 'Food & Dining';
      else if (normalized.contains('kishan cafe') || normalized.contains('kishancafe')) suggestedName = 'Food & Dining';
      else if (normalized.contains('chandra food products')) suggestedName = 'Food & Dining';
      else {
        final words = normalized.split(' ');
        for (final word in words) {
          if (['restaurant', 'food', 'cafe', 'cate', 'coffee', 'hotel', 'swiggy', 'zomato'].contains(word)) suggestedName = 'Food & Dining';
        }
      }
    }
    
    if (suggestedName != null) {
      final list = type.toUpperCase() == 'CREDIT' ? provider.incomeCategories : provider.expenseCategories;
      try {
        final category = list.firstWhere((c) => c.name.toLowerCase() == suggestedName!.toLowerCase());
        return category.id;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  print('Result for KISHAN CAFE: ${suggestCategoryId('kishancafe@hdfc (KISHAN CAFE)', 'DEBIT')}');
  print('Result for cate: ${suggestCategoryId('cate', 'DEBIT')}');
}
