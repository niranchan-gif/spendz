import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

import '../../../models/wallet_document_model.dart';

/// Service for exporting, downloading, and sharing documents from the secure vault.
class DocumentExportService {
  /// Generates a professional PDF containing the document metadata and original scan.
  Future<File> generateDocumentPdf({
    required WalletDocumentModel document,
    required Uint8List decryptedBytes,
    String? secureDocNumber,
  }) async {
    final isPdfBytes =
        decryptedBytes.length >= 4 &&
        decryptedBytes[0] == 0x25 &&
        decryptedBytes[1] == 0x50 &&
        decryptedBytes[2] == 0x44 &&
        decryptedBytes[3] == 0x46;
    final isPdf = isPdfBytes || document.mimeType.contains('pdf');
    final tempDir = await getTemporaryDirectory();
    final fileName =
        'spendz_export_${document.documentName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')}_${const Uuid().v4().substring(0, 8)}.pdf';
    final targetFile = File('${tempDir.path}/$fileName');

    if (isPdf && decryptedBytes.isNotEmpty) {
      // If the original was already a PDF, write it directly
      await targetFile.writeAsBytes(decryptedBytes, flush: true);
      return targetFile;
    }

    // Build a structured PDF document
    final pdfDoc = PdfDocument();
    pdfDoc.pageSettings.margins.all = 36; // 0.5 inch margins

    final page = pdfDoc.pages.add();
    final graphics = page.graphics;
    final pageSize = page.getClientSize();

    // Color palette
    final primaryColor = PdfColor(39, 56, 34); // Deep Olive
    final secondaryColor = PdfColor(74, 98, 66); // Muted Sage
    final textColor = PdfColor(28, 29, 26);
    final mutedTextColor = PdfColor(104, 112, 99);
    final borderColor = PdfColor(220, 224, 218);

    // Fonts
    final titleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      18,
      style: PdfFontStyle.bold,
    );
    final subtitleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      11,
      style: PdfFontStyle.bold,
    );
    final regularFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final boldFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      10,
      style: PdfFontStyle.bold,
    );
    final captionFont = PdfStandardFont(PdfFontFamily.helvetica, 8);

    double currentY = 0;

    // Header bar
    graphics.drawRectangle(
      brush: PdfSolidBrush(primaryColor),
      bounds: Rect.fromLTWH(0, currentY, pageSize.width, 40),
    );

    graphics.drawString(
      'SPENDZ SECURE VAULT DOCUMENT',
      titleFont,
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      bounds: Rect.fromLTWH(12, currentY + 10, pageSize.width - 24, 24),
    );

    currentY += 52;

    // Document title & category
    graphics.drawString(
      document.documentName,
      titleFont,
      brush: PdfSolidBrush(textColor),
      bounds: Rect.fromLTWH(0, currentY, pageSize.width, 24),
    );
    currentY += 26;

    final categoryDisplay = document.category
        .replaceAll('_', ' ')
        .toUpperCase();
    graphics.drawString(
      'Category: $categoryDisplay',
      subtitleFont,
      brush: PdfSolidBrush(secondaryColor),
      bounds: Rect.fromLTWH(0, currentY, pageSize.width, 16),
    );
    currentY += 22;

    // Metadata Summary Grid
    final metadataRows = <MapEntry<String, String>>[];
    if (secureDocNumber != null && secureDocNumber.isNotEmpty) {
      metadataRows.add(MapEntry('Document Number', secureDocNumber));
    }
    if (document.issueDate != null) {
      metadataRows.add(
        MapEntry(
          'Issue Date',
          DateFormat('dd MMM yyyy').format(document.issueDate!),
        ),
      );
    }
    if (document.expiryDate != null) {
      metadataRows.add(
        MapEntry(
          'Expiry Date',
          DateFormat('dd MMM yyyy').format(document.expiryDate!),
        ),
      );
    }
    metadataRows.add(
      MapEntry(
        'Exported On',
        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
      ),
    );

    // Draw Metadata Table
    for (final entry in metadataRows) {
      graphics.drawString(
        '${entry.key}:',
        boldFont,
        brush: PdfSolidBrush(mutedTextColor),
        bounds: Rect.fromLTWH(0, currentY, 140, 16),
      );
      graphics.drawString(
        entry.value,
        regularFont,
        brush: PdfSolidBrush(textColor),
        bounds: Rect.fromLTWH(145, currentY, pageSize.width - 145, 16),
      );
      currentY += 18;
    }

    if (document.description != null && document.description!.isNotEmpty) {
      currentY += 6;
      graphics.drawString(
        'Details & Extracted Notes:',
        boldFont,
        brush: PdfSolidBrush(secondaryColor),
        bounds: Rect.fromLTWH(0, currentY, pageSize.width, 16),
      );
      currentY += 18;

      graphics.drawString(
        document.description!,
        regularFont,
        brush: PdfSolidBrush(textColor),
        bounds: Rect.fromLTWH(0, currentY, pageSize.width, 40),
      );
      currentY += 46;
    }

    // Divider line
    currentY += 8;
    graphics.drawLine(
      PdfPen(borderColor, width: 1),
      Offset(0, currentY),
      Offset(pageSize.width, currentY),
    );
    currentY += 16;

    if (decryptedBytes.isNotEmpty) {
      // Scanned Image Section
      graphics.drawString(
        'ORIGINAL SCANNED DOCUMENT',
        subtitleFont,
        brush: PdfSolidBrush(secondaryColor),
        bounds: Rect.fromLTWH(0, currentY, pageSize.width, 16),
      );
      currentY += 20;

      try {
        final pdfBitmap = PdfBitmap(decryptedBytes);
        final remainingHeight = pageSize.height - currentY - 24;

        // Calculate aspect-ratio preserved dimensions
        double imgWidth = pageSize.width;
        double imgHeight = (pdfBitmap.height / pdfBitmap.width) * imgWidth;

        if (imgHeight > remainingHeight) {
          imgHeight = remainingHeight;
          imgWidth = (pdfBitmap.width / pdfBitmap.height) * imgHeight;
        }

        final imgX = (pageSize.width - imgWidth) / 2;

        // Draw light border around image
        graphics.drawRectangle(
          pen: PdfPen(borderColor, width: 1),
          bounds: Rect.fromLTWH(
            imgX - 1,
            currentY - 1,
            imgWidth + 2,
            imgHeight + 2,
          ),
        );

        graphics.drawImage(
          pdfBitmap,
          Rect.fromLTWH(imgX, currentY, imgWidth, imgHeight),
        );
        currentY += imgHeight + 8;
      } catch (e) {
        debugPrint(
          '[DocumentExportService] Error rendering bitmap into PDF: $e',
        );
      }
    } else {
      // Virtual ID Card representation when no physical file attached
      currentY += 10;
      final cardRect = Rect.fromLTWH(0, currentY, pageSize.width, 130);
      graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(245, 248, 244)),
        pen: PdfPen(secondaryColor, width: 1.5),
        bounds: cardRect,
      );

      // Card Header
      graphics.drawRectangle(
        brush: PdfSolidBrush(primaryColor),
        bounds: Rect.fromLTWH(0, currentY, pageSize.width, 28),
      );
      graphics.drawString(
        'VIRTUAL ${document.category.replaceAll("_", " ").toUpperCase()} CARD',
        subtitleFont,
        brush: PdfSolidBrush(PdfColor(255, 255, 255)),
        bounds: Rect.fromLTWH(12, currentY + 6, pageSize.width - 24, 18),
      );

      // Card Content
      final contentY = currentY + 38;
      final displayHolder = document.holderName ?? 'Verified Cardholder';
      final displayNumber =
          secureDocNumber ?? document.maskedIdentifier ?? '•••• •••• ••••';

      graphics.drawString(
        'NAME: $displayHolder',
        boldFont,
        brush: PdfSolidBrush(textColor),
        bounds: Rect.fromLTWH(16, contentY, pageSize.width - 32, 16),
      );
      graphics.drawString(
        'NUMBER: $displayNumber',
        boldFont,
        brush: PdfSolidBrush(secondaryColor),
        bounds: Rect.fromLTWH(16, contentY + 22, pageSize.width - 32, 16),
      );
      graphics.drawString(
        'AUTHENTIC SPENDZ 2.0 DIGITAL VAULT RECORD • HARDWARE BACKED',
        captionFont,
        brush: PdfSolidBrush(mutedTextColor),
        bounds: Rect.fromLTWH(16, contentY + 54, pageSize.width - 32, 14),
      );
      currentY += 150;
    }

    // Footer
    graphics.drawString(
      'Encrypted by Spendz 2.0 • Hardware Keystore & AES-256-GCM authenticated vault',
      captionFont,
      brush: PdfSolidBrush(mutedTextColor),
      bounds: Rect.fromLTWH(0, pageSize.height - 12, pageSize.width, 12),
    );

    final bytes = await pdfDoc.save();
    pdfDoc.dispose();

    await targetFile.writeAsBytes(bytes, flush: true);
    return targetFile;
  }

  /// Exports and saves the decrypted original file to the public Downloads folder.
  Future<File?> downloadOriginalToDevice({
    required WalletDocumentModel document,
    required Uint8List decryptedBytes,
  }) async {
    try {
      final ext = document.mimeType.contains('pdf') ? 'pdf' : 'jpg';
      final cleanName = document.documentName.replaceAll(
        RegExp(r'[^a-zA-Z0-9_\-]'),
        '_',
      );
      final fileName =
          '${cleanName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.$ext';

      Directory? targetDir;
      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Download');
        if (!await targetDir.exists()) {
          targetDir = await getExternalStorageDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      targetDir ??= await getApplicationDocumentsDirectory();

      final destinationFile = File('${targetDir.path}/$fileName');
      await destinationFile.writeAsBytes(decryptedBytes, flush: true);
      return destinationFile;
    } catch (e) {
      debugPrint('[DocumentExportService] Download error: $e');
      return null;
    }
  }

  /// Safely shares the document using system share sheet.
  Future<void> shareDocument({
    required WalletDocumentModel document,
    required Uint8List decryptedBytes,
    String? secureDocNumber,
  }) async {
    try {
      final pdfFile = await generateDocumentPdf(
        document: document,
        decryptedBytes: decryptedBytes,
        secureDocNumber: secureDocNumber,
      );

      final xFile = XFile(
        pdfFile.path,
        name: '${document.documentName}.pdf',
        mimeType: 'application/pdf',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Spendz Document: ${document.documentName}',
          subject: document.documentName,
        ),
      );
    } catch (e) {
      debugPrint('[DocumentExportService] Share error: $e');
      rethrow;
    }
  }
}
