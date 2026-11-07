import 'package:flutter/material.dart';
import '../models/wallet_document_model.dart';
import '../database/wallet_document_repository.dart';
import '../features/wallet/services/drive_document_service.dart';
import '../features/wallet/services/document_vault_service.dart';

class WalletDocumentProvider with ChangeNotifier {
  final WalletDocumentRepository _repository = WalletDocumentRepository();

  List<WalletDocumentModel> _documents = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'all';

  List<WalletDocumentModel> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;

  List<WalletDocumentModel> get favoriteDocuments =>
      _documents.where((d) => d.isFavorite).toList();

  List<WalletDocumentModel> get expiringDocuments =>
      _documents.where((d) => d.isExpiringSoon || d.isExpired).toList();

  WalletDocumentProvider() {
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await DriveDocumentService.instance.restoreSession();
      if (DriveDocumentService.instance.isSignedIn) {
        // One-time migration: upload old encrypted local attachments, then
        // delete their local ciphertext only after Drive confirms the upload.
        try {
          await DocumentVaultService().migrateLegacyAttachments();
        } catch (_) {
          // Keep legacy files intact if migration cannot be completed.
        }
        final remoteFiles = await DriveDocumentService.instance.listDocuments();
        for (final remote in remoteFiles) {
          final properties = remote.appProperties;
          final documentId = properties['spendzDocumentId'];
          if (documentId == null || documentId.isEmpty) continue;

          final existing = await _repository.getDocumentById(documentId);
          final nameParts = remote.fileName.split('.');
          final displayName = nameParts.length > 1
              ? nameParts.sublist(0, nameParts.length - 1).join('.')
              : remote.fileName;
          final attachmentType = properties['spendzAttachmentType'] ??
              (remote.mimeType.toLowerCase().contains('pdf') ? 'pdf' : 'image');

          final remoteModel = existing != null
              ? existing.copyWith(
                  driveFileId: remote.fileId,
                  encryptedFilePath: '',
                  mimeType: remote.mimeType,
                  fileSize: remote.size,
                  attachmentType: attachmentType,
                )
              : WalletDocumentModel(
                  id: documentId,
                  documentName: displayName,
                  category: properties['spendzCategory'] ?? 'other',
                  driveFileId: remote.fileId,
                  mimeType: remote.mimeType,
                  fileSize: remote.size,
                  attachmentType: attachmentType,
                  issueDate: DateTime.tryParse(properties['spendzIssueDate'] ?? ''),
                  expiryDate: DateTime.tryParse(properties['spendzExpiryDate'] ?? ''),
                  createdAt: DateTime.tryParse(properties['spendzCreatedAt'] ?? '') ??
                      DateTime.now(),
                  updatedAt: DateTime.now(),
                );
          await _repository.upsert(remoteModel);
        }
      }

      _documents = _selectedCategory == 'all'
          ? await _repository.getAllDocuments()
          : await _repository.getDocumentsByCategory(_selectedCategory);
    } catch (e) {
      _error = 'Google Drive sync unavailable: $e';
      try {
        _documents = _selectedCategory == 'all'
            ? await _repository.getAllDocuments()
            : await _repository.getDocumentsByCategory(_selectedCategory);
      } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCategoryFilter(String category) async {
    _selectedCategory = category;
    await loadDocuments();
  }

  Future<void> addDocument(WalletDocumentModel document) async {
    try {
      await _repository.insert(document);
      await loadDocuments();
    } catch (e) {
      _error = 'Failed to add document: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateDocument(WalletDocumentModel document) async {
    try {
      await _repository.update(document);
      await loadDocuments();
    } catch (e) {
      _error = 'Failed to update document: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      await _repository.delete(id);
      await loadDocuments();
    } catch (e) {
      _error = 'Failed to delete document: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleDocumentFavorite(String id) async {
    try {
      final doc = _documents.firstWhere((d) => d.id == id);
      final newFav = !doc.isFavorite;
      await _repository.toggleFavorite(id, newFav);
      await loadDocuments();
    } catch (e) {
      _error = 'Failed to toggle favorite: $e';
      notifyListeners();
    }
  }

  Future<List<WalletDocumentModel>> searchDocuments(String query) async {
    if (query.trim().isEmpty) return _documents;
    try {
      return await _repository.searchDocuments(query);
    } catch (e) {
      _error = 'Search failed: $e';
      notifyListeners();
      return [];
    }
  }

  Future<List<WalletDocumentModel>> fetchExpiringDocuments({
    int days = 30,
  }) async {
    try {
      return await _repository.getExpiringDocuments(daysThreshold: days);
    } catch (e) {
      _error = 'Failed to fetch expiring documents: $e';
      return [];
    }
  }

  WalletDocumentModel? getDocumentById(String id) {
    try {
      return _documents.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
), '');
          final remoteModel = existing?.copyWith(
                driveFileId: remote.fileId,
                encryptedFilePath: '',
                mimeType: remote.mimeType,
                fileSize: remote.size,
                attachmentType: properties['spendzAttachmentType'] ??
                    (remote.mimeType.contains('pdf') ? 'pdf' : 'image'),
              ) ??
              WalletDocumentModel(
                id: documentId,
                documentName: name,
                category: properties['spendzCategory'] ?? 'other',
                driveFileId: remote.fileId,
                mimeType: remote.mimeType,
                fileSize: remote.size,
                attachmentType: properties['spendzAttachmentType'] ??
                    (remote.mimeType.contains('pdf') ? 'pdf' : 'image'),
                issueDate: DateTime.tryParse(properties['spendzIssueDate'] ?? ''),
                expiryDate: DateTime.tryParse(properties['spendzExpiryDate'] ?? ''),
                createdAt: DateTime.tryParse(properties['spendzCreatedAt'] ?? '') ??
                    DateTime.now(),
                updatedAt: DateTime.now(),
              );
          await _repository.upsert(remoteModel);
        }
      }

      if (_selectedCategory == 'all') {
        _documents = await _repository.getAllDocuments();
      } else {
        _documents = await _repository.getDocumentsByCategory(
          _selectedCategory,
        );
      }
    } catch (e) {
      // Preserve access to metadata already cached locally if Drive is offline.
      _error = 'Google Drive sync unavailable: $e';
      try {
        _documents = _selectedCategory == 'all'
            ? await _repository.getAllDocuments()
            : await _repository.getDocumentsByCategory(_selectedCategory);
      } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCategoryFilter(String category) async {
    _selectedCategory = category;
    await loadDocuments();
  }

  Future<void> addDocument(WalletDocumentModel document) async {
    try {
      await _repository.insert(document);
      await loadDocuments();
    } catch (e) {
      _error = 'Failed to add document: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateDocument(WalletDocumentModel document) async {
    try {
      await _repository.update(document);
      await loadDocuments();
    } catch (e) {
      _error = 'Failed to update document: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      await _repository.delete(id);
      await loadDocuments();
    } catch (e) {
      _error = 'Failed to delete document: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleDocumentFavorite(String id) async {
    try {
      final doc = _documents.firstWhere((d) => d.id == id);
      final newFav = !doc.isFavorite;
      await _repository.toggleFavorite(id, newFav);
      await loadDocuments();
    } catch (e) {
      _error = 'Failed to toggle favorite: $e';
      notifyListeners();
    }
  }

  Future<List<WalletDocumentModel>> searchDocuments(String query) async {
    if (query.trim().isEmpty) return _documents;
    try {
      return await _repository.searchDocuments(query);
    } catch (e) {
      _error = 'Search failed: $e';
      notifyListeners();
      return [];
    }
  }

  Future<List<WalletDocumentModel>> fetchExpiringDocuments({
    int days = 30,
  }) async {
    try {
      return await _repository.getExpiringDocuments(daysThreshold: days);
    } catch (e) {
      _error = 'Failed to fetch expiring documents: $e';
      return [];
    }
  }

  WalletDocumentModel? getDocumentById(String id) {
    try {
      return _documents.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
