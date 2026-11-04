import '../models/wallet_card_model.dart';
import 'database_helper.dart';
import 'transaction_dao.dart';

class WalletCardRepository {
  final dbHelper = DatabaseHelper.instance;
  final TransactionDao _transactionDao = TransactionDao();

  Future<WalletCardModel> insert(WalletCardModel card) async {
    final db = await dbHelper.database;
    await db.insert('wallet_cards', card.toMap());
    return card;
  }

  Future<List<WalletCardModel>> getAllCards() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'wallet_cards',
      orderBy: 'is_default DESC, display_order ASC, is_favorite DESC, created_at DESC',
    );
    return maps.map((m) => WalletCardModel.fromMap(m)).toList();
  }

  Future<WalletCardModel?> getCardById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'wallet_cards',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return WalletCardModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<WalletCardModel>> getFavoriteCards() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'wallet_cards',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => WalletCardModel.fromMap(m)).toList();
  }

  Future<List<WalletCardModel>> searchCards(String query) async {
    final db = await dbHelper.database;
    final pattern = '%$query%';
    final maps = await db.query(
      'wallet_cards',
      where: 'nickname LIKE ? OR issuer_name LIKE ? OR cardholder_name LIKE ? OR last_four LIKE ?',
      whereArgs: [pattern, pattern, pattern, pattern],
      orderBy: 'is_favorite DESC, created_at DESC',
    );
    return maps.map((m) => WalletCardModel.fromMap(m)).toList();
  }

  Future<int> update(WalletCardModel card) async {
    final db = await dbHelper.database;
    return await db.update(
      'wallet_cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> toggleFavorite(String id, bool isFavorite) async {
    final db = await dbHelper.database;
    return await db.update(
      'wallet_cards',
      {
        'is_favorite': isFavorite ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setDefaultCard(String id) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.update('wallet_cards', {'is_default': 0});
      await txn.update(
        'wallet_cards',
        {'is_default': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<int> updateThemeAndLayout(String id, {String? themeId, String? layoutId}) async {
    final db = await dbHelper.database;
    final Map<String, dynamic> updates = {
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (themeId != null) {
      updates['theme_gradient'] = themeId;
    }
    if (layoutId != null) {
      updates['card_layout_id'] = layoutId;
    }
    return await db.update(
      'wallet_cards',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateOrder(List<String> cardIds) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (int i = 0; i < cardIds.length; i++) {
      batch.update(
        'wallet_cards',
        {'display_order': i, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [cardIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Deletes a card and safely unlinks associated transactions (setting their card_id to NULL).
  Future<int> delete(String id) async {
    final db = await dbHelper.database;
    // Safely unlink any transaction associated with this card
    await _transactionDao.unlinkCardFromTransactions(id);
    return await db.delete(
      'wallet_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

