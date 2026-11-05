import 'dart:io';
import '../models/wallet_pass_model.dart';
import 'database_helper.dart';

class WalletPassRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<WalletPassModel> insert(WalletPassModel pass) async {
    final db = await dbHelper.database;
    await db.insert('wallet_passes', pass.toMap());
    return pass;
  }

  /// Purges sample tickets and automatically deletes any travel tickets
  /// whose journey time was more than 24 hours ago (including attached user documents).
  Future<int> purgeExpiredAndSampleTransitTickets() async {
    try {
      final db = await dbHelper.database;
      final maps = await db.query('wallet_passes');
      final passes = maps.map((m) => WalletPassModel.fromMap(m)).toList();
      final now = DateTime.now();
      int deletedCount = 0;

      for (final pass in passes) {
        bool shouldDelete = false;

        // 1. Remove dummy sample ticket only
        if (pass.id == 'sample_transit_pass') {
          shouldDelete = true;
        }

        // 2. Automatically delete transit tickets & boarding passes 24 hours after journey time
        if (!shouldDelete &&
            (pass.passType == 'transit_ticket' ||
                pass.passType == 'boarding_pass')) {
          final journeyTime = pass.validUntil ?? pass.createdAt;
          final cutoff = journeyTime.add(const Duration(hours: 24));
          if (now.isAfter(cutoff)) {
            shouldDelete = true;
          }
        }

        if (shouldDelete) {
          _cleanupPassFiles(pass);
          await db.delete(
            'wallet_passes',
            where: 'id = ?',
            whereArgs: [pass.id],
          );
          deletedCount++;
        }
      }

      return deletedCount;
    } catch (_) {
      return 0;
    }
  }

  void _cleanupPassFiles(WalletPassModel pass) {
    try {
      // 1. If encryptedCodePath points to an uploaded file on disk, delete it
      if (pass.encryptedCodePath.isNotEmpty) {
        final f = File(pass.encryptedCodePath);
        if (f.existsSync()) {
          f.deleteSync();
        }
      }

      // 2. If notes has a Doc: <path> pointer, delete it from storage as well
      if (pass.notes != null) {
        final match = RegExp(r'Doc:\s*([^\n]+)').firstMatch(pass.notes!);
        if (match != null) {
          final docPath = match.group(1)?.trim();
          if (docPath != null && docPath.isNotEmpty) {
            final docFile = File(docPath);
            if (docFile.existsSync()) {
              docFile.deleteSync();
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<List<WalletPassModel>> getAllPasses() async {
    await purgeExpiredAndSampleTransitTickets();
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
    final existing = await getPassById(id);
    if (existing != null) {
      _cleanupPassFiles(existing);
    }
    final db = await dbHelper.database;
    return await db.delete('wallet_passes', where: 'id = ?', whereArgs: [id]);
  }
}
