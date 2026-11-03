/// Result of document classification.
class DocumentClassificationResult {
  final String category;
  final double confidence; // 0.0 to 1.0
  final List<String> reasons;
  final bool isHighConfidence;

  const DocumentClassificationResult({
    required this.category,
    required this.confidence,
    required this.reasons,
    required this.isHighConfidence,
  });

  /// Readable category label for UI display.
  String get displayCategoryName {
    switch (category) {
      case 'aadhaar':
        return 'Aadhaar Card';
      case 'pan':
        return 'PAN Card';
      case 'driving_license':
        return 'Driving Licence';
      case 'passport':
        return 'Passport';
      case 'rc':
        return 'Vehicle RC';
      case 'insurance':
        return 'Insurance Policy';
      case 'college_id':
        return 'College / Student ID';
      case 'certificate':
        return 'Certificate';
      case 'other':
      default:
        return 'Unclassified / Other';
    }
  }

  /// Explicit disclaimer required by security guidelines:
  /// OCR classification is pattern-based and does not certify legal validity.
  static const String legalDisclaimer =
      'Classification is based on automated text pattern matching and does NOT verify legal document authenticity.';
}

/// Deterministic classifier that detects document categories based on multi-keyword
/// intersections, structural patterns, and government agency signatures.
class DocumentClassifier {
  static const double highConfidenceThreshold = 0.70;
  static const double minimumAcceptableConfidence = 0.40;

  // Regex patterns
  static final RegExp _aadhaarRegex = RegExp(r'\b\d{4}\s\d{4}\s\d{4}\b');
  static final RegExp _panRegex = RegExp(r'\b[A-Z]{5}[0-9]{4}[A-Z]\b');
  static final RegExp _dlRegex = RegExp(r'\b[A-Z]{2}[- ]?[0-9]{2}[- ]?[0-9]{11}\b', caseSensitive: false);
  static final RegExp _dlAlternativeRegex = RegExp(r'\bDL[- ]?[0-9A-Z]{10,15}\b', caseSensitive: false);
  static final RegExp _passportRegex = RegExp(r'\b[A-PR-WYa-pr-wy][1-9][0-9]\s?[0-9]{4}[0-9]\b');
  static final RegExp _passportOldRegex = RegExp(r'\b[A-Z][0-9]{7}\b');
  static final RegExp _rcRegex = RegExp(r'\b[A-Z]{2}[ -]?[0-9]{1,2}[ -]?[A-Z]{1,3}[ -]?[0-9]{4}\b', caseSensitive: false);

  /// Classifies a document using the raw OCR text.
  DocumentClassificationResult classify(String rawText) {
    if (rawText.trim().isEmpty) {
      return const DocumentClassificationResult(
        category: 'other',
        confidence: 0.0,
        reasons: ['No text detected in document'],
        isHighConfidence: false,
      );
    }

    final lower = rawText.toLowerCase();

    // Score all categories
    final scores = <String, _CategoryScore>{
      'aadhaar': _scoreAadhaar(rawText, lower),
      'pan': _scorePan(rawText, lower),
      'driving_license': _scoreDrivingLicence(rawText, lower),
      'passport': _scorePassport(rawText, lower),
      'rc': _scoreVehicleRc(rawText, lower),
      'insurance': _scoreInsurance(rawText, lower),
      'college_id': _scoreCollegeId(rawText, lower),
      'certificate': _scoreCertificate(rawText, lower),
    };

    // Find highest scoring category
    String bestCategory = 'other';
    double highestScore = 0.0;
    List<String> bestReasons = [];

    for (final entry in scores.entries) {
      if (entry.value.score > highestScore) {
        highestScore = entry.value.score;
        bestCategory = entry.key;
        bestReasons = entry.value.reasons;
      }
    }

    // Require minimum confidence; otherwise remain 'other'
    if (highestScore < minimumAcceptableConfidence) {
      return DocumentClassificationResult(
        category: 'other',
        confidence: highestScore,
        reasons: bestReasons.isEmpty
            ? ['Insufficient document markers detected']
            : ['Low confidence: ${bestReasons.join(", ")}'],
        isHighConfidence: false,
      );
    }

    final clampedConfidence = highestScore.clamp(0.0, 1.0);
    return DocumentClassificationResult(
      category: bestCategory,
      confidence: clampedConfidence,
      reasons: bestReasons,
      isHighConfidence: clampedConfidence >= highConfidenceThreshold,
    );
  }

  // --- Category Scoring Rules (Multi-keyword & pattern requirements) ---

  _CategoryScore _scoreAadhaar(String raw, String lower) {
    int points = 0;
    final reasons = <String>[];

    if (_aadhaarRegex.hasMatch(raw)) {
      points += 40;
      reasons.add('12-digit Aadhaar pattern matched');
    }
    if (lower.contains('unique identification authority of india') || lower.contains('uidai')) {
      points += 40;
      reasons.add('UIDAI authority header found');
    }
    if (lower.contains('government of india') || lower.contains('govt of india')) {
      points += 15;
      reasons.add('Government of India header');
    }
    if (lower.contains('mera aadhaar') || lower.contains('meri pehchan') || lower.contains('aadhaar')) {
      points += 20;
      reasons.add('Aadhaar keyword found');
    }
    if (lower.contains('vid:') || lower.contains('enrollment no')) {
      points += 15;
      reasons.add('VID / Enrollment marker found');
    }

    return _CategoryScore(points / 100.0, reasons);
  }

  _CategoryScore _scorePan(String raw, String lower) {
    int points = 0;
    final reasons = <String>[];

    if (_panRegex.hasMatch(raw)) {
      points += 45;
      reasons.add('10-character PAN pattern matched');
    }
    if (lower.contains('income tax department') || lower.contains('incometax')) {
      points += 40;
      reasons.add('Income Tax Department header found');
    }
    if (lower.contains('permanent account number') || lower.contains('pan card')) {
      points += 25;
      reasons.add('Permanent Account Number title found');
    }
    if (lower.contains("father's name") || lower.contains('fathers name')) {
      points += 15;
      reasons.add("Father's Name field marker found");
    }

    return _CategoryScore(points / 100.0, reasons);
  }

  _CategoryScore _scoreDrivingLicence(String raw, String lower) {
    int points = 0;
    final reasons = <String>[];

    if (_dlRegex.hasMatch(raw) || _dlAlternativeRegex.hasMatch(raw)) {
      points += 40;
      reasons.add('Driving Licence number format matched');
    }
    if (lower.contains('driving licence') || lower.contains('driving license')) {
      points += 40;
      reasons.add('Driving Licence title found');
    }
    if (lower.contains('transport department') || lower.contains('union of india') || lower.contains('rto')) {
      points += 20;
      reasons.add('Transport Department authority header');
    }
    if (lower.contains('authorisation to drive') || lower.contains('form 7') || lower.contains('lmv') || lower.contains('mcwg')) {
      points += 25;
      reasons.add('Vehicle class / Form 7 designation found');
    }

    return _CategoryScore(points / 100.0, reasons);
  }

  _CategoryScore _scorePassport(String raw, String lower) {
    int points = 0;
    final reasons = <String>[];

    if (_passportRegex.hasMatch(raw) || _passportOldRegex.hasMatch(raw)) {
      points += 35;
      reasons.add('Passport number pattern matched');
    }
    if (lower.contains('passport') || lower.contains('passeport')) {
      points += 40;
      reasons.add('Passport title found');
    }
    if (lower.contains('republic of india') || lower.contains('bharat sarkar')) {
      points += 20;
      reasons.add('Republic of India header found');
    }
    if (lower.contains('type p') || lower.contains('code ind') || raw.contains('P<IND') || raw.contains('<<<<')) {
      points += 35;
      reasons.add('MRZ / Type P Passport indicators found');
    }
    if (lower.contains('given name') || lower.contains('surname') || lower.contains('nationality')) {
      points += 15;
      reasons.add('Standard passport metadata fields found');
    }

    return _CategoryScore(points / 100.0, reasons);
  }

  _CategoryScore _scoreVehicleRc(String raw, String lower) {
    int points = 0;
    final reasons = <String>[];

    if (_rcRegex.hasMatch(raw)) {
      points += 35;
      reasons.add('Vehicle registration number matched');
    }
    if (lower.contains('registration certificate') || lower.contains('certificate of registration')) {
      points += 45;
      reasons.add('Registration Certificate title found');
    }
    if (lower.contains('chassis no') || lower.contains('engine no')) {
      points += 25;
      reasons.add('Chassis / Engine number markers found');
    }
    if (lower.contains('ministry of road transport') || lower.contains('parivahan')) {
      points += 20;
      reasons.add('Ministry of Road Transport / Parivahan marker');
    }

    return _CategoryScore(points / 100.0, reasons);
  }

  _CategoryScore _scoreInsurance(String raw, String lower) {
    int points = 0;
    final reasons = <String>[];

    if (lower.contains('certificate of insurance') || lower.contains('policy schedule') || lower.contains('insurance policy')) {
      points += 45;
      reasons.add('Insurance Policy title found');
    }
    if (lower.contains('policy number') || lower.contains('policy no')) {
      points += 30;
      reasons.add('Policy Number field found');
    }
    if (lower.contains('sum insured') || lower.contains('premium') || lower.contains('period of insurance')) {
      points += 25;
      reasons.add('Sum Insured / Premium / Period indicators found');
    }
    if (lower.contains('general insurance') || lower.contains('life insurance') || lower.contains('motor insurance')) {
      points += 20;
      reasons.add('Insurance company type marker');
    }

    return _CategoryScore(points / 100.0, reasons);
  }

  _CategoryScore _scoreCollegeId(String raw, String lower) {
    int points = 0;
    final reasons = <String>[];

    if (lower.contains('student id') || lower.contains('identity card') || lower.contains('student identity card')) {
      points += 40;
      reasons.add('Student / Identity card title found');
    }
    if (lower.contains('college') || lower.contains('university') || lower.contains('institute of technology') || lower.contains('school')) {
      points += 35;
      reasons.add('Educational institution name found');
    }
    if (lower.contains('roll no') || lower.contains('enrollment no') || lower.contains('reg no') || lower.contains('branch')) {
      points += 25;
      reasons.add('Roll number / branch student markers found');
    }

    return _CategoryScore(points / 100.0, reasons);
  }

  _CategoryScore _scoreCertificate(String raw, String lower) {
    int points = 0;
    final reasons = <String>[];

    if (lower.contains('certificate of') || lower.contains('completion certificate') || lower.contains('certificate of achievement')) {
      points += 45;
      reasons.add('Certificate title found');
    }
    if (lower.contains('certifies that') || lower.contains('has successfully completed') || lower.contains('awarded to')) {
      points += 40;
      reasons.add('Certification statement found');
    }
    if (lower.contains('course') || lower.contains('participation') || lower.contains('conferred upon')) {
      points += 20;
      reasons.add('Course completion keywords found');
    }

    return _CategoryScore(points / 100.0, reasons);
  }
}

class _CategoryScore {
  final double score;
  final List<String> reasons;
  const _CategoryScore(this.score, this.reasons);
}

