import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'document_encryption_service.dart';

class MasterKeyLostException extends VaultSecurityException {
  MasterKeyLostException()
      : super(
          'Master encryption key not found in secure hardware storage, but encrypted documents exist in vault. '
          'Silent regeneration prevented to avoid data loss. Manual key recovery or vault reset required.',
        );
}

class KeyStorageException extends VaultSecurityException {
  KeyStorageException(super.message);
}

/// Secure master key management service for Spendz Document Vault.
///
/// Hardware backing:
/// - Android: Android Keystore with AES-GCM and RSA-OAEP key wrapping.
/// - iOS: iOS Keychain with kSecAttrAccessibleAfterFirstUnlock.
///
/// Critical Protection Rule:
/// If the secure hardware storage reports no key, but the application database contains
/// documents, the service enters a [MasterKeyLostException] state rather than silently
/// generating a new key (which would permanently orphan all existing encrypted files).
class WalletKeyService {
  static const String _keyStorageKey = 'spendz_wallet_master_encryption_key_v1';
  static const int keyLengthBytes = 32; // 256 bits

  final FlutterSecureStorage _secureStorage;
  final AesGcm _cipher;

  // In-memory cache for the session (cleared on lock / app kill)
  List<int>? _cachedKey;

  WalletKeyService({
    FlutterSecureStorage? secureStorage,
    AesGcm? cipher,
  })  : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: false,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            ),
        _cipher = cipher ?? AesGcm.with256bits();

  /// Checks if master key exists in hardware secure storage.
  Future<bool> hasMasterKey() async {
    try {
      final value = await _secureStorage.read(key: _keyStorageKey);
      return value != null && value.isNotEmpty;
    } catch (e) {
      throw KeyStorageException('Failed to inspect secure storage: $e');
    }
  }

  /// Retrieves the existing master key or throws if not available.
  Future<List<int>?> getMasterKey() async {
    if (_cachedKey != null) {
      return List<int>.unmodifiable(_cachedKey!);
    }

    try {
      final base64Key = await _secureStorage.read(key: _keyStorageKey);
      if (base64Key == null || base64Key.isEmpty) {
        return null;
      }

      final keyBytes = base64Decode(base64Key);
      if (keyBytes.length != keyLengthBytes) {
        throw InvalidKeyException(
          'Corrupted key material in secure storage. Expected $keyLengthBytes bytes, found ${keyBytes.length}.',
        );
      }

      _cachedKey = List<int>.from(keyBytes);
      return List<int>.unmodifiable(_cachedKey!);
    } catch (e) {
      if (e is VaultSecurityException) rethrow;
      throw KeyStorageException('Failed to retrieve master key from secure storage: $e');
    }
  }

  /// Retrieves the existing key, or generates a new 256-bit key if this is a first-time setup.
  ///
  /// [hasExistingVaultDocuments] must return true if the database currently holds encrypted documents.
  /// If documents exist but the hardware key is missing, throws [MasterKeyLostException].
  Future<List<int>> getOrCreateMasterKey({
    required bool Function() hasExistingVaultDocuments,
  }) async {
    final existingKey = await getMasterKey();
    if (existingKey != null) {
      return existingKey;
    }

    // Key is missing in secure storage. Check if user already has encrypted files.
    if (hasExistingVaultDocuments()) {
      throw MasterKeyLostException();
    }

    // Clean first-time generation using CSPRNG
    final secretKey = await _cipher.newSecretKey();
    final newKeyBytes = await secretKey.extractBytes();

    if (newKeyBytes.length != keyLengthBytes) {
      throw InvalidKeyException('CSPRNG generated unexpected key length: ${newKeyBytes.length}');
    }

    final base64Key = base64Encode(newKeyBytes);
    await _secureStorage.write(key: _keyStorageKey, value: base64Key);

    _cachedKey = List<int>.from(newKeyBytes);
    return List<int>.unmodifiable(_cachedKey!);
  }

  /// Rotates the master key in secure storage.
  ///
  /// The caller is responsible for re-encrypting existing documents with the new key.
  Future<void> rotateMasterKey(List<int> newKeyBytes) async {
    if (newKeyBytes.length != keyLengthBytes) {
      throw InvalidKeyException('New master key must be $keyLengthBytes bytes (256 bits).');
    }

    final base64Key = base64Encode(newKeyBytes);
    await _secureStorage.write(key: _keyStorageKey, value: base64Key);
    _cachedKey = List<int>.from(newKeyBytes);
  }

  /// Clears in-memory key cache (e.g. on lock or logout).
  void clearMemoryCache() {
    _cachedKey = null;
  }

  /// Deletes the master key from secure storage (e.g., during testing or complete vault reset).
  Future<void> deleteKeyForReset() async {
    _cachedKey = null;
    await _secureStorage.delete(key: _keyStorageKey);
  }
}
