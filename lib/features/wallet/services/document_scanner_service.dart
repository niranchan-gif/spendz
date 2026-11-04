import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'image_processing_service.dart';

/// Represents the output of a document scanning or capture session.
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

/// Production-quality document scanner service with multi-modal capture:
/// 1. Native ML Kit Document Scanner (edge detection, perspective correction, auto-crop)
/// 2. Camera Capture via ImagePicker
/// 3. Photo Gallery Selection via ImagePicker
/// 4. Ephemeral caching and safe path verification
class DocumentScannerService {
  final ImageProcessingService _imageProcessor;
  final ImagePicker _imagePicker;

  DocumentScannerService({
    ImageProcessingService? imageProcessor,
    ImagePicker? imagePicker,
  })  : _imageProcessor = imageProcessor ?? ImageProcessingService(),
        _imagePicker = imagePicker ?? ImagePicker();

  /// Starts the Google Play Services native document scanner session.
  ///
  /// Features:
  /// - Real-time edge detection overlay
  /// - Automatic perspective correction & warping
  /// - Manual corner handle adjustment
  /// - Multi-page scanning (up to [pageLimit])
  /// - Rotation & filters
  ///
  /// Returns `null` if the user cancels scanning or if the native scanner is unavailable.
  Future<ScannedDocumentBatch?> startScanSession({
    int pageLimit = 10,
    bool allowGalleryImport = true,
  }) async {
    try {
      final options = DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg, DocumentFormat.pdf},
        mode: ScannerMode.full,
        isGalleryImport: allowGalleryImport,
        pageLimit: pageLimit,
      );

      final scanner = DocumentScanner(options: options);
      final DocumentScanningResult result = await scanner.scanDocument();
      await scanner.close();

      final rawImagePaths = result.images;
      if (rawImagePaths == null || rawImagePaths.isEmpty) {
        return null;
      }

      final pageImages = <Uint8List>[];
      final verifiedPaths = <String>[];

      for (final rawPath in rawImagePaths) {
        final localFile = await _resolveAndVerifyPath(rawPath);
        if (localFile != null && await localFile.exists()) {
          final bytes = await localFile.readAsBytes();
          if (bytes.isNotEmpty) {
            pageImages.add(bytes);
            verifiedPaths.add(localFile.path);
          }
        }
      }

      if (pageImages.isEmpty) {
        return null;
      }

      // Check if native PDF was generated
      Uint8List? pdfBytes;
      String? pdfPath;
      final rawPdfUri = result.pdf?.uri;
      if (rawPdfUri != null) {
        final pdfFile = await _resolveAndVerifyPath(rawPdfUri);
        if (pdfFile != null && await pdfFile.exists()) {
          pdfPath = pdfFile.path;
          pdfBytes = await pdfFile.readAsBytes();
        }
      }

      // If multi-page scan without native PDF, generate high-quality PDF using Syncfusion engine
      if (pdfBytes == null && pageImages.length > 1) {
        pdfBytes = _imageProcessor.createPdfFromImages(pageImages);
      }

      return ScannedDocumentBatch(
        pageImages: pageImages,
        originalPaths: verifiedPaths,
        pdfBytes: pdfBytes,
        pdfPath: pdfPath,
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED' || e.message?.toLowerCase().contains('cancel') == true) {
        debugPrint('[DocumentScannerService] Scanner cancelled by user');
        return null;
      }
      debugPrint('[DocumentScannerService] Scanner platform exception: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[DocumentScannerService] Scanner error: $e');
      return null;
    }
  }

  /// Captures a single document photo directly via Camera with high resolution.
  Future<ScannedDocumentBatch?> captureFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) return null;

      final file = File(photo.path);
      if (!await file.exists() || await file.length() == 0) return null;

      final bytes = await file.readAsBytes();
      return ScannedDocumentBatch(
        pageImages: [bytes],
        originalPaths: [file.path],
      );
    } catch (e) {
      debugPrint('[DocumentScannerService] Camera capture error: $e');
      return null;
    }
  }

  /// Imports an image directly from the photo gallery.
  Future<ScannedDocumentBatch?> pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (image == null) return null;

      final file = File(image.path);
      if (!await file.exists() || await file.length() == 0) return null;

      final bytes = await file.readAsBytes();
      return ScannedDocumentBatch(
        pageImages: [bytes],
        originalPaths: [file.path],
      );
    } catch (e) {
      debugPrint('[DocumentScannerService] Gallery pick error: $e');
      return null;
    }
  }

  /// Resolves raw path strings, stripping file:// schemes and verifying local accessibility.
  Future<File?> _resolveAndVerifyPath(String rawPath) async {
    try {
      String clean = rawPath.trim();
      if (clean.startsWith('file://')) {
        try {
          clean = Uri.parse(clean).toFilePath();
        } catch (_) {
          clean = clean.replaceFirst('file://', '');
        }
      }

      final file = File(clean);
      if (await file.exists()) {
        return file;
      }

      // If the file cannot be accessed directly (e.g. URI artifact), attempt copy via bytes if possible
      return null;
    } catch (e) {
      debugPrint('[DocumentScannerService] Error resolving path $rawPath: $e');
      return null;
    }
  }

  /// Writes arbitrary bytes to a verified staging file in app cache.
  Future<String> stageBytesToCache(Uint8List bytes, {String extension = 'jpg'}) async {
    final tempDir = await getTemporaryDirectory();
    final stagingFile = File('${tempDir.path}/scan_stage_${const Uuid().v4()}.$extension');
    await stagingFile.writeAsBytes(bytes, flush: true);
    return stagingFile.path;
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
