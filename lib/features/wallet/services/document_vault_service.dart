import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../database/wallet_document_repository.dart';
import '../../../models/wallet_document_model.dart';
import '../security/document_encryption_service.dart';
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
/// - Atomic staging and write verification for imported documents.
/// - AES-256-GCM authenticated encryption before saving to disk.
/// - Automatic cleanup of failed or partial imports.
/// - Ephemeral, in-memory decryption for images.
/// - Scoped temporary caching for PDF previews with automatic cleanup.
/// - Deletion of both metadata and underlying ciphertext files.
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
  final String? _customVaultDirectory; // Optional override for isolated unit testing
  final String? _customTempDirectory; // Optional override for isolated unit testing

  DocumentVaultService({
    WalletDocumentRepository? documentRepository,
    DocumentEncryptionService? encryptionService,
    WalletKeyService? keyService,
    String? customVaultDirectory,
    String? customTempDirectory,
  })  : _documentRepository = documentRepository ?? WalletDocumentRepository(),
        _encryptionService = encryptionService ?? DocumentEncryptionService(),
        _keyService = keyService ?? WalletKeyService(),
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

  /// Imports a document: validates input, encrypts with AES-256-GCM, writes to private storage,
  /// verifies the write, and persists metadata in SQLite.
  ///
  /// Cleans up any staging or ciphertext files if an error occurs.
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
        'Document size (${(fileBytes.length / (1024 * 1024)).toStringAsFixed(1)} MB) exceeds maximum allowed size of 25 MB.',
      );
    }

    final docId = const Uuid().v4();
    final vaultDir = await getVaultDirectory();
    final stagingFile = File(p.join(vaultDir.path, '$docId.tmp'));
    final finalEncryptedFile = File(p.join(vaultDir.path, '$docId.enc'));

    try {
      // 1. Obtain master encryption key (safely checking if prior documents exist)
      final existingDocs = await _documentRepository.getAllDocuments();
      final masterKey = await _keyService.getOrCreateMasterKey(
        hasExistingVaultDocuments: () => existingDocs.isNotEmpty,
      );

      // 2. Encrypt bytes using AES-256-GCM
      final encryptedBytes = await _encryptionService.encryptBytes(
        fileBytes,
        keyBytes: masterKey,
      );

      // 3. Staging write
      await stagingFile.writeAsBytes(encryptedBytes, flush: true);

      // 4. Verify staging write
      if (!await stagingFile.exists() || await stagingFile.length() != encryptedBytes.length) {
        throw VaultStorageException('Failed to verify staged ciphertext write.');
      }

      // 5. Atomic rename to permanent encrypted file
      await stagingFile.rename(finalEncryptedFile.path);

      // 6. Verify final encrypted file
      if (!await finalEncryptedFile.exists() || await finalEncryptedFile.length() != encryptedBytes.length) {
        throw VaultStorageException('Failed to verify permanent encrypted file on disk.');
      }

      // 7. Store document metadata in SQLite
      final now = DateTime.now();
      final docModel = WalletDocumentModel(
        id: docId,
        documentName: documentName.trim(),
        category: category,
        description: description?.trim().isEmpty == true ? null : description?.trim(),
        encryptedFilePath: finalEncryptedFile.path,
        thumbnailPath: null, // No permanent plaintext thumbnails stored
        mimeType: normalizedMime,
        fileSize: fileBytes.length,
        issueDate: issueDate,
        expiryDate: expiryDate,
        isFavorite: isFavorite,
        createdAt: now,
        updatedAt: now,
      );

      await _documentRepository.insert(docModel);
      return docModel;
    } catch (e) {
      // Failure rollback: clean up partial files
      if (await stagingFile.exists()) {
        await stagingFile.delete().catchError((_) => stagingFile);
      }
      if (await finalEncryptedFile.exists()) {
        await finalEncryptedFile.delete().catchError((_) => finalEncryptedFile);
      }
      rethrow;
    }
  }

  /// Decrypts and returns the raw plaintext bytes of [document].
  ///
  /// For in-memory image rendering or processing.
  Future<Uint8List> decryptDocumentBytes(WalletDocumentModel document) async {
    final masterKey = await _keyService.getMasterKey();
    if (masterKey == null) {
      throw MasterKeyLostException();
    }

    final file = File(document.encryptedFilePath);
    if (!await file.exists()) {
      throw VaultStorageException('Encrypted file not found on disk at: ${document.encryptedFilePath}');
    }

    final encryptedBytes = await file.readAsBytes();
    return await _encryptionService.decryptBytes(
      encryptedBytes,
      keyBytes: masterKey,
    );
  }

  /// Stages a temporary decrypted copy for PDF previewing or external opening.
  ///
  /// The caller must ensure [cleanupPreviewFile] is called when viewing is finished.
  Future<File> stageDecryptedPreviewFile(WalletDocumentModel document) async {
    final decryptedBytes = await decryptDocumentBytes(document);
    final tempDir = await getTempDirectory();

    final ext = document.mimeType.contains('pdf')
        ? '.pdf'
        : (document.mimeType.contains('png') ? '.png' : '.jpg');

    final previewFile = File(p.join(tempDir.path, '${document.id}_preview$ext'));
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
  ///
  /// Should be called on application launch, preview exit, and app lifecycle transitions.
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

  /// Deletes a document from both SQLite database and private encrypted file storage.
  Future<void> deleteDocument(String documentId) async {
    final doc = await _documentRepository.getDocumentById(documentId);
    if (doc != null) {
      final file = File(doc.encryptedFilePath);
      if (await file.exists()) {
        await file.delete().catchError((_) => file);
      }
    }
    await _documentRepository.delete(documentId);
  }
}
