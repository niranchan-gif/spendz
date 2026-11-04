import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import 'image_processing_service.dart';

/// Represents a captured or attached document payload.
class DocumentAttachmentPayload {
  final List<Uint8List> pages;
  final Uint8List? pdfBytes;
  final String mimeType;
  final String fileName;
  final String attachmentType; // 'image', 'pdf', 'scanned_pdf'
  final int? explicitPageCount;
  final int? fileSizeBytes;

  const DocumentAttachmentPayload({
    required this.pages,
    this.pdfBytes,
    required this.mimeType,
    required this.fileName,
    required this.attachmentType,
    this.explicitPageCount,
    this.fileSizeBytes,
  });

  int get pageCount =>
      explicitPageCount ??
      (pages.isNotEmpty ? pages.length : (pdfBytes != null ? 1 : 0));
  bool get isPdf => mimeType.contains('pdf') || pdfBytes != null;
  Uint8List get primaryBytes =>
      pdfBytes ?? (pages.isNotEmpty ? pages.first : Uint8List(0));
  int get calculatedSize => fileSizeBytes ?? primaryBytes.length;
}

/// Backwards compatibility alias for existing consumers.
typedef ScannedDocumentBatch = DocumentAttachmentPayload;

/// Service managing document scanning and original attachment capture.
///
/// Features:
/// - Native document scanner with automatic edge detection, perspective correction, enhancement (CunningDocumentScanner)
/// - Pure offline camera capture fallback
/// - Multi-image gallery selection
/// - PDF and image file selection with safe content URI byte copying
/// - Page rotation, cropping, enhancement
/// - Multi-page PDF generation via Syncfusion
/// - Direct PDF saving to phone storage (SAF / Downloads)
/// - ZERO OCR dependencies
class DocumentScannerService {
  final ImageProcessingService _imageProcessor;
  final ImagePicker _imagePicker;

  DocumentScannerService({
    ImageProcessingService? imageProcessor,
    ImagePicker? imagePicker,
  }) : _imageProcessor = imageProcessor ?? ImageProcessingService(),
       _imagePicker = imagePicker ?? ImagePicker();

  ImageProcessingService get imageProcessor => _imageProcessor;

  /// Returns the standardized default PDF filename for a given category.
  static String getDefaultPdfFileName(String category) {
    final clean = category.toLowerCase().trim();
    switch (clean) {
      case 'aadhaar':
      case 'aadhaar_card':
        return 'Aadhaar_Document.pdf';
      case 'pan':
      case 'pan_card':
        return 'PAN_Card.pdf';
      case 'driving_license':
      case 'driving_licence':
        return 'Driving_Licence.pdf';
      case 'passport':
        return 'Passport.pdf';
      case 'credit_card':
      case 'debit_card':
        return 'Payment_Card.pdf';
      case 'insurance':
        return 'Insurance_Policy.pdf';
      case 'voter_id':
        return 'Voter_ID.pdf';
      case 'vehicle_rc':
        return 'Vehicle_RC.pdf';
      default:
        return 'Spendz_Document.pdf';
    }
  }

  /// Formats byte length into human-readable string (KB / MB).
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).round();
      return '$kb KB';
    }
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
    return '$mb MB';
  }

  /// Calculates the number of pages inside a PDF file.
  int getPdfPageCount(Uint8List pdfBytes) {
    if (pdfBytes.isEmpty) return 0;
    try {
      final loadedDoc = PdfDocument(inputBytes: pdfBytes);
      final count = loadedDoc.pages.count;
      loadedDoc.dispose();
      return count;
    } catch (e) {
      debugPrint('[DocumentScannerService] Failed to parse PDF page count: $e');
      return 1;
    }
  }

  /// Scans multiple physical document pages using the dedicated native document scanner.
  ///
  /// Utilizes hardware-accelerated boundary detection, perspective correction,
  /// automatic cropping, and flash controls.
  Future<List<Uint8List>> scanWithNativeScanner({int maxPages = 20}) async {
    try {
      final pictures = await CunningDocumentScanner.getPictures(
        noOfPages: maxPages,
        scannerSource: ScannerSource.cameraAndGallery,
      );

      if (pictures == null || pictures.isEmpty) return [];

      final results = <Uint8List>[];
      for (final path in pictures) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            results.add(bytes);
          }
        }
      }

      await CunningDocumentScanner.cleanCache();
      return results;
    } catch (e) {
      debugPrint(
        '[DocumentScannerService] Native document scanner error: $e. Falling back to camera.',
      );
      return [];
    }
  }

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

  /// Picks an existing document (PDF or Image) from device storage.
  ///
  /// Uses safe byte copying to ensure Android content URIs are preserved.
  Future<DocumentAttachmentPayload?> pickExistingDocument() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );

      if (files.isEmpty) return null;
      final file = files.first;

      final fileBytes = await file.xFile.readAsBytes();
      if (fileBytes.isEmpty) return null;

      final isPdf =
          file.extension?.toLowerCase() == 'pdf' ||
          (fileBytes.length >= 4 &&
              fileBytes[0] == 0x25 &&
              fileBytes[1] == 0x50 &&
              fileBytes[2] == 0x44 &&
              fileBytes[3] == 0x46); // '%PDF'

      if (isPdf) {
        final pageCount = getPdfPageCount(fileBytes);
        return DocumentAttachmentPayload(
          pages: const [],
          pdfBytes: fileBytes,
          mimeType: 'application/pdf',
          fileName: file.name,
          attachmentType: 'pdf',
          explicitPageCount: pageCount,
          fileSizeBytes: fileBytes.length,
        );
      } else {
        return DocumentAttachmentPayload(
          pages: [fileBytes],
          pdfBytes: null,
          mimeType: 'image/${file.extension ?? 'jpeg'}',
          fileName: file.name,
          attachmentType: 'image',
          explicitPageCount: 1,
          fileSizeBytes: fileBytes.length,
        );
      }
    } catch (e) {
      debugPrint('[DocumentScannerService] Pick existing document error: $e');
      return null;
    }
  }

  /// Picks a PDF file from device storage (legacy alias).
  Future<DocumentAttachmentPayload?> pickPdfFile() async {
    return pickExistingDocument();
  }

  /// Generates a high-quality PDF from captured page images.
  Uint8List generatePdfFromPages(
    List<Uint8List> pages, {
    String title = 'Spendz Document',
    String? category,
  }) {
    if (pages.isEmpty) {
      throw ArgumentError('At least one page is required to generate a PDF.');
    }

    // Compress large images sensibly to avoid excessive memory usage
    final optimized = pages
        .map(
          (p) => _imageProcessor.compressAndOptimize(
            p,
            maxDimension: 2048,
            quality: 85,
          ),
        )
        .toList();
    return _imageProcessor.createPdfFromImages(optimized, title: title);
  }

  /// Saves a generated PDF to phone storage (Downloads or user-selected SAF destination).
  ///
  /// Guarantees that the saved PDF can be accessed directly using the phone's file manager.
  Future<String?> savePdfToPhoneStorage({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    if (pdfBytes.isEmpty) return null;

    final sanitizedName = fileName.endsWith('.pdf')
        ? fileName
        : '$fileName.pdf';

    // 1. Try FilePicker saveFile (Storage Access Framework ACTION_CREATE_DOCUMENT)
    try {
      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Save PDF to Phone Storage',
        fileName: sanitizedName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: pdfBytes,
      );
      if (savedUri != null) {
        final path = savedUri.toFilePath(windows: Platform.isWindows);
        return path.isNotEmpty ? path : savedUri.toString();
      }
    } catch (e) {
      debugPrint('[DocumentScannerService] FilePicker saveFile error: $e');
    }

    // 2. Direct Downloads folder fallback for Android/iOS
    try {
      Directory? targetDir;
      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Download');
        if (!await targetDir.exists()) {
          final externalDirs = await getExternalStorageDirectories(
            type: StorageDirectory.downloads,
          );
          if (externalDirs != null && externalDirs.isNotEmpty) {
            targetDir = externalDirs.first;
          }
        }
      } else {
        targetDir =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }

      if (await targetDir.exists()) {
        var destination = File('${targetDir.path}/$sanitizedName');
        if (await destination.exists()) {
          final baseName = p.basenameWithoutExtension(sanitizedName);
          final timestamp = DateFormat(
            'yyyyMMdd_HHmmss',
          ).format(DateTime.now());
          destination = File('${targetDir.path}/${baseName}_$timestamp.pdf');
        }
        await destination.writeAsBytes(pdfBytes, flush: true);
        return destination.path;
      }
    } catch (e) {
      debugPrint(
        '[DocumentScannerService] Downloads directory write error: $e',
      );
    }

    return null;
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
  Future<File?> stageBytesToCache(
    Uint8List bytes, {
    String extension = 'jpg',
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetFile = File(
        '${tempDir.path}/attachment_${const Uuid().v4()}.$extension',
      );
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
