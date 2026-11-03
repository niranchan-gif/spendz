import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('spendwise.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN owed_amount REAL DEFAULT 0.0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE transactions ADD COLUMN expected_payments INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE transactions ADD COLUMN linked_payments INTEGER DEFAULT 0');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        type TEXT NOT NULL,
        is_default INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT,
        subcategory TEXT,
        merchant TEXT,
        description TEXT,
        date TEXT NOT NULL,
        payment_method TEXT,
        notes TEXT,
        source TEXT NOT NULL,
        bank_name TEXT,
        reference_id TEXT,
        owed_amount REAL DEFAULT 0.0,
        expected_payments INTEGER DEFAULT 0,
        linked_payments INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_date ON transactions (date);
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_category_id ON transactions (category_id);
    ''');

    await _seedDefaultCategories(db);
  }

  Future _seedDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final uuid = Uuid();

    final expenseCategories = [
      {'name': 'Food & Dining', 'icon': 'restaurant', 'color': '0xFFE57373'},
      {'name': 'Groceries', 'icon': 'local_grocery_store', 'color': '0xFF81C784'},
      {'name': 'Transport', 'icon': 'directions_car', 'color': '0xFF64B5F6'},
      {'name': 'Rent & Housing', 'icon': 'house', 'color': '0xFFFFB74D'},
      {'name': 'Bills & Utilities', 'icon': 'receipt', 'color': '0xFF4DB6AC'},
      {'name': 'Shopping', 'icon': 'shopping_bag', 'color': '0xFFBA68C8'},
      {'name': 'Entertainment', 'icon': 'movie', 'color': '0xFFF06292'},
      {'name': 'Health', 'icon': 'local_hospital', 'color': '0xFFE57373'},
      {'name': 'Education', 'icon': 'school', 'color': '0xFF4DD0E1'},
      {'name': 'Travel', 'icon': 'flight', 'color': '0xFF90CAF9'},
      {'name': 'Subscriptions', 'icon': 'subscriptions', 'color': '0xFFFF8A65'},
      {'name': 'Personal Care', 'icon': 'spa', 'color': '0xFFAED581'},
      {'name': 'Electronics', 'icon': 'devices', 'color': '0xFF7986CB'},
      {'name': 'Gifts', 'icon': 'card_giftcard', 'color': '0xFFFFD54F'},
      {'name': 'Investments', 'icon': 'trending_up', 'color': '0xFF4DB6AC'},
      {'name': 'Other', 'icon': 'category', 'color': '0xFF9E9E9E'},
    ];

    final incomeCategories = [
      {'name': 'Salary', 'icon': 'work', 'color': '0xFF81C784'},
      {'name': 'Freelance', 'icon': 'computer', 'color': '0xFF64B5F6'},
      {'name': 'Business', 'icon': 'business_center', 'color': '0xFF4DB6AC'},
      {'name': 'Interest', 'icon': 'account_balance', 'color': '0xFF90CAF9'},
      {'name': 'Refund', 'icon': 'replay', 'color': '0xFFAED581'},
      {'name': 'Gift', 'icon': 'redeem', 'color': '0xFFFFD54F'},
      {'name': 'Other Income', 'icon': 'attach_money', 'color': '0xFF81C784'},
    ];

    for (var cat in expenseCategories) {
      await db.insert('categories', {
        'id': uuid.v4(),
        'name': cat['name'],
        'icon': cat['icon'],
        'color': cat['color'],
        'type': 'expense',
        'is_default': 1,
        'created_at': now,
      });
    }

    for (var cat in incomeCategories) {
      await db.insert('categories', {
        'id': uuid.v4(),
        'name': cat['name'],
        'icon': cat['icon'],
        'color': cat['color'],
        'type': 'income',
        'is_default': 1,
        'created_at': now,
      });
    }
  }

  Future<void> clearAllTransactions() async {
    final db = await instance.database;
    await db.delete('transactions');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
