import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../models/wallet_document_model.dart';

/// Service for exporting, downloading, and sharing documents from the secure vault.
class DocumentExportService {
  /// Exports the decrypted document PDF. Throws FileSystemException if no PDF attachment exists.
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
        decryptedBytes[3] == 0x46; // %PDF
    final isPdf = isPdfBytes ||
        document.mimeType.toLowerCase().contains('pdf') ||
        document.attachmentType.toLowerCase().contains('pdf');

    if (!isPdf || decryptedBytes.isEmpty) {
      throw const FileSystemException('No PDF attachment found to export.');
    }

    final tempDir = await getTemporaryDirectory();
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    final cleanName =
        document.documentName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final safeName = cleanName.isEmpty ? 'document' : cleanName;
    final fileName =
        'spendz_export_${safeName}_${const Uuid().v4().substring(0, 8)}.pdf';
    final targetFile = File('${tempDir.path}/$fileName');

    await targetFile.writeAsBytes(decryptedBytes, flush: true);
    if (!await targetFile.exists()) {
      throw FileSystemException(
        'Failed to write exported PDF to disk',
        targetFile.path,
      );
    }
    return targetFile;
  }

  /// Exports and saves the decrypted original file to the public Downloads folder.
  Future<File?> downloadOriginalToDevice({
    required WalletDocumentModel document,
    required Uint8List decryptedBytes,
  }) async {
    try {
      final isPdfBytes =
          decryptedBytes.length >= 4 &&
          decryptedBytes[0] == 0x25 &&
          decryptedBytes[1] == 0x50 &&
          decryptedBytes[2] == 0x44 &&
          decryptedBytes[3] == 0x46;
      final isPdf = isPdfBytes ||
          document.mimeType.toLowerCase().contains('pdf') ||
          document.attachmentType.toLowerCase().contains('pdf');
      final ext = isPdf
          ? 'pdf'
          : (document.mimeType.toLowerCase().contains('png') ? 'png' : 'jpg');
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

  /// Safely shares the user's actual document attachment using the system share sheet.
  Future<void> shareDocument({
    required WalletDocumentModel document,
    required Uint8List decryptedBytes,
    String? secureDocNumber,
  }) async {
    if (!document.hasAttachment || decryptedBytes.isEmpty) {
      throw const FileSystemException('No attachment found to share.');
    }

    final isPdfBytes =
        decryptedBytes.length >= 4 &&
        decryptedBytes[0] == 0x25 &&
        decryptedBytes[1] == 0x50 &&
        decryptedBytes[2] == 0x44 &&
        decryptedBytes[3] == 0x46; // %PDF
    final isPdf = isPdfBytes ||
        document.mimeType.toLowerCase().contains('pdf') ||
        document.attachmentType.toLowerCase().contains('pdf');

    final tempDir = await getTemporaryDirectory();
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }

    final cleanName =
        document.documentName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final safeName = cleanName.isEmpty ? 'document' : cleanName;
    final ext = isPdf
        ? 'pdf'
        : (document.mimeType.toLowerCase().contains('png') ? 'png' : 'jpg');
    final mimeType = isPdf ? 'application/pdf' : 'image/$ext';

    final targetFile = File(
      '${tempDir.path}/spendz_${safeName}_${const Uuid().v4().substring(0, 8)}.$ext',
    );
    await targetFile.writeAsBytes(decryptedBytes, flush: true);
    if (!await targetFile.exists()) {
      throw FileSystemException(
        'Failed to prepare file for sharing',
        targetFile.path,
      );
    }

    final xFile = XFile(
      targetFile.path,
      name: '${document.documentName}.$ext',
      mimeType: mimeType,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        text: 'Spendz: ${document.documentName}',
        subject: document.documentName,
      ),
    );
  }
}
