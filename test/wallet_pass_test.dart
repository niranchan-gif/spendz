import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spendz/database/database_helper.dart';
import 'package:spendz/database/wallet_pass_repository.dart';
import 'package:spendz/models/wallet_pass_model.dart';
import 'package:uuid/uuid.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('wallet_passes');
  });

  test('WalletPassRepository inserts and retrieves pass correctly', () async {
    final repo = WalletPassRepository();
    final pass = WalletPassModel(
      id: const Uuid().v4(),
      title: 'IRCTC Vande Bharat',
      passType: 'transit_ticket',
      encryptedCodePath: 'PNR-123456',
      codeFormat: 'QR_CODE',
      issuer: 'Indian Railways',
      validUntil: DateTime.now().add(const Duration(days: 2)),
      notes: 'PNR: 8421-950-231\nSeat: 42 (Window)\nTime: 05:45 AM',
      isFavorite: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.insert(pass);
    final passes = await repo.getAllPasses();

    print('Passes in db: ${passes.length}');
    for (final p in passes) {
      print('Pass: ${p.title}, id: ${p.id}, validUntil: ${p.validUntil}, notes: ${p.notes}');
    }

    expect(passes.any((p) => p.id == pass.id), isTrue);
  });
}

