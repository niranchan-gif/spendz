/// Encapsulates extracted metadata fields from a document with confidence metrics.
class ExtractedFields {
  final String? holderName;
  final String? documentNumber; // Masked / sanitized for sensitive documents
  final String? rawDocumentNumber; // Original unmasked for validation only
  final String? issuer;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? vehicleNumber;
  final String? policyPeriod;
  final Map<String, double> fieldConfidences;

  const ExtractedFields({
    this.holderName,
    this.documentNumber,
    this.rawDocumentNumber,
    this.issuer,
    this.issueDate,
    this.expiryDate,
    this.vehicleNumber,
    this.policyPeriod,
    this.fieldConfidences = const {},
  });
}

/// Robust, rule-based field extractor with strict contextual checks for dates and identifiers.
class DocumentFieldExtractor {
  // Regex patterns
  static final RegExp _aadhaarRegex = RegExp(r'\b(\d{4})\s(\d{4})\s(\d{4})\b');
  static final RegExp _panRegex = RegExp(r'\b([A-Z]{5}[0-9]{4}[A-Z])\b');
  static final RegExp _dlRegex = RegExp(r'\b([A-Z]{2}[- ]?[0-9]{2}[- ]?[0-9]{11})\b', caseSensitive: false);
  static final RegExp _passportRegex = RegExp(r'\b([A-PR-WYa-pr-wy][1-9][0-9]\s?[0-9]{4}[0-9])\b');
  static final RegExp _passportOldRegex = RegExp(r'\b([A-Z][0-9]{7})\b');
  static final RegExp _rcRegex = RegExp(r'\b([A-Z]{2}[ -]?[0-9]{1,2}[ -]?[A-Z]{1,3}[ -]?[0-9]{4})\b', caseSensitive: false);

  // Date parsing regexes
  static final RegExp _dateDmyRegex = RegExp(
    r'\b(0?[1-9]|[12][0-9]|3[01])[\/\-\.](0?[1-9]|1[012])[\/\-\.]((?:19|20)\d\d)\b',
  );
  static final RegExp _dateYmdRegex = RegExp(
    r'\b((?:19|20)\d\d)[\/\-\.](0?[1-9]|1[012])[\/\-\.](0?[1-9]|[12][0-9]|3[01])\b',
  );
  static final RegExp _dateTextRegex = RegExp(
    r'\b(0?[1-9]|[12][0-9]|3[01])\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s,]+((?:19|20)\d\d)\b',
    caseSensitive: false,
  );

  /// Extracts fields based on document category and OCR text.
  ExtractedFields extract({
    required String rawText,
    required String category,
  }) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? holderName;
    String? docNum;
    String? rawDocNum;
    String? issuer;
    DateTime? issueDate;
    DateTime? expiryDate;
    String? vehicleNumber;
    String? policyPeriod;
    final confidences = <String, double>{};

    // 1. Category-specific Document Number & Issuer extraction
    switch (category) {
      case 'aadhaar':
        issuer = 'Unique Identification Authority of India (UIDAI)';
        confidences['issuer'] = 0.95;
        final match = _aadhaarRegex.firstMatch(rawText);
        if (match != null) {
          rawDocNum = match.group(0);
          // Aadhaar must be masked for privacy: '•••• •••• 1234'
          docNum = '•••• •••• ${match.group(3)}';
          confidences['documentNumber'] = 0.95;
        }
        break;

      case 'pan':
        issuer = 'Income Tax Department, Govt. of India';
        confidences['issuer'] = 0.95;
        final match = _panRegex.firstMatch(rawText);
        if (match != null) {
          rawDocNum = match.group(1);
          docNum = rawDocNum;
          confidences['documentNumber'] = 0.95;
        }
        break;

      case 'driving_license':
        issuer = 'Ministry of Road Transport and Highways (MoRTH)';
        confidences['issuer'] = 0.90;
        final match = _dlRegex.firstMatch(rawText);
        if (match != null) {
          rawDocNum = match.group(1);
          docNum = rawDocNum;
          confidences['documentNumber'] = 0.90;
        }
        break;

      case 'passport':
        issuer = 'Ministry of External Affairs, Republic of India';
        confidences['issuer'] = 0.95;
        final match = _passportRegex.firstMatch(rawText) ?? _passportOldRegex.firstMatch(rawText);
        if (match != null) {
          rawDocNum = match.group(1);
          docNum = rawDocNum;
          confidences['documentNumber'] = 0.90;
        }
        break;

      case 'rc':
        issuer = 'Ministry of Road Transport & Highways';
        confidences['issuer'] = 0.85;
        final match = _rcRegex.firstMatch(rawText);
        if (match != null) {
          rawDocNum = match.group(1);
          docNum = rawDocNum;
          vehicleNumber = rawDocNum;
          confidences['documentNumber'] = 0.90;
          confidences['vehicleNumber'] = 0.90;
        }
        break;

      case 'insurance':
        // Try extracting policy number
        final policyRegex = RegExp(r'(?:policy\s*(?:no|number|#)[\s:]*)([A-Z0-9\-\/]{6,25})', caseSensitive: false);
        final match = policyRegex.firstMatch(rawText);
        if (match != null) {
          docNum = match.group(1);
          rawDocNum = docNum;
          confidences['documentNumber'] = 0.85;
        }
        break;

      default:
        // Generic number lookup if present
        break;
    }

    // 2. Holder Name Extraction heuristics
    holderName = _extractHolderName(lines, category);
    if (holderName != null) {
      confidences['holderName'] = 0.75;
    }

    // 3. Contextual Date Extraction (Issue date vs Expiry date)
    final dates = _extractContextualDates(lines);
    issueDate = dates.issueDate;
    expiryDate = dates.expiryDate;
    if (issueDate != null) confidences['issueDate'] = 0.85;
    if (expiryDate != null) confidences['expiryDate'] = 0.85;

    return ExtractedFields(
      holderName: holderName,
      documentNumber: docNum,
      rawDocumentNumber: rawDocNum,
      issuer: issuer,
      issueDate: issueDate,
      expiryDate: expiryDate,
      vehicleNumber: vehicleNumber,
      policyPeriod: policyPeriod,
      fieldConfidences: confidences,
    );
  }

  /// Extracts holder name by inspecting document structure and nearby label markers.
  String? _extractHolderName(List<String> lines, String category) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // Explicit name labels: "Name: John Doe", "Holder Name: Jane Smith"
      final labelMatch = RegExp(r'^(?:name|cardholder\s*name|holder\s*name|student\s*name|insured\s*name)[\s:]+([A-Za-z\s\.\-]+)$', caseSensitive: false).firstMatch(line);
      if (labelMatch != null) {
        final val = labelMatch.group(1)?.trim();
        if (_isValidPersonName(val)) return val;
      }

      // PAN card format: Line before "Father's Name"
      if (category == 'pan' && lower.contains("father's name") && i > 0) {
        final candidate = lines[i - 1].trim();
        if (_isValidPersonName(candidate)) return candidate;
      }

      // Passport: line after "Given Name" or "Surname"
      if (category == 'passport' && (lower.contains('given name') || lower.contains('nom')) && i + 1 < lines.length) {
        final candidate = lines[i + 1].trim();
        if (_isValidPersonName(candidate)) return candidate;
      }
    }

    return null;
  }

  bool _isValidPersonName(String? name) {
    if (name == null || name.length < 3 || name.length > 50) return false;
    // Disallow numbers or agency names
    if (RegExp(r'\d').hasMatch(name)) return false;
    final lower = name.toLowerCase();
    if (lower.contains('government') ||
        lower.contains('authority') ||
        lower.contains('department') ||
        lower.contains('india') ||
        lower.contains('tax') ||
        lower.contains('transport') ||
        lower.contains('uidai')) {
      return false;
    }
    return true;
  }

  /// Extracts dates ONLY when accompanied by explicit contextual evidence.
  /// Never guesses a random date is an expiry date.
  _ContextualDates _extractContextualDates(List<String> lines) {
    DateTime? issueDate;
    DateTime? expiryDate;

    final expiryKeywords = [
      'expiry',
      'expires',
      'valid till',
      'valid upto',
      'valid up to',
      'valid to',
      'valid through',
      'to date',
      'end date',
      'exp date',
      'exp:',
    ];

    final issueKeywords = [
      'issue date',
      'date of issue',
      'issued on',
      'issued date',
      'from date',
      'start date',
      'reg date',
      'doi',
      'valid from',
    ];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // Check current line and adjacent line for date
      final lineDates = _findDatesInString(line);

      // Check if line contains expiry keywords
      final hasExpiryKeyword = expiryKeywords.any((k) => lower.contains(k));
      final hasIssueKeyword = issueKeywords.any((k) => lower.contains(k));

      if (hasExpiryKeyword && expiryDate == null) {
        if (lineDates.isNotEmpty) {
          expiryDate = lineDates.first;
        } else if (i + 1 < lines.length) {
          final nextDates = _findDatesInString(lines[i + 1]);
          if (nextDates.isNotEmpty) {
            expiryDate = nextDates.first;
          }
        }
      }

      if (hasIssueKeyword && issueDate == null) {
        if (lineDates.isNotEmpty) {
          issueDate = lineDates.first;
        } else if (i + 1 < lines.length) {
          final nextDates = _findDatesInString(lines[i + 1]);
          if (nextDates.isNotEmpty) {
            issueDate = nextDates.first;
          }
        }
      }
    }

    return _ContextualDates(issueDate: issueDate, expiryDate: expiryDate);
  }

  /// Finds and parses all valid calendar dates in [text].
  List<DateTime> _findDatesInString(String text) {
    final results = <DateTime>[];

    // 1. Match DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    for (final match in _dateDmyRegex.allMatches(text)) {
      final day = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3)!);
      if (day != null && month != null && year != null) {
        final parsed = _safeConstructDate(year, month, day);
        if (parsed != null) results.add(parsed);
      }
    }

    // 2. Match YYYY-MM-DD
    for (final match in _dateYmdRegex.allMatches(text)) {
      final year = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final day = int.tryParse(match.group(3)!);
      if (day != null && month != null && year != null) {
        final parsed = _safeConstructDate(year, month, day);
        if (parsed != null) results.add(parsed);
      }
    }

    // 3. Match "15 Jan 2028"
    for (final match in _dateTextRegex.allMatches(text)) {
      final day = int.tryParse(match.group(1)!);
      final monthStr = match.group(2)!.toLowerCase();
      final year = int.tryParse(match.group(3)!);
      final month = _monthStringToNumber(monthStr);
      if (day != null && month != null && year != null) {
        final parsed = _safeConstructDate(year, month, day);
        if (parsed != null) results.add(parsed);
      }
    }

    return results;
  }

  int? _monthStringToNumber(String m) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
      'may': 5, 'jun': 6, 'jul': 7, 'aug': 8,
      'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[m.substring(0, 3)];
  }

  DateTime? _safeConstructDate(int year, int month, int day) {
    try {
      final d = DateTime(year, month, day);
      if (d.year == year && d.month == month && d.day == day) {
        return d;
      }
    } catch (_) {}
    return null;
  }
}

class _ContextualDates {
  final DateTime? issueDate;
  final DateTime? expiryDate;
  const _ContextualDates({this.issueDate, this.expiryDate});
}

