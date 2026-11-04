import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../database/database_helper.dart';
import '../../../database/wallet_document_repository.dart';
import '../../../models/wallet_document_model.dart';
import '../security/document_encryption_service.dart';
import '../security/secure_number_service.dart';
import '../security/wallet_key_service.dart';

class VaultValidationException extends VaultSecurityException {
  VaultValidationException(super.message);
}

class VaultStorageException extends VaultSecurityException {
  VaultStorageException(super.message);
}

/// Service managing the secure local lifecycle of encrypted documents in Spendz.
///
/// Features:
/// - AES-256-GCM authenticated encryption for document attachments.
/// - Encrypted metadata payload for sensitive fields (DOB, address, account numbers).
/// - Atomic staging and write verification for imported documents.
/// - Support for documents without attachments (pure manual record) or with image/PDF attachments.
/// - Ephemeral, in-memory decryption for images.
/// - Scoped temporary caching for PDF previews with automatic cleanup.
/// - Deletion of metadata, underlying ciphertext files, and secure hardware keys.
class DocumentVaultService {
  static const int maxFileSizeBytes = 25 * 1024 * 1024; // 25 MB max
  static const Set<String> supportedMimeTypes = {
    'application/pdf',
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  };

  final WalletDocumentRepository _documentRepository;
  final DocumentEncryptionService _encryptionService;
  final WalletKeyService _keyService;
  final SecureNumberService _secureNumberService;
  final String? _customVaultDirectory;
  final String? _customTempDirectory;

  DocumentVaultService({
    WalletDocumentRepository? documentRepository,
    DocumentEncryptionService? encryptionService,
    WalletKeyService? keyService,
    SecureNumberService? secureNumberService,
    String? customVaultDirectory,
    String? customTempDirectory,
  }) : _documentRepository = documentRepository ?? WalletDocumentRepository(),
       _encryptionService = encryptionService ?? DocumentEncryptionService(),
       _keyService = keyService ?? WalletKeyService(),
       _secureNumberService = secureNumberService ?? SecureNumberService(),
       _customVaultDirectory = customVaultDirectory,
       _customTempDirectory = customTempDirectory;

  /// Returns the private application directory where encrypted documents reside.
  Future<Directory> getVaultDirectory() async {
    final Directory dir;
    if (_customVaultDirectory != null) {
      dir = Directory(_customVaultDirectory);
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      dir = Directory(p.join(appDir.path, 'vault'));
    }
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Returns the private cache directory where temporary preview files are staged.
  Future<Directory> getTempDirectory() async {
    final Directory dir;
    if (_customTempDirectory != null) {
      dir = Directory(_customTempDirectory);
    } else {
      final cacheDir = await getTemporaryDirectory();
      dir = Directory(p.join(cacheDir.path, 'vault_temp'));
    }
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Encrypts an arbitrary metadata map using the master encryption key.
  Future<String> encryptMetadataFields(Map<String, dynamic> fields) async {
    if (fields.isEmpty) return '';
    final masterKey = await _keyService.getOrCreateMasterKey();
    final jsonStr = jsonEncode(fields);
    final encryptedBytes = await _encryptionService.encryptBytes(
      utf8.encode(jsonStr),
      keyBytes: masterKey,
    );
    return base64Encode(encryptedBytes);
  }

  /// Decrypts an encrypted metadata map using the master encryption key.
  Future<Map<String, dynamic>> decryptMetadataFields(
    String base64Ciphertext,
  ) async {
    if (base64Ciphertext.trim().isEmpty) return {};
    try {
      final masterKey = await _keyService.getMasterKey();
      if (masterKey == null) return {};
      final encryptedBytes = base64Decode(base64Ciphertext);
      final decrypted = await _encryptionService.decryptBytes(
        encryptedBytes,
        keyBytes: masterKey,
      );
      final jsonStr = utf8.decode(decrypted);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Saves a manual document with optional attachment and sensitive encrypted fields.
  Future<WalletDocumentModel> saveManualDocument({
    required String documentName,
    required String category,
    String? holderName,
    String? maskedIdentifier,
    String? unmaskedIdentifier,
    Map<String, dynamic>? extraFields,
    String? description,
    DateTime? issueDate,
    DateTime? expiryDate,
    bool isFavorite = false,
    List<int>? attachmentBytes,
    String? attachmentMimeType,
    String? attachmentType,
  }) async {
    final docId = const Uuid().v4();
    final now = DateTime.now();

    // 1. Encrypt sensitive extra fields if present
    String? encryptedFieldsCiphertext;
    if (extraFields != null && extraFields.isNotEmpty) {
      encryptedFieldsCiphertext = await encryptMetadataFields(extraFields);
    }

    // 2. Save full unmasked number in SecureNumberService if provided
    if (unmaskedIdentifier != null && unmaskedIdentifier.trim().isNotEmpty) {
      await _secureNumberService.saveDocumentFullNumber(
        docId,
        unmaskedIdentifier.trim(),
      );
    }

    // 3. Encrypt and write attachment file if provided
    String encryptedFilePath = '';
    String normalizedMime = 'none';
    int fileSize = 0;
    String finalAttachmentType = 'none';

    if (attachmentBytes != null && attachmentBytes.isNotEmpty) {
      if (attachmentBytes.length > maxFileSizeBytes) {
        throw VaultValidationException(
          'Attachment size exceeds maximum allowed size of 25 MB.',
        );
      }

      normalizedMime = (attachmentMimeType ?? 'image/jpeg')
          .toLowerCase()
          .trim();
      final vaultDir = await getVaultDirectory();
      final stagingFile = File(p.join(vaultDir.path, '$docId.tmp'));
      final finalEncryptedFile = File(p.join(vaultDir.path, '$docId.enc'));

      try {
        final masterKey = await _keyService.getOrCreateMasterKey();

        final encryptedBytes = await _encryptionService.encryptBytes(
          attachmentBytes,
          keyBytes: masterKey,
        );

        await stagingFile.writeAsBytes(encryptedBytes, flush: true);
        if (!await stagingFile.exists() ||
            await stagingFile.length() != encryptedBytes.length) {
          throw VaultStorageException(
            'Failed to verify staged attachment ciphertext write.',
          );
        }

        await stagingFile.rename(finalEncryptedFile.path);
        encryptedFilePath = finalEncryptedFile.path;
        fileSize = attachmentBytes.length;
        finalAttachmentType =
            attachmentType ??
            (normalizedMime.contains('pdf') ? 'pdf' : 'image');
      } catch (e) {
        if (await stagingFile.exists())
          await stagingFile.delete().catchError((_) => stagingFile);
        if (await finalEncryptedFile.exists())
          await finalEncryptedFile.delete().catchError(
            (_) => finalEncryptedFile,
          );
        rethrow;
      }
    }

    final docModel = WalletDocumentModel(
      id: docId,
      documentName: documentName.trim(),
      category: category.toLowerCase().trim(),
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      encryptedFilePath: encryptedFilePath,
      thumbnailPath: null,
      mimeType: normalizedMime,
      fileSize: fileSize,
      issueDate: issueDate,
      expiryDate: expiryDate,
      isFavorite: isFavorite,
      maskedIdentifier: maskedIdentifier?.trim(),
      holderName: holderName?.trim(),
      encryptedFields: encryptedFieldsCiphertext,
      attachmentType: finalAttachmentType,
      createdAt: now,
      updatedAt: now,
    );

    await _documentRepository.insert(docModel);
    return docModel;
  }

  /// Legacy import method preserved for backwards compatibility.
  Future<WalletDocumentModel> importDocument({
    required String documentName,
    required String category,
    required String mimeType,
    required List<int> fileBytes,
    String? description,
    DateTime? issueDate,
    DateTime? expiryDate,
    bool isFavorite = false,
  }) async {
    final normalizedMime = mimeType.toLowerCase().trim();
    if (!supportedMimeTypes.contains(normalizedMime)) {
      throw VaultValidationException(
        'Unsupported document MIME type: "$normalizedMime". Supported formats: PDF, JPEG, PNG, WEBP.',
      );
    }

    if (fileBytes.isEmpty) {
      throw VaultValidationException('Cannot import empty document.');
    }

    if (fileBytes.length > maxFileSizeBytes) {
      throw VaultValidationException(
        'Document size exceeds maximum allowed size of 25 MB.',
      );
    }

    return await saveManualDocument(
      documentName: documentName,
      category: category,
      description: description,
      issueDate: issueDate,
      expiryDate: expiryDate,
      isFavorite: isFavorite,
      attachmentBytes: fileBytes,
      attachmentMimeType: normalizedMime,
      attachmentType: normalizedMime.contains('pdf') ? 'pdf' : 'image',
    );
  }

  /// Replaces or attaches a new file to an existing document.
  Future<WalletDocumentModel> attachFileToDocument({
    required WalletDocumentModel document,
    required List<int> fileBytes,
    required String mimeType,
    String? attachmentType,
  }) async {
    if (fileBytes.isEmpty) {
      throw VaultValidationException('Attachment bytes cannot be empty.');
    }
    if (fileBytes.length > maxFileSizeBytes) {
      throw VaultValidationException('Attachment size exceeds 25 MB.');
    }

    final vaultDir = await getVaultDirectory();
    final stagingFile = File(p.join(vaultDir.path, '${document.id}_new.tmp'));
    final finalEncryptedFile = File(
      p.join(vaultDir.path, '${document.id}.enc'),
    );

    final masterKey = await _keyService.getOrCreateMasterKey();

    final encryptedBytes = await _encryptionService.encryptBytes(
      fileBytes,
      keyBytes: masterKey,
    );

    await stagingFile.writeAsBytes(encryptedBytes, flush: true);
    await stagingFile.rename(finalEncryptedFile.path);

    final normalizedMime = mimeType.toLowerCase().trim();
    final updated = document.copyWith(
      encryptedFilePath: finalEncryptedFile.path,
      mimeType: normalizedMime,
      fileSize: fileBytes.length,
      attachmentType:
          attachmentType ?? (normalizedMime.contains('pdf') ? 'pdf' : 'image'),
      updatedAt: DateTime.now(),
    );

    await _documentRepository.update(updated);
    return updated;
  }

  /// Removes the attachment from an existing document while preserving all metadata.
  Future<WalletDocumentModel> removeAttachmentFromDocument(
    WalletDocumentModel document,
  ) async {
    if (document.hasAttachment) {
      final file = File(document.encryptedFilePath);
      if (await file.exists()) {
        await file.delete().catchError((_) => file);
      }
    }

    final updated = document.copyWith(
      encryptedFilePath: '',
      mimeType: 'none',
      fileSize: 0,
      attachmentType: 'none',
      updatedAt: DateTime.now(),
    );

    await _documentRepository.update(updated);
    return updated;
  }

  /// Updates existing document metadata.
  Future<WalletDocumentModel> updateDocumentDetails({
    required WalletDocumentModel document,
    required String documentName,
    required String category,
    String? holderName,
    String? maskedIdentifier,
    String? unmaskedIdentifier,
    Map<String, dynamic>? extraFields,
    String? description,
    DateTime? issueDate,
    DateTime? expiryDate,
  }) async {
    String? encryptedFieldsCiphertext = document.encryptedFields;
    if (extraFields != null) {
      encryptedFieldsCiphertext = await encryptMetadataFields(extraFields);
    }

    if (unmaskedIdentifier != null && unmaskedIdentifier.trim().isNotEmpty) {
      await _secureNumberService.saveDocumentFullNumber(
        document.id,
        unmaskedIdentifier.trim(),
      );
    }

    final updated = document.copyWith(
      documentName: documentName.trim(),
      category: category.toLowerCase().trim(),
      holderName: holderName?.trim(),
      maskedIdentifier: maskedIdentifier?.trim(),
      encryptedFields: encryptedFieldsCiphertext,
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      issueDate: issueDate,
      expiryDate: expiryDate,
      updatedAt: DateTime.now(),
    );

    await _documentRepository.update(updated);
    return updated;
  }

  /// Decrypts and returns the raw plaintext bytes of [document].
  Future<Uint8List> decryptDocumentBytes(WalletDocumentModel document) async {
    if (!document.hasAttachment) {
      return Uint8List(0);
    }

    final masterKey = await _keyService.getMasterKey();
    if (masterKey == null) {
      throw MasterKeyLostException();
    }

    final file = File(document.encryptedFilePath);
    if (!await file.exists()) {
      throw VaultStorageException(
        'Encrypted file not found on disk at: ${document.encryptedFilePath}',
      );
    }

    final encryptedBytes = await file.readAsBytes();
    return await _encryptionService.decryptBytes(
      encryptedBytes,
      keyBytes: masterKey,
    );
  }

  /// Stages a temporary decrypted copy for PDF previewing or external opening.
  Future<File> stageDecryptedPreviewFile(WalletDocumentModel document) async {
    if (!document.hasAttachment) {
      throw VaultValidationException('Document has no attachment to preview.');
    }

    final decryptedBytes = await decryptDocumentBytes(document);
    final tempDir = await getTempDirectory();

    final ext = document.mimeType.contains('pdf')
        ? '.pdf'
        : (document.mimeType.contains('png') ? '.png' : '.jpg');

    final previewFile = File(
      p.join(tempDir.path, '${document.id}_preview$ext'),
    );
    await previewFile.writeAsBytes(decryptedBytes, flush: true);
    return previewFile;
  }

  /// Removes an individual preview file.
  Future<void> cleanupPreviewFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Cleans up all files in the temporary preview cache.
  Future<void> cleanupAllTemporaryFiles() async {
    try {
      final tempDir = await getTempDirectory();
      if (await tempDir.exists()) {
        final entities = await tempDir.list().toList();
        for (final entity in entities) {
          if (entity is File) {
            await entity.delete().catchError((_) => entity);
          }
        }
      }
    } catch (_) {}
  }

  /// Deletes a document from SQLite database, private encrypted storage, and secure keystore.
  Future<void> deleteDocument(String documentId) async {
    final doc = await _documentRepository.getDocumentById(documentId);
    if (doc != null && doc.hasAttachment) {
      final file = File(doc.encryptedFilePath);
      if (await file.exists()) {
        await file.delete().catchError((_) => file);
      }
    }
    await _secureNumberService.deleteDocumentFullNumber(documentId);
    await _documentRepository.delete(documentId);
  }

  /// Completely resets the vault by deleting orphaned files, clearing documents,
  /// and generating a fresh master key in secure hardware storage.
  Future<void> resetVault() async {
    try {
      final dir = await getVaultDirectory();
      if (await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is File &&
              (entity.path.endsWith('.enc') || entity.path.endsWith('.tmp'))) {
            await entity.delete().catchError((_) => entity);
          }
        }
      }
    } catch (_) {}

    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('wallet_documents');
    } catch (_) {}

    await _keyService.resetAndRegenerateMasterKey();
  }
}
