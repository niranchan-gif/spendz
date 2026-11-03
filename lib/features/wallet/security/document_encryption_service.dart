import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Exceptions thrown during vault encryption and decryption operations.
class VaultSecurityException implements Exception {
  final String message;
  VaultSecurityException(this.message);

  @override
  String toString() => 'VaultSecurityException: $message';
}

class InvalidFileHeaderException extends VaultSecurityException {
  InvalidFileHeaderException(super.message);
}

class UnsupportedFormatVersionException extends VaultSecurityException {
  UnsupportedFormatVersionException(super.message);
}

class UnsupportedAlgorithmException extends VaultSecurityException {
  UnsupportedAlgorithmException(super.message);
}

class DecryptionAuthenticationException extends VaultSecurityException {
  DecryptionAuthenticationException(super.message);
}

class InvalidKeyException extends VaultSecurityException {
  InvalidKeyException(super.message);
}

/// Production AES-256-GCM authenticated encryption service for Spendz Document Vault.
///
/// Binary File Format:
/// ┌──────────────┬─────────────┬──────────────┬──────────┬──────────┬────────────────────────┐
/// │ Magic (4B)   │ Version(1B) │ Alg ID(1B)   │ Nonce(12B│ Tag (16B)│ Ciphertext (Remaining) │
/// │ 'SPDZ' (hex) │ 0x01        │ 0x01(AES-GCM)│ 96-bit   │ 128-bit  │                        │
/// └──────────────┴─────────────┴──────────────┴──────────┴──────────┴────────────────────────┘
///
/// Authenticated Additional Data (AAD):
/// The 6-byte header [Magic + Version + AlgID] is supplied as AAD to the AES-GCM cipher.
/// Any tampering with the version, algorithm identifier, or magic bytes invalidates the
/// authentication tag and causes decryption to abort before any plaintext is released.
class DocumentEncryptionService {
  static const List<int> magicBytes = [0x53, 0x50, 0x44, 0x5A]; // 'S', 'P', 'D', 'Z'
  static const int currentVersion = 1;
  static const int algorithmAes256Gcm = 1;
  static const int nonceLength = 12; // 96-bit standard GCM nonce
  static const int tagLength = 16; // 128-bit standard GCM auth tag
  static const int headerLength = 4 + 1 + 1 + nonceLength + tagLength; // 34 bytes

  final AesGcm _cipher;

  DocumentEncryptionService({AesGcm? cipher})
      : _cipher = cipher ?? AesGcm.with256bits(nonceLength: nonceLength);

  /// Additional Authenticated Data bound to the cipher
  static Uint8List _buildAad(int version, int algorithm) {
    return Uint8List.fromList([
      ...magicBytes,
      version,
      algorithm,
    ]);
  }

  /// Encrypts [plainBytes] using AES-256-GCM with a freshly generated 12-byte CSPRNG nonce.
  ///
  /// [keyBytes] must be exactly 32 bytes (256 bits).
  /// Returns the complete versioned binary envelope including magic header, nonce, tag, and ciphertext.
  Future<Uint8List> encryptBytes(
    List<int> plainBytes, {
    required List<int> keyBytes,
    List<int>? customNonce, // For deterministic security testing only
  }) async {
    if (keyBytes.length != 32) {
      throw InvalidKeyException('Master key must be exactly 32 bytes (256 bits). Received ${keyBytes.length} bytes.');
    }

    final secretKey = SecretKey(keyBytes);
    final aad = _buildAad(currentVersion, algorithmAes256Gcm);

    final SecretBox secretBox;
    if (customNonce != null) {
      if (customNonce.length != nonceLength) {
        throw VaultSecurityException('Nonce must be exactly $nonceLength bytes. Received ${customNonce.length}.');
      }
      secretBox = await _cipher.encrypt(
        plainBytes,
        secretKey: secretKey,
        nonce: customNonce,
        aad: aad,
      );
    } else {
      secretBox = await _cipher.encrypt(
        plainBytes,
        secretKey: secretKey,
        aad: aad,
      );
    }

    // Assemble binary envelope:
    // Header (34 bytes) + Ciphertext
    final totalLength = headerLength + secretBox.cipherText.length;
    final result = Uint8List(totalLength);
    final buffer = ByteData.sublistView(result);

    int offset = 0;
    // 1. Magic
    result.setRange(offset, offset + 4, magicBytes);
    offset += 4;

    // 2. Format Version
    buffer.setUint8(offset, currentVersion);
    offset += 1;

    // 3. Algorithm ID
    buffer.setUint8(offset, algorithmAes256Gcm);
    offset += 1;

    // 4. Nonce
    result.setRange(offset, offset + nonceLength, secretBox.nonce);
    offset += nonceLength;

    // 5. Auth Tag (MAC)
    result.setRange(offset, offset + tagLength, secretBox.mac.bytes);
    offset += tagLength;

    // 6. Ciphertext
    result.setRange(offset, totalLength, secretBox.cipherText);

    return result;
  }

  /// Decrypts [encryptedBytes] using AES-256-GCM.
  ///
  /// Verifies the magic header, format version, algorithm, nonce, and authentication tag.
  /// If any byte of the ciphertext, header, or tag is altered, or if the wrong key is used,
  /// throws [DecryptionAuthenticationException] and NEVER returns partial plaintext.
  Future<Uint8List> decryptBytes(
    List<int> encryptedBytes, {
    required List<int> keyBytes,
  }) async {
    if (keyBytes.length != 32) {
      throw InvalidKeyException('Master key must be exactly 32 bytes (256 bits). Received ${keyBytes.length} bytes.');
    }

    if (encryptedBytes.length < headerLength) {
      throw InvalidFileHeaderException(
        'Encrypted file corrupted or incomplete. File size is ${encryptedBytes.length} bytes, minimum required is $headerLength bytes.',
      );
    }

    // 1. Validate Magic
    for (int i = 0; i < 4; i++) {
      if (encryptedBytes[i] != magicBytes[i]) {
        throw InvalidFileHeaderException('Invalid magic identifier. Not a Spendz Vault document.');
      }
    }

    // 2. Validate Version
    final version = encryptedBytes[4];
    if (version != currentVersion) {
      throw UnsupportedFormatVersionException(
        'Unsupported vault format version: $version. Current supported version is $currentVersion.',
      );
    }

    // 3. Validate Algorithm ID
    final algorithm = encryptedBytes[5];
    if (algorithm != algorithmAes256Gcm) {
      throw UnsupportedAlgorithmException(
        'Unsupported encryption algorithm ID: $algorithm. Expected AES-256-GCM ($algorithmAes256Gcm).',
      );
    }

    // Extract Nonce, Tag, and Ciphertext
    int offset = 6;
    final nonce = encryptedBytes.sublist(offset, offset + nonceLength);
    offset += nonceLength;

    final tag = encryptedBytes.sublist(offset, offset + tagLength);
    offset += tagLength;

    final cipherText = encryptedBytes.sublist(offset);

    final secretKey = SecretKey(keyBytes);
    final aad = _buildAad(version, algorithm);

    try {
      final decrypted = await _cipher.decrypt(
        SecretBox(
          cipherText,
          nonce: nonce,
          mac: Mac(tag),
        ),
        secretKey: secretKey,
        aad: aad,
      );

      return Uint8List.fromList(decrypted);
    } catch (e) {
      // Catch any cryptography error, tag mismatch, or corrupted data
      throw DecryptionAuthenticationException(
        'Authentication verification failed: document is corrupted, tampered with, or master key is incorrect.',
      );
    }
  }
}
