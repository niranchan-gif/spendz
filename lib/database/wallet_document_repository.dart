import '../models/wallet_document_model.dart';
import 'database_helper.dart';

class WalletDocumentRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<WalletDocumentModel> insert(WalletDocumentModel document) async {
    final db = await dbHelper.database;
    await db.insert('wallet_documents', document.toMap());
    return document;
  }

  Future<List<WalletDocumentModel>> getAllDocuments() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'wallet_documents',
      orderBy: 'is_favorite DESC, created_at DESC',
    );
    return maps.map((m) => WalletDocumentModel.fromMap(m)).toList();
  }

  Future<WalletDocumentModel?> getDocumentById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'wallet_documents',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return WalletDocumentModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<WalletDocumentModel>> getFavoriteDocuments() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'wallet_documents',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => WalletDocumentModel.fromMap(m)).toList();
  }

  Future<List<WalletDocumentModel>> getDocumentsByCategory(String category) async {
    final db = await dbHelper.database;
    if (category.toLowerCase() == 'all') {
      return getAllDocuments();
    }
    final maps = await db.query(
      'wallet_documents',
      where: 'category = ?',
      whereArgs: [category.toLowerCase()],
      orderBy: 'is_favorite DESC, created_at DESC',
    );
    return maps.map((m) => WalletDocumentModel.fromMap(m)).toList();
  }

  Future<List<WalletDocumentModel>> getExpiringDocuments({int daysThreshold = 30}) async {
    final db = await dbHelper.database;
    final now = DateTime.now();
    final thresholdDate = now.add(Duration(days: daysThreshold));

    final maps = await db.query(
      'wallet_documents',
      where: 'expiry_date IS NOT NULL AND expiry_date <= ?',
      whereArgs: [thresholdDate.toIso8601String()],
      orderBy: 'expiry_date ASC',
    );
    return maps.map((m) => WalletDocumentModel.fromMap(m)).toList();
  }

  Future<List<WalletDocumentModel>> searchDocuments(String query) async {
    final db = await dbHelper.database;
    final pattern = '%$query%';
    final maps = await db.query(
      'wallet_documents',
      where: 'document_name LIKE ? OR category LIKE ? OR description LIKE ?',
      whereArgs: [pattern, pattern, pattern],
      orderBy: 'is_favorite DESC, created_at DESC',
    );
    return maps.map((m) => WalletDocumentModel.fromMap(m)).toList();
  }

  Future<int> update(WalletDocumentModel document) async {
    final db = await dbHelper.database;
    return await db.update(
      'wallet_documents',
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<int> toggleFavorite(String id, bool isFavorite) async {
    final db = await dbHelper.database;
    return await db.update(
      'wallet_documents',
      {
        'is_favorite': isFavorite ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(String id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'wallet_documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

