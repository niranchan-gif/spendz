import '../models/category_model.dart';
import 'database_helper.dart';

class CategoryDao {
  final dbHelper = DatabaseHelper.instance;

  Future<CategoryModel> insert(CategoryModel category) async {
    final db = await dbHelper.database;
    await db.insert('categories', category.toMap());
    return category;
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await dbHelper.database;
    final maps = await db.query('categories');
    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return CategoryModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(CategoryModel category) async {
    final db = await dbHelper.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await dbHelper.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
