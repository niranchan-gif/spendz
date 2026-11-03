import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/wallet/security/document_encryption_service.dart';
import '../../features/wallet/security/wallet_auth_service.dart';
import '../../features/wallet/services/document_vault_service.dart';
import '../../models/wallet_document_model.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/glass_container.dart';

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

  bool _isAuthenticating = false;
  bool _isDecrypting = false;
  String? _errorMessage;
  Uint8List? _decryptedImageBytes;
  File? _stagedPdfFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateAndDecrypt();
    });
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
        // Stage PDF preview file in private temporary directory
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
        // Ephemeral in-memory decryption for image formats (zero disk trace)
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
          SnackBar(content: Text('Could not open PDF viewer: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final isPdf = doc.mimeType.contains('pdf');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          doc.documentName,
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Re-authenticate & Reload',
            icon: const Icon(Icons.refresh),
            onPressed: (_isAuthenticating || _isDecrypting) ? null : _authenticateAndDecrypt,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Security status header banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AES-256-GCM Hardware-Protected Vault',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPdf ? 'PDF' : 'IMAGE',
                        style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Content Area
              Expanded(
                child: _buildPreviewBody(),
              ),

              const SizedBox(height: 12),

              // Metadata footer
              GlassContainer(
                padding: const EdgeInsets.all(12),
                borderRadius: 16,
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
            const Icon(Icons.fingerprint, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Waiting for authentication...', style: AppTextStyles.bodyMedium),
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
            const SizedBox(height: 16),
            Text('Decrypting vault document...', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text('Verifying AES-256-GCM auth tag', style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock, size: 56, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Access Restricted',
                style: AppTextStyles.heading3.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _authenticateAndDecrypt,
                icon: const Icon(Icons.lock_open),
                label: const Text('Unlock & Decrypt'),
              ),
            ],
          ),
        ),
      );
    }

    // Success State - Image Preview
    if (_decryptedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.black26,
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
        ),
      );
    }

    // Success State - PDF Preview
    if (_stagedPdfFile != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf, size: 72, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                widget.document.documentName,
                style: AppTextStyles.heading3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Decrypted PDF ready in secure staging sandbox.',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white60),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  backgroundColor: AppColors.primary,
                ),
                onPressed: _openPdfWithExternalApp,
                icon: const Icon(Icons.open_in_new, color: Colors.black),
                label: const Text(
                  'Open in PDF Viewer',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Decrypted preview file will be wiped immediately upon leaving this screen.',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: Colors.white38),
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
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
