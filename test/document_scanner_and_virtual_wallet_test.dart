import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:spendz/features/wallet/ocr/document_classifier.dart';
import 'package:spendz/features/wallet/ocr/document_field_extractor.dart';
import 'package:spendz/features/wallet/ocr/document_ocr_service.dart';
import 'package:spendz/features/wallet/services/document_export_service.dart';
import 'package:spendz/models/wallet_document_model.dart';
import 'package:spendz/screens/wallet/widgets/virtual_document_card.dart';

Uint8List _generateSampleImageBytes({int width = 300, int height = 200}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(240, 240, 240));
  for (int x = 10; x < width - 10; x += 15) {
    for (int y = 10; y < height - 10; y += 20) {
      image.setPixelRgb(x, y, 30, 30, 30);
    }
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 85));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('spendz_test_docs_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => tempDir.path,
        );
  });

  tearDownAll(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('Document OCR Engine & Error Handling Tests', () {
    test(
      'Handles non-existent image file path gracefully without crashing',
      () async {
        final engine = MlKitOcrEngine();
        final result = await engine.processImagePath(
          '/path/to/non_existent_file.jpg',
        );
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('does not exist'));
      },
    );

    test('Handles empty image bytes gracefully', () async {
      final engine = MlKitOcrEngine();
      final result = await engine.processImageBytes(Uint8List(0));
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('empty'));
    });

    test(
      'Detects PDF magic bytes and avoids invalid bitmap decoding',
      () async {
        final engine = MlKitOcrEngine();
        // Dummy PDF starting with %PDF-1.4
        final dummyPdfBytes = Uint8List.fromList([
          0x25,
          0x50,
          0x44,
          0x46,
          0x2D,
          0x31,
          0x2E,
          0x34,
          0x0A,
          ...List.filled(50, 0x20),
        ]);
        final result = await engine.processImageBytes(dummyPdfBytes);
        expect(result.isSuccess, isTrue);
      },
    );

    test(
      'MockOcrEngine handles failure and success modes deterministically',
      () async {
        final mock = MockOcrEngine(predefinedText: 'TEST DOCUMENT TEXT');
        final res = await mock.processImagePath('any.jpg');
        expect(res.isSuccess, isTrue);
        expect(res.fullText, 'TEST DOCUMENT TEXT');

        mock.shouldFail = true;
        final failRes = await mock.processImagePath('any.jpg');
        expect(failRes.isSuccess, isFalse);
      },
    );
  });

  group('Document Classification Tests Across All Categories', () {
    late DocumentClassifier classifier;

    setUp(() {
      classifier = DocumentClassifier();
    });

    test('Classifies Debit Card with high confidence', () {
      const text = '''
HDFC BANK DEBIT CARD
4111 2222 3333 4444
VALID THRU 08/29
VISA PLATINUM
ROHIT SHARMA
''';
      final res = classifier.classify(text);
      expect(res.category, 'debit_card');
      expect(res.isHighConfidence, isTrue);
      expect(res.displayCategoryName, 'Debit Card');
    });

    test('Classifies Credit Card with high confidence', () {
      const text = '''
ICICI BANK CREDIT CARD
5241 8899 7766 1234
VALID THRU 11/28
MASTERCARD REWARDS PLATINUM
PRIYA PATEL
''';
      final res = classifier.classify(text);
      expect(res.category, 'credit_card');
      expect(res.isHighConfidence, isTrue);
      expect(res.displayCategoryName, 'Credit Card');
    });

    test('Classifies Voter ID with high confidence', () {
      const text = '''
ELECTION COMMISSION OF INDIA
भारत निर्वाचन आयोग
ELECTOR'S PHOTO IDENTITY CARD
EPIC NO: WBF1234567
NAME: ANAND VERMA
FATHER'S NAME: RAMESH VERMA
ASSEMBLY CONSTITUENCY: 154
''';
      final res = classifier.classify(text);
      expect(res.category, 'voter_id');
      expect(res.isHighConfidence, isTrue);
      expect(res.displayCategoryName, 'Voter ID');
    });

    test('Classifies Bank Document with high confidence', () {
      const text = '''
STATE BANK OF INDIA
STATEMENT OF ACCOUNT
ACCOUNT NO: 201889912345
IFSC: SBIN0001234
SAVINGS ACCOUNT BRANCH MUMBAI
OPENING BALANCE: 45000.00
CLOSING BALANCE: 52000.00
''';
      final res = classifier.classify(text);
      expect(res.category, 'bank_document');
      expect(res.isHighConfidence, isTrue);
      expect(res.displayCategoryName, 'Bank Document');
    });

    test('Classifies Aadhaar Card with high confidence', () {
      const text = '''
GOVERNMENT OF INDIA
UNIQUE IDENTIFICATION AUTHORITY OF INDIA
MERA AADHAAR MERI PEHCHAN
1234 5678 9012
NAME: SNEHA GUPTA
DOB: 14/05/1995
GENDER: FEMALE
''';
      final res = classifier.classify(text);
      expect(res.category, 'aadhaar');
      expect(res.isHighConfidence, isTrue);
      expect(res.displayCategoryName, 'Aadhaar Card');
    });

    test('Classifies PAN Card with high confidence', () {
      const text = '''
INCOME TAX DEPARTMENT
GOVT. OF INDIA
PERMANENT ACCOUNT NUMBER CARD
ABCDE1234F
NAME: VIKRAM MALHOTRA
FATHER'S NAME: RAJESH MALHOTRA
DATE OF BIRTH: 22/10/1988
''';
      final res = classifier.classify(text);
      expect(res.category, 'pan');
      expect(res.isHighConfidence, isTrue);
      expect(res.displayCategoryName, 'PAN Card');
    });

    test('Classifies Driving Licence with high confidence', () {
      const text = '''
UNION OF INDIA DRIVING LICENCE
TRANSPORT DEPARTMENT
DL-0420110012345
NAME: KARAN JOSHI
AUTHORISATION TO DRIVE: LMV, MCWG
VALID TILL: 25/12/2032
''';
      final res = classifier.classify(text);
      expect(res.category, 'driving_license');
      expect(res.isHighConfidence, isTrue);
      expect(res.displayCategoryName, 'Driving Licence');
    });

    test('Classifies Passport with high confidence', () {
      const text = '''
REPUBLIC OF INDIA
PASSPORT
PASSEPORT
CODE IND
PASSPORT NO: K1234567
GIVEN NAME: ADITYA
SURNAME: ROY
NATIONALITY: INDIAN
P<INDROY<<ADITYA<<<<<<<<<<<<<<<<<<<
''';
      final res = classifier.classify(text);
      expect(res.category, 'passport');
      expect(res.isHighConfidence, isTrue);
      expect(res.displayCategoryName, 'Passport');
    });

    test('Classifies Insurance Policy with high confidence', () {
      const text = '''
STAR HEALTH AND ALLIED INSURANCE
CERTIFICATE OF INSURANCE / POLICY SCHEDULE
POLICY NUMBER: P/123456/01/2024
HEALTH INSURANCE POLICY
SUM INSURED: 500000
PERIOD OF INSURANCE: 01/01/2024 TO 31/12/2025
''';
      final res = classifier.classify(text);
      expect(res.category, 'insurance');
      expect(res.isHighConfidence, isTrue);
      expect(res.displayCategoryName, 'Insurance Policy');
    });

    test('Uncertain text defaults to other/unclassified category', () {
      const text = 'Grocery receipt with apples, oranges, bread, total 450 rs';
      final res = classifier.classify(text);
      expect(res.category, 'other');
      expect(res.isHighConfidence, isFalse);
    });
  });

  group('Intelligent OCR-to-Field Mapping Tests', () {
    late DocumentFieldExtractor extractor;

    setUp(() {
      extractor = DocumentFieldExtractor();
    });

    test(
      'Extracts Debit Card fields accurately with masked card number and no CVV',
      () {
        const text = '''
HDFC BANK DEBIT CARD
4111 2222 3333 4444
VALID THRU 08/29
VISA PLATINUM
ROHIT SHARMA
CVV 123
''';
        final fields = extractor.extract(rawText: text, category: 'debit_card');
        expect(fields.documentNumber, '•••• •••• •••• 4444');
        expect(fields.rawDocumentNumber, '4111222233334444');
        expect(fields.cardNetwork, 'Visa');
        expect(fields.issuingBank, 'HDFC Bank');
        expect(fields.expiryDate?.month, 8);
        expect(fields.expiryDate?.year, 2029);
        expect(fields.holderName, 'ROHIT SHARMA');
        // Ensure CVV is NEVER extracted into any field
        expect(fields.documentNumber, isNot(contains('123')));
        expect(fields.holderName, isNot(contains('123')));
      },
    );

    test('Extracts Aadhaar fields with masked 12-digit number and address', () {
      const text = '''
GOVERNMENT OF INDIA
UNIQUE IDENTIFICATION AUTHORITY OF INDIA
NAME: SNEHA GUPTA
DOB: 14/05/1995
GENDER: FEMALE
ADDRESS: 123 BAKER STREET, SECTOR 4, PUNE 411001
1234 5678 9012
''';
      final fields = extractor.extract(rawText: text, category: 'aadhaar');
      expect(fields.documentNumber, '•••• •••• 9012');
      expect(fields.rawDocumentNumber, '1234 5678 9012');
      expect(fields.gender, 'Female');
      expect(fields.dob?.year, 1995);
      expect(fields.dob?.month, 5);
      expect(fields.dob?.day, 14);
      expect(fields.address, contains('123 BAKER STREET'));
    });

    test('Extracts PAN Card fields with father name and DOB', () {
      const text = '''
INCOME TAX DEPARTMENT
GOVT. OF INDIA
ABCDE1234F
NAME: VIKRAM MALHOTRA
FATHER'S NAME: RAJESH MALHOTRA
DATE OF BIRTH: 22/10/1988
''';
      final fields = extractor.extract(rawText: text, category: 'pan');
      expect(fields.documentNumber, 'ABCDE1234F');
      expect(fields.fatherName, 'RAJESH MALHOTRA');
      expect(fields.dob?.year, 1988);
      expect(fields.dob?.month, 10);
      expect(fields.dob?.day, 22);
    });

    test('Extracts Driving Licence vehicle classes and validity date', () {
      const text = '''
UNION OF INDIA DRIVING LICENCE
DL-0420110012345
NAME: KARAN JOSHI
AUTHORISATION TO DRIVE: LMV, MCWG
VALID TILL: 25/12/2032
''';
      final fields = extractor.extract(
        rawText: text,
        category: 'driving_license',
      );
      expect(fields.documentNumber, 'DL-0420110012345');
      expect(fields.vehicleCategories, contains('LMV'));
      expect(fields.vehicleCategories, contains('MCWG'));
      expect(fields.expiryDate?.year, 2032);
      expect(fields.expiryDate?.month, 12);
      expect(fields.expiryDate?.day, 25);
    });

    test('Extracts Voter ID EPIC number and elector name', () {
      const text = '''
ELECTION COMMISSION OF INDIA
EPIC NO: WBF1234567
ELECTOR NAME: ANAND VERMA
FATHER'S NAME: RAMESH VERMA
''';
      final fields = extractor.extract(rawText: text, category: 'voter_id');
      expect(fields.documentNumber, 'WBF1234567');
      expect(fields.fatherName, 'RAMESH VERMA');
    });

    test('Preserves unclassified text lines for user review', () {
      const text = '''
INCOME TAX DEPARTMENT
ABCDE1234F
NAME: VIKRAM MALHOTRA
UNRECOGNIZED SPECIAL CLAUSE REF 49A
MISCELLANEOUS STAMP 9988
''';
      final fields = extractor.extract(rawText: text, category: 'pan');
      expect(fields.unclassifiedLines.isNotEmpty, isTrue);
      expect(
        fields.unclassifiedLines.any(
          (l) => l.contains('UNRECOGNIZED SPECIAL CLAUSE'),
        ),
        isTrue,
      );
    });
  });

  group('Virtual Document Card Widget Rendering Tests', () {
    testWidgets('Renders Debit Card without overflows', (tester) async {
      final doc = WalletDocumentModel(
        id: 'doc-1',
        documentName: 'HDFC Millennia Debit Card',
        category: 'debit_card',
        description:
            'Holder: ROHIT SHARMA\nNumber: •••• •••• •••• 4444\nBank: HDFC Bank\nNetwork: Visa',
        encryptedFilePath: '/fake/path.enc',
        mimeType: 'image/jpeg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: VirtualDocumentCard(document: doc),
              ),
            ),
          ),
        ),
      );

      expect(find.text('HDFC BANK'), findsOneWidget);
      expect(find.text('•••• •••• •••• 4444'), findsOneWidget);
      expect(find.text('ROHIT SHARMA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders Aadhaar Card with tricolor and UIDAI badge', (
      tester,
    ) async {
      final doc = WalletDocumentModel(
        id: 'doc-2',
        documentName: 'Aadhaar Card',
        category: 'aadhaar',
        description: 'Holder: Sneha Gupta\nNumber: •••• •••• 9012',
        encryptedFilePath: '/fake/path.enc',
        mimeType: 'image/jpeg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: VirtualDocumentCard(document: doc),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Government of India'), findsOneWidget);
      expect(find.text('UIDAI'), findsOneWidget);
      expect(find.text('•••• •••• 9012'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders Passport Card without overflows', (tester) async {
      final doc = WalletDocumentModel(
        id: 'doc-3',
        documentName: 'Indian Passport',
        category: 'passport',
        description:
            'Holder: Aditya Roy\nNumber: K1234567\nNationality: INDIAN',
        encryptedFilePath: '/fake/path.enc',
        mimeType: 'image/jpeg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: VirtualDocumentCard(document: doc),
              ),
            ),
          ),
        ),
      );

      expect(find.text('REPUBLIC OF INDIA / PASSPORT'), findsOneWidget);
      expect(find.text('K1234567'), findsOneWidget);
      expect(find.text('INDIAN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Document Export & PDF Generation Tests', () {
    test('Generates valid PDF containing metadata and image payload', () async {
      final exportService = DocumentExportService();
      final sampleBytes = _generateSampleImageBytes(width: 200, height: 150);

      final doc = WalletDocumentModel(
        id: 'test-export-doc',
        documentName: 'Passport Scan',
        category: 'passport',
        description:
            'Holder: Priya Sharma\nNumber: M1234567\nIssuer: Ministry of External Affairs',
        encryptedFilePath: '/fake/enc.bin',
        mimeType: 'image/jpeg',
        issueDate: DateTime(2022, 1, 15),
        expiryDate: DateTime(2032, 1, 14),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final pdfFile = await exportService.generateDocumentPdf(
        document: doc,
        decryptedBytes: sampleBytes,
        secureDocNumber: 'M1234567',
      );

      expect(await pdfFile.exists(), isTrue);
      final fileSize = await pdfFile.length();
      expect(
        fileSize,
        greaterThan(500),
      ); // PDF header + metadata + embedded bitmap

      // Clean up
      try {
        await pdfFile.delete();
      } catch (_) {}
    });
  });
}
