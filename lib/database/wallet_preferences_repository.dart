import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class WalletPreferencesRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<void> setPreference(String key, String value) async {
    final db = await dbHelper.database;
    await db.insert(
      'wallet_preferences',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getPreference(String key) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'wallet_preferences',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['value']?.toString();
    }
    return null;
  }

  Future<Map<String, String>> getAllPreferences() async {
    final db = await dbHelper.database;
    final maps = await db.query('wallet_preferences');
    final Map<String, String> prefs = {};
    for (var m in maps) {
      final k = m['key']?.toString();
      final v = m['value']?.toString();
      if (k != null && v != null) {
        prefs[k] = v;
      }
    }
    return prefs;
  }

  Future<int> deletePreference(String key) async {
    final db = await dbHelper.database;
    return await db.delete(
      'wallet_preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<int> clearAllPreferences() async {
    final db = await dbHelper.database;
    return await db.delete('wallet_preferences');
  }
}

