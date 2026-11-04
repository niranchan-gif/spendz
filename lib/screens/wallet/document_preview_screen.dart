import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_text_styles.dart';
import '../../database/wallet_document_repository.dart';
import '../../features/wallet/security/document_encryption_service.dart';
import '../../features/wallet/security/wallet_auth_service.dart';
import '../../features/wallet/security/secure_number_service.dart';
import '../../features/wallet/services/document_vault_service.dart';
import '../../features/wallet/services/document_export_service.dart';
import '../../features/wallet/services/document_scanner_service.dart';
import '../../models/wallet_document_model.dart';
import '../../providers/wallet_document_provider.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/design_system/reusable_card.dart';
import '../../widgets/design_system/secure_protected_field.dart';
import '../../widgets/design_system/custom_dialog.dart';
import 'document_attachment_scanner_screen.dart';
import 'document_creation_screen.dart';
import 'widgets/virtual_document_card.dart';

class DocumentPreviewScreen extends StatefulWidget {
  final WalletDocumentModel document;

  const DocumentPreviewScreen({super.key, required this.document});

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  final DocumentVaultService _vaultService = DocumentVaultService();
  final SecureNumberService _secureNumberService = SecureNumberService();
  final DocumentExportService _exportService = DocumentExportService();

  late WalletDocumentModel _currentDocument;
  bool _isAuthenticating = false;
  bool _isDecrypting = false;
  bool _isExporting = false;
  String? _errorMessage;
  Uint8List? _decryptedImageBytes;
  File? _stagedPdfFile;
  String? _secureDocumentNumber;

  @override
  void initState() {
    super.initState();
    _currentDocument = widget.document;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSecureDocNumber();
      if (_currentDocument.hasAttachment) {
        _authenticateAndDecrypt();
      }
    });
  }

  Future<void> _loadSecureDocNumber() async {
    final num = await _secureNumberService.getDocumentFullNumber(
      _currentDocument.id,
    );
    if (mounted && num != null) {
      setState(() => _secureDocumentNumber = num);
    }
  }

  @override
  void dispose() {
    if (_stagedPdfFile != null) {
      _vaultService.cleanupPreviewFile(_stagedPdfFile!);
    }
    super.dispose();
  }

  Future<void> _authenticateAndDecrypt() async {
    if (!_currentDocument.hasAttachment) {
      setState(() {
        _isAuthenticating = false;
        _isDecrypting = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final authService = context.read<WalletAuthService>();
    final authenticated = await authService.authenticate(
      localizedReason:
          'Authenticate to view "${_currentDocument.documentName}"',
    );

    if (!mounted) return;

    if (!authenticated) {
      setState(() {
        _isAuthenticating = false;
        _errorMessage =
            authService.lastErrorMessage ??
            'Authentication required to preview this document.';
      });
      return;
    }

    setState(() {
      _isAuthenticating = false;
      _isDecrypting = true;
    });

    try {
      if (_currentDocument.mimeType.contains('pdf')) {
        final file = await _vaultService.stageDecryptedPreviewFile(
          _currentDocument,
        );
        if (!mounted) {
          await _vaultService.cleanupPreviewFile(file);
          return;
        }
        setState(() {
          _stagedPdfFile = file;
          _isDecrypting = false;
        });
      } else {
        final bytes = await _vaultService.decryptDocumentBytes(
          _currentDocument,
        );
        if (!mounted) return;
        setState(() {
          _decryptedImageBytes = bytes;
          _isDecrypting = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDecrypting = false;
        if (e is DecryptionAuthenticationException) {
          _errorMessage =
              'Decryption failed: Document integrity check failed or master key mismatch.';
        } else if (e is VaultSecurityException) {
          _errorMessage = e.message;
        } else {
          _errorMessage = 'Failed to load document: $e';
        }
      });
    }
  }

  Future<void> _openDocument() async {
    if (_currentDocument.hasAttachment) {
      if (_decryptedImageBytes == null && _stagedPdfFile == null) {
        await _authenticateAndDecrypt();
        if (!mounted) return;
      }

      if (_stagedPdfFile != null) {
        try {
          final result = await OpenFilex.open(_stagedPdfFile!.path);
          if (result.type != ResultType.done && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not open PDF viewer: ${result.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening PDF: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
        return;
      }

      if (_decryptedImageBytes != null) {
        // Open full-screen zoomable preview modal
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        _decryptedImageBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        return;
      }
    }

    // Document without physical attachment: generate official Virtual Card PDF & open
    setState(() => _isExporting = true);
    try {
      final pdfFile = await _exportService.generateDocumentPdf(
        document: _currentDocument,
        decryptedBytes: Uint8List(0),
        secureDocNumber: _secureDocumentNumber,
      );
      if (mounted) {
        setState(() => _isExporting = false);
        await OpenFilex.open(pdfFile.path);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open document: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _shareDocument() async {
    // Warn user before sharing sensitive document copy
    final proceed = await CustomDialog.showConfirmation(
      context: context,
      title: 'Share Document?',
      message:
          'You are about to share a copy of "${_currentDocument.documentName}". Anyone you send this to will be able to view its contents.',
      confirmLabel: 'Proceed & Share',
      cancelLabel: 'Cancel',
      icon: Icons.share_rounded,
    );

    if (proceed != true || !mounted) return;

    // Strict biometric authentication required to share any document
    final authService = context.read<WalletAuthService>();
    final authenticated = await authService.authenticate(
      localizedReason:
          'Authenticate with biometrics to share "${_currentDocument.documentName}"',
    );

    if (!mounted) return;

    if (!authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authService.lastErrorMessage ??
                'Biometric authentication is required to share documents.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      Uint8List bytes = Uint8List(0);
      if (_currentDocument.hasAttachment) {
        if (_decryptedImageBytes == null && _stagedPdfFile == null) {
          await _authenticateAndDecrypt();
          if (!mounted) {
            setState(() => _isExporting = false);
            return;
          }
        }
        if (_stagedPdfFile != null) {
          bytes = await _stagedPdfFile!.readAsBytes();
        } else if (_decryptedImageBytes != null) {
          bytes = _decryptedImageBytes!;
        }
      }

      await _exportService.shareDocument(
        document: _currentDocument,
        decryptedBytes: bytes,
        secureDocNumber: _secureDocumentNumber,
      );
      if (mounted) setState(() => _isExporting = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openEditScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DocumentCreationScreen(documentToEdit: _currentDocument),
      ),
    );

    final updated = await WalletDocumentRepository().getDocumentById(
      _currentDocument.id,
    );
    if (updated != null && mounted) {
      setState(() => _currentDocument = updated);
      _loadSecureDocNumber();
      if (_currentDocument.hasAttachment) {
        _authenticateAndDecrypt();
      }
    }
  }

  Future<void> _attachOrReplaceCopy() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.document_scanner_rounded,
                color: AppColors.primary,
              ),
              title: const Text(
                'Scan Document (Multi-Page)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Capture front & back with boundary detection & PDF generation',
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final payload =
                    await Navigator.push<DocumentAttachmentPayload?>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocumentAttachmentScannerScreen(
                          category: _currentDocument.category,
                          suggestedTitle: _currentDocument.documentName,
                        ),
                      ),
                    );
                if (payload != null) _processNewAttachment(payload);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.folder_open_rounded,
                color: AppColors.primary,
              ),
              title: const Text(
                'Attach Existing PDF from Phone',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Select a pre-existing PDF from device storage',
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final payload = await DocumentScannerService()
                    .pickExistingDocument();
                if (payload != null) _processNewAttachment(payload);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processNewAttachment(DocumentAttachmentPayload payload) async {
    final bytes = payload.primaryBytes;
    if (bytes.isNotEmpty) {
      final updated = await _vaultService.attachFileToDocument(
        document: _currentDocument,
        fileBytes: bytes,
        mimeType: payload.mimeType,
        attachmentType: payload.attachmentType,
      );
      setState(() => _currentDocument = updated);
      if (mounted) {
        await context.read<WalletDocumentProvider>().loadDocuments();
        if (!mounted) return;
        _authenticateAndDecrypt();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attachment updated: ${payload.fileName}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _removeAttachment() async {
    final confirmed = await CustomDialog.showConfirmation(
      context: context,
      title: 'Remove Attachment Copy?',
      message:
          'This will delete the attached file copy from vault storage while preserving all your entered card/document details.',
      confirmLabel: 'Remove Attachment',
      cancelLabel: 'Cancel',
      isDestructive: true,
      icon: Icons.attachment_outlined,
    );

    if (confirmed == true && mounted) {
      final updated = await _vaultService.removeAttachmentFromDocument(
        _currentDocument,
      );
      setState(() {
        _currentDocument = updated;
        _decryptedImageBytes = null;
        _stagedPdfFile = null;
      });
      if (!mounted) return;
      await context.read<WalletDocumentProvider>().loadDocuments();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Attachment copy removed')));
    }
  }

  Future<void> _deleteDocument() async {
    final confirmed = await CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Document?',
      message:
          'This will permanently delete "${_currentDocument.documentName}" and securely wipe its encrypted data from disk.',
      confirmLabel: 'Delete Permanently',
      cancelLabel: 'Cancel',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true && mounted) {
      await _vaultService.deleteDocument(_currentDocument.id);
      if (!mounted) return;
      await context.read<WalletDocumentProvider>().loadDocuments();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Document deleted')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = _currentDocument;
    final isPdf = doc.mimeType.contains('pdf');
    final surfaceColor = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: Text(
          doc.documentName,
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: doc.isFavorite ? 'Remove Favorite' : 'Add Favorite',
            icon: Icon(
              doc.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: doc.isFavorite ? Colors.amber : textSecondary,
            ),
            onPressed: () async {
              await context
                  .read<WalletDocumentProvider>()
                  .toggleDocumentFavorite(doc.id);
              setState(() {
                _currentDocument = doc.copyWith(isFavorite: !doc.isFavorite);
              });
            },
          ),
          IconButton(
            tooltip: 'Delete Document',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            onPressed: _deleteDocument,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Virtual Document Card Presentation
              VirtualDocumentCard(document: doc, showShadow: true),

              // 2. Hardware Keystore Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'AES-256-GCM Hardware-Protected Vault',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        doc.hasAttachment
                            ? (isPdf ? 'PDF' : 'IMAGE')
                            : 'MANUAL',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Biometric Protected Number Field (Biometric authentication required to reveal)
              if (doc.maskedIdentifier != null ||
                  _secureDocumentNumber != null) ...[
                const SizedBox(height: AppSpacing.sm),
                SecureProtectedField(
                  label:
                      '${doc.category.toUpperCase().replaceAll("_", " ")} NUMBER',
                  maskedValue:
                      doc.maskedIdentifier ??
                      (_secureDocumentNumber != null &&
                              _secureDocumentNumber!.length > 4
                          ? '•••• •••• ${_secureDocumentNumber!.substring(_secureDocumentNumber!.length - 4)}'
                          : '••••••••'),
                  showCopyButton: true,
                  onRetrieveProtectedValue: () async {
                    final num = await _secureNumberService
                        .getDocumentFullNumber(doc.id);
                    if (num != null && num.isNotEmpty) {
                      return num;
                    }
                    return doc.maskedIdentifier;
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              // 4. Primary Actions Row (Unified, Non-Repeating)
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.visibility_rounded,
                      label: 'Open',
                      onTap: !_isExporting ? _openDocument : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.share_rounded,
                      label: 'Share',
                      onTap: !_isExporting ? _shareDocument : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.edit_note_rounded,
                      label: 'Edit',
                      onTap: _openEditScreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 5. Original Scan / Physical Copy Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Original Copy',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (doc.hasAttachment)
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _attachOrReplaceCopy,
                          icon: const Icon(Icons.refresh_rounded, size: 14),
                          label: const Text(
                            'Replace',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _removeAttachment,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            'Remove',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              if (doc.hasAttachment) ...[
                // Details badge: Filename, Page count, File size, Date added
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              (doc.isPdf ? Colors.redAccent : AppColors.primary)
                                  .withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          doc.isPdf
                              ? Icons.picture_as_pdf_rounded
                              : Icons.photo_rounded,
                          color: doc.isPdf
                              ? Colors.redAccent
                              : AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DocumentScannerService.getDefaultPdfFileName(
                                doc.category,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${doc.isPdf ? 'PDF Document' : 'Image'} • ${DocumentScannerService.formatFileSize(doc.fileSize)} • Added ${DateFormatter.formatShortDate(doc.createdAt)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Interactive preview container (tap to open full viewer)
                InkWell(
                  onTap: _openDocument,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Container(
                    height: (_decryptedImageBytes != null) ? 320 : 220,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: _buildPreviewBody(),
                  ),
                ),
              ] else ...[
                // No attachment: Add Original Copy Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.attachment_outlined,
                        size: 48,
                        color: AppColors.getTextSecondary(
                          context,
                        ).withAlpha(120),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Add Original Copy',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Attach a multi-page camera scan or an existing PDF from your phone.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _attachOrReplaceCopy,
                            icon: const Icon(
                              Icons.document_scanner_rounded,
                              size: 16,
                            ),
                            label: const Text('Scan Document'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final payload = await DocumentScannerService()
                                  .pickExistingDocument();
                              if (payload != null) {
                                _processNewAttachment(payload);
                              }
                            },
                            icon: const Icon(
                              Icons.folder_open_rounded,
                              size: 16,
                            ),
                            label: const Text('Attach PDF'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              // 6. Extracted Notes & Document Information (Structured Labeled Fields)
              _buildDocumentInformation(doc, context),

              // 7. Metadata Footer Card
              ReusableCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetaItem(
                      'CATEGORY',
                      doc.category.replaceAll('_', ' ').toUpperCase(),
                    ),
                    _buildMetaItem(
                      'FILE SIZE',
                      doc.hasAttachment
                          ? '${(doc.fileSize / 1024).toStringAsFixed(0)} KB'
                          : 'None',
                    ),
                    _buildMetaItem(
                      'EXPIRY DATE',
                      doc.expiryDate != null
                          ? DateFormatter.formatShortDate(doc.expiryDate!)
                          : 'No Expiry',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final surfaceColor = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.getBorder(context)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isEnabled ? AppColors.primary : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isEnabled ? textPrimary : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentInformation(
    WalletDocumentModel doc,
    BuildContext context,
  ) {
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final emerald = AppColors.getEmeraldAccent(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Map<String, String> fields = {};
    String? additionalNotes;

    // 1. Core model dates
    if (doc.issueDate != null) {
      fields['Issue Date'] = DateFormatter.formatShortDate(doc.issueDate!);
    }
    if (doc.expiryDate != null) {
      fields['Expiry Date'] = DateFormatter.formatShortDate(doc.expiryDate!);
    }

    // 2. From structured description
    if (doc.description != null && doc.description!.trim().isNotEmpty) {
      final lines = doc.description!.split('\n');
      for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isEmpty) continue;
        final colonIdx = line.indexOf(':');
        if (colonIdx > 0 && colonIdx < line.length - 1) {
          final key = line.substring(0, colonIdx).trim();
          final val = line.substring(colonIdx + 1).trim();
          if (val.isNotEmpty) {
            if (key.toLowerCase() == 'notes') {
              additionalNotes = (additionalNotes != null
                  ? '$additionalNotes\n$val'
                  : val);
            } else {
              fields[_formatFieldLabel(key)] = val;
            }
          }
        } else {
          additionalNotes = (additionalNotes != null
              ? '$additionalNotes\n$line'
              : line);
        }
      }
    }

    if (fields.isEmpty && additionalNotes == null) {
      return const SizedBox.shrink();
    }

    final fieldEntries = fields.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Document Information',
                style: AppTextStyles.headingSmall.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: emerald.withAlpha(20),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '${fieldEntries.length} Details',
                style: TextStyle(
                  color: emerald,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (fieldEntries.isNotEmpty)
          ReusableCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fieldEntries.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                thickness: 0.5,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
                color: isDark
                    ? Colors.white.withAlpha(15)
                    : AppColors.getBorder(context).withAlpha(120),
              ),
              itemBuilder: (context, index) {
                final entry = fieldEntries[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        entry.key.toUpperCase(),
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
                        child: Text(
                          entry.value,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (additionalNotes != null && additionalNotes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ReusableCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOTES',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  additionalNotes,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  String _formatFieldLabel(String key) {
    switch (key.toLowerCase()) {
      case 'dob':
        return 'Date of Birth';
      case 'father_name':
        return 'Father / Guardian';
      case 'address':
        return 'Address';
      case 'bank_name':
        return 'Bank';
      case 'card_network':
        return 'Network';
      case 'policy_type':
        return 'Policy Type';
      case 'policy_provider':
        return 'Provider';
      case 'vehicle_classes':
        return 'Vehicle Class';
      default:
        return key.replaceAll('_', ' ');
    }
  }

  Widget _buildPreviewBody() {
    if (!_currentDocument.hasAttachment) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.attachment_outlined,
                size: 48,
                color: AppColors.getTextSecondary(context).withAlpha(120),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No Physical Copy Attached',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This document was saved as a manual entry without an attached physical copy.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _attachOrReplaceCopy,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('Attach Scanned Copy or PDF'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isAuthenticating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fingerprint_rounded,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Waiting for authentication...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.getTextPrimary(context),
              ),
            ),
          ],
        ),
      );
    }

    if (_isDecrypting) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Decrypting vault document...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.getTextPrimary(context),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_clock_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Document Locked',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: _authenticateAndDecrypt,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Authenticate to Unlock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_stagedPdfFile != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.picture_as_pdf_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'PDF Document Staged Decrypted',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'PDF will be safely wiped from cache upon screen exit.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _openDocument,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open with PDF Viewer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_decryptedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Center(
            child: Image.memory(
              _decryptedImageBytes!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Text('Failed to render decrypted image.'),
              ),
            ),
          ),
        ),
      );
    }

    return const Center(child: Text('Document unavailable.'));
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppColors.getTextSecondary(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(context),
          ),
        ),
      ],
    );
  }
}
