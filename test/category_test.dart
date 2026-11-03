import 'package:flutter_test/flutter_test.dart';
import 'package:spendz/services/category_engine.dart';
import 'package:spendz/providers/category_provider.dart';
import 'package:spendz/models/category_model.dart';
import 'package:spendz/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('CategoryEngine test', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    final provider = CategoryProvider();
    await provider.loadCategories(); // wait for it to load
    
    print('Expense categories loaded: ${provider.expenseCategories.length}');
    
    final catId = CategoryEngine.suggestCategoryId('KISHAN CAFE', 'DEBIT', provider);
    print('Suggested category ID for KISHAN CAFE: $catId');
    
    if (catId != null) {
      final cat = provider.getCategoryById(catId);
      print('Category Name: ${cat?.name}');
    }
  });
}
