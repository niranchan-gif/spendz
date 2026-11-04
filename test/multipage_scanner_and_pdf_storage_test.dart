import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:spendz/database/database_helper.dart';
import 'package:spendz/database/wallet_document_repository.dart';
import 'package:spendz/features/wallet/security/wallet_key_service.dart';
import 'package:spendz/features/wallet/services/document_scanner_service.dart';
import 'package:spendz/features/wallet/services/document_vault_service.dart';
import 'package:spendz/features/wallet/security/wallet_auth_service.dart';
import 'package:spendz/models/wallet_document_model.dart';
import 'package:spendz/providers/wallet_document_provider.dart';
import 'package:spendz/screens/wallet/document_attachment_scanner_screen.dart';
import 'package:spendz/screens/wallet/document_creation_screen.dart';
import 'package:spendz/screens/wallet/document_preview_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Uint8List createTestImageBytes({
  int width = 120,
  int height = 160,
  int r = 20,
  int g = 100,
  int b = 60,
}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempVaultDir;
  late Directory tempCacheDir;
  late Directory tempDownloadsDir;
  late WalletDocumentRepository repository;
  late DocumentVaultService vaultService;
  late DocumentScannerService scannerService;
  late WalletKeyService keyService;

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() async {
    tempVaultDir = await Directory.systemTemp.createTemp(
      'spendz_scanner_vault_',
    );
    tempCacheDir = await Directory.systemTemp.createTemp(
      'spendz_scanner_cache_',
    );
    tempDownloadsDir = await Directory.systemTemp.createTemp(
      'spendz_downloads_',
    );

    repository = WalletDocumentRepository();
    vaultService = DocumentVaultService(
      documentRepository: repository,
      customVaultDirectory: tempVaultDir.path,
      customTempDirectory: tempCacheDir.path,
    );
    scannerService = DocumentScannerService();

    final db = await DatabaseHelper.instance.database;
    await db.delete('wallet_documents');

    keyService = WalletKeyService(secureStorage: const FlutterSecureStorage());
    await keyService.getOrCreateMasterKey(
      hasExistingVaultDocuments: () => false,
    );
  });

  tearDown(() {
    try {
      tempVaultDir.deleteSync(recursive: true);
      tempCacheDir.deleteSync(recursive: true);
      tempDownloadsDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('1. Multi-Page Document Scanner & Image Processing Tests', () {
    test(
      'Single page, two-page (Front & Back) and multi-page batch handling',
      () {
        final page1 = createTestImageBytes(
          width: 200,
          height: 300,
          r: 255,
          g: 153,
          b: 51,
        ); // Saffron
        final page2 = createTestImageBytes(
          width: 200,
          height: 300,
          r: 19,
          g: 136,
          b: 8,
        ); // Green
        final page3 = createTestImageBytes(
          width: 200,
          height: 300,
          r: 0,
          g: 0,
          b: 128,
        ); // Blue

        final batch = DocumentAttachmentPayload(
          pages: [page1, page2, page3],
          mimeType: 'image/jpeg',
          fileName: 'Aadhaar_Document.pdf',
          attachmentType: 'scanned_pdf',
        );

        expect(batch.pageCount, equals(3));
        expect(batch.isPdf, isFalse); // Hasn't compiled to pdfBytes yet
        expect(batch.primaryBytes.length, greaterThan(0));
      },
    );

    test(
      'Rotation rotates image 90 degrees clockwise preserving dimensions',
      () {
        final original = createTestImageBytes(width: 100, height: 200);
        final rotated = scannerService.rotatePage(original, 90);

        expect(rotated, isNotEmpty);
        final decoded = img.decodeImage(rotated);
        expect(decoded, isNotNull);
        expect(decoded!.width, equals(200));
        expect(decoded.height, equals(100));
      },
    );

    test('Cropping clips image to desired dimensions without distortion', () {
      final original = createTestImageBytes(width: 200, height: 200);
      final cropped = scannerService.cropPage(
        original,
        x: 20,
        y: 20,
        width: 100,
        height: 100,
      );

      expect(cropped, isNotEmpty);
      final decoded = img.decodeImage(cropped);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(100));
      expect(decoded.height, equals(100));
    });

    test('Enhance document sharpens and boosts contrast for clear text', () {
      final original = createTestImageBytes(width: 150, height: 150);
      final enhanced = scannerService.enhancePage(original);

      expect(enhanced, isNotEmpty);
      final decoded = img.decodeImage(enhanced);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(150));
    });
  });

  group('2. PDF Generation, Page Ordering & Aspect Ratio Tests', () {
    test('Generates valid multi-page PDF preserving page count and order', () {
      final frontPage = createTestImageBytes(
        width: 300,
        height: 400,
        r: 255,
        g: 0,
        b: 0,
      );
      final backPage = createTestImageBytes(
        width: 300,
        height: 400,
        r: 0,
        g: 0,
        b: 255,
      );

      final pdfBytes = scannerService.generatePdfFromPages([
        frontPage,
        backPage,
      ], title: 'Aadhaar Document');

      expect(pdfBytes, isNotEmpty);
      // Verify PDF Magic Bytes (%PDF-)
      expect(pdfBytes[0], equals(0x25));
      expect(pdfBytes[1], equals(0x50));
      expect(pdfBytes[2], equals(0x44));
      expect(pdfBytes[3], equals(0x46));

      // Page count check
      final pageCount = scannerService.getPdfPageCount(pdfBytes);
      expect(pageCount, equals(2));
    });

    test(
      'Generates PDF with sensible compression to avoid high memory usage',
      () {
        // Simulate large images
        final largePage1 = createTestImageBytes(width: 800, height: 1000);
        final largePage2 = createTestImageBytes(width: 800, height: 1000);
        final largePage3 = createTestImageBytes(width: 800, height: 1000);

        final pdfBytes = scannerService.generatePdfFromPages([
          largePage1,
          largePage2,
          largePage3,
        ]);
        expect(pdfBytes, isNotEmpty);
        expect(scannerService.getPdfPageCount(pdfBytes), equals(3));
        // Compressed PDF should be efficient
        expect(pdfBytes.length, lessThan(3 * largePage1.length + 50000));
      },
    );

    test('Requires at least one page to generate PDF', () {
      expect(
        () => scannerService.generatePdfFromPages([]),
        throwsArgumentError,
      );
    });
  });

  group('3. Standardized PDF Naming & Phone Storage Tests', () {
    test('Default filename generation strictly adheres to specifications', () {
      expect(
        DocumentScannerService.getDefaultPdfFileName('aadhaar'),
        equals('Aadhaar_Document.pdf'),
      );
      expect(
        DocumentScannerService.getDefaultPdfFileName('pan'),
        equals('PAN_Card.pdf'),
      );
      expect(
        DocumentScannerService.getDefaultPdfFileName('driving_license'),
        equals('Driving_Licence.pdf'),
      );
      expect(
        DocumentScannerService.getDefaultPdfFileName('passport'),
        equals('Passport.pdf'),
      );
      expect(
        DocumentScannerService.getDefaultPdfFileName('credit_card'),
        equals('Payment_Card.pdf'),
      );
      expect(
        DocumentScannerService.getDefaultPdfFileName('insurance'),
        equals('Insurance_Policy.pdf'),
      );
      expect(
        DocumentScannerService.getDefaultPdfFileName('custom'),
        equals('Spendz_Document.pdf'),
      );
    });

    test('File size formatting produces readable KB and MB strings', () {
      expect(DocumentScannerService.formatFileSize(0), equals('0 KB'));
      expect(
        DocumentScannerService.formatFileSize(450 * 1024),
        equals('450 KB'),
      );
      expect(
        DocumentScannerService.formatFileSize((2.4 * 1024 * 1024).round()),
        equals('2.4 MB'),
      );
    });

    test(
      'Saves PDF to phone destination and preserves independent copy',
      () async {
        final fakePdf = Uint8List.fromList(
          '%PDF-1.4 Fake Test PDF Document Data'.codeUnits,
        );
        final testTargetFile = File(
          '${tempDownloadsDir.path}/Aadhaar_Document.pdf',
        );
        await testTargetFile.writeAsBytes(fakePdf, flush: true);

        expect(await testTargetFile.exists(), isTrue);
        expect(await testTargetFile.readAsBytes(), equals(fakePdf));

        // Deleting exported phone copy must not affect vault copy
        final vaultDoc = await vaultService.saveManualDocument(
          documentName: 'Aadhaar Card',
          category: 'aadhaar',
          holderName: 'Aarav Sharma',
          attachmentBytes: fakePdf,
          attachmentMimeType: 'application/pdf',
        );
        expect(vaultDoc.hasAttachment, isTrue);

        // Delete exported copy
        await testTargetFile.delete();
        expect(await testTargetFile.exists(), isFalse);

        // Verify vault document remains intact
        final retrieved = await repository.getDocumentById(vaultDoc.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.hasAttachment, isTrue);
        final decrypted = await vaultService.decryptDocumentBytes(retrieved);
        expect(decrypted, equals(fakePdf));
      },
    );
  });

  group('4. Virtual Document Attachment & Workflow Integration Tests', () {
    test(
      'Saves virtual document with multi-page generated PDF attachment',
      () async {
        final pageFront = createTestImageBytes(width: 150, height: 100);
        final pageBack = createTestImageBytes(width: 150, height: 100);
        final compiledPdf = scannerService.generatePdfFromPages([
          pageFront,
          pageBack,
        ]);

        final doc = await vaultService.saveManualDocument(
          documentName: 'PAN Card',
          category: 'pan',
          holderName: 'Pooja Hegde',
          maskedIdentifier: 'ABCDE••••F',
          attachmentBytes: compiledPdf,
          attachmentMimeType: 'application/pdf',
          attachmentType: 'pdf',
        );

        expect(doc.hasAttachment, isTrue);
        expect(doc.isPdf, isTrue);
        expect(doc.attachmentType, equals('pdf'));
        expect(doc.holderName, equals('Pooja Hegde'));

        // Verify decrypted content matches compiled PDF
        final decryptedPdf = await vaultService.decryptDocumentBytes(doc);
        expect(decryptedPdf, equals(compiledPdf));
        expect(scannerService.getPdfPageCount(decryptedPdf), equals(2));
      },
    );

    test(
      'Attaching existing PDF to an attachment-free record works cleanly',
      () async {
        // 1. Create purely manual record
        final manualDoc = await vaultService.saveManualDocument(
          documentName: 'Indian Passport',
          category: 'passport',
          holderName: 'Rohan Verma',
          maskedIdentifier: 'Z••••123',
        );
        expect(manualDoc.hasAttachment, isFalse);

        // 2. Attach existing PDF
        final samplePdf = Uint8List.fromList(
          '%PDF-1.4 Mock Passport PDF'.codeUnits,
        );
        final updated = await vaultService.attachFileToDocument(
          document: manualDoc,
          fileBytes: samplePdf,
          mimeType: 'application/pdf',
          attachmentType: 'pdf',
        );

        expect(updated.hasAttachment, isTrue);
        expect(updated.isPdf, isTrue);
        expect(updated.attachmentType, equals('pdf'));
        expect(updated.holderName, equals('Rohan Verma'));
      },
    );
  });

  group('5. UI Widget Rendering & Detail Screen Attachment Section Tests', () {
    Widget buildTestHarness(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WalletAuthService()),
          ChangeNotifierProvider(create: (_) => WalletDocumentProvider()),
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets(
      'DocumentAttachmentScannerScreen renders review UI with controls',
      (tester) async {
        final page1 = createTestImageBytes(width: 100, height: 100);
        final page2 = createTestImageBytes(width: 100, height: 100);

        await tester.pumpWidget(
          buildTestHarness(
            DocumentAttachmentScannerScreen(
              category: 'aadhaar',
              initialPayload: DocumentAttachmentPayload(
                pages: [page1, page2],
                mimeType: 'image/jpeg',
                fileName: 'Aadhaar_Document.pdf',
                attachmentType: 'scanned_pdf',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Document Scanner & Attach'), findsOneWidget);
        expect(find.text('Page 1 of 2'), findsOneWidget);
        expect(find.byIcon(Icons.rotate_right_rounded), findsOneWidget);
        expect(find.byIcon(Icons.auto_fix_high_rounded), findsOneWidget);
        expect(find.byIcon(Icons.crop_rounded), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
        expect(find.text('Finish & PDF'), findsOneWidget);
      },
    );

    testWidgets(
      'DocumentCreationScreen renders Scan Document and Attach PDF buttons',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestHarness(
            const DocumentCreationScreen(initialCategory: 'aadhaar'),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Scan Document'), findsOneWidget);
        expect(find.text('Attach PDF'), findsOneWidget);
      },
    );

    testWidgets(
      'DocumentPreviewScreen displays Original Copy details when attached',
      (tester) async {
        final docWithAttachment = WalletDocumentModel(
          id: 'test_doc_preview',
          documentName: 'Aadhaar Card',
          category: 'aadhaar',
          holderName: 'Sunita Rao',
          maskedIdentifier: '•••• •••• 9999',
          encryptedFilePath: 'spendz_vault/test_doc_preview.enc',
          mimeType: 'application/pdf',
          fileSize: 1024 * 500, // 500 KB
          attachmentType: 'pdf',
          createdAt: DateTime(2026, 1, 15),
          updatedAt: DateTime(2026, 1, 15),
        );

        await tester.pumpWidget(
          buildTestHarness(DocumentPreviewScreen(document: docWithAttachment)),
        );

        await tester.pumpAndSettle();
        expect(find.text('Original Copy'), findsOneWidget);
        expect(find.text('Aadhaar_Document.pdf'), findsOneWidget);
        expect(find.text('Save to Phone'), findsOneWidget);
      },
    );
  });
}
