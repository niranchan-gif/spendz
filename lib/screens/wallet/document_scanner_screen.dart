import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/wallet/services/document_scanner_service.dart';
import 'document_review_screen.dart';

class DocumentScannerScreen extends StatefulWidget {
  final DocumentScannerService? scannerService;

  const DocumentScannerScreen({super.key, this.scannerService});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  late final DocumentScannerService _scannerService;
  bool _isLaunchingScanner = false;

  @override
  void initState() {
    super.initState();
    _scannerService = widget.scannerService ?? DocumentScannerService();
    // Auto-launch the native scanner when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNativeScanner();
    });
  }

  Future<void> _startNativeScanner() async {
    setState(() => _isLaunchingScanner = true);

    try {
      final batch = await _scannerService.startScanSession(
        pageLimit: 10,
        allowGalleryImport: true,
      );

      setState(() => _isLaunchingScanner = false);

      if (batch == null || batch.isEmpty) {
        // User cancelled scan
        if (mounted && !Navigator.of(context).canPop()) {
          return;
        }
        return;
      }

      if (!mounted) return;

      // Determine whether we have a PDF or primary image
      final hasPdf = batch.pdfBytes != null;
      final fileBytes = hasPdf ? batch.pdfBytes! : batch.pageImages.first;
      final filePath = hasPdf ? (batch.pdfPath ?? '') : batch.originalPaths.first;
      final mimeType = hasPdf ? 'application/pdf' : 'image/jpeg';

      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => DocumentReviewScreen(
            originalBytes: fileBytes,
            originalFilePath: filePath,
            mimeType: mimeType,
          ),
        ),
      );

      // Clean up batch staging files
      await _scannerService.cleanupBatchFiles(batch);

      if (saved == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isLaunchingScanner = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanner error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickFileFallback() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );

      if (result.isEmpty) return;

      final file = File(result.first.path!);
      final bytes = await file.readAsBytes();
      final ext = result.first.extension?.toLowerCase() ?? 'jpg';
      final mimeType = ext == 'pdf' ? 'application/pdf' : 'image/jpeg';

      if (!mounted) return;

      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => DocumentReviewScreen(
            originalBytes: bytes,
            originalFilePath: file.path,
            mimeType: mimeType,
          ),
        ),
      );

      if (saved == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File picker error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Document Scanner', style: AppTextStyles.heading3),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withAlpha(25),
                  border: Border.all(color: AppColors.primary.withAlpha(80), width: 2),
                ),
                child: const Icon(
                  Icons.document_scanner_outlined,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Spendz Smart Scanner',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Edge detection • Perspective correction • Auto-crop • On-device OCR • AES-256-GCM Vault',
              style: TextStyle(color: Colors.white60, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            if (_isLaunchingScanner)
              const Column(
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Starting scanner...', style: TextStyle(color: Colors.white70)),
                ],
              )
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startNativeScanner,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Start Camera Scanner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickFileFallback,
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Import PDF or Image from Device'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

