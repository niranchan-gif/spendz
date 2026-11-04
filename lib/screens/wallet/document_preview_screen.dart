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
import '../../models/wallet_document_model.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/design_system/reusable_card.dart';
import '../../widgets/design_system/primary_button.dart';
import '../../widgets/design_system/secure_protected_field.dart';

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

  bool _isAuthenticating = false;
  bool _isDecrypting = false;
  String? _errorMessage;
  Uint8List? _decryptedImageBytes;
  File? _stagedPdfFile;
  String? _secureDocumentNumber;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateAndDecrypt();
      _loadSecureDocNumber();
    });
  }

  Future<void> _loadSecureDocNumber() async {
    final num = await _secureNumberService.getDocumentFullNumber(widget.document.id);
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
      localizedReason: 'Authenticate to view "${widget.document.documentName}"',
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
      if (widget.document.mimeType.contains('pdf')) {
        final file = await _vaultService.stageDecryptedPreviewFile(widget.document);
        if (!mounted) {
          await _vaultService.cleanupPreviewFile(file);
          return;
        }
        setState(() {
          _stagedPdfFile = file;
          _isDecrypting = false;
        });
      } else {
        final bytes = await _vaultService.decryptDocumentBytes(widget.document);
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

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final isPdf = doc.mimeType.contains('pdf');
    final surfaceColor = AppColors.getSurface(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: Text(
          doc.documentName,
          style: AppTextStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Re-authenticate & Reload',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: (_isAuthenticating || _isDecrypting) ? null : _authenticateAndDecrypt,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Security status header banner
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

              // If secure document number is stored, show protected field
              if (_secureDocumentNumber != null && _secureDocumentNumber!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                SecureProtectedField(
                  label: '${doc.category.toUpperCase()} NUMBER',
                  maskedValue: _secureDocumentNumber!.length > 4
                      ? '•••• •••• ${_secureDocumentNumber!.substring(_secureDocumentNumber!.length - 4)}'
                      : '••••••••',
                  onRetrieveProtectedValue: () => _secureNumberService.getDocumentFullNumber(doc.id),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Content Area
              Expanded(
                child: _buildPreviewBody(),
              ),

              const SizedBox(height: AppSpacing.md),

              // Metadata footer
              ReusableCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetaItem('CATEGORY', doc.category.replaceAll('_', ' ').toUpperCase()),
                    _buildMetaItem('SIZE', '${(doc.fileSize / 1024).toStringAsFixed(0)} KB'),
                    _buildMetaItem(
                      'EXPIRY',
                      doc.expiryDate != null ? DateFormatter.formatShortDate(doc.expiryDate!) : 'No Expiry',
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            const Icon(Icons.fingerprint_rounded, size: 64, color: AppColors.primary),
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
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Verifying AES-256-GCM auth tag',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.getTextSecondary(context),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock_rounded, size: 56, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Access Restricted',
                style: AppTextStyles.headingSmall.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Unlock & Decrypt',
                icon: Icons.lock_open_rounded,
                onPressed: _authenticateAndDecrypt,
              ),
            ],
          ),
        ),
      );
    }

    // Success State - Image Preview
    if (_decryptedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          color: Colors.black.withAlpha(20),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: Image.memory(
                _decryptedImageBytes!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    'Corrupted image payload',
                    style: TextStyle(color: AppColors.getTextSecondary(context)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Success State - PDF Preview
    if (_stagedPdfFile != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.getBorder(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf_rounded, size: 72, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.document.documentName,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.getTextPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Decrypted PDF ready in secure staging sandbox.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.getTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: _openPdfWithExternalApp,
                icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
                label: const Text(
                  'Open in PDF Viewer',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Decrypted preview file will be wiped immediately upon leaving this screen.',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: AppColors.getTextSecondary(context).withAlpha(140),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
