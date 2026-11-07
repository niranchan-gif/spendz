import 'package:flutter/material.dart';
import '../../../features/wallet/security/secure_number_service.dart';
import '../../../features/wallet/security/wallet_auth_service.dart';
import '../../../models/wallet_document_model.dart';
import '../../../models/wallet_card_model.dart';

enum StitchCardType {
  aadhaar,
  pan,
  debit,
  credit,
  mediclaim,
  voterId,
  passport,
  drivingLicence,
}

class StitchSpotlightCard extends StatefulWidget {
  final StitchCardType cardType;
  final String? cardId;
  final String? documentId;
  final String? holderName;
  final String? maskedNumber;
  final String? revealedNumber;
  final String? dob;
  final String? gender;
  final String? issuer;
  final String? expiry;
  final String? cardNetwork;
  final String? policyNumber;
  final String? epicNumber;
  final String? passportNumber;
  final String? vehicleClass;
  final String? stateName;
  final VoidCallback? onTap;

  const StitchSpotlightCard({
    super.key,
    required this.cardType,
    this.cardId,
    this.documentId,
    this.holderName,
    this.maskedNumber,
    this.revealedNumber,
    this.dob,
    this.gender,
    this.issuer,
    this.expiry,
    this.cardNetwork,
    this.policyNumber,
    this.epicNumber,
    this.passportNumber,
    this.vehicleClass,
    this.stateName,
    this.onTap,
  });

  static String _formatMonthYear(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final y = (date.year % 100).toString().padLeft(2, '0');
    return '$m/$y';
  }

  static String _formatFullDate(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final mon = months[date.month - 1];
    return '$day $mon ${date.year}';
  }

  factory StitchSpotlightCard.fromDocument({
    required WalletDocumentModel document,
    VoidCallback? onTap,
  }) {
    final cat = document.category.toLowerCase();
    final name = document.documentName.toLowerCase();
    StitchCardType type;
    if (cat.contains('aadhaar')) {
      type = StitchCardType.aadhaar;
    } else if (cat.contains('pan')) {
      type = StitchCardType.pan;
    } else if (cat.contains('credit') || name.contains('credit')) {
      type = StitchCardType.credit;
    } else if (cat.contains('debit') ||
        cat.contains('payment') ||
        name.contains('debit')) {
      type = StitchCardType.debit;
    } else if (cat.contains('insur') || cat.contains('medic')) {
      type = StitchCardType.mediclaim;
    } else if (cat.contains('voter') || cat.contains('epic')) {
      type = StitchCardType.voterId;
    } else if (cat.contains('passport')) {
      type = StitchCardType.passport;
    } else if (cat.contains('licen') || cat.contains('driv')) {
      type = StitchCardType.drivingLicence;
    } else {
      type = StitchCardType.aadhaar;
    }

    String? holder = document.holderName;
    String? dob;
    String? gender;
    String? provider;
    String? bank;
    String? network;
    String? issuer;
    String? stateName;
    String? vehicleClass;

    if (document.description != null && document.description!.isNotEmpty) {
      for (final line in document.description!.split('\n')) {
        final t = line.trim();
        if ((holder == null || holder.isEmpty) && t.startsWith('Holder:')) {
          holder = t.replaceFirst('Holder:', '').trim();
        } else if (t.startsWith('DOB:')) {
          dob = t.replaceFirst('DOB:', '').trim();
        } else if (t.startsWith('Gender:')) {
          gender = t.replaceFirst('Gender:', '').trim();
        } else if (t.startsWith('Provider:')) {
          provider = t.replaceFirst('Provider:', '').trim();
        } else if (t.startsWith('Bank:')) {
          bank = t.replaceFirst('Bank:', '').trim();
        } else if (t.startsWith('Network:')) {
          network = t.replaceFirst('Network:', '').trim();
        } else if (t.startsWith('Issuer:')) {
          issuer = t.replaceFirst('Issuer:', '').trim();
        } else if (t.startsWith('State:')) {
          stateName = t.replaceFirst('State:', '').trim();
        } else if (t.startsWith('Vehicle Class:')) {
          vehicleClass = t.replaceFirst('Vehicle Class:', '').trim();
        }
      }
    }

    if (holder == null || holder.trim().isEmpty) {
      holder = document.documentName;
    }

    String? effectiveIssuer = provider ?? bank ?? issuer;
    if (effectiveIssuer == null || effectiveIssuer.trim().isEmpty) {
      if (type == StitchCardType.mediclaim) {
        effectiveIssuer = document.documentName.trim().isNotEmpty
            ? document.documentName.trim()
            : 'Health Insurance';
      } else if (type == StitchCardType.debit) {
        effectiveIssuer = document.documentName.trim().isNotEmpty
            ? document.documentName.trim()
            : 'Debit Card';
      } else if (type == StitchCardType.credit) {
        effectiveIssuer = document.documentName.trim().isNotEmpty
            ? document.documentName.trim()
            : 'Credit Card';
      } else {
        effectiveIssuer = document.documentName;
      }
    }

    final expiry = document.expiryDate;
    String? expiryLabel;
    if (expiry != null) {
      if (type == StitchCardType.debit || type == StitchCardType.credit) {
        expiryLabel = _formatMonthYear(expiry);
      } else {
        expiryLabel = _formatFullDate(expiry);
      }
    }

    return StitchSpotlightCard(
      cardType: type,
      documentId: document.id,
      holderName: holder,
      issuer: effectiveIssuer,
      cardNetwork: network,
      expiry: expiryLabel,
      dob: dob,
      gender: gender,
      vehicleClass: vehicleClass,
      stateName: stateName,
      maskedNumber: document.maskedIdentifier,
      policyNumber: document.maskedIdentifier,
      epicNumber: document.maskedIdentifier,
      passportNumber: document.maskedIdentifier,
      onTap: onTap,
    );
  }

  factory StitchSpotlightCard.fromCard({
    required WalletCardModel card,
    VoidCallback? onTap,
  }) {
    final isCredit = card.cardType.toLowerCase().contains('credit');
    final bankName = card.issuerName.trim().isNotEmpty
        ? card.issuerName.trim()
        : (card.nickname.trim().isNotEmpty
              ? card.nickname.trim()
              : (isCredit ? 'Credit Card' : 'Debit Card'));
    final network = card.cardNetwork.trim().isNotEmpty
        ? card.cardNetwork.toUpperCase()
        : (isCredit ? 'CREDIT' : 'DEBIT');

    final expYearStr = card.expiryYear.toString();
    final shortYear = expYearStr.length >= 2
        ? expYearStr.substring(expYearStr.length - 2)
        : expYearStr.padLeft(2, '0');
    final expiryLabel =
        '${card.expiryMonth.toString().padLeft(2, '0')}/$shortYear';

    return StitchSpotlightCard(
      cardType: isCredit ? StitchCardType.credit : StitchCardType.debit,
      cardId: card.id,
      holderName: card.cardholderName,
      maskedNumber: card.maskedNumber,
      issuer: bankName,
      cardNetwork: network,
      expiry: expiryLabel,
      onTap: onTap,
    );
  }

  @override
  State<StitchSpotlightCard> createState() => _StitchSpotlightCardState();
}

class _StitchSpotlightCardState extends State<StitchSpotlightCard> {
  bool _isRevealed = false;
  String? _unmaskedNumber;

  String _formatCardNumber(String raw) {
    return SecureNumberService.formatCardNumber(raw);
  }

  String _formatAadhaarNumber(String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+'), '');
    if (clean.length == 12) {
      return '${clean.substring(0, 4)} ${clean.substring(4, 8)} ${clean.substring(8)}';
    }
    return _formatCardNumber(clean);
  }

  Future<void> _toggleReveal() async {
    if (_isRevealed) {
      setState(() {
        _isRevealed = false;
        _unmaskedNumber = null;
      });
      return;
    }

    bool ok = false;
    final auth = WalletAuthService();
    try {
      final canAuth = await auth.canCheckBiometrics();
      if (canAuth) {
        ok = await auth.authenticate(
          localizedReason: 'Authenticate to reveal number',
          forceBiometrics: false,
        );
      } else {
        ok = true;
      }
    } catch (_) {
      ok = true;
    }

    if (!ok || !mounted) return;

    String? realNumber = widget.revealedNumber;
    if (realNumber == null || realNumber.isEmpty) {
      final sec = SecureNumberService();
      if (widget.cardId != null && widget.cardId!.isNotEmpty) {
        realNumber = await sec.getCardFullNumber(widget.cardId!);
      } else if (widget.documentId != null && widget.documentId!.isNotEmpty) {
        realNumber = await sec.getDocumentFullNumber(widget.documentId!);
      }
    }

    if (mounted) {
      setState(() {
        _isRevealed = true;
        _unmaskedNumber = realNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x222C221E),
              blurRadius: 8,
              offset: Offset(2.5, 4),
            ),
            BoxShadow(
              color: Colors.white,
              blurRadius: 2,
              offset: Offset(-1.5, -1.5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: _buildCardContent(context),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    switch (widget.cardType) {
      case StitchCardType.aadhaar:
        return _buildAadhaarCard(context);
      case StitchCardType.pan:
        return _buildPanCard(context);
      case StitchCardType.debit:
        return _buildDebitCard(context);
      case StitchCardType.credit:
        return _buildCreditCard(context);
      case StitchCardType.mediclaim:
        return _buildMediclaimCard(context);
      case StitchCardType.voterId:
        return _buildVoterIdCard(context);
      case StitchCardType.passport:
        return _buildPassportCard(context);
      case StitchCardType.drivingLicence:
        return _buildDrivingLicenceCard(context);
    }
  }

  Widget _buildRevealButton({Color? bgColor, Color? textColor}) {
    final bg = bgColor ?? Colors.white.withAlpha(50);
    final fg = textColor ?? Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleReveal,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isRevealed
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 13,
                color: fg,
              ),
              const SizedBox(width: 4),
              Text(
                _isRevealed ? 'HIDE' : 'REVEAL',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 1. AADHAAR CARD ────────────────────────────────────────────────────────
  Widget _buildAadhaarCard(BuildContext context) {
    final holder =
        (widget.holderName != null && widget.holderName!.trim().isNotEmpty)
        ? widget.holderName!
        : 'Tap to Add Aadhaar';
    final number = _isRevealed
        ? (_unmaskedNumber != null && _unmaskedNumber!.isNotEmpty
            ? _formatAadhaarNumber(_unmaskedNumber!)
            : (widget.revealedNumber != null &&
                      widget.revealedNumber!.isNotEmpty
                  ? _formatAadhaarNumber(widget.revealedNumber!)
                  : (widget.maskedNumber ?? '•••• •••• ••••')))
        : (widget.maskedNumber != null && widget.maskedNumber!.isNotEmpty
              ? widget.maskedNumber!
              : '•••• •••• ••••');
    final dob = widget.dob ?? '—';
    final gender = widget.gender ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD4E09B), // Chartreuse Olive
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/aadhar.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF933E),
                          ),
                          child: const Icon(
                            Icons.wb_sunny_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GOVERNMENT OF INDIA',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF554337),
                              letterSpacing: 0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Unique Identification Authority of India',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2C221E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F4D2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'UIDAI',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C221E),
                  ),
                ),
              ),
            ],
          ),

          Row(
            children: [
              Container(
                width: 44,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F4D2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color(0xFF2C221E),
                      size: 34,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: const Color(0xFFA44A3F),
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: const Text(
                          'VERIFIED',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 9,
                        color: Color(0xFF554337),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      holder,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C221E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DOB',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 8,
                                  color: Color(0xFF554337),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                dob,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2C221E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gender',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 8,
                                  color: Color(0xFF554337),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                gender,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2C221E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF6F4D2),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFFA44A3F),
                  size: 18,
                ),
              ),
            ],
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AADHAAR NUMBER',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF554337),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        number,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C221E),
                          letterSpacing: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildRevealButton(
                  bgColor: const Color(0xFFF19C79),
                  textColor: const Color(0xFF2C221E),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. PAN CARD ────────────────────────────────────────────────────────────
  Widget _buildPanCard(BuildContext context) {
    final holder =
        (widget.holderName != null && widget.holderName!.trim().isNotEmpty)
        ? widget.holderName!
        : 'Tap to Add PAN';
    final number = _isRevealed
        ? (_unmaskedNumber != null && _unmaskedNumber!.isNotEmpty
            ? _unmaskedNumber!
            : (widget.revealedNumber ?? widget.maskedNumber ?? '••••••••••'))
        : (widget.maskedNumber != null && widget.maskedNumber!.isNotEmpty
              ? widget.maskedNumber!
              : '••••••••••');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFCBDFBD), // Pistachio
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/PAN.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFF2E6385),
                          ),
                          child: const Icon(
                            Icons.account_balance_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INCOME TAX DEPARTMENT',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF024667),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'GOVERNMENT OF INDIA • INCOME TAX DEPT',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2E6385),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFECA55),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFF735500),
                  size: 16,
                ),
              ),
            ],
          ),

          Row(
            children: [
              Container(
                width: 44,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF2E6385),
                  size: 34,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CARDHOLDER NAME',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 8,
                        color: Color(0xFF554337),
                      ),
                    ),
                    Text(
                      holder,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111C2D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'STATUS',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 8,
                        color: Color(0xFF554337),
                      ),
                    ),
                    const Text(
                      'ACTIVE & LINKED',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F5B38),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PERMANENT ACCOUNT NUMBER',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF554337),
                        ),
                      ),
                      Text(
                        number,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E6385),
                          letterSpacing: 1.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildRevealButton(
                  bgColor: const Color(0xFFF19C79),
                  textColor: const Color(0xFF2C221E),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. DEBIT CARD ──────────────────────────────────────────────────────────
  Widget _buildDebitCard(BuildContext context) {
    final holder =
        (widget.holderName != null && widget.holderName!.trim().isNotEmpty)
        ? widget.holderName!
        : 'Tap to Add Debit Card';
    final issuer =
        (widget.issuer != null && widget.issuer!.trim().isNotEmpty)
        ? widget.issuer!.trim()
        : 'DEBIT CARD';
    final network =
        (widget.cardNetwork != null && widget.cardNetwork!.trim().isNotEmpty)
        ? widget.cardNetwork!.trim().toUpperCase()
        : 'DEBIT';
    final number = _isRevealed
        ? (_unmaskedNumber != null && _unmaskedNumber!.isNotEmpty
            ? _formatCardNumber(_unmaskedNumber!)
            : (widget.revealedNumber != null &&
                      widget.revealedNumber!.isNotEmpty
                  ? _formatCardNumber(widget.revealedNumber!)
                  : (widget.maskedNumber ?? '•••• •••• •••• ••••')))
        : (widget.maskedNumber != null && widget.maskedNumber!.isNotEmpty
              ? widget.maskedNumber!
              : '•••• •••• •••• ••••');
    final expiry = widget.expiry ?? 'MM/YY';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFA44A3F), // Deep Crimson Brick
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset(
                        'assets/credit_Debit.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.credit_card_rounded,
                          color: Color(0xFFFECA55),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        issuer.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFECA55),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.contactless_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      network,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildRevealButton(
                    bgColor: const Color(0xFFFECA55),
                    textColor: const Color(0xFF2C221E),
                  ),
                ],
              ),
            ],
          ),

          Row(
            children: [
              Container(
                width: 36,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFD778),
                      Color(0xFFF5BA3B),
                      Color(0xFFB8860B),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEBIT CARD • ${issuer.toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 9,
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      number,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CARD HOLDER',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 8,
                        color: Colors.white60,
                      ),
                    ),
                    Text(
                      holder,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'EXPIRES / CVV',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 8,
                      color: Colors.white60,
                    ),
                  ),
                  Text(
                    '$expiry • •••',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFECA55),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  network,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111C2D),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 4. CREDIT CARD ─────────────────────────────────────────────────────────
  Widget _buildCreditCard(BuildContext context) {
    final holder =
        (widget.holderName != null && widget.holderName!.trim().isNotEmpty)
        ? widget.holderName!
        : 'Tap to Add Credit Card';
    final issuer =
        (widget.issuer != null && widget.issuer!.trim().isNotEmpty)
        ? widget.issuer!.trim()
        : 'CREDIT CARD';
    final network =
        (widget.cardNetwork != null && widget.cardNetwork!.trim().isNotEmpty)
        ? widget.cardNetwork!.trim().toUpperCase()
        : 'CREDIT';
    final number = _isRevealed
        ? (_unmaskedNumber != null && _unmaskedNumber!.isNotEmpty
            ? _formatCardNumber(_unmaskedNumber!)
            : (widget.revealedNumber != null &&
                      widget.revealedNumber!.isNotEmpty
                  ? _formatCardNumber(widget.revealedNumber!)
                  : (widget.maskedNumber ?? '•••• •••• •••• ••••')))
        : (widget.maskedNumber != null && widget.maskedNumber!.isNotEmpty
              ? widget.maskedNumber!
              : '•••• •••• •••• ••••');
    final expiry = widget.expiry ?? 'MM/YY';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD4E09B), // Chartreuse Olive
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset(
                        'assets/credit_Debit.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.diamond_rounded,
                          color: Color(0xFF2C221E),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        issuer.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C221E),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.contactless_rounded,
                    color: Color(0xFF2C221E),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C221E).withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      network,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C221E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildRevealButton(
                    bgColor: const Color(0xFFF19C79),
                    textColor: const Color(0xFF2C221E),
                  ),
                ],
              ),
            ],
          ),

          Row(
            children: [
              Container(
                width: 36,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFFEDB92),
                      Color(0xFFF4B338),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CREDIT CARD • ${issuer.toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 9,
                        color: Color(0xFF4C6B22),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      number,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C221E),
                        letterSpacing: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRIMARY HOLDER',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 8,
                        color: Color(0xFF4C6B22),
                      ),
                    ),
                    Text(
                      holder,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C221E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'VALID THRU',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 8,
                      color: Color(0xFF4C6B22),
                    ),
                  ),
                  Text(
                    expiry,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C221E),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Text(
                network,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2C221E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 5. MEDICLAIM / HEALTH INSURANCE ────────────────────────────────────────
  Widget _buildMediclaimCard(BuildContext context) {
    final holder =
        (widget.holderName != null && widget.holderName!.trim().isNotEmpty)
        ? widget.holderName!
        : 'Tap to Add Insurance';
    final provider =
        (widget.issuer != null && widget.issuer!.trim().isNotEmpty)
        ? widget.issuer!.trim()
        : 'Health Insurance';
    final policy = _isRevealed
        ? (_unmaskedNumber != null && _unmaskedNumber!.isNotEmpty
            ? _unmaskedNumber!
            : (widget.revealedNumber ??
                  widget.policyNumber ??
                  widget.maskedNumber ??
                  '—'))
        : (widget.policyNumber ?? widget.maskedNumber ?? '••••••••••••');
    final expiry = widget.expiry ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF19C79), // Coral Terracotta
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/Insurance.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFA44A3F),
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFA44A3F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Cashless Medi-Claim Card',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2C221E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildRevealButton(
                bgColor: const Color(0xFFF6F4D2),
                textColor: const Color(0xFFA44A3F),
              ),
            ],
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INSURED PERSON',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 8,
                          color: Color(0xFF554337),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        holder,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111C2D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'POLICY NUMBER',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 8,
                          color: Color(0xFF554337),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        policy,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFA44A3F),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.health_and_safety_rounded,
                      color: Color(0xFFA44A3F),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Cashless Network Covered',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 9,
                          color: Color(0xFF2C221E),
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (expiry != '—' && expiry != 'MM/YY')
                Text(
                  'VALID THRU: $expiry',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C221E),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 6. VOTER ID (EPIC CARD) ────────────────────────────────────────────────
  Widget _buildVoterIdCard(BuildContext context) {
    final holder =
        (widget.holderName != null && widget.holderName!.trim().isNotEmpty)
        ? widget.holderName!
        : 'Tap to Add Voter ID';
    final epicDisplay = _isRevealed
        ? (_unmaskedNumber != null && _unmaskedNumber!.isNotEmpty
            ? _unmaskedNumber!
            : (widget.revealedNumber ??
                  widget.epicNumber ??
                  widget.maskedNumber ??
                  '—'))
        : (widget.epicNumber ?? widget.maskedNumber ?? '••••••••••');
    final region = widget.stateName?.isNotEmpty == true
        ? widget.stateName!
        : (widget.issuer?.isNotEmpty == true &&
                  widget.issuer != 'Election Commission of India'
              ? widget.issuer!
              : 'OFFICIAL ELECTOR');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFCBDFBD), // Pistachio
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/voterid.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFF2E6385),
                          ),
                          child: const Icon(
                            Icons.how_to_vote_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ELECTION COMMISSION OF INDIA',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2E6385),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'ELECTION COMMISSION OF INDIA • EPIC',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111C2D),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFC9E6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'ELECTOR',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF001E2F),
                  ),
                ),
              ),
            ],
          ),

          Row(
            children: [
              Container(
                width: 44,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF2E6385),
                  size: 34,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ELECTOR NAME',
                      style: TextStyle(fontSize: 8, color: Color(0xFF554337)),
                    ),
                    Text(
                      holder,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111C2D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'CONSTITUENCY / REGION',
                      style: TextStyle(fontSize: 8, color: Color(0xFF554337)),
                    ),
                    Text(
                      region,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E6385),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(
                  Icons.thumb_up_rounded,
                  color: Color(0xFF954A00),
                  size: 18,
                ),
              ),
            ],
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EPIC NUMBER',
                        style: TextStyle(fontSize: 8, color: Color(0xFF554337)),
                      ),
                      Text(
                        epicDisplay,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111C2D),
                          letterSpacing: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildRevealButton(
                  bgColor: const Color(0xFFF19C79),
                  textColor: const Color(0xFF2C221E),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 7. INDIAN PASSPORT ─────────────────────────────────────────────────────
  Widget _buildPassportCard(BuildContext context) {
    final holder =
        (widget.holderName != null && widget.holderName!.trim().isNotEmpty)
        ? widget.holderName!
        : 'Tap to Add Passport';
    final passportDisplay = _isRevealed
        ? (_unmaskedNumber != null && _unmaskedNumber!.isNotEmpty
            ? _unmaskedNumber!
            : (widget.revealedNumber ??
                  widget.passportNumber ??
                  widget.maskedNumber ??
                  '—'))
        : (widget.passportNumber ?? widget.maskedNumber ?? '••••••••');
    final expiry = widget.expiry ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFA44A3F), // Deep Crimson Brick
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/passport.jpeg',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFECA55),
                          ),
                          child: const Icon(
                            Icons.public_rounded,
                            color: Color(0xFF735500),
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PASSPORT',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFECA55),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'INDIAN PASSPORT',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFECA55).withAlpha(50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Type P • IND',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFECA55),
                  ),
                ),
              ),
            ],
          ),

          Row(
            children: [
              Container(
                width: 44,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white70,
                  size: 34,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SURNAME / GIVEN NAMES',
                      style: TextStyle(fontSize: 8, color: Colors.white60),
                    ),
                    Text(
                      holder,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NATIONALITY',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  color: Colors.white60,
                                ),
                              ),
                              Text(
                                'INDIAN',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFECA55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'EXPIRY DATE',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  color: Colors.white60,
                                ),
                              ),
                              Text(
                                expiry,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PASSPORT NUMBER',
                        style: TextStyle(fontSize: 8, color: Colors.white60),
                      ),
                      Text(
                        passportDisplay,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFECA55),
                          letterSpacing: 1.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildRevealButton(
                  bgColor: const Color(0xFFD4E09B),
                  textColor: const Color(0xFF2C221E),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 8. DRIVING LICENCE (MoRTH) ─────────────────────────────────────────────
  Widget _buildDrivingLicenceCard(BuildContext context) {
    final holder =
        (widget.holderName != null && widget.holderName!.trim().isNotEmpty)
        ? widget.holderName!
        : 'Tap to Add Licence';
    final dlDisplay = _isRevealed
        ? (_unmaskedNumber != null && _unmaskedNumber!.isNotEmpty
            ? _unmaskedNumber!
            : (widget.revealedNumber ?? widget.maskedNumber ?? '—'))
        : (widget.maskedNumber != null && widget.maskedNumber!.isNotEmpty
              ? widget.maskedNumber!
              : '••••••••••••••••');
    final vehicleClass = widget.vehicleClass?.isNotEmpty == true
        ? widget.vehicleClass!
        : 'LMV • MCWG';
    final expiry = widget.expiry ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFCBDFBD), // Pistachio
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/licence.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFF2E6385),
                          ),
                          child: const Icon(
                            Icons.drive_eta_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UNION OF INDIA',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF024667),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'DRIVING LICENCE • MoRTH',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2E6385),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4E09B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  vehicleClass,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C221E),
                  ),
                ),
              ),
            ],
          ),

          Row(
            children: [
              Container(
                width: 44,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF2E6385),
                  size: 34,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LICENCE HOLDER',
                      style: TextStyle(fontSize: 8, color: Color(0xFF554337)),
                    ),
                    Text(
                      holder,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111C2D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CLASS',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  color: Color(0xFF554337),
                                ),
                              ),
                              Text(
                                vehicleClass,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E6385),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'VALID THRU',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  color: Color(0xFF554337),
                                ),
                              ),
                              Text(
                                expiry,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F5B38),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LICENCE NUMBER',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF554337),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        dlDisplay,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E6385),
                          letterSpacing: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildRevealButton(
                  bgColor: const Color(0xFFF19C79),
                  textColor: const Color(0xFF2C221E),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
