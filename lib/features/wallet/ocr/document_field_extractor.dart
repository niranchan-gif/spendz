/// Encapsulates extracted metadata fields from a document with confidence metrics.
class ExtractedFields {
  final String? holderName;
  final String? documentNumber; // Masked / sanitized for sensitive documents
  final String? rawDocumentNumber; // Original unmasked for secure hardware storage
  final String? issuer;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final DateTime? dob;
  final String? gender;
  final String? address;
  final String? fatherName;
  final String? vehicleCategories;
  final String? vehicleNumber;
  final String? nationality;
  final String? placeOfBirth;
  final String? cardNetwork;
  final String? issuingBank;
  final String? policyType;
  final String? accountNumber;
  final String? ifscCode;
  final List<String> unclassifiedLines;
  final Map<String, double> fieldConfidences;
  final String rawFullText;

  const ExtractedFields({
    this.holderName,
    this.documentNumber,
    this.rawDocumentNumber,
    this.issuer,
    this.issueDate,
    this.expiryDate,
    this.dob,
    this.gender,
    this.address,
    this.fatherName,
    this.vehicleCategories,
    this.vehicleNumber,
    this.nationality,
    this.placeOfBirth,
    this.cardNetwork,
    this.issuingBank,
    this.policyType,
    this.accountNumber,
    this.ifscCode,
    this.unclassifiedLines = const [],
    this.fieldConfidences = const {},
    this.rawFullText = '',
  });

  /// Serializes structured key-value pairs into a clean multi-line description
  /// that is both human-readable and structured for later parsing.
  String toDescriptionString() {
    final buffer = StringBuffer();
    if (holderName != null && holderName!.isNotEmpty) buffer.writeln('Holder: $holderName');
    if (documentNumber != null && documentNumber!.isNotEmpty) buffer.writeln('Number: $documentNumber');
    if (issuer != null && issuer!.isNotEmpty) buffer.writeln('Issuer: $issuer');
    if (cardNetwork != null && cardNetwork!.isNotEmpty) buffer.writeln('Network: $cardNetwork');
    if (issuingBank != null && issuingBank!.isNotEmpty) buffer.writeln('Bank: $issuingBank');
    if (fatherName != null && fatherName!.isNotEmpty) buffer.writeln("Father's Name: $fatherName");
    if (dob != null) buffer.writeln('DOB: ${dob!.year}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}');
    if (gender != null && gender!.isNotEmpty) buffer.writeln('Gender: $gender');
    if (vehicleCategories != null && vehicleCategories!.isNotEmpty) buffer.writeln('Vehicle Class: $vehicleCategories');
    if (vehicleNumber != null && vehicleNumber!.isNotEmpty) buffer.writeln('Vehicle No: $vehicleNumber');
    if (nationality != null && nationality!.isNotEmpty) buffer.writeln('Nationality: $nationality');
    if (placeOfBirth != null && placeOfBirth!.isNotEmpty) buffer.writeln('Place of Birth: $placeOfBirth');
    if (policyType != null && policyType!.isNotEmpty) buffer.writeln('Policy Type: $policyType');
    if (accountNumber != null && accountNumber!.isNotEmpty) buffer.writeln('Account No: $accountNumber');
    if (ifscCode != null && ifscCode!.isNotEmpty) buffer.writeln('IFSC: $ifscCode');
    if (address != null && address!.isNotEmpty) buffer.writeln('Address: $address');

    if (unclassifiedLines.isNotEmpty) {
      buffer.writeln('\n--- Unclassified OCR Text ---');
      for (final line in unclassifiedLines.take(10)) {
        buffer.writeln('• $line');
      }
    }

    return buffer.toString().trim();
  }
}

/// Robust, rule-based field extractor with strict contextual checks for dates and identifiers.
class DocumentFieldExtractor {
  // Regex patterns
  static final RegExp _cardRegex = RegExp(r'\b(?:\d{4}[ -]?){3}\d{4}\b');
  static final RegExp _cardExpiryRegex = RegExp(r'\b(0[1-9]|1[0-2])[\/ -](\d{2}|\d{4})\b');
  static final RegExp _aadhaarRegex = RegExp(r'\b(\d{4})\s(\d{4})\s(\d{4})\b');
  static final RegExp _panRegex = RegExp(r'\b([A-Z]{5}[0-9]{4}[A-Z])\b');
  static final RegExp _dlRegex = RegExp(r'\b([A-Z]{2}[- ]?[0-9]{2}[- ]?[0-9]{11})\b', caseSensitive: false);
  static final RegExp _dlAlternativeRegex = RegExp(r'\bDL[- ]?([0-9A-Z]{10,15})\b', caseSensitive: false);
  static final RegExp _voterIdRegex = RegExp(r'\b([A-Z]{3}[0-9]{7})\b');
  static final RegExp _passportRegex = RegExp(r'\b([A-PR-WYa-pr-wy][1-9][0-9]\s?[0-9]{4}[0-9])\b');
  static final RegExp _passportOldRegex = RegExp(r'\b([A-Z][0-9]{7})\b');
  static final RegExp _rcRegex = RegExp(r'\b([A-Z]{2}[ -]?[0-9]{1,2}[ -]?[A-Z]{1,3}[ -]?[0-9]{4})\b', caseSensitive: false);
  static final RegExp _ifscRegex = RegExp(r'\b([A-Z]{4}0[A-Z0-9]{6})\b');

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

    final usedLines = <String>{};
    String? holderName;
    String? docNum;
    String? rawDocNum;
    String? issuer;
    DateTime? issueDate;
    DateTime? expiryDate;
    DateTime? dob;
    String? gender;
    String? address;
    String? fatherName;
    String? vehicleCategories;
    String? vehicleNumber;
    String? nationality;
    String? placeOfBirth;
    String? cardNetwork;
    String? issuingBank;
    String? policyType;
    String? accountNumber;
    String? ifscCode;
    final confidences = <String, double>{};

    // 1. Category-specific extraction
    switch (category) {
      case 'debit_card':
      case 'credit_card':
        final isCredit = category == 'credit_card';
        // Extract card number
        final cardMatch = _cardRegex.firstMatch(rawText);
        if (cardMatch != null) {
          final fullCard = cardMatch.group(0)!.replaceAll(RegExp(r'[\s\-]'), '');
          rawDocNum = fullCard;
          docNum = '•••• •••• •••• ${fullCard.substring(fullCard.length - 4)}';
          confidences['documentNumber'] = 0.95;
          _markUsedLine(lines, cardMatch.group(0)!, usedLines);
        }

        // Card network
        final lower = rawText.toLowerCase();
        if (lower.contains('visa')) {
          cardNetwork = 'Visa';
        } else if (lower.contains('mastercard')) {
          cardNetwork = 'Mastercard';
        } else if (lower.contains('rupay')) {
          cardNetwork = 'RuPay';
        } else if (lower.contains('american express') || lower.contains('amex')) {
          cardNetwork = 'American Express';
        } else if (lower.contains('diners')) {
          cardNetwork = 'Diners Club';
        } else if (lower.contains('maestro')) {
          cardNetwork = 'Maestro';
        }
        if (cardNetwork != null) confidences['cardNetwork'] = 0.90;

        // Issuing bank
        issuingBank = _detectBank(lower);
        if (issuingBank != null) {
          issuer = issuingBank;
          confidences['issuer'] = 0.90;
        } else {
          issuer = isCredit ? 'Credit Card Issuer' : 'Debit Card Issuer';
        }

        // Expiry date (MM/YY)
        final expMatch = _cardExpiryRegex.firstMatch(rawText);
        if (expMatch != null) {
          final month = int.tryParse(expMatch.group(1)!);
          var year = int.tryParse(expMatch.group(2)!);
          if (month != null && year != null) {
            if (year < 100) year += 2000;
            expiryDate = DateTime(year, month, 28);
            confidences['expiryDate'] = 0.90;
            _markUsedLine(lines, expMatch.group(0)!, usedLines);
          }
        }

        // Cardholder name
        holderName = _extractCardholderName(lines, usedLines);
        if (holderName != null) confidences['holderName'] = 0.80;
        break;

      case 'aadhaar':
        issuer = 'Unique Identification Authority of India (UIDAI)';
        confidences['issuer'] = 0.95;
        final match = _aadhaarRegex.firstMatch(rawText);
        if (match != null) {
          rawDocNum = match.group(0);
          docNum = '•••• •••• ${match.group(3)}';
          confidences['documentNumber'] = 0.95;
          _markUsedLine(lines, match.group(0)!, usedLines);
        }

        // Gender
        final lowerAadhaar = rawText.toLowerCase();
        if (lowerAadhaar.contains('female')) {
          gender = 'Female';
        } else if (lowerAadhaar.contains('male')) {
          gender = 'Male';
        } else if (lowerAadhaar.contains('transgender')) {
          gender = 'Transgender';
        }
        if (gender != null) confidences['gender'] = 0.95;

        // Address extraction
        address = _extractAddress(lines, usedLines);
        if (address != null) confidences['address'] = 0.75;
        break;

      case 'pan':
        issuer = 'Income Tax Department, Govt. of India';
        confidences['issuer'] = 0.95;
        final match = _panRegex.firstMatch(rawText);
        if (match != null) {
          rawDocNum = match.group(1);
          docNum = rawDocNum;
          confidences['documentNumber'] = 0.95;
          _markUsedLine(lines, match.group(0)!, usedLines);
        }

        // Father's name
        fatherName = _extractLabeledField(lines, ["father's name", 'fathers name', 'father name'], usedLines);
        if (fatherName != null) confidences['fatherName'] = 0.85;
        break;

      case 'driving_license':
        issuer = 'Ministry of Road Transport and Highways (MoRTH)';
        confidences['issuer'] = 0.90;
        final match = _dlRegex.firstMatch(rawText) ?? _dlAlternativeRegex.firstMatch(rawText);
        if (match != null) {
          rawDocNum = match.group(1);
          docNum = rawDocNum;
          confidences['documentNumber'] = 0.90;
          _markUsedLine(lines, match.group(0)!, usedLines);
        }

        // Vehicle categories
        final vcMatch = RegExp(r'\b(LMV|MCWG|MCWOG|HGMV|TRANS|3W-CAB)\b', caseSensitive: false).allMatches(rawText);
        if (vcMatch.isNotEmpty) {
          final uniqueClasses = vcMatch.map((m) => m.group(0)!.toUpperCase()).toSet().toList();
          vehicleCategories = uniqueClasses.join(', ');
          confidences['vehicleCategories'] = 0.85;
        }
        break;

      case 'voter_id':
        issuer = 'Election Commission of India';
        confidences['issuer'] = 0.95;
        final match = _voterIdRegex.firstMatch(rawText);
        if (match != null) {
          rawDocNum = match.group(1);
          docNum = rawDocNum;
          confidences['documentNumber'] = 0.95;
          _markUsedLine(lines, match.group(0)!, usedLines);
        }

        fatherName = _extractLabeledField(lines, ["father's name", 'fathers name', "husband's name", 'relative name'], usedLines);
        if (fatherName != null) confidences['fatherName'] = 0.80;

        final lowerVoter = rawText.toLowerCase();
        if (lowerVoter.contains('female')) {
          gender = 'Female';
        } else if (lowerVoter.contains('male')) {
          gender = 'Male';
        }
        break;

      case 'passport':
        issuer = 'Ministry of External Affairs, Republic of India';
        confidences['issuer'] = 0.95;
        nationality = 'INDIAN';
        confidences['nationality'] = 0.95;
        final match = _passportRegex.firstMatch(rawText) ?? _passportOldRegex.firstMatch(rawText);
        if (match != null) {
          rawDocNum = match.group(1);
          docNum = rawDocNum;
          confidences['documentNumber'] = 0.90;
          _markUsedLine(lines, match.group(0)!, usedLines);
        }

        placeOfBirth = _extractLabeledField(lines, ['place of birth', 'birth place'], usedLines);
        if (placeOfBirth != null) confidences['placeOfBirth'] = 0.85;
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
          _markUsedLine(lines, match.group(0)!, usedLines);
        }
        break;

      case 'insurance':
        final policyRegex = RegExp(r'(?:policy\s*(?:no|number|#)[\s:]*)([A-Z0-9\-\/]{6,25})', caseSensitive: false);
        final match = policyRegex.firstMatch(rawText);
        if (match != null) {
          docNum = match.group(1);
          rawDocNum = docNum;
          confidences['documentNumber'] = 0.85;
          _markUsedLine(lines, match.group(0)!, usedLines);
        }

        final lowerIns = rawText.toLowerCase();
        if (lowerIns.contains('health')) {
          policyType = 'Health Insurance';
        } else if (lowerIns.contains('motor') || lowerIns.contains('car') || lowerIns.contains('two wheeler')) {
          policyType = 'Motor Insurance';
        } else if (lowerIns.contains('life') || lowerIns.contains('term')) {
          policyType = 'Life Insurance';
        } else {
          policyType = 'General Insurance';
        }
        confidences['policyType'] = 0.85;

        issuer = _detectInsuranceProvider(lowerIns) ?? 'Insurance Provider';
        confidences['issuer'] = 0.85;
        break;

      case 'bank_document':
        issuer = _detectBank(rawText.toLowerCase()) ?? 'Bank';
        confidences['issuer'] = 0.85;

        final ifscMatch = _ifscRegex.firstMatch(rawText);
        if (ifscMatch != null) {
          ifscCode = ifscMatch.group(1);
          confidences['ifscCode'] = 0.95;
          _markUsedLine(lines, ifscMatch.group(0)!, usedLines);
        }

        final accMatch = RegExp(r'(?:a\/c|account\s*(?:no|number)[\s:]*)([0-9]{9,18})', caseSensitive: false).firstMatch(rawText);
        if (accMatch != null) {
          final acc = accMatch.group(1)!;
          accountNumber = acc;
          rawDocNum = acc;
          docNum = '•••• ${acc.substring(acc.length - 4)}';
          confidences['accountNumber'] = 0.90;
          _markUsedLine(lines, accMatch.group(0)!, usedLines);
        }
        break;

      default:
        // Generic documents
        break;
    }

    // 2. Holder Name Extraction heuristics
    holderName ??= _extractHolderName(lines, category, usedLines);
    if (holderName != null) {
      confidences['holderName'] = 0.75;
    }

    // 3. Contextual Date Extraction (Issue date, Expiry date, DOB)
    final dates = _extractContextualDates(lines, usedLines);
    issueDate ??= dates.issueDate;
    expiryDate ??= dates.expiryDate;
    dob ??= dates.dob;

    if (issueDate != null) confidences['issueDate'] = 0.85;
    if (expiryDate != null) confidences['expiryDate'] = 0.85;
    if (dob != null) confidences['dob'] = 0.85;

    // 4. Collect Unclassified Lines
    final unclassified = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.length > 2 && !usedLines.contains(trimmed) && !_isNoiseLine(trimmed)) {
        unclassified.add(trimmed);
      }
    }

    return ExtractedFields(
      holderName: holderName,
      documentNumber: docNum,
      rawDocumentNumber: rawDocNum,
      issuer: issuer,
      issueDate: issueDate,
      expiryDate: expiryDate,
      dob: dob,
      gender: gender,
      address: address,
      fatherName: fatherName,
      vehicleCategories: vehicleCategories,
      vehicleNumber: vehicleNumber,
      nationality: nationality,
      placeOfBirth: placeOfBirth,
      cardNetwork: cardNetwork,
      issuingBank: issuingBank,
      policyType: policyType,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      unclassifiedLines: unclassified,
      fieldConfidences: confidences,
      rawFullText: rawText,
    );
  }

  // --- Helper Heuristics ---

  void _markUsedLine(List<String> lines, String snippet, Set<String> used) {
    for (final line in lines) {
      if (line.contains(snippet)) {
        used.add(line.trim());
      }
    }
  }

  String? _detectBank(String lower) {
    if (lower.contains('hdfc')) return 'HDFC Bank';
    if (lower.contains('state bank of india') || lower.contains('sbi')) return 'State Bank of India (SBI)';
    if (lower.contains('icici')) return 'ICICI Bank';
    if (lower.contains('axis bank') || lower.contains('axis')) return 'Axis Bank';
    if (lower.contains('kotak')) return 'Kotak Mahindra Bank';
    if (lower.contains('punjab national') || lower.contains('pnb')) return 'Punjab National Bank';
    if (lower.contains('bank of baroda') || lower.contains('bob')) return 'Bank of Baroda';
    if (lower.contains('canara')) return 'Canara Bank';
    if (lower.contains('indusind')) return 'IndusInd Bank';
    if (lower.contains('yes bank')) return 'Yes Bank';
    if (lower.contains('standard chartered')) return 'Standard Chartered';
    if (lower.contains('citi')) return 'Citibank';
    if (lower.contains('hsbc')) return 'HSBC';
    return null;
  }

  String? _detectInsuranceProvider(String lower) {
    if (lower.contains('lic') || lower.contains('life insurance corporation')) return 'Life Insurance Corporation (LIC)';
    if (lower.contains('star health')) return 'Star Health & Allied Insurance';
    if (lower.contains('icici lombard')) return 'ICICI Lombard';
    if (lower.contains('hdfc ergo')) return 'HDFC ERGO';
    if (lower.contains('care health') || lower.contains('religare')) return 'Care Health Insurance';
    if (lower.contains('bajaj allianz')) return 'Bajaj Allianz';
    if (lower.contains('new india assurance')) return 'The New India Assurance';
    if (lower.contains('united india')) return 'United India Insurance';
    if (lower.contains('oriental insurance')) return 'The Oriental Insurance';
    if (lower.contains('tata aig')) return 'Tata AIG';
    if (lower.contains('max life')) return 'Max Life Insurance';
    return null;
  }

  String? _extractCardholderName(List<String> lines, Set<String> used) {
    for (final line in lines) {
      final upper = line.toUpperCase().trim();
      // Candidate must be letters/spaces only, 4 to 28 chars, all caps, not matching known keywords
      if (RegExp(r'^[A-Z\s]{4,28}$').hasMatch(upper)) {
        if (!_isCardKeyword(upper) && !_isNoiseLine(upper)) {
          used.add(line);
          return upper;
        }
      }
    }
    return null;
  }

  bool _isCardKeyword(String text) {
    final lower = text.toLowerCase();
    return lower.contains('bank') ||
        lower.contains('debit') ||
        lower.contains('credit') ||
        lower.contains('visa') ||
        lower.contains('mastercard') ||
        lower.contains('rupay') ||
        lower.contains('valid') ||
        lower.contains('thru') ||
        lower.contains('platinum') ||
        lower.contains('signature') ||
        lower.contains('rewards') ||
        lower.contains('customer');
  }

  String? _extractHolderName(List<String> lines, String category, Set<String> used) {
    final nameLabels = ['name:', 'name', 'holder name:', 'full name:', 'elector name:'];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      for (final label in nameLabels) {
        if (lower.startsWith(label) || lower.contains('$label:')) {
          final parts = line.split(RegExp(r'[:\-]'));
          if (parts.length > 1 && parts[1].trim().length > 2) {
            final cand = parts[1].trim();
            if (_isValidNameCandidate(cand)) {
              used.add(line);
              return _cleanName(cand);
            }
          } else if (i + 1 < lines.length) {
            final nextLine = lines[i + 1].trim();
            if (_isValidNameCandidate(nextLine)) {
              used.add(line);
              used.add(nextLine);
              return _cleanName(nextLine);
            }
          }
        }
      }
    }

    // Category-specific heuristic: Aadhaar / PAN often has name near the top
    if (category == 'aadhaar' || category == 'pan') {
      for (int i = 0; i < lines.length && i < 6; i++) {
        final line = lines[i].trim();
        if (_isValidNameCandidate(line) && !_isGovtHeader(line)) {
          used.add(line);
          return _cleanName(line);
        }
      }
    }

    return null;
  }

  String? _extractLabeledField(List<String> lines, List<String> labels, Set<String> used) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      for (final label in labels) {
        if (lower.contains(label)) {
          final parts = line.split(RegExp(r'[:\-]'));
          if (parts.length > 1 && parts[1].trim().length > 2) {
            final val = parts[1].trim();
            used.add(line);
            return val;
          } else if (i + 1 < lines.length) {
            final next = lines[i + 1].trim();
            if (next.length > 2 && !_isNoiseLine(next)) {
              used.add(line);
              used.add(next);
              return next;
            }
          }
        }
      }
    }
    return null;
  }

  String? _extractAddress(List<String> lines, Set<String> used) {
    final addrBuffer = StringBuffer();
    bool capturing = false;

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('address:') || lower.contains('address') || lower.contains('s/o') || lower.contains('d/o') || lower.contains('w/o')) {
        capturing = true;
        final clean = line.replaceAll(RegExp(r'^(address|address:)\s*', caseSensitive: false), '').trim();
        if (clean.isNotEmpty) addrBuffer.writeln(clean);
        used.add(line);
        continue;
      }

      if (capturing) {
        // Stop capturing if we hit pin code or another labeled section
        if (RegExp(r'\b[1-9][0-9]{5}\b').hasMatch(line)) {
          addrBuffer.writeln(line.trim());
          used.add(line);
          break;
        }
        if (line.contains(':') || line.length < 3) {
          break;
        }
        addrBuffer.writeln(line.trim());
        used.add(line);
        if (addrBuffer.length > 150) break;
      }
    }

    final result = addrBuffer.toString().trim();
    return result.isEmpty ? null : result;
  }

  _ContextualDates _extractContextualDates(List<String> lines, Set<String> used) {
    DateTime? issueDate;
    DateTime? expiryDate;
    DateTime? dob;

    final expiryKeywords = ['valid till', 'valid upto', 'valid until', 'expiry', 'expires', 'exp date', 'valid through', 'valid thru'];
    final issueKeywords = ['issue date', 'date of issue', 'issued on', 'date of registration', 'issued date', 'valid from'];
    final dobKeywords = ['date of birth', 'dob', 'birth date', 'yob', 'year of birth'];

    for (final line in lines) {
      final lower = line.toLowerCase();

      // Check Expiry Date
      if (expiryDate == null) {
        for (final kw in expiryKeywords) {
          if (lower.contains(kw)) {
            final parsed = _findDateInString(line);
            if (parsed != null) {
              expiryDate = parsed;
              used.add(line);
              break;
            }
          }
        }
      }

      // Check Issue Date
      if (issueDate == null) {
        for (final kw in issueKeywords) {
          if (lower.contains(kw)) {
            final parsed = _findDateInString(line);
            if (parsed != null) {
              issueDate = parsed;
              used.add(line);
              break;
            }
          }
        }
      }

      // Check DOB
      if (dob == null) {
        for (final kw in dobKeywords) {
          if (lower.contains(kw)) {
            final parsed = _findDateInString(line);
            if (parsed != null) {
              dob = parsed;
              used.add(line);
              break;
            }
          }
        }
      }
    }

    return _ContextualDates(issueDate: issueDate, expiryDate: expiryDate, dob: dob);
  }

  DateTime? _findDateInString(String text) {
    // 1. Text date format: '25 Dec 2028'
    final textMatch = _dateTextRegex.firstMatch(text);
    if (textMatch != null) {
      final d = int.tryParse(textMatch.group(1)!);
      final m = _monthNameToNumber(textMatch.group(2)!);
      final y = int.tryParse(textMatch.group(3)!);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }

    // 2. DMY format: '25/12/2028'
    final dmyMatch = _dateDmyRegex.firstMatch(text);
    if (dmyMatch != null) {
      final d = int.tryParse(dmyMatch.group(1)!);
      final m = int.tryParse(dmyMatch.group(2)!);
      final y = int.tryParse(dmyMatch.group(3)!);
      if (d != null && m != null && y != null && m <= 12 && d <= 31) {
        return DateTime(y, m, d);
      }
    }

    // 3. YMD format: '2028-12-25'
    final ymdMatch = _dateYmdRegex.firstMatch(text);
    if (ymdMatch != null) {
      final y = int.tryParse(ymdMatch.group(1)!);
      final m = int.tryParse(ymdMatch.group(2)!);
      final d = int.tryParse(ymdMatch.group(3)!);
      if (d != null && m != null && y != null && m <= 12 && d <= 31) {
        return DateTime(y, m, d);
      }
    }

    return null;
  }

  int? _monthNameToNumber(String monthName) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[monthName.toLowerCase().substring(0, 3)];
  }

  bool _isValidNameCandidate(String candidate) {
    final trimmed = candidate.trim();
    if (trimmed.length < 3 || trimmed.length > 40) return false;
    // Names should primarily contain alphabetic characters and spaces
    if (RegExp(r'\d').hasMatch(trimmed)) return false;
    if (trimmed.contains('/') || trimmed.contains('\\') || trimmed.contains('@')) return false;
    return true;
  }

  bool _isGovtHeader(String text) {
    final lower = text.toLowerCase();
    return lower.contains('government') ||
        lower.contains('india') ||
        lower.contains('authority') ||
        lower.contains('income tax') ||
        lower.contains('department') ||
        lower.contains('transport') ||
        lower.contains('ministry') ||
        lower.contains('parivahan') ||
        lower.contains('uidai');
  }

  bool _isNoiseLine(String text) {
    final lower = text.toLowerCase();
    return lower.contains('http') ||
        lower.contains('www.') ||
        lower.contains('.gov.in') ||
        lower.contains('helpline') ||
        lower.contains('toll free') ||
        lower.contains('signature') ||
        text.length < 3;
  }

  String _cleanName(String raw) {
    return raw.replaceAll(RegExp(r'^(name|holder|full name)[\s:]*', caseSensitive: false), '').trim();
  }
}

class _ContextualDates {
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final DateTime? dob;

  const _ContextualDates({this.issueDate, this.expiryDate, this.dob});
}
