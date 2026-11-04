import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Sets an explicit database instance for isolated testing.
  static void setTestDatabase(Database? db) {
    _database = db;
  }

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
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _addColumnIfNotExists(
    Database db,
    String table,
    String column,
    String columnDef,
  ) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      final columnExists = info.any(
        (col) => (col['name'] as String?)?.toLowerCase() == column.toLowerCase(),
      );
      if (!columnExists) {
        await db.execute('ALTER TABLE $table ADD COLUMN $column $columnDef');
      }
    } catch (_) {
      // Safe fallback if column already exists or table structure differs
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _addColumnIfNotExists(db, 'transactions', 'owed_amount', 'REAL DEFAULT 0.0');
    }
    if (oldVersion < 3) {
      await _addColumnIfNotExists(db, 'transactions', 'expected_payments', 'INTEGER DEFAULT 0');
      await _addColumnIfNotExists(db, 'transactions', 'linked_payments', 'INTEGER DEFAULT 0');
    }
    if (oldVersion < 4) {
      // 1. Add nullable card_id column to transactions idempotently
      await _addColumnIfNotExists(db, 'transactions', 'card_id', 'TEXT');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_card_id ON transactions (card_id)');

      // 2. Create wallet_cards table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS wallet_cards (
          id TEXT PRIMARY KEY,
          nickname TEXT NOT NULL,
          issuer_name TEXT NOT NULL,
          cardholder_name TEXT NOT NULL,
          masked_number TEXT NOT NULL,
          last_four TEXT NOT NULL,
          expiry_month INTEGER NOT NULL,
          expiry_year INTEGER NOT NULL,
          card_type TEXT NOT NULL,
          card_network TEXT NOT NULL,
          theme_gradient TEXT NOT NULL,
          is_favorite INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_wallet_cards_fav ON wallet_cards (is_favorite)');

      // 3. Create wallet_documents table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS wallet_documents (
          id TEXT PRIMARY KEY,
          document_name TEXT NOT NULL,
          category TEXT NOT NULL,
          description TEXT,
          encrypted_file_path TEXT NOT NULL,
          thumbnail_path TEXT,
          mime_type TEXT NOT NULL,
          file_size INTEGER NOT NULL DEFAULT 0,
          issue_date TEXT,
          expiry_date TEXT,
          is_favorite INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_wallet_docs_cat ON wallet_documents (category)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_wallet_docs_fav ON wallet_documents (is_favorite)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_wallet_docs_expiry ON wallet_documents (expiry_date)');

      // 4. Create wallet_passes table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS wallet_passes (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          pass_type TEXT NOT NULL,
          encrypted_code_path TEXT NOT NULL,
          code_format TEXT NOT NULL,
          issuer TEXT,
          valid_until TEXT,
          is_favorite INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_wallet_passes_fav ON wallet_passes (is_favorite)');

      // 5. Create wallet_preferences table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS wallet_preferences (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    // 1. Categories
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

    // 2. Transactions
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
        card_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_transactions_date ON transactions (date)');
    await db.execute('CREATE INDEX idx_transactions_category_id ON transactions (category_id)');
    await db.execute('CREATE INDEX idx_transactions_card_id ON transactions (card_id)');

    // 3. Wallet Cards
    await db.execute('''
      CREATE TABLE wallet_cards (
        id TEXT PRIMARY KEY,
        nickname TEXT NOT NULL,
        issuer_name TEXT NOT NULL,
        cardholder_name TEXT NOT NULL,
        masked_number TEXT NOT NULL,
        last_four TEXT NOT NULL,
        expiry_month INTEGER NOT NULL,
        expiry_year INTEGER NOT NULL,
        card_type TEXT NOT NULL,
        card_network TEXT NOT NULL,
        theme_gradient TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_wallet_cards_fav ON wallet_cards (is_favorite)');

    // 4. Wallet Documents
    await db.execute('''
      CREATE TABLE wallet_documents (
        id TEXT PRIMARY KEY,
        document_name TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        encrypted_file_path TEXT NOT NULL,
        thumbnail_path TEXT,
        mime_type TEXT NOT NULL,
        file_size INTEGER NOT NULL DEFAULT 0,
        issue_date TEXT,
        expiry_date TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_wallet_docs_cat ON wallet_documents (category)');
    await db.execute('CREATE INDEX idx_wallet_docs_fav ON wallet_documents (is_favorite)');
    await db.execute('CREATE INDEX idx_wallet_docs_expiry ON wallet_documents (expiry_date)');

    // 5. Wallet Passes
    await db.execute('''
      CREATE TABLE wallet_passes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        pass_type TEXT NOT NULL,
        encrypted_code_path TEXT NOT NULL,
        code_format TEXT NOT NULL,
        issuer TEXT,
        valid_until TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_wallet_passes_fav ON wallet_passes (is_favorite)');

    // 6. Wallet Preferences
    await db.execute('''
      CREATE TABLE wallet_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
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

  Future<void> clearAllWalletData() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('wallet_cards');
      await txn.delete('wallet_documents');
      await txn.delete('wallet_passes');
      await txn.delete('wallet_preferences');
      // Unlink card_id from all transactions
      await txn.rawUpdate('UPDATE transactions SET card_id = NULL');
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
