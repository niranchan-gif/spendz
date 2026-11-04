import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/wallet/services/document_scanner_service.dart';
import '../../widgets/design_system/reusable_card.dart';
import 'document_review_screen.dart';

class DocumentScannerScreen extends StatefulWidget {
  final DocumentScannerService? scannerService;

  const DocumentScannerScreen({super.key, this.scannerService});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  late final DocumentScannerService _scannerService;
  bool _isProcessing = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _scannerService = widget.scannerService ?? DocumentScannerService();
    // Auto-launch the smart scanner on first open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSmartScanner();
    });
  }

  Future<void> _startSmartScanner() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Opening Smart Document Scanner...';
    });

    try {
      final batch = await _scannerService.startScanSession(
        pageLimit: 10,
        allowGalleryImport: true,
      );

      setState(() => _isProcessing = false);

      if (batch == null || batch.isEmpty) {
        return;
      }

      await _navigateToReview(batch);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Smart scanner was interrupted. You can use standard camera or gallery capture below.');
    }
  }

  Future<void> _captureFromCamera() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Opening Camera...';
    });

    try {
      final batch = await _scannerService.captureFromCamera();
      setState(() => _isProcessing = false);

      if (batch == null || batch.isEmpty) return;
      await _navigateToReview(batch);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Camera capture error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Selecting image from gallery...';
    });

    try {
      final batch = await _scannerService.pickFromGallery();
      setState(() => _isProcessing = false);

      if (batch == null || batch.isEmpty) return;
      await _navigateToReview(batch);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Gallery selection error: $e');
    }
  }

  Future<void> _pickDocumentFile() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Opening file browser...';
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );

      setState(() => _isProcessing = false);
      if (result.isEmpty) return;

      final pickedFile = result.first;
      final bytes = await pickedFile.readAsBytes();
      String? filePath = pickedFile.path;

      if (bytes.isEmpty) {
        _showError('Selected file is empty or inaccessible');
        return;
      }

      final ext = pickedFile.extension?.toLowerCase() ?? 'jpg';
      final isPdf = ext == 'pdf';
      final mimeType = isPdf ? 'application/pdf' : 'image/jpeg';

      filePath ??= await _scannerService.stageBytesToCache(bytes, extension: ext);

      if (!mounted) return;

      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => DocumentReviewScreen(
            originalBytes: bytes as dynamic,
            originalFilePath: filePath!,
            mimeType: mimeType,
          ),
        ),
      );

      if (saved == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('File import error: $e');
    }
  }

  Future<void> _navigateToReview(ScannedDocumentBatch batch) async {
    if (!mounted) return;

    final hasPdf = batch.pdfBytes != null;
    final fileBytes = hasPdf ? batch.pdfBytes! : batch.pageImages.first;
    String filePath = hasPdf ? (batch.pdfPath ?? '') : batch.originalPaths.first;
    final mimeType = hasPdf ? 'application/pdf' : 'image/jpeg';

    if (filePath.isEmpty) {
      filePath = await _scannerService.stageBytesToCache(fileBytes, extension: hasPdf ? 'pdf' : 'jpg');
    }

    if (!mounted) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentReviewScreen(
          originalBytes: fileBytes,
          originalFilePath: filePath,
          mimeType: mimeType,
        ),
      ),
    );

    // Clean up temporary batch files
    await _scannerService.cleanupBatchFiles(batch);

    if (saved == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: Text(
          'Scan or Import Document',
          style: AppTextStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withAlpha(20),
                    border: Border.all(color: AppColors.primary.withAlpha(80), width: 2),
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Spendz Document Vault',
                style: AppTextStyles.headingMedium.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'On-device ML Kit OCR • Edge detection • Automatic perspective correction • AES-256-GCM hardware protection',
                style: AppTextStyles.caption.copyWith(color: textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              if (_isProcessing) ...[
                const Spacer(),
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _statusMessage,
                        style: AppTextStyles.bodyMedium.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ] else ...[
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildScanOptionTile(
                        context,
                        title: 'Smart Scanner',
                        subtitle: 'Real-time document edge detection, auto-crop & perspective correction',
                        icon: Icons.document_scanner_rounded,
                        isPrimary: true,
                        onTap: _startSmartScanner,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildScanOptionTile(
                        context,
                        title: 'Camera Photo',
                        subtitle: 'Quick high-resolution document photo capture',
                        icon: Icons.camera_alt_rounded,
                        onTap: _captureFromCamera,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildScanOptionTile(
                        context,
                        title: 'Import from Gallery',
                        subtitle: 'Select document photo or receipt from your device photos',
                        icon: Icons.photo_library_rounded,
                        onTap: _pickFromGallery,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildScanOptionTile(
                        context,
                        title: 'Import PDF or File',
                        subtitle: 'Load existing PDF statement, certificate or scanned file',
                        icon: Icons.picture_as_pdf_rounded,
                        onTap: _pickDocumentFile,
                      ),
                    ],
                  ),
                ),
              ],

              // Privacy banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '100% Offline & Private. All OCR and encryption happens on your device.',
                        style: AppTextStyles.caption.copyWith(fontSize: 11, color: textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanOptionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    final surfaceColor = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return InkWell(
      onTap: _isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: ReusableCard(
        border: isPrimary ? Border.all(color: AppColors.primary, width: 1.5) : null,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isPrimary ? AppColors.primary : surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary.withAlpha(60)),
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.white : AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(color: textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: textSecondary),
          ],
        ),
      ),
    );
  }
}
