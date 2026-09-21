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

  Future<bool> transactionExistsWithReference(String referenceId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'transactions',
      columns: ['id'],
      where: 'reference_id = ?',
      whereArgs: [referenceId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }
}
