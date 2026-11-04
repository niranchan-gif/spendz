import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'image_processing_service.dart';

/// Represents a captured or attached document payload.
class DocumentAttachmentPayload {
  final List<Uint8List> pages;
  final Uint8List? pdfBytes;
  final String mimeType;
  final String fileName;
  final String attachmentType; // 'image', 'pdf', 'scanned_pdf'

  const DocumentAttachmentPayload({
    required this.pages,
    this.pdfBytes,
    required this.mimeType,
    required this.fileName,
    required this.attachmentType,
  });

  int get pageCount => pages.isNotEmpty ? pages.length : (pdfBytes != null ? 1 : 0);
  bool get isPdf => mimeType.contains('pdf') || pdfBytes != null;
  Uint8List get primaryBytes => pdfBytes ?? (pages.isNotEmpty ? pages.first : Uint8List(0));
}

/// Backwards compatibility alias for existing consumers.
typedef ScannedDocumentBatch = DocumentAttachmentPayload;

/// Service managing document scanning and original attachment capture.
///
/// Pure offline, multi-page capture with:
/// - Camera capture
/// - Multi-image gallery selection
/// - PDF file import
/// - Page rotation, cropping, enhancement
/// - Multi-page PDF generation via Syncfusion
/// - ZERO OCR dependencies
class DocumentScannerService {
  final ImageProcessingService _imageProcessor;
  final ImagePicker _imagePicker;

  DocumentScannerService({
    ImageProcessingService? imageProcessor,
    ImagePicker? imagePicker,
  })  : _imageProcessor = imageProcessor ?? ImageProcessingService(),
        _imagePicker = imagePicker ?? ImagePicker();

  ImageProcessingService get imageProcessor => _imageProcessor;

  /// Captures a single page via device camera.
  Future<Uint8List?> capturePageFromCamera() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (picked == null) return null;
      return await picked.readAsBytes();
    } catch (e) {
      debugPrint('[DocumentScannerService] Camera capture error: $e');
      return null;
    }
  }

  /// Picks one or more images from device photo gallery.
  Future<List<Uint8List>> pickPagesFromGallery() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 92,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (pickedFiles.isEmpty) return [];

      final results = <Uint8List>[];
      for (final file in pickedFiles) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          results.add(bytes);
        }
      }
      return results;
    } catch (e) {
      debugPrint('[DocumentScannerService] Gallery pick error: $e');
      return [];
    }
  }

  /// Picks a PDF file from device storage.
  Future<DocumentAttachmentPayload?> pickPdfFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result.isEmpty) return null;
      final file = result.first;
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) return null;

      return DocumentAttachmentPayload(
        pages: const [],
        pdfBytes: bytes,
        mimeType: 'application/pdf',
        fileName: file.name,
        attachmentType: 'pdf',
      );
    } catch (e) {
      debugPrint('[DocumentScannerService] PDF pick error: $e');
      return null;
    }
  }

  /// Generates a high-quality PDF from captured page images.
  Uint8List generatePdfFromPages(List<Uint8List> pages, {String title = 'Spendz Document'}) {
    return _imageProcessor.createPdfFromImages(pages, title: title);
  }

  /// Rotates a page image 90 degrees clockwise.
  Uint8List rotatePage(Uint8List imageBytes, [int angle = 90]) {
    return _imageProcessor.rotateImage(imageBytes, angle);
  }

  /// Crops a page image.
  Uint8List cropPage(
    Uint8List imageBytes, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    return _imageProcessor.cropImage(
      imageBytes,
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }

  /// Enhances page readability (contrast + sharpening).
  Uint8List enhancePage(Uint8List imageBytes) {
    return _imageProcessor.enhanceDocument(imageBytes);
  }

  /// Stages bytes to a verified temporary file.
  Future<File?> stageBytesToCache(Uint8List bytes, {String extension = 'jpg'}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetFile = File('${tempDir.path}/attachment_${const Uuid().v4()}.$extension');
      await targetFile.writeAsBytes(bytes, flush: true);
      if (await targetFile.exists() && await targetFile.length() > 0) {
        return targetFile;
      }
      return null;
    } catch (e) {
      debugPrint('[DocumentScannerService] Cache staging error: $e');
      return null;
    }
  }

  /// Legacy helper for starting scan session.
  Future<DocumentAttachmentPayload?> captureFromCamera() async {
    final bytes = await capturePageFromCamera();
    if (bytes == null) return null;
    return DocumentAttachmentPayload(
      pages: [bytes],
      mimeType: 'image/jpeg',
      fileName: 'camera_capture.jpg',
      attachmentType: 'image',
    );
  }

  /// Legacy helper for picking from gallery.
  Future<DocumentAttachmentPayload?> pickFromGallery() async {
    final pages = await pickPagesFromGallery();
    if (pages.isEmpty) return null;
    return DocumentAttachmentPayload(
      pages: pages,
      mimeType: 'image/jpeg',
      fileName: 'gallery_import.jpg',
      attachmentType: pages.length > 1 ? 'scanned_pdf' : 'image',
    );
  }
}
