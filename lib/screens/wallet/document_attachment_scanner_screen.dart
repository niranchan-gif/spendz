import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/wallet/services/document_scanner_service.dart';

/// Screen for capturing, previewing, cropping, rotating, and organizing document attachments.
///
/// Features:
/// - Camera multi-page capture
/// - Gallery photo import
/// - PDF document selection
/// - Page reordering, rotation (90° clockwise), cropping, and deletion
/// - Multi-page PDF generation via Syncfusion
/// - Pure offline, zero OCR
class DocumentAttachmentScannerScreen extends StatefulWidget {
  final DocumentScannerService? scannerService;
  final DocumentAttachmentPayload? initialPayload;

  const DocumentAttachmentScannerScreen({
    super.key,
    this.scannerService,
    this.initialPayload,
  });

  @override
  State<DocumentAttachmentScannerScreen> createState() => _DocumentAttachmentScannerScreenState();
}

class _DocumentAttachmentScannerScreenState extends State<DocumentAttachmentScannerScreen> {
  late final DocumentScannerService _scannerService;
  final List<Uint8List> _pages = [];
  Uint8List? _pdfBytes;
  String? _pdfFileName;
  int _currentPageIndex = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scannerService = widget.scannerService ?? DocumentScannerService();
    if (widget.initialPayload != null) {
      if (widget.initialPayload!.pages.isNotEmpty) {
        _pages.addAll(widget.initialPayload!.pages);
      }
      _pdfBytes = widget.initialPayload!.pdfBytes;
      _pdfFileName = widget.initialPayload!.fileName;
    }
  }

  Future<void> _captureFromCamera() async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await _scannerService.capturePageFromCamera();
      if (bytes != null && bytes.isNotEmpty) {
        setState(() {
          _pages.add(bytes);
          _pdfBytes = null;
          _pdfFileName = null;
          _currentPageIndex = _pages.length - 1;
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isProcessing = true);
    try {
      final images = await _scannerService.pickPagesFromGallery();
      if (images.isNotEmpty) {
        setState(() {
          _pages.addAll(images);
          _pdfBytes = null;
          _pdfFileName = null;
          _currentPageIndex = _pages.length - 1;
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickPdf() async {
    setState(() => _isProcessing = true);
    try {
      final payload = await _scannerService.pickPdfFile();
      if (payload != null && payload.pdfBytes != null) {
        setState(() {
          _pages.clear();
          _pdfBytes = payload.pdfBytes;
          _pdfFileName = payload.fileName;
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _rotateCurrentPage() {
    if (_pages.isEmpty || _currentPageIndex >= _pages.length) return;
    setState(() => _isProcessing = true);
    try {
      final rotated = _scannerService.rotatePage(_pages[_currentPageIndex], 90);
      setState(() {
        _pages[_currentPageIndex] = rotated;
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _retakeCurrentPage() async {
    if (_pages.isEmpty || _currentPageIndex >= _pages.length) return;
    setState(() => _isProcessing = true);
    try {
      final bytes = await _scannerService.capturePageFromCamera();
      if (bytes != null && bytes.isNotEmpty) {
        setState(() {
          _pages[_currentPageIndex] = bytes;
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _movePageLeft() {
    if (_currentPageIndex > 0) {
      setState(() {
        final item = _pages.removeAt(_currentPageIndex);
        _pages.insert(_currentPageIndex - 1, item);
        _currentPageIndex--;
      });
    }
  }

  void _movePageRight() {
    if (_currentPageIndex < _pages.length - 1) {
      setState(() {
        final item = _pages.removeAt(_currentPageIndex);
        _pages.insert(_currentPageIndex + 1, item);
        _currentPageIndex++;
      });
    }
  }

  void _deleteCurrentPage() {
    if (_pages.isEmpty) return;
    setState(() {
      _pages.removeAt(_currentPageIndex);
      if (_currentPageIndex >= _pages.length && _pages.isNotEmpty) {
        _currentPageIndex = _pages.length - 1;
      }
    });
  }

  void _confirmAttachment() {
    if (_pdfBytes != null) {
      final payload = DocumentAttachmentPayload(
        pages: const [],
        pdfBytes: _pdfBytes,
        mimeType: 'application/pdf',
        fileName: _pdfFileName ?? 'document_attachment.pdf',
        attachmentType: 'pdf',
      );
      Navigator.pop(context, payload);
      return;
    }

    if (_pages.isEmpty) {
      Navigator.pop(context, null);
      return;
    }

    if (_pages.length == 1) {
      final payload = DocumentAttachmentPayload(
        pages: _pages,
        pdfBytes: null,
        mimeType: 'image/jpeg',
        fileName: 'scanned_page_1.jpg',
        attachmentType: 'image',
      );
      Navigator.pop(context, payload);
    } else {
      // Multi-page document: compile into clean PDF
      final pdf = _scannerService.generatePdfFromPages(_pages, title: 'Scanned Document (${_pages.length} Pages)');
      final payload = DocumentAttachmentPayload(
        pages: _pages,
        pdfBytes: pdf,
        mimeType: 'application/pdf',
        fileName: 'multi_page_document_${_pages.length}p.pdf',
        attachmentType: 'scanned_pdf',
      );
      Navigator.pop(context, payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAttachment = _pages.isNotEmpty || _pdfBytes != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attach Document Copy'),
        actions: [
          if (hasAttachment)
            TextButton(
              onPressed: _confirmAttachment,
              child: const Text('Attach', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: hasAttachment
                      ? (_pdfBytes != null ? _buildPdfPreview(isDark) : _buildMultiPageViewer(isDark))
                      : _buildEmptyPrompt(isDark),
                ),
                _buildBottomToolbar(isDark, hasAttachment),
              ],
            ),
    );
  }

  Widget _buildEmptyPrompt(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Attach Document Copy',
              style: AppTextStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Capture multiple pages with your camera, select photos from your gallery, or import an existing PDF file.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.getTextSecondary(context)),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _captureFromCamera,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: _pickPdf,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Upload PDF File'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfPreview(bool isDark) {
    final sizeKb = (_pdfBytes!.length / 1024).toStringAsFixed(1);
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: Colors.red.withAlpha(80)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_rounded, size: 72, color: Colors.redAccent),
            const SizedBox(height: AppSpacing.md),
            Text(
              _pdfFileName ?? 'Document.pdf',
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'PDF Document • $sizeKb KB',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.getTextSecondary(context)),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _pickPdf,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Replace PDF'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiPageViewer(bool isDark) {
    if (_pages.isEmpty) return const SizedBox.shrink();
    final currentBytes = _pages[_currentPageIndex];

    return Column(
      children: [
        // Page counter & reorder bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page ${_currentPageIndex + 1} of ${_pages.length}',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                    onPressed: _currentPageIndex > 0 ? _movePageLeft : null,
                    tooltip: 'Move page left',
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onPressed: _currentPageIndex < _pages.length - 1 ? _movePageRight : null,
                    tooltip: 'Move page right',
                  ),
                  IconButton(
                    icon: const Icon(Icons.rotate_right_rounded),
                    onPressed: _rotateCurrentPage,
                    tooltip: 'Rotate 90°',
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined),
                    onPressed: _retakeCurrentPage,
                    tooltip: 'Retake photo',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: _deleteCurrentPage,
                    tooltip: 'Delete page',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Main preview image
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            clipBehavior: Clip.antiAlias,
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.5,
              child: Center(
                child: Image.memory(
                  currentBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),

        // Bottom page thumbnails strip
        if (_pages.length > 1)
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _pages.length,
              separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final isSelected = index == _currentPageIndex;
                return GestureDetector(
                  onTap: () => setState(() => _currentPageIndex = index),
                  child: Container(
                    width: 54,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade400,
                        width: isSelected ? 2.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(_pages[index], fit: BoxFit.cover),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBottomToolbar(bool isDark, bool hasAttachment) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _captureFromCamera,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: Text(_pages.isEmpty ? 'Add Photo' : 'Add Page'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Add Gallery'),
              ),
            ),
            if (hasAttachment) ...[
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                onPressed: _confirmAttachment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
