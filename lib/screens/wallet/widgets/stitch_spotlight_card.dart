import 'package:flutter/material.dart';
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
}

class StitchSpotlightCard extends StatefulWidget {
  final StitchCardType cardType;
  final String? holderName;
  final String? maskedNumber;
  final String? revealedNumber;
  final String? dob;
  final String? gender;
  final String? issuer;
  final String? expiry;
  final String? policyNumber;
  final String? epicNumber;
  final String? passportNumber;
  final VoidCallback? onTap;

  const StitchSpotlightCard({
    super.key,
    required this.cardType,
    this.holderName,
    this.maskedNumber,
    this.revealedNumber,
    this.dob,
    this.gender,
    this.issuer,
    this.expiry,
    this.policyNumber,
    this.epicNumber,
    this.passportNumber,
    this.onTap,
  });

  factory StitchSpotlightCard.fromDocument({
    required WalletDocumentModel document,
    VoidCallback? onTap,
  }) {
    final cat = document.category.toLowerCase();
    StitchCardType type;
    if (cat.contains('aadhaar')) {
      type = StitchCardType.aadhaar;
    } else if (cat.contains('pan')) {
      type = StitchCardType.pan;
    } else if (cat.contains('insur') || cat.contains('medic')) {
      type = StitchCardType.mediclaim;
    } else if (cat.contains('voter') || cat.contains('epic')) {
      type = StitchCardType.voterId;
    } else if (cat.contains('passport')) {
      type = StitchCardType.passport;
    } else {
      type = StitchCardType.aadhaar;
    }

    return StitchSpotlightCard(
      cardType: type,
      holderName: document.holderName?.isNotEmpty == true ? document.holderName : document.documentName,
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
    return StitchSpotlightCard(
      cardType: isCredit ? StitchCardType.credit : StitchCardType.debit,
      holderName: card.cardholderName,
      maskedNumber: card.maskedNumber,
      issuer: card.issuerName,
      expiry: '${card.expiryMonth.toString().padLeft(2, '0')}/${card.expiryYear.toString().substring(card.expiryYear.toString().length >= 2 ? card.expiryYear.toString().length - 2 : 0)}',
      onTap: onTap,
    );
  }

  @override
  State<StitchSpotlightCard> createState() => _StitchSpotlightCardState();
}

class _StitchSpotlightCardState extends State<StitchSpotlightCard> {
  bool _isRevealed = false;

  Future<void> _toggleReveal() async {
    if (_isRevealed) {
      setState(() => _isRevealed = false);
      return;
    }
    final auth = WalletAuthService();
    final ok = await auth.authenticate(
      localizedReason: 'Authenticate to reveal card number',
      forceBiometrics: true,
    );
    if (ok && mounted) {
      setState(() => _isRevealed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFB5CCA7), width: 1.5),
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
    }
  }

  // ─── 1. AADHAAR CARD ────────────────────────────────────────────────────────
  Widget _buildAadhaarCard(BuildContext context) {
    final holder = (widget.holderName != null && widget.holderName!.trim().isNotEmpty)
        ? widget.holderName!
        : 'Tap to Add Aadhaar';
    final number = _isRevealed
        ? (widget.revealedNumber ?? widget.maskedNumber ?? '•••• •••• ••••')
        : (widget.maskedNumber != null && widget.maskedNumber!.isNotEmpty
            ? widget.maskedNumber!
            : '•••• •••• ••••');
    final dob = widget.dob ?? '—';
    final gender = widget.gender ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4D2), // Cream
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E0BD), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF933E),
                      border: Border.all(color: const Color(0xFFD9835E), width: 1.0),
                    ),
                    child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'भारत सरकार • GOVT OF INDIA',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF954A00),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'भारतीय विशिष्ट पहचान प्राधिकरण',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111C2D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDCC6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'UIDAI',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF301400),
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
                  color: const Color(0xFFDEE8FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD8E3FB)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.person, color: Color(0xFF2E6385), size: 34),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: const Color(0xFF954A00),
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
                      'Name / नाम',
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
                                'DOB / जन्म',
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
                                  color: Color(0xFF111C2D),
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
                                'Gender / लिंग',
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
                                  color: Color(0xFF111C2D),
                                ),
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
                  gradient: LinearGradient(
                    colors: [Color(0xFFFECA55), Color(0xFFFF933E), Color(0xFF82B4DA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
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
                Column(
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
                        color: Color(0xFF111C2D),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _toggleReveal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF933E),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF933E).withAlpha(80),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fingerprint_rounded, size: 13, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          _isRevealed ? 'Hide' : 'Reveal',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
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
    final holder = (widget.holderName != null && widget.holderName!.trim().isNotEmpty)
        ? widget.holderName!
        : 'Tap to Add PAN';
    final number = _isRevealed
        ? (widget.revealedNumber ?? widget.maskedNumber ?? '••••••••••')
        : (widget.maskedNumber != null && widget.maskedNumber!.isNotEmpty
            ? widget.maskedNumber!
            : '••••••••••');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFCBDFBD), // Pistachio
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB5CCA7), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF2E6385),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INCOME TAX DEPARTMENT',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF024667),
                        ),
                      ),
                      Text(
                        'GOVT. OF INDIA • आयकर विभाग',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E6385),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFECA55),
                ),
                child: const Icon(Icons.stars_rounded, color: Color(0xFF735500), size: 16),
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
                child: const Icon(Icons.person, color: Color(0xFF2E6385), size: 34),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CARDHOLDER NAME',
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 8, color: Color(0xFF554337)),
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
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "STATUS",
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 8, color: Color(0xFF554337)),
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
                Column(
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
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _toggleReveal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E6385),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_rounded, size: 13, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          _isRevealed ? 'Hide' : 'View PAN',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. SPENDZ PLATINUM DEBIT ───────────────────────────────────────────────
  Widget _buildDebitCard(BuildContext context) {
    final holder = (widget.holderName != null && widget.holderName!.trim().isNotEmpty)
        ? widget.holderName!
        : 'Tap to Add Debit Card';
    final number = widget.maskedNumber ?? '•••• •••• •••• ••••';
    final issuer = widget.issuer ?? 'HDFC Bank';
    final expiry = widget.expiry ?? '12/28';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFA44A3F), // Deep Crimson Brick
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF883B32), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.token_rounded, color: Color(0xFFFECA55), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'SPENDZ RESERVE',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFECA55),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.contactless_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'PLATINUM',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
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
                    colors: [Color(0xFFFFD778), Color(0xFFF5BA3B), Color(0xFFB8860B)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
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
                  ),
                ],
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CARD HOLDER',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 8, color: Colors.white60),
                  ),
                  Text(
                    holder,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'EXPIRES / CVV',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 8, color: Colors.white60),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'RuPay »',
                  style: TextStyle(
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

  // ─── 4. WORLD ELITE CREDIT CARD ─────────────────────────────────────────────
  Widget _buildCreditCard(BuildContext context) {
    final holder = (widget.holderName != null && widget.holderName!.trim().isNotEmpty)
        ? widget.holderName!
        : 'Tap to Add Credit Card';
    final number = widget.maskedNumber ?? '•••• •••• •••• ••••';
    final expiry = widget.expiry ?? '10/29';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD4E09B), // Warm Chartreuse
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBFCC85), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.diamond_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'WORLD ELITE CREDIT',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '₹ 5,00,000 Limit',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
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
                    colors: [Color(0xFFFFFFFF), Color(0xFFFEDB92), Color(0xFFF4B338)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SPENDZ BLACK GOLD',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 9,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
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
                  ),
                ],
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PRIMARY HOLDER',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 8, color: Colors.white70),
                  ),
                  Text(
                    holder,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'VALID THRU',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 8, color: Colors.white70),
                  ),
                  Text(
                    expiry,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Text(
                'VISA Infinite',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 5. STAR HEALTH MEDICLAIM ───────────────────────────────────────────────
  Widget _buildMediclaimCard(BuildContext context) {
    final holder = (widget.holderName != null && widget.holderName!.trim().isNotEmpty)
        ? widget.holderName!
        : 'Tap to Add Insurance';
    final policy = widget.policyNumber ?? widget.maskedNumber ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF19C79), // Coral Terracotta
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9835E), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFBA1A1A),
                    ),
                    child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 15),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STAR HEALTH & ALLIED',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFBA1A1A),
                        ),
                      ),
                      Text(
                        'Cashless Medi-Claim Card',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111C2D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '₹ 15 Lakh Sum',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF93000A),
                  ),
                ),
              ),
            ],
          ),

          Container(
            padding: const EdgeInsets.all(8),
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
                      const Text('INSURED PERSON', style: TextStyle(fontSize: 7.5, color: Color(0xFF554337))),
                      Text(holder, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF111C2D))),
                      const SizedBox(height: 3),
                      const Text('TPA GROUP ID', style: TextStyle(fontSize: 7.5, color: Color(0xFF554337))),
                      const Text('SH-CORP-48821', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF111C2D))),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('POLICY NUMBER', style: TextStyle(fontSize: 7.5, color: Color(0xFF554337))),
                      Text(policy, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFBA1A1A))),
                      const SizedBox(height: 3),
                      const Text('EMERGENCY HELPLINE', style: TextStyle(fontSize: 7.5, color: Color(0xFF554337))),
                      const Text('1800 425 2255', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFBA1A1A))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.health_and_safety_rounded, color: Color(0xFFBA1A1A), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Pre-auth Network across 14,000+ Hospitals',
                    style: TextStyle(fontSize: 8.5, color: Color(0xFF554337), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFBA1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'E-Card PDF',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
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
    final holder = (widget.holderName != null && widget.holderName!.trim().isNotEmpty)
        ? widget.holderName!
        : 'Tap to Add Voter ID';
    final epic = widget.epicNumber ?? widget.maskedNumber ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFCBDFBD), // Pistachio
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB5CCA7), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF2E6385),
                    ),
                    child: const Icon(Icons.how_to_vote_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ELECTION COMMISSION OF INDIA',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E6385),
                        ),
                      ),
                      Text(
                        'भारत निर्वाचन आयोग • EPIC CARD',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111C2D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                child: const Icon(Icons.person, color: Color(0xFF2E6385), size: 34),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ELECTOR NAME', style: TextStyle(fontSize: 8, color: Color(0xFF554337))),
                    Text(
                      holder,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111C2D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text('CONSTITUENCY', style: TextStyle(fontSize: 8, color: Color(0xFF554337))),
                    const Text(
                      '168 - Bangalore South',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E6385),
                      ),
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
                child: const Icon(Icons.thumb_up_rounded, color: Color(0xFF954A00), size: 18),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('EPIC NUMBER', style: TextStyle(fontSize: 8, color: Color(0xFF554337))),
                    Text(
                      epic,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111C2D),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Part 42 • Polling 19',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111C2D),
                  ),
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
    final holder = (widget.holderName != null && widget.holderName!.trim().isNotEmpty)
        ? widget.holderName!
        : 'Tap to Add Passport';
    final passportNum = widget.passportNumber ?? widget.maskedNumber ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFA44A3F), // Deep Crimson Brick
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF883B32), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFECA55),
                    ),
                    child: const Icon(Icons.public_rounded, color: Color(0xFF735500), size: 17),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PASSPORT • पासपोर्ट',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFECA55),
                        ),
                      ),
                      Text(
                        'REPUBLIC OF INDIA • भारत गणराज्य',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                child: const Icon(Icons.person, color: Colors.white70, size: 34),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SURNAME / GIVEN NAMES', style: TextStyle(fontSize: 8, color: Colors.white60)),
                    Text(
                      holder,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NATIONALITY', style: TextStyle(fontSize: 7.5, color: Colors.white60)),
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
                              Text('EXPIRY DATE', style: TextStyle(fontSize: 7.5, color: Colors.white60)),
                              Text(
                                '22 OCT 2032',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PASSPORT NUMBER', style: TextStyle(fontSize: 8, color: Colors.white60)),
                    Text(
                      passportNum,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFECA55),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Valid till Oct 2032',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
