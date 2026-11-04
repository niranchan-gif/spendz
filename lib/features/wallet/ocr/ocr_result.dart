import 'dart:ui';

/// Represents a single recognized line in a document.
class OcrLine {
  final String text;
  final Rect? boundingBox;
  final List<String> recognizedLanguages;

  const OcrLine({
    required this.text,
    this.boundingBox,
    this.recognizedLanguages = const [],
  });
}

/// Represents a recognized text block (paragraph/section).
class OcrBlock {
  final String text;
  final List<OcrLine> lines;
  final Rect? boundingBox;
  final List<String> recognizedLanguages;

  const OcrBlock({
    required this.text,
    required this.lines,
    this.boundingBox,
    this.recognizedLanguages = const [],
  });
}

/// Comprehensive result of on-device optical character recognition.
class OcrResult {
  final String fullText;
  final List<OcrBlock> blocks;
  final List<OcrLine> lines;
  final bool isSuccess;
  final String? errorMessage;

  const OcrResult({
    required this.fullText,
    required this.blocks,
    required this.lines,
    this.isSuccess = true,
    this.errorMessage,
  });

  factory OcrResult.failure(String error) {
    return OcrResult(
      fullText: '',
      blocks: const [],
      lines: const [],
      isSuccess: false,
      errorMessage: error,
    );
  }

  factory OcrResult.fromText(String text) {
    final splitLines = text.split('\n');
    final ocrLines = splitLines
        .map((l) => OcrLine(text: l.trim()))
        .where((l) => l.text.isNotEmpty)
        .toList();

    return OcrResult(
      fullText: text,
      blocks: [OcrBlock(text: text, lines: ocrLines)],
      lines: ocrLines,
      isSuccess: true,
    );
  }
}
