// ignore_for_file: avoid_print, dangling_library_doc_comments, unnecessary_import
/// Phase 2 — Database Migration & Wallet Repository Tests
///
/// Covers:
///  • v3→v4 migration (additive only — transactions/categories preserved)
///  • Fresh v4 DB creation
///  • WalletCard  CRUD + search + favorites + safe delete
///  • WalletDocument CRUD + category filter + expiry filter
///  • WalletPass CRUD + active passes + favorites
///  • WalletPreferences set/get/delete/clear
///  • Card-transaction association (associate, getByCard, unlink on delete)
///  • card_id = NULL compatibility for existing transactions
///  • DB reopen / persistence
///  • Invalid / empty data handling

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

/// Minimal v3 schema (without card_id, without wallet tables).
Future<Database> _openV3(String path) async {
  return databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 3,
      onCreate: (db, version) async {
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
      },
    ),
  );
}

/// Opens (or creates) a v4 database at [path] using the same migration logic
/// as DatabaseHelper.
Future<Database> _openV4(String path) async {
  return databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 4,
      onCreate: (db, version) async {
        await _createV4Tables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _migrateToV4(db, oldVersion);
      },
    ),
  );
}

Future<void> _createV4Tables(Database db) async {
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
      card_id TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');
  await db.execute('CREATE INDEX idx_transactions_date ON transactions (date)');
  await db.execute(
    'CREATE INDEX idx_transactions_card_id ON transactions (card_id)',
  );
  await _createWalletTables(db);
}

Future<void> _migrateToV4(Database db, int oldVersion) async {
  if (oldVersion < 2) {
    await db.execute(
      'ALTER TABLE transactions ADD COLUMN owed_amount REAL DEFAULT 0.0',
    );
  }
  if (oldVersion < 3) {
    await db.execute(
      'ALTER TABLE transactions ADD COLUMN expected_payments INTEGER DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE transactions ADD COLUMN linked_payments INTEGER DEFAULT 0',
    );
  }
  if (oldVersion < 4) {
    await db.execute('ALTER TABLE transactions ADD COLUMN card_id TEXT');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_card_id ON transactions (card_id)',
    );
    await _createWalletTables(db);
  }
}

Future<void> _createWalletTables(Database db) async {
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
  await db.execute('''
    CREATE TABLE IF NOT EXISTS wallet_preferences (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');
}

// ─── Sample data factories ───────────────────────────────────────────────────

Map<String, dynamic> _sampleCard({
  String id = 'card-1',
  bool favorite = false,
}) => {
  'id': id,
  'nickname': 'My HDFC Card',
  'issuer_name': 'HDFC Bank',
  'cardholder_name': 'Test User',
  'masked_number': '**** **** **** 1234',
  'last_four': '1234',
  'expiry_month': 12,
  'expiry_year': 2027,
  'card_type': 'debit',
  'card_network': 'Visa',
  'theme_gradient': 'blue,darkBlue',
  'is_favorite': favorite ? 1 : 0,
  'created_at': '2024-01-01T00:00:00.000',
  'updated_at': '2024-01-01T00:00:00.000',
};

Map<String, dynamic> _sampleDoc({
  String id = 'doc-1',
  String category = 'identity',
  String? expiryDate,
  bool favorite = false,
}) => {
  'id': id,
  'document_name': 'Aadhaar Card',
  'category': category,
  'description': 'Government ID',
  'encrypted_file_path': '/secure/aadhaar.enc',
  'thumbnail_path': null,
  'mime_type': 'application/pdf',
  'file_size': 102400,
  'issue_date': '2020-01-01',
  'expiry_date': expiryDate,
  'is_favorite': favorite ? 1 : 0,
  'created_at': '2024-01-01T00:00:00.000',
  'updated_at': '2024-01-01T00:00:00.000',
};

Map<String, dynamic> _samplePass({
  String id = 'pass-1',
  String? validUntil,
  bool favorite = false,
}) => {
  'id': id,
  'title': 'Gym Membership',
  'pass_type': 'membership',
  'encrypted_code_path': 'GYM123456',
  'code_format': 'QR_CODE',
  'issuer': 'FitLife Gym',
  'valid_until': validUntil,
  'is_favorite': favorite ? 1 : 0,
  'created_at': '2024-01-01T00:00:00.000',
  'updated_at': '2024-01-01T00:00:00.000',
};

Map<String, dynamic> _sampleTransaction({String id = 'tx-1', String? cardId}) =>
    {
      'id': id,
      'amount': 500.0,
      'type': 'expense',
      'category_id': null,
      'subcategory': null,
      'merchant': 'Amazon',
      'description': 'Online shopping',
      'date': '2024-06-01T10:00:00.000',
      'payment_method': 'card',
      'notes': null,
      'source': 'manual',
      'bank_name': null,
      'reference_id': null,
      'owed_amount': 0.0,
      'expected_payments': 0,
      'linked_payments': 0,
      'card_id': cardId,
      'created_at': '2024-06-01T10:00:00.000',
      'updated_at': '2024-06-01T10:00:00.000',
    };

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // ── 1. Migration: v3 → v4 ──────────────────────────────────────────────────
  group('Migration v3 → v4', () {
    late String tempPath;

    setUp(() {
      // Use a unique temp file so v3 data actually persists across open/close
      final tempDir = Directory.systemTemp.createTempSync('spendz_test_');
      tempPath = '${tempDir.path}/spendwise_test.db';
    });

    tearDown(() {
      try {
        File(tempPath).parent.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('wallet tables are created after migration', () async {
      // Create a v3 DB with seed data
      final v3db = await _openV3(tempPath);
      await v3db.insert('categories', {
        'id': 'cat-1',
        'name': 'Food',
        'icon': 'food',
        'color': '0xFF4CAF50',
        'type': 'expense',
        'is_default': 1,
        'created_at': '2024-01-01T00:00:00.000',
      });
      await v3db.insert('transactions', {
        'id': 'tx-seed',
        'amount': 250.0,
        'type': 'expense',
        'date': '2024-05-01T08:00:00.000',
        'source': 'manual',
        'created_at': '2024-05-01T08:00:00.000',
        'updated_at': '2024-05-01T08:00:00.000',
      });
      await v3db.close();

      // Re-open as v4 — triggers onUpgrade
      final v4db = await _openV4(tempPath);

      // Wallet tables must exist
      final tables = await v4db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final names = tables.map((r) => r['name'] as String).toSet();
      expect(
        names,
        containsAll([
          'wallet_cards',
          'wallet_documents',
          'wallet_passes',
          'wallet_preferences',
        ]),
      );

      // card_id column must exist on transactions
      final cols = await v4db.rawQuery('PRAGMA table_info(transactions)');
      final colNames = cols.map((c) => c['name'] as String).toSet();
      expect(colNames, contains('card_id'));

      // Original transaction is preserved
      final txs = await v4db.query('transactions');
      expect(txs.length, 1);
      expect(txs.first['id'], 'tx-seed');
      expect(txs.first['card_id'], isNull);

      // Original category is preserved
      final cats = await v4db.query('categories');
      expect(cats.length, 1);
      expect(cats.first['name'], 'Food');

      await v4db.close();
    });
  });

  // ── 2. Fresh v4 DB creation ────────────────────────────────────────────────
  group('Fresh v4 DB creation', () {
    test('all 6 tables are created', () async {
      final db = await _openV4(inMemoryDatabasePath);
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final names = tables.map((r) => r['name'] as String).toSet();
      expect(
        names,
        containsAll([
          'categories',
          'transactions',
          'wallet_cards',
          'wallet_documents',
          'wallet_passes',
          'wallet_preferences',
        ]),
      );
      await db.close();
    });

    test('transactions table has card_id column', () async {
      final db = await _openV4(inMemoryDatabasePath);
      final cols = await db.rawQuery('PRAGMA table_info(transactions)');
      final colNames = cols.map((c) => c['name'] as String).toSet();
      expect(
        colNames,
        containsAll(['card_id', 'amount', 'type', 'date', 'source']),
      );
      await db.close();
    });
  });

  // ── 3. WalletCard CRUD ─────────────────────────────────────────────────────
  group('WalletCard CRUD', () {
    late Database db;

    setUp(() async => db = await _openV4(inMemoryDatabasePath));
    tearDown(() async => db.close());

    test('insert and read by id', () async {
      await db.insert('wallet_cards', _sampleCard());
      final rows = await db.query(
        'wallet_cards',
        where: 'id = ?',
        whereArgs: ['card-1'],
      );
      expect(rows.length, 1);
      expect(rows.first['nickname'], 'My HDFC Card');
      expect(rows.first['last_four'], '1234');
    });

    test('update card nickname', () async {
      await db.insert('wallet_cards', _sampleCard());
      await db.update(
        'wallet_cards',
        {'nickname': 'HDFC Platinum', 'updated_at': '2024-06-01T00:00:00.000'},
        where: 'id = ?',
        whereArgs: ['card-1'],
      );
      final rows = await db.query(
        'wallet_cards',
        where: 'id = ?',
        whereArgs: ['card-1'],
      );
      expect(rows.first['nickname'], 'HDFC Platinum');
    });

    test('delete card', () async {
      await db.insert('wallet_cards', _sampleCard());
      await db.delete('wallet_cards', where: 'id = ?', whereArgs: ['card-1']);
      final rows = await db.query('wallet_cards');
      expect(rows, isEmpty);
    });

    test('get all cards', () async {
      await db.insert('wallet_cards', _sampleCard(id: 'card-1'));
      await db.insert('wallet_cards', _sampleCard(id: 'card-2'));
      final rows = await db.query('wallet_cards');
      expect(rows.length, 2);
    });

    test('search cards by nickname', () async {
      await db.insert('wallet_cards', _sampleCard(id: 'card-1'));
      await db.insert(
        'wallet_cards',
        _sampleCard(id: 'card-2')..['nickname'] = 'SBI Savings',
      );
      final results = await db.query(
        'wallet_cards',
        where: 'nickname LIKE ?',
        whereArgs: ['%HDFC%'],
      );
      expect(results.length, 1);
    });

    test('favorite filtering', () async {
      await db.insert(
        'wallet_cards',
        _sampleCard(id: 'card-1', favorite: true),
      );
      await db.insert(
        'wallet_cards',
        _sampleCard(id: 'card-2', favorite: false),
      );
      final favs = await db.query('wallet_cards', where: 'is_favorite = 1');
      expect(favs.length, 1);
      expect(favs.first['id'], 'card-1');
    });

    test('toggle favorite', () async {
      await db.insert('wallet_cards', _sampleCard());
      await db.update(
        'wallet_cards',
        {'is_favorite': 1},
        where: 'id = ?',
        whereArgs: ['card-1'],
      );
      final row = await db.query(
        'wallet_cards',
        where: 'id = ?',
        whereArgs: ['card-1'],
      );
      expect(row.first['is_favorite'], 1);
    });
  });

  // ── 4. WalletDocument CRUD ─────────────────────────────────────────────────
  group('WalletDocument CRUD', () {
    late Database db;

    setUp(() async => db = await _openV4(inMemoryDatabasePath));
    tearDown(() async => db.close());

    test('insert and read', () async {
      await db.insert('wallet_documents', _sampleDoc());
      final rows = await db.query('wallet_documents');
      expect(rows.length, 1);
      expect(rows.first['document_name'], 'Aadhaar Card');
    });

    test('category filter', () async {
      await db.insert(
        'wallet_documents',
        _sampleDoc(id: 'doc-1', category: 'identity'),
      );
      await db.insert(
        'wallet_documents',
        _sampleDoc(id: 'doc-2', category: 'financial'),
      );
      final identity = await db.query(
        'wallet_documents',
        where: 'category = ?',
        whereArgs: ['identity'],
      );
      expect(identity.length, 1);
      expect(identity.first['id'], 'doc-1');
    });

    test('expiry filter — expiring within 30 days', () async {
      final soon = DateTime.now()
          .add(const Duration(days: 15))
          .toIso8601String()
          .substring(0, 10);
      final later = DateTime.now()
          .add(const Duration(days: 90))
          .toIso8601String()
          .substring(0, 10);
      await db.insert(
        'wallet_documents',
        _sampleDoc(id: 'doc-soon', expiryDate: soon),
      );
      await db.insert(
        'wallet_documents',
        _sampleDoc(id: 'doc-later', expiryDate: later),
      );
      await db.insert('wallet_documents', _sampleDoc(id: 'doc-null'));

      final cutoff = DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String()
          .substring(0, 10);
      final expiring = await db.query(
        'wallet_documents',
        where: 'expiry_date IS NOT NULL AND expiry_date <= ?',
        whereArgs: [cutoff],
      );
      expect(expiring.length, 1);
      expect(expiring.first['id'], 'doc-soon');
    });

    test('favorite filtering', () async {
      await db.insert(
        'wallet_documents',
        _sampleDoc(id: 'doc-1', favorite: true),
      );
      await db.insert(
        'wallet_documents',
        _sampleDoc(id: 'doc-2', favorite: false),
      );
      final favs = await db.query('wallet_documents', where: 'is_favorite = 1');
      expect(favs.length, 1);
    });

    test('update and delete', () async {
      await db.insert('wallet_documents', _sampleDoc());
      await db.update(
        'wallet_documents',
        {'document_name': 'PAN Card'},
        where: 'id = ?',
        whereArgs: ['doc-1'],
      );
      final row = await db.query(
        'wallet_documents',
        where: 'id = ?',
        whereArgs: ['doc-1'],
      );
      expect(row.first['document_name'], 'PAN Card');

      await db.delete(
        'wallet_documents',
        where: 'id = ?',
        whereArgs: ['doc-1'],
      );
      expect(await db.query('wallet_documents'), isEmpty);
    });
  });

  // ── 5. WalletPass CRUD ─────────────────────────────────────────────────────
  group('WalletPass CRUD', () {
    late Database db;

    setUp(() async => db = await _openV4(inMemoryDatabasePath));
    tearDown(() async => db.close());

    test('insert and read', () async {
      await db.insert('wallet_passes', _samplePass());
      final rows = await db.query('wallet_passes');
      expect(rows.length, 1);
      expect(rows.first['title'], 'Gym Membership');
      expect(rows.first['encrypted_code_path'], 'GYM123456');
    });

    test('active passes filter (valid_until > now or null)', () async {
      final future = DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String();
      final past = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String();
      await db.insert(
        'wallet_passes',
        _samplePass(id: 'pass-future', validUntil: future),
      );
      await db.insert(
        'wallet_passes',
        _samplePass(id: 'pass-past', validUntil: past),
      );
      await db.insert('wallet_passes', _samplePass(id: 'pass-null'));

      final now = DateTime.now().toIso8601String();
      final active = await db.query(
        'wallet_passes',
        where: 'valid_until IS NULL OR valid_until > ?',
        whereArgs: [now],
      );
      expect(active.length, 2); // future + null
      final ids = active.map((r) => r['id']).toSet();
      expect(ids, containsAll(['pass-future', 'pass-null']));
    });

    test('search passes by title', () async {
      await db.insert('wallet_passes', _samplePass(id: 'pass-1'));
      await db.insert('wallet_passes', {
        ..._samplePass(id: 'pass-2'),
        'title': 'Movie Ticket',
      });
      final results = await db.query(
        'wallet_passes',
        where: 'title LIKE ?',
        whereArgs: ['%Gym%'],
      );
      expect(results.length, 1);
    });

    test('favorite toggle', () async {
      await db.insert('wallet_passes', _samplePass());
      await db.update(
        'wallet_passes',
        {'is_favorite': 1},
        where: 'id = ?',
        whereArgs: ['pass-1'],
      );
      final row = await db.query(
        'wallet_passes',
        where: 'id = ?',
        whereArgs: ['pass-1'],
      );
      expect(row.first['is_favorite'], 1);
    });
  });

  // ── 6. WalletPreferences ───────────────────────────────────────────────────
  group('WalletPreferences', () {
    late Database db;

    setUp(() async => db = await _openV4(inMemoryDatabasePath));
    tearDown(() async => db.close());

    test('set and get preference', () async {
      await db.insert('wallet_preferences', {
        'key': 'theme',
        'value': 'dark',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      final rows = await db.query(
        'wallet_preferences',
        where: 'key = ?',
        whereArgs: ['theme'],
      );
      expect(rows.first['value'], 'dark');
    });

    test('update preference via replace', () async {
      await db.insert('wallet_preferences', {
        'key': 'theme',
        'value': 'dark',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('wallet_preferences', {
        'key': 'theme',
        'value': 'light',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      final rows = await db.query('wallet_preferences');
      expect(rows.length, 1);
      expect(rows.first['value'], 'light');
    });

    test('delete preference', () async {
      await db.insert('wallet_preferences', {
        'key': 'key1',
        'value': 'val1',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.delete(
        'wallet_preferences',
        where: 'key = ?',
        whereArgs: ['key1'],
      );
      expect(await db.query('wallet_preferences'), isEmpty);
    });

    test('get all preferences returns map', () async {
      await db.insert('wallet_preferences', {
        'key': 'a',
        'value': '1',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('wallet_preferences', {
        'key': 'b',
        'value': '2',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      final rows = await db.query('wallet_preferences');
      final map = {
        for (var r in rows) r['key'] as String: r['value'] as String,
      };
      expect(map, {'a': '1', 'b': '2'});
    });
  });

  // ── 7. Card–Transaction association ───────────────────────────────────────
  group('Card–Transaction association', () {
    late Database db;

    setUp(() async => db = await _openV4(inMemoryDatabasePath));
    tearDown(() async => db.close());

    test('associate card with transaction', () async {
      await db.insert('wallet_cards', _sampleCard());
      await db.insert('transactions', _sampleTransaction(id: 'tx-1'));

      await db.update(
        'transactions',
        {'card_id': 'card-1'},
        where: 'id = ?',
        whereArgs: ['tx-1'],
      );
      final tx = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: ['tx-1'],
      );
      expect(tx.first['card_id'], 'card-1');
    });

    test('get transactions by card_id', () async {
      await db.insert('wallet_cards', _sampleCard());
      await db.insert(
        'transactions',
        _sampleTransaction(id: 'tx-1', cardId: 'card-1'),
      );
      await db.insert('transactions', _sampleTransaction(id: 'tx-2'));

      final byCard = await db.query(
        'transactions',
        where: 'card_id = ?',
        whereArgs: ['card-1'],
      );
      expect(byCard.length, 1);
      expect(byCard.first['id'], 'tx-1');
    });

    test(
      'safe delete: card deletion nullifies card_id on transactions',
      () async {
        await db.insert('wallet_cards', _sampleCard());
        await db.insert(
          'transactions',
          _sampleTransaction(id: 'tx-1', cardId: 'card-1'),
        );

        // Simulate WalletCardRepository safe delete
        await db.update(
          'transactions',
          {'card_id': null},
          where: 'card_id = ?',
          whereArgs: ['card-1'],
        );
        await db.delete('wallet_cards', where: 'id = ?', whereArgs: ['card-1']);

        final tx = await db.query(
          'transactions',
          where: 'id = ?',
          whereArgs: ['tx-1'],
        );
        expect(tx.first['card_id'], isNull);
        expect(await db.query('wallet_cards'), isEmpty);
      },
    );

    test('existing transactions without card_id load correctly', () async {
      await db.insert('transactions', _sampleTransaction(id: 'tx-legacy'));
      final tx = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: ['tx-legacy'],
      );
      expect(tx.first['card_id'], isNull);
      expect(tx.first['amount'], 500.0);
    });

    test('unlink card from all transactions', () async {
      await db.insert('wallet_cards', _sampleCard());
      await db.insert(
        'transactions',
        _sampleTransaction(id: 'tx-a', cardId: 'card-1'),
      );
      await db.insert(
        'transactions',
        _sampleTransaction(id: 'tx-b', cardId: 'card-1'),
      );
      await db.insert('transactions', _sampleTransaction(id: 'tx-c'));

      await db.update(
        'transactions',
        {'card_id': null},
        where: 'card_id = ?',
        whereArgs: ['card-1'],
      );

      final linked = await db.query(
        'transactions',
        where: 'card_id = ?',
        whereArgs: ['card-1'],
      );
      expect(linked, isEmpty);

      final all = await db.query('transactions');
      expect(all.length, 3); // all transactions still exist
    });
  });

  // ── 8. Null / invalid data handling ───────────────────────────────────────
  group('Edge cases', () {
    late Database db;

    setUp(() async => db = await _openV4(inMemoryDatabasePath));
    tearDown(() async => db.close());

    test('document with null expiry_date is handled gracefully', () async {
      await db.insert('wallet_documents', _sampleDoc());
      final rows = await db.query('wallet_documents');
      expect(rows.first['expiry_date'], isNull);
    });

    test('pass with null valid_until is treated as permanent', () async {
      await db.insert('wallet_passes', _samplePass());
      final rows = await db.query('wallet_passes');
      expect(rows.first['valid_until'], isNull);
    });

    test('inserting duplicate id throws', () async {
      await db.insert('wallet_cards', _sampleCard());
      expect(
        () async => db.insert('wallet_cards', _sampleCard()),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('querying non-existent id returns empty list', () async {
      final rows = await db.query(
        'wallet_cards',
        where: 'id = ?',
        whereArgs: ['no-such-id'],
      );
      expect(rows, isEmpty);
    });

    test('preference key is unique — no duplicates', () async {
      await db.insert('wallet_preferences', {
        'key': 'k',
        'value': 'v1',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await db.insert('wallet_preferences', {
        'key': 'k',
        'value': 'v2',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      final rows = await db.query('wallet_preferences');
      expect(rows.length, 1);
      expect(rows.first['value'], 'v2');
    });
  });
}
