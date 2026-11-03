import '../models/transaction_model.dart';
import 'database_helper.dart';

class TransactionDao {
  final dbHelper = DatabaseHelper.instance;

  Future<TransactionModel> insert(TransactionModel transaction) async {
    final db = await dbHelper.database;
    await db.insert('transactions', transaction.toMap());
    return transaction;
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<TransactionModel?> getTransactionById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return TransactionModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(TransactionModel transaction) async {
    final db = await dbHelper.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> transactionExistsWithReference(String referenceId, {double? amount, DateTime? date}) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'transactions',
      columns: ['id'],
      where: 'reference_id = ?',
      whereArgs: [referenceId],
      limit: 1,
    );
    if (maps.isNotEmpty) return true;

    if (amount != null && date != null) {
      final dateStart = DateTime(date.year, date.month, date.day).toIso8601String();
      final dateEnd = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
      final duplicateMaps = await db.query(
        'transactions',
        columns: ['id'],
        where: 'amount = ? AND date >= ? AND date <= ?',
        whereArgs: [amount, dateStart, dateEnd],
        limit: 1,
      );
      if (duplicateMaps.isNotEmpty) return true;
    }
    
    return false;
  }

  Future<List<TransactionModel>> getTransactionsByCard(String cardId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'card_id = ?',
      whereArgs: [cardId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<int> associateCard(String transactionId, String? cardId) async {
    final db = await dbHelper.database;
    return await db.update(
      'transactions',
      {'card_id': cardId, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  Future<int> unlinkCardFromTransactions(String cardId) async {
    final db = await dbHelper.database;
    return await db.update(
      'transactions',
      {'card_id': null, 'updated_at': DateTime.now().toIso8601String()},
      where: 'card_id = ?',
      whereArgs: [cardId],
    );
  }
}
