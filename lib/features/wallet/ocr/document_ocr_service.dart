import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'ocr_result.dart';

/// Abstract contract for on-device OCR recognition.
abstract class DocumentOcrEngine {
  Future<OcrResult> processImagePath(String filePath);
  Future<OcrResult> processImageBytes(Uint8List imageBytes);
  Future<void> dispose();
}

/// Google ML Kit on-device Text Recognition implementation.
/// Runs 100% locally on the device — zero data transmitted over network.
class MlKitOcrEngine implements DocumentOcrEngine {
  TextRecognizer? _recognizer;

  TextRecognizer _getRecognizer() {
    return _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
  }

  @override
  Future<OcrResult> processImagePath(String filePath) async {
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final recognizedText = await _getRecognizer().processImage(inputImage);

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
    } catch (e) {
      debugPrint('ML Kit OCR error: $e');
      return OcrResult.failure('Failed to recognize text: $e');
    }
  }

  @override
  Future<OcrResult> processImageBytes(Uint8List imageBytes) async {
    // Write bytes to ephemeral temp file for InputImage consumption
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/ocr_staging_${const Uuid().v4()}.jpg');
    try {
      await tempFile.writeAsBytes(imageBytes, flush: true);
      final result = await processImagePath(tempFile.path);
      return result;
    } finally {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
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
  Future<OcrResult> processImageBytes(Uint8List imageBytes) async {
    if (shouldFail) {
      return OcrResult.failure('Simulated OCR Engine Failure');
    }
    return OcrResult.fromText(predefinedText);
  }

  @override
  Future<void> dispose() async {}
}

