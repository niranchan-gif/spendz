import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'image_processing_service.dart';

/// Represents the output of a multi-page document scanning session.
class ScannedDocumentBatch {
  final List<Uint8List> pageImages;
  final List<String> originalPaths;
  final Uint8List? pdfBytes;
  final String? pdfPath;

  const ScannedDocumentBatch({
    required this.pageImages,
    required this.originalPaths,
    this.pdfBytes,
    this.pdfPath,
  });

  int get pageCount => pageImages.length;
  bool get isEmpty => pageImages.isEmpty;
}

/// Professional document scanner service using Google Play Services ML Kit Document Scanner
/// on Android/iOS, with multi-page, edge detection, perspective correction, enhancement, and PDF generation.
class DocumentScannerService {
  final ImageProcessingService _imageProcessor;

  DocumentScannerService({
    ImageProcessingService? imageProcessor,
  }) : _imageProcessor = imageProcessor ?? ImageProcessingService();

  /// Starts the native document scanner session.
  ///
  /// Features:
  /// - Real-time edge detection overlay
  /// - Automatic perspective correction & warping
  /// - Manual corner handle adjustment
  /// - Multi-page scanning (up to [pageLimit])
  /// - Built-in shadow cleaning and contrast filters
  /// - Rotation
  ///
  /// Returns `null` if the user cancels scanning.
  Future<ScannedDocumentBatch?> startScanSession({
    int pageLimit = 10,
    bool allowGalleryImport = true,
  }) async {
    try {
      final options = DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg, DocumentFormat.pdf},
        mode: ScannerMode.full, // Full interactive edge detection, manual adjustment, and filters
        isGalleryImport: allowGalleryImport,
        pageLimit: pageLimit,
      );

      final scanner = DocumentScanner(options: options);
      final DocumentScanningResult result = await scanner.scanDocument();
      await scanner.close();

      final imagePaths = result.images;
      if (imagePaths == null || imagePaths.isEmpty) {
        // User cancelled or no pages scanned
        return null;
      }

      final pageImages = <Uint8List>[];
      for (final path in imagePaths) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          pageImages.add(bytes);
        }
      }

      if (pageImages.isEmpty) {
        return null;
      }

      // Check if native PDF was generated
      Uint8List? pdfBytes;
      String? rawPdfUri = result.pdf?.uri;
      String? pdfPath;
      if (rawPdfUri != null) {
        pdfPath = rawPdfUri.startsWith('file://') ? Uri.parse(rawPdfUri).toFilePath() : rawPdfUri;
        final pdfFile = File(pdfPath);
        if (await pdfFile.exists()) {
          pdfBytes = await pdfFile.readAsBytes();
        }
      }

      // If multi-page scan without native PDF, generate high-quality PDF using Syncfusion engine
      if (pdfBytes == null && pageImages.length > 1) {
        pdfBytes = _imageProcessor.createPdfFromImages(pageImages);
      }

      return ScannedDocumentBatch(
        pageImages: pageImages,
        originalPaths: imagePaths,
        pdfBytes: pdfBytes,
        pdfPath: pdfPath,
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED' || e.message?.contains('cancel') == true) {
        debugPrint('Document scanner cancelled by user');
        return null;
      }
      debugPrint('Document scanner platform exception: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Document scanner general error: $e');
      return null;
    }
  }

  /// Ephemeral staging cleanup for scanned image batches.
  Future<void> cleanupBatchFiles(ScannedDocumentBatch batch) async {
    for (final path in batch.originalPaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    if (batch.pdfPath != null) {
      try {
        final pdfFile = File(batch.pdfPath!);
        if (await pdfFile.exists()) {
          await pdfFile.delete();
        }
      } catch (_) {}
    }
  }
}

