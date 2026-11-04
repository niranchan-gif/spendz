// ignore_for_file: avoid_print
import 'package:spendz/services/category_engine.dart';
import 'package:spendz/providers/category_provider.dart';
import 'package:spendz/models/category_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

// Create a mock CategoryProvider
class MockCategoryProvider extends CategoryProvider {
  final List<CategoryModel> _mockCategories = [];

  @override
  List<CategoryModel> get categories => _mockCategories;

  @override
  List<CategoryModel> get expenseCategories =>
      _mockCategories.where((c) => c.type == 'expense').toList();

  @override
  List<CategoryModel> get incomeCategories =>
      _mockCategories.where((c) => c.type == 'income').toList();

  void addMock(String name, String type) {
    _mockCategories.add(
      CategoryModel(
        id: Uuid().v4(),
        name: name,
        icon: 'icon',
        color: '0xFF000000',
        type: type,
        isDefault: true,
        createdAt: DateTime.now(),
      ),
    );
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final provider = MockCategoryProvider();
  provider.addMock('Food & Dining', 'expense');
  provider.addMock('Transport', 'expense');
  provider.addMock('Other', 'expense');
  provider.addMock('Other Income', 'income');

  print('--- Testing KISHAN CAFE ---');
  final id1 = CategoryEngine.suggestCategoryId(
    'kishancafe@hdfc (KISHAN CAFE)',
    'DEBIT',
    provider,
  );
  print('ID: $id1');

  print('--- Testing Parent Transfer ---');
  final id2 = CategoryEngine.suggestCategoryId(
    'VIJAYALAKSHMI MUTHUKUMAR',
    'CREDIT',
    provider,
  );
  print('ID: $id2');

  print('--- Testing Unknown ---');
  final id3 = CategoryEngine.suggestCategoryId(
    'SOMETHING RANDOM',
    'DEBIT',
    provider,
  );
  print('ID: $id3');
}
