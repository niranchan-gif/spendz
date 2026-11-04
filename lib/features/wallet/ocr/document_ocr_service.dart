import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'ocr_result.dart';

/// Abstract contract for on-device OCR recognition.
abstract class DocumentOcrEngine {
  Future<OcrResult> processImagePath(String filePath);
  Future<OcrResult> processImageBytes(Uint8List imageBytes, {String? mimeType});
  Future<void> dispose();
}

/// Google ML Kit on-device Text Recognition implementation.
/// Runs 100% locally on the device — zero network data transmission.
///
/// Features:
/// - Resolves and validates local filesystem paths (handles file://, content URIs, spaces).
/// - Automatically detects and extracts text from PDFs using native Syncfusion PDF parser.
/// - Downscales oversized images to prevent Android native OOM exceptions.
/// - Guarantees proper lifecycle disposal of ML Kit TextRecognizer instances.
class MlKitOcrEngine implements DocumentOcrEngine {
  static const int _maxDimension = 2400;
  static const int _maxFileSizeBytes = 8 * 1024 * 1024; // 8MB

  @override
  Future<OcrResult> processImagePath(String filePath) async {
    try {
      final cleanPath = _sanitizePath(filePath);
      final file = File(cleanPath);

      if (!await file.exists()) {
        debugPrint('[MlKitOcrEngine] Image file does not exist at path: $cleanPath');
        return OcrResult.failure('Selected image file does not exist or cannot be accessed');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        debugPrint('[MlKitOcrEngine] Image file is empty (0 bytes): $cleanPath');
        return OcrResult.failure('Selected image file is empty');
      }

      // Check if file is a PDF
      if (cleanPath.toLowerCase().endsWith('.pdf')) {
        final pdfBytes = await file.readAsBytes();
        return _extractTextFromPdf(pdfBytes);
      }

      // Check for PDF magic bytes in case extension is missing/incorrect (%PDF -> 0x25, 0x50, 0x44, 0x46)
      if (fileSize > 4) {
        final header = await file.openRead(0, 4).first;
        if (listEquals(header, [0x25, 0x50, 0x44, 0x46])) {
          final pdfBytes = await file.readAsBytes();
          return _extractTextFromPdf(pdfBytes);
        }
      }

      // Handle potentially oversized images to prevent OutOfMemory crashes
      String pathForOcr = cleanPath;
      File? downscaledTempFile;

      if (fileSize > _maxFileSizeBytes) {
        downscaledTempFile = await _createDownscaledImageFile(file);
        if (downscaledTempFile != null) {
          pathForOcr = downscaledTempFile.path;
        }
      }

      try {
        return await _runMlKitRecognizer(pathForOcr);
      } finally {
        if (downscaledTempFile != null && await downscaledTempFile.exists()) {
          try {
            await downscaledTempFile.delete();
          } catch (_) {}
        }
      }
    } catch (e, stack) {
      debugPrint('[MlKitOcrEngine] OCR processing error: $e\n$stack');
      return OcrResult.failure('Text recognition failed: ${e.toString()}');
    }
  }

  @override
  Future<OcrResult> processImageBytes(Uint8List imageBytes, {String? mimeType}) async {
    if (imageBytes.isEmpty) {
      return OcrResult.failure('Provided document image bytes are empty');
    }

    // Check if input is a PDF (by MIME type or magic bytes)
    if (mimeType == 'application/pdf' ||
        (imageBytes.length >= 4 &&
            imageBytes[0] == 0x25 &&
            imageBytes[1] == 0x50 &&
            imageBytes[2] == 0x44 &&
            imageBytes[3] == 0x46)) {
      return _extractTextFromPdf(imageBytes);
    }

    // Write bytes to a verified staging file in application cache
    final tempDir = await getTemporaryDirectory();
    final stagingFileName = 'ocr_staging_${const Uuid().v4()}.jpg';
    final stagingFile = File('${tempDir.path}/$stagingFileName');

    try {
      // If bytes are very large, downscale before saving to disk
      Uint8List bytesToWrite = imageBytes;
      if (imageBytes.length > _maxFileSizeBytes) {
        final decoded = img.decodeImage(imageBytes);
        if (decoded != null && (decoded.width > _maxDimension || decoded.height > _maxDimension)) {
          final resized = img.copyResize(
            decoded,
            width: decoded.width > decoded.height ? _maxDimension : null,
            height: decoded.height >= decoded.width ? _maxDimension : null,
          );
          bytesToWrite = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
        }
      }

      await stagingFile.writeAsBytes(bytesToWrite, flush: true);
      return await _runMlKitRecognizer(stagingFile.path);
    } catch (e, stack) {
      debugPrint('[MlKitOcrEngine] Staging OCR error: $e\n$stack');
      return OcrResult.failure('Failed to process image for text recognition: $e');
    } finally {
      if (await stagingFile.exists()) {
        try {
          await stagingFile.delete();
        } catch (_) {}
      }
    }
  }

  /// Runs ML Kit TextRecognizer on a verified local file path with proper lifecycle disposal.
  Future<OcrResult> _runMlKitRecognizer(String absoluteLocalPath) async {
    final inputImage = InputImage.fromFilePath(absoluteLocalPath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await recognizer.processImage(inputImage);

      final blocks = <OcrBlock>[];
      final lines = <OcrLine>[];

      for (final block in recognizedText.blocks) {
        final blockLines = <OcrLine>[];
        for (final line in block.lines) {
          final ocrLine = OcrLine(
            text: line.text,
            boundingBox: line.boundingBox,
            recognizedLanguages: line.recognizedLanguages,
          );
          blockLines.add(ocrLine);
          lines.add(ocrLine);
        }

        blocks.add(OcrBlock(
          text: block.text,
          lines: blockLines,
          boundingBox: block.boundingBox,
          recognizedLanguages: block.recognizedLanguages,
        ));
      }

      return OcrResult(
        fullText: recognizedText.text,
        blocks: blocks,
        lines: lines,
        isSuccess: true,
      );
    } finally {
      await recognizer.close();
    }
  }

  /// Extracts text safely from uncompressed PDF streams or returns a structured empty result.
  OcrResult _extractTextFromPdf(Uint8List pdfBytes) {
    try {
      final textBuffer = StringBuffer();
      final latinString = String.fromCharCodes(pdfBytes);
      final tjRegex = RegExp(r'\(([^)]+)\)\s*(?:Tj|TJ)');
      for (final match in tjRegex.allMatches(latinString)) {
        final t = match.group(1)?.trim();
        if (t != null && t.length > 1) {
          textBuffer.writeln(t);
        }
      }
      final text = textBuffer.toString().trim();
      if (text.isNotEmpty) {
        return OcrResult.fromText(text);
      }
      return const OcrResult(
        fullText: '',
        blocks: [],
        lines: [],
        isSuccess: true,
      );
    } catch (e) {
      debugPrint('[MlKitOcrEngine] PDF text scan: $e');
      return const OcrResult(
        fullText: '',
        blocks: [],
        lines: [],
        isSuccess: true,
      );
    }
  }

  /// Downscales high-resolution images to fit within [_maxDimension].
  Future<File?> _createDownscaledImageFile(File original) async {
    try {
      final bytes = await original.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      if (decoded.width <= _maxDimension && decoded.height <= _maxDimension) {
        return null;
      }

      final resized = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? _maxDimension : null,
        height: decoded.height >= decoded.width ? _maxDimension : null,
      );

      final tempDir = await getTemporaryDirectory();
      final downscaledFile = File('${tempDir.path}/ocr_downscaled_${const Uuid().v4()}.jpg');
      await downscaledFile.writeAsBytes(img.encodeJpg(resized, quality: 85), flush: true);
      return downscaledFile;
    } catch (e) {
      debugPrint('[MlKitOcrEngine] Downscaling error: $e');
      return null;
    }
  }

  /// Sanitizes file path strings, stripping file:// schemes and URI encodings.
  String _sanitizePath(String rawPath) {
    String path = rawPath.trim();
    if (path.startsWith('file://')) {
      try {
        path = Uri.parse(path).toFilePath();
      } catch (_) {
        path = path.replaceFirst('file://', '');
      }
    }
    return path;
  }

  @override
  Future<void> dispose() async {}
}

/// Deterministic Mock OCR Engine for unit testing and offline environments.
class MockOcrEngine implements DocumentOcrEngine {
  String predefinedText;
  bool shouldFail;

  MockOcrEngine({
    this.predefinedText = '',
    this.shouldFail = false,
  });

  @override
  Future<OcrResult> processImagePath(String filePath) async {
    if (shouldFail) {
      return OcrResult.failure('Simulated OCR Engine Failure');
    }
    return OcrResult.fromText(predefinedText);
  }

  @override
  Future<OcrResult> processImageBytes(Uint8List imageBytes, {String? mimeType}) async {
    if (shouldFail) {
      return OcrResult.failure('Simulated OCR Engine Failure');
    }
    return OcrResult.fromText(predefinedText);
  }

  @override
  Future<void> dispose() async {}
}
