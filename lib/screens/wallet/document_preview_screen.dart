import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/wallet/security/document_encryption_service.dart';
import '../../features/wallet/security/wallet_auth_service.dart';
import '../../features/wallet/security/secure_number_service.dart';
import '../../features/wallet/services/document_vault_service.dart';
import '../../features/wallet/services/document_export_service.dart';
import '../../models/wallet_document_model.dart';
import '../../providers/wallet_document_provider.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/design_system/reusable_card.dart';
import '../../widgets/design_system/primary_button.dart';
import '../../widgets/design_system/secure_protected_field.dart';
import '../../widgets/design_system/custom_dialog.dart';
import '../../widgets/design_system/app_bottom_sheet.dart';
import '../../widgets/design_system/app_form_field.dart';
import 'widgets/virtual_document_card.dart';

class DocumentPreviewScreen extends StatefulWidget {
  final WalletDocumentModel document;

  const DocumentPreviewScreen({
    super.key,
    required this.document,
  });

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
      _authenticateAndDecrypt();
      _loadSecureDocNumber();
    });
  }

  Future<void> _loadSecureDocNumber() async {
    final num = await _secureNumberService.getDocumentFullNumber(_currentDocument.id);
    if (mounted && num != null) {
      setState(() => _secureDocumentNumber = num);
    }
  }

  @override
  void dispose() {
    // Immediate ephemeral cleanup: never leave decrypted preview files around
    if (_stagedPdfFile != null) {
      _vaultService.cleanupPreviewFile(_stagedPdfFile!);
    }
    super.dispose();
  }

  Future<void> _authenticateAndDecrypt() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final authService = context.read<WalletAuthService>();
    final authenticated = await authService.authenticate(
      localizedReason: 'Authenticate to view "${_currentDocument.documentName}"',
    );

    if (!mounted) return;

    if (!authenticated) {
      setState(() {
        _isAuthenticating = false;
        _errorMessage = authService.lastErrorMessage ?? 'Authentication required to preview this document.';
      });
      return;
    }

    setState(() {
      _isAuthenticating = false;
      _isDecrypting = true;
    });

    try {
      if (_currentDocument.mimeType.contains('pdf')) {
        final file = await _vaultService.stageDecryptedPreviewFile(_currentDocument);
        if (!mounted) {
          await _vaultService.cleanupPreviewFile(file);
          return;
        }
        setState(() {
          _stagedPdfFile = file;
          _isDecrypting = false;
        });
      } else {
        final bytes = await _vaultService.decryptDocumentBytes(_currentDocument);
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
          _errorMessage = 'Decryption failed: Document integrity check failed or master key mismatch.';
        } else if (e is VaultSecurityException) {
          _errorMessage = e.message;
        } else {
          _errorMessage = 'Failed to load document: $e';
        }
      });
    }
  }

  Future<void> _openPdfWithExternalApp() async {
    if (_stagedPdfFile == null) return;
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
  }

  Future<void> _downloadOriginal() async {
    if (_decryptedImageBytes == null && _stagedPdfFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please unlock document first')),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final bytes = _decryptedImageBytes ?? await _stagedPdfFile!.readAsBytes();
      final savedFile = await _exportService.downloadOriginalToDevice(
        document: _currentDocument,
        decryptedBytes: bytes,
      );

      if (mounted) {
        setState(() => _isExporting = false);
        if (savedFile != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to Downloads: ${savedFile.path.split(Platform.pathSeparator).last}'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save file'), backgroundColor: AppColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    if (_decryptedImageBytes == null && _stagedPdfFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please unlock document first')),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final bytes = _decryptedImageBytes ?? await _stagedPdfFile!.readAsBytes();
      final pdfFile = await _exportService.generateDocumentPdf(
        document: _currentDocument,
        decryptedBytes: bytes,
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
          SnackBar(content: Text('PDF Export error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _shareDocument() async {
    if (_decryptedImageBytes == null && _stagedPdfFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please unlock document first')),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final bytes = _decryptedImageBytes ?? await _stagedPdfFile!.readAsBytes();
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
          SnackBar(content: Text('Share error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showEditModal() {
    final titleController = TextEditingController(text: _currentDocument.documentName);
    final descController = TextEditingController(text: _currentDocument.description ?? '');
    DateTime? issueDate = _currentDocument.issueDate;
    DateTime? expiryDate = _currentDocument.expiryDate;

    AppBottomSheet.show(
      context: context,
      title: 'Edit Document Details',
      child: StatefulBuilder(
        builder: (ctx, setModalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppFormField(
                controller: titleController,
                label: 'Document Title',
                prefixIcon: Icons.title_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              AppFormField(
                controller: descController,
                label: 'Notes & Metadata',
                prefixIcon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(expiryDate != null ? DateFormatter.formatShortDate(expiryDate!) : 'Set Expiry'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2060),
                        );
                        if (picked != null) {
                          setModalState(() => expiryDate = picked);
                        }
                      },
                    ),
                  ),
                  if (expiryDate != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () => setModalState(() => expiryDate = null),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Save Changes',
                onPressed: () async {
                  final updated = _currentDocument.copyWith(
                    documentName: titleController.text.trim(),
                    description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                    issueDate: issueDate,
                    expiryDate: expiryDate,
                    updatedAt: DateTime.now(),
                  );
                  await context.read<WalletDocumentProvider>().updateDocument(updated);
                  setState(() => _currentDocument = updated);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteDocument() async {
    final confirmed = await CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Document?',
      message: 'This will permanently delete "${_currentDocument.documentName}" and securely wipe its encrypted data from disk.',
      confirmLabel: 'Delete Permanently',
      cancelLabel: 'Cancel',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true && mounted) {
      await context.read<WalletDocumentProvider>().deleteDocument(_currentDocument.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
        Navigator.of(context).pop();
      }
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
          style: AppTextStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: doc.isFavorite ? 'Remove Favorite' : 'Add Favorite',
            icon: Icon(
              doc.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: doc.isFavorite ? Colors.amber : textSecondary,
            ),
            onPressed: () async {
              await context.read<WalletDocumentProvider>().toggleDocumentFavorite(doc.id);
              setState(() {
                _currentDocument = doc.copyWith(isFavorite: !doc.isFavorite);
              });
            },
          ),
          IconButton(
            tooltip: 'Edit Details',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditModal,
          ),
          IconButton(
            tooltip: 'Delete Document',
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: _deleteDocument,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Virtual Document Card Presentation
              VirtualDocumentCard(
                document: doc,
                showShadow: true,
              ),

              // 2. Hardware Keystore Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.primary, size: 18),
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        isPdf ? 'PDF' : 'IMAGE',
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

              // 3. Biometric Protected Number Field
              if (_secureDocumentNumber != null && _secureDocumentNumber!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                SecureProtectedField(
                  label: '${doc.category.toUpperCase().replaceAll("_", " ")} NUMBER',
                  maskedValue: _secureDocumentNumber!.length > 4
                      ? '•••• •••• ${_secureDocumentNumber!.substring(_secureDocumentNumber!.length - 4)}'
                      : '••••••••',
                  onRetrieveProtectedValue: () => _secureNumberService.getDocumentFullNumber(doc.id),
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              // 4. Quick Actions Row (Download, PDF Export, Share)
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.download_rounded,
                      label: 'Download',
                      onTap: _isExporting ? null : _downloadOriginal,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.picture_as_pdf_rounded,
                      label: 'Export PDF',
                      onTap: _isExporting ? null : _exportPdf,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.share_rounded,
                      label: 'Share',
                      onTap: _isExporting ? null : _shareDocument,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 5. Original Scan Preview Section
              Text(
                'Original Scanned Document',
                style: AppTextStyles.headingSmall.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),

              Container(
                height: 320,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: _buildPreviewBody(),
              ),
              const SizedBox(height: AppSpacing.md),

              // 6. Extracted Notes & Description
              if (doc.description != null && doc.description!.isNotEmpty) ...[
                Text(
                  'Extracted Document Details',
                  style: AppTextStyles.headingSmall.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                ReusableCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.description!,
                        style: AppTextStyles.bodyMedium.copyWith(color: textPrimary, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // 7. Metadata Footer Card
              ReusableCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetaItem('CATEGORY', doc.category.replaceAll('_', ' ').toUpperCase()),
                    _buildMetaItem('FILE SIZE', '${(doc.fileSize / 1024).toStringAsFixed(0)} KB'),
                    _buildMetaItem(
                      'EXPIRY DATE',
                      doc.expiryDate != null ? DateFormatter.formatShortDate(doc.expiryDate!) : 'No Expiry',
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
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewBody() {
    if (_isAuthenticating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fingerprint_rounded, size: 56, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Waiting for authentication...',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.getTextPrimary(context)),
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
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.getTextPrimary(context)),
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
              const Icon(Icons.lock_clock_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Document Locked',
                style: AppTextStyles.headingSmall.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.getTextSecondary(context)),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: _authenticateAndDecrypt,
                icon: const Icon(Icons.lock_open_rounded, size: 18),
                label: const Text('Unlock Document'),
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

    // Success - Decrypted Image
    if (_decryptedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.8,
          maxScale: 4.0,
          child: Center(
            child: Image.memory(
              _decryptedImageBytes!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Text('Corrupted image payload'),
              ),
            ),
          ),
        ),
      );
    }

    // Success - Decrypted PDF
    if (_stagedPdfFile != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_rounded, size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'PDF Staged in Secure Memory',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _openPdfWithExternalApp,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open in PDF Viewer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 10,
            color: AppColors.getTextSecondary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(context),
          ),
        ),
      ],
    );
  }
}
