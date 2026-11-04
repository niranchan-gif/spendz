import '../models/wallet_pass_model.dart';
import 'database_helper.dart';

class WalletPassRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<WalletPassModel> insert(WalletPassModel pass) async {
    final db = await dbHelper.database;
    await db.insert('wallet_passes', pass.toMap());
    return pass;
  }

  Future<List<WalletPassModel>> getAllPasses() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'wallet_passes',
      orderBy: 'is_favorite DESC, created_at DESC',
    );
    return maps.map((m) => WalletPassModel.fromMap(m)).toList();
  }

  Future<WalletPassModel?> getPassById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'wallet_passes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return WalletPassModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<WalletPassModel>> getFavoritePasses() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'wallet_passes',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => WalletPassModel.fromMap(m)).toList();
  }

  Future<List<WalletPassModel>> searchPasses(String query) async {
    final db = await dbHelper.database;
    final pattern = '%$query%';
    final maps = await db.query(
      'wallet_passes',
      where: 'title LIKE ? OR pass_type LIKE ? OR issuer LIKE ?',
      whereArgs: [pattern, pattern, pattern],
      orderBy: 'is_favorite DESC, created_at DESC',
    );
    return maps.map((m) => WalletPassModel.fromMap(m)).toList();
  }

  Future<List<WalletPassModel>> getActivePasses() async {
    final db = await dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'wallet_passes',
      where: 'valid_until IS NULL OR valid_until >= ?',
      whereArgs: [now],
      orderBy: 'is_favorite DESC, created_at DESC',
    );
    return maps.map((m) => WalletPassModel.fromMap(m)).toList();
  }

  Future<int> update(WalletPassModel pass) async {
    final db = await dbHelper.database;
    return await db.update(
      'wallet_passes',
      pass.toMap(),
      where: 'id = ?',
      whereArgs: [pass.id],
    );
  }

  Future<int> toggleFavorite(String id, bool isFavorite) async {
    final db = await dbHelper.database;
    return await db.update(
      'wallet_passes',
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
    return await db.delete('wallet_passes', where: 'id = ?', whereArgs: [id]);
  }
}
