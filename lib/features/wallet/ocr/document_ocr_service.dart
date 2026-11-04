import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ocr_result.dart';

/// Abstract contract for on-device OCR recognition.
///
/// NOTE: The document module has been transitioned to manual entry + virtual cards.
/// OCR is removed from the active workflow.
abstract class DocumentOcrEngine {
  Future<OcrResult> processImagePath(String filePath);
  Future<OcrResult> processImageBytes(Uint8List imageBytes, {String? mimeType});
  Future<void> dispose();
}

/// Fallback / Legacy mock OCR engine (ML Kit text recognition removed from workflow).
class MlKitOcrEngine implements DocumentOcrEngine {
  @override
  Future<OcrResult> processImagePath(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return OcrResult.failure('Image file does not exist at path: $filePath');
    }
    final size = await file.length();
    if (size == 0) {
      return OcrResult.failure('Image file is empty');
    }
    return const OcrResult(fullText: '', blocks: [], lines: []);
  }

  @override
  Future<OcrResult> processImageBytes(Uint8List imageBytes, {String? mimeType}) async {
    if (imageBytes.isEmpty) {
      return OcrResult.failure('Provided document image bytes are empty');
    }
    return const OcrResult(fullText: '', blocks: [], lines: []);
  }

  @override
  Future<void> dispose() async {}
}

/// Deterministic Mock OCR Engine for unit testing and offline environments.
class MockOcrEngine implements DocumentOcrEngine {
  final String? predefinedText;
  bool shouldFail;

  MockOcrEngine({
    this.predefinedText,
    this.shouldFail = false,
  });

  @override
  Future<OcrResult> processImagePath(String filePath) async {
    if (shouldFail) {
      return OcrResult.failure('Simulated OCR Engine Failure');
    }
    final text = predefinedText ?? 'MOCK EXTRACTED DOCUMENT TEXT\nNAME: JOHN DOE\nID: 1234567890';
    return OcrResult.fromText(text);
  }

  @override
  Future<OcrResult> processImageBytes(Uint8List imageBytes, {String? mimeType}) async {
    if (shouldFail) {
      return OcrResult.failure('Simulated OCR Engine Failure');
    }
    final text = predefinedText ?? 'MOCK EXTRACTED DOCUMENT TEXT\nNAME: JOHN DOE\nID: 1234567890';
    return OcrResult.fromText(text);
  }

  @override
  Future<void> dispose() async {}
}
