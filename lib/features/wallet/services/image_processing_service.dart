import 'dart:typed_data';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Pure Dart image processing service for document scanning, enhancement, and PDF generation.
///
/// Features:
/// - Perspective correction / manual cropping
/// - Contrast adjustment
/// - Grayscale conversion
/// - Document clean/enhancement filter (sharpening + adaptive contrast)
/// - Resolution optimization & compression
/// - Multi-page PDF generation via Syncfusion PDF
class ImageProcessingService {
  /// Converts an image to grayscale using luminance weights.
  Uint8List toGrayscale(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    final grayscale = img.grayscale(image);
    return Uint8List.fromList(img.encodeJpg(grayscale, quality: 90));
  }

  /// Adjusts image contrast (e.g. 1.25 for +25% contrast).
  Uint8List adjustContrast(Uint8List imageBytes, {double contrast = 1.3}) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    final adjusted = img.adjustColor(image, contrast: contrast);
    return Uint8List.fromList(img.encodeJpg(adjusted, quality: 90));
  }

  /// Enhances document text readability:
  /// Applies grayscale, boosts contrast, and sharpens text contours.
  Uint8List enhanceDocument(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    // 1. Convert to grayscale for clean background
    var processed = img.grayscale(image);

    // 2. Enhance contrast to separate text from background shadows
    processed = img.adjustColor(processed, contrast: 1.45, brightness: 1.05);

    // 3. Subtle sharpening to define text edges
    processed = img.convolution(
      processed,
      filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
      div: 1,
    );

    return Uint8List.fromList(img.encodeJpg(processed, quality: 92));
  }

  /// Rotates image clockwise by [angleDegrees] (90, 180, 270).
  Uint8List rotateImage(Uint8List imageBytes, int angleDegrees) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    final rotated = img.copyRotate(image, angle: angleDegrees.toDouble());
    return Uint8List.fromList(img.encodeJpg(rotated, quality: 90));
  }

  /// Crops an image to [x], [y], [width], [height].
  Uint8List cropImage(
    Uint8List imageBytes, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    // Clamp coordinates to image boundaries
    final clampedX = x.clamp(0, image.width - 1);
    final clampedY = y.clamp(0, image.height - 1);
    final clampedW = width.clamp(1, image.width - clampedX);
    final clampedH = height.clamp(1, image.height - clampedY);

    final cropped = img.copyCrop(
      image,
      x: clampedX,
      y: clampedY,
      width: clampedW,
      height: clampedH,
    );

    return Uint8List.fromList(img.encodeJpg(cropped, quality: 90));
  }

  /// Compresses and scales down an image if it exceeds [maxDimension],
  /// preserving readability while reducing storage footprint.
  Uint8List compressAndOptimize(
    Uint8List imageBytes, {
    int maxDimension = 2048,
    int quality = 85,
  }) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    img.Image target = image;
    if (image.width > maxDimension || image.height > maxDimension) {
      if (image.width >= image.height) {
        target = img.copyResize(image, width: maxDimension);
      } else {
        target = img.copyResize(image, height: maxDimension);
      }
    }

    return Uint8List.fromList(img.encodeJpg(target, quality: quality));
  }

  /// Generates a PDF containing the provided [pageImagesBytes] in order.
  Uint8List createPdfFromImages(
    List<Uint8List> pageImagesBytes, {
    String title = 'Scanned Document',
  }) {
    if (pageImagesBytes.isEmpty) {
      throw ArgumentError('At least one page is required to generate a PDF.');
    }

    final PdfDocument document = PdfDocument();
    document.documentInformation.title = title;
    document.documentInformation.author = 'Spendz 2.0 Smart Vault';
    document.documentInformation.producer = 'Spendz Smart Document Scanner';

    for (final pageBytes in pageImagesBytes) {
      final PdfBitmap bitmap = PdfBitmap(pageBytes);
      final PdfPage page = document.pages.add();

      // Fit image within the PDF page maintaining aspect ratio
      final double pageWidth = page.getClientSize().width;
      final double pageHeight = page.getClientSize().height;

      final double scaleX = pageWidth / bitmap.width;
      final double scaleY = pageHeight / bitmap.height;
      final double scale = scaleX < scaleY ? scaleX : scaleY;

      final double renderWidth = bitmap.width * scale;
      final double renderHeight = bitmap.height * scale;
      final double offsetX = (pageWidth - renderWidth) / 2;
      final double offsetY = (pageHeight - renderHeight) / 2;

      page.graphics.drawImage(
        bitmap,
        Rect.fromLTWH(offsetX, offsetY, renderWidth, renderHeight),
      );
    }

    final List<int> pdfBytes = document.saveSync();
    document.dispose();
    return Uint8List.fromList(pdfBytes);
  }
}
