import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'document_encryption_service.dart';
import 'wallet_key_service.dart';

/// Secure hardware-backed storage service for full card and document numbers.
///
/// Full numbers are never stored in SQLite or SharedPreferences.
/// They are encrypted with AES-256-GCM using [WalletKeyService] and stored in
/// hardware-backed keystore/keychain storage.
class SecureNumberService {
  static const String _cardPrefix = 'spendz_enc_card_';
  static const String _docPrefix = 'spendz_enc_doc_';

  final FlutterSecureStorage _secureStorage;
  final WalletKeyService _keyService;
  final DocumentEncryptionService _encryptionService;

  SecureNumberService({
    FlutterSecureStorage? secureStorage,
    WalletKeyService? keyService,
    DocumentEncryptionService? encryptionService,
  })  : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            ),
        _keyService = keyService ?? WalletKeyService(),
        _encryptionService = encryptionService ?? DocumentEncryptionService();

  /// Saves the full card number encrypted in secure storage.
  Future<void> saveCardFullNumber(String cardId, String fullNumber) async {
    final sanitized = fullNumber.replaceAll(RegExp(r'\s+'), '');
    if (sanitized.isEmpty) return;

    try {
      final masterKey = await _keyService.getOrCreateMasterKey();
      final plaintext = utf8.encode(sanitized);
      final encrypted = await _encryptionService.encryptBytes(
        plaintext,
        keyBytes: masterKey,
      );
      await _secureStorage.write(
        key: '$_cardPrefix$cardId',
        value: base64Encode(encrypted),
      );
    } catch (e) {
      debugPrint('SecureNumberService: Failed to store encrypted card number securely: $e');
    }
  }

  /// Retrieves and decrypts the full card number. Returns null if not found or corrupted.
  Future<String?> getCardFullNumber(String cardId) async {
    try {
      final base64Enc = await _secureStorage.read(key: '$_cardPrefix$cardId');
      if (base64Enc == null || base64Enc.isEmpty) return null;

      final masterKey = await _keyService.getMasterKey();
      if (masterKey == null) return null;

      final encryptedBytes = base64Decode(base64Enc);
      final decrypted = await _encryptionService.decryptBytes(
        encryptedBytes,
        keyBytes: masterKey,
      );
      return utf8.decode(decrypted);
    } catch (_) {
      return null;
    }
  }

  /// Removes stored full number on card deletion.
  Future<void> deleteCardFullNumber(String cardId) async {
    try {
      await _secureStorage.delete(key: '$_cardPrefix$cardId');
    } catch (_) {}
  }

  /// Saves the full document number encrypted in secure storage.
  Future<void> saveDocumentFullNumber(String docId, String fullNumber) async {
    final sanitized = fullNumber.trim();
    if (sanitized.isEmpty) return;

    try {
      final masterKey = await _keyService.getOrCreateMasterKey();
      final plaintext = utf8.encode(sanitized);
      final encrypted = await _encryptionService.encryptBytes(
        plaintext,
        keyBytes: masterKey,
      );
      await _secureStorage.write(
        key: '$_docPrefix$docId',
        value: base64Encode(encrypted),
      );
    } catch (e) {
      debugPrint('SecureNumberService: Failed to store encrypted doc number securely: $e');
    }
  }

  /// Retrieves and decrypts the full document number. Returns null if not found.
  Future<String?> getDocumentFullNumber(String docId) async {
    try {
      final base64Enc = await _secureStorage.read(key: '$_docPrefix$docId');
      if (base64Enc == null || base64Enc.isEmpty) return null;

      final masterKey = await _keyService.getMasterKey();
      if (masterKey == null) return null;

      final encryptedBytes = base64Decode(base64Enc);
      final decrypted = await _encryptionService.decryptBytes(
        encryptedBytes,
        keyBytes: masterKey,
      );
      return utf8.decode(decrypted);
    } catch (_) {
      return null;
    }
  }

  /// Removes stored full document number on document deletion.
  Future<void> deleteDocumentFullNumber(String docId) async {
    try {
      await _secureStorage.delete(key: '$_docPrefix$docId');
    } catch (_) {}
  }

  /// Formats raw card number string with spaces every 4 characters.
  static String formatCardNumber(String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }
}
