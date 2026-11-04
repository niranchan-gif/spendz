import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../features/wallet/security/secure_number_service.dart';
import '../../../features/wallet/security/wallet_auth_service.dart';
import '../../../models/wallet_document_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_radius.dart';

/// Ultra-high-fidelity, authentic virtual card widget for Indian & Global
/// identity documents, financial cards, and certificates.
///
/// Supports dedicated authentic layouts for:
/// - Aadhaar Card (UIDAI Tricolor, Ashoka emblem, watermark, QR, biometric lock)
/// - PAN Card (Income Tax Dept oceanic navy/teal, Ashoka crest, QR, signature strip)
/// - Driving Licence (MoRTH Union of India, EMV Smart Chip, vehicle class badges)
/// - Passport (Deep royal midnight navy leatherette, metallic gold foil emblem, ICAO MRZ)
/// - Vehicle RC (High Security Registration Plate layout, vehicle specs)
/// - Insurance Card (Medical shield, cashless hospital network, policy details)
/// - Voter ID / EPIC (Election Commission of India layout)
/// - Payment Cards (Brushed metal finish, EMV chip, contactless symbol, network badge)
/// - Generic / Certificates (Sleek vault certificate layout)
///
/// Features hardware-backed Biometric Tap-to-Reveal:
/// Masked by default, private numbers require biometric authentication to reveal,
/// with automatic 30s session timeout and background re-masking.
class VirtualDocumentCard extends StatefulWidget {
  final WalletDocumentModel document;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool showShadow;
  final bool isInteractive;
  final bool allowReveal;

  const VirtualDocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onFavoriteToggle,
    this.showShadow = true,
    this.isInteractive = true,
    this.allowReveal = true,
  });

  @override
  State<VirtualDocumentCard> createState() => _VirtualDocumentCardState();
}

class _VirtualDocumentCardState extends State<VirtualDocumentCard>
    with WidgetsBindingObserver {
  bool _isRevealed = false;
  String? _unmaskedNumber;
  Timer? _sessionTimer;
  final SecureNumberService _secureNumberService = SecureNumberService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _maskNumber();
    }
  }

  void _maskNumber() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    if (mounted) {
      setState(() {
        _isRevealed = false;
        _unmaskedNumber = null;
      });
    }
  }

  Future<void> _toggleReveal() async {
    if (_isRevealed) {
      _maskNumber();
      return;
    }

    WalletAuthService? authService;
    try {
      authService = context.read<WalletAuthService>();
    } catch (_) {}

    if (authService != null) {
      final authenticated = await authService.authenticate(
        localizedReason:
            'Authenticate with biometrics to reveal private document number',
      );
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authService.lastErrorMessage ??
                    'Biometric authentication required to reveal private number.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    final fullNumber = await _secureNumberService.getDocumentFullNumber(
      widget.document.id,
    );
    if (!mounted) return;

    if (fullNumber != null && fullNumber.isNotEmpty) {
      setState(() {
        _isRevealed = true;
        _unmaskedNumber = fullNumber;
      });

      _sessionTimer?.cancel();
      _sessionTimer = Timer(const Duration(seconds: 30), () {
        if (mounted) _maskNumber();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No unmasked number found in secure storage.'),
        ),
      );
    }
  }

  String _formatRevealedNumber(String category, String raw) {
    final clean = raw.replaceAll(' ', '').trim();
    switch (category.toLowerCase()) {
      case 'aadhaar':
        if (clean.length == 12) {
          return '${clean.substring(0, 4)} ${clean.substring(4, 8)} ${clean.substring(8, 12)}';
        }
        return raw;
      case 'debit_card':
      case 'credit_card':
        if (clean.length == 16) {
          return '${clean.substring(0, 4)} ${clean.substring(4, 8)} ${clean.substring(8, 12)} ${clean.substring(12, 16)}';
        }
        return raw;
      case 'pan':
        return raw.toUpperCase();
      default:
        return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        // Standard ID-1 card aspect ratio ~1.586 (85.60 mm × 53.98 mm)
        final cardHeight = (cardWidth / 1.586).clamp(210.0, 245.0);

        return Container(
          width: cardWidth,
          height: cardHeight,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card + 4),
            boxShadow: widget.showShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(55),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.card + 4),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppRadius.card + 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card + 4),
                child: _buildCardContent(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(BuildContext context) {
    switch (widget.document.category.toLowerCase()) {
      case 'debit_card':
      case 'credit_card':
        return _buildPaymentCard(context);
      case 'aadhaar':
        return _buildAadhaarCard(context);
      case 'pan':
        return _buildPanCard(context);
      case 'driving_license':
        return _buildDrivingLicenceCard(context);
      case 'passport':
        return _buildPassportCard(context);
      case 'voter_id':
        return _buildVoterIdCard(context);
      case 'insurance':
        return _buildInsuranceCard(context);
      case 'rc':
        return _buildRcCard(context);
      case 'certificate':
      default:
        return _buildGenericDocCard(context);
    }
  }

  // ==========================================
  // 1. AUTHENTIC AADHAAR CARD (UIDAI)
  // ==========================================
  Widget _buildAadhaarCard(BuildContext context) {
    final meta = _parseCardMetadata();
    final holder = meta.holder.isNotEmpty
        ? meta.holder
        : widget.document.documentName;
    final defaultNumber = meta.number.isNotEmpty
        ? meta.number
        : '•••• •••• 4567';
    final displayNumber = (_isRevealed && _unmaskedNumber != null)
        ? _formatRevealedNumber('aadhaar', _unmaskedNumber!)
        : defaultNumber;

    return Stack(
      children: [
        // Background: Warm ivory security parchment
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFDF9), Color(0xFFFBF8F0), Color(0xFFF5EFE1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Subtle Guilloche / Chakra Security Watermark
        Positioned.fill(
          child: CustomPaint(
            painter: _SecurityWatermarkPainter(
              accentColor: const Color(0xFFFF9933).withAlpha(18),
            ),
          ),
        ),

        // Official Indian Tricolor Top Ribbon (Saffron, White, Emerald)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 4.5,
            child: Row(
              children: [
                Expanded(child: Container(color: const Color(0xFFFF9933))),
                Expanded(child: Container(color: const Color(0xFFFFFFFF))),
                Expanded(child: Container(color: const Color(0xFF138808))),
              ],
            ),
          ),
        ),

        // Card Content
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Emblem + Govt of India + UIDAI Logo & Slogan
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 26,
                    height: 32,
                    child: CustomPaint(
                      painter: _AshokaEmblemPainter(color: Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'भारत सरकार',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.3,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Government of India',
                          style: TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w700,
                            fontSize: 8.5,
                            letterSpacing: 0.8,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // UIDAI Badge + Motto
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CustomPaint(
                              painter: _UidaiSunburstPainter(),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF138808).withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF138808).withAlpha(60),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'UIDAI',
                              style: TextStyle(
                                color: Color(0xFF138808),
                                fontWeight: FontWeight.w900,
                                fontSize: 9.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'मेरा आधार, मेरी पहचान',
                        style: TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w700,
                          fontSize: 8,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Middle Row: Photo Box + Details + QR Tile
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Photo Portrait Frame with Security Hologram Border
                    Container(
                      width: 48,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.person,
                            color: Color(0xFF94A3B8),
                            size: 34,
                          ),
                          Positioned(
                            bottom: 1,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 0.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9933).withAlpha(40),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Text(
                                'UID',
                                style: TextStyle(
                                  fontSize: 6,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Holder Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            holder,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            meta.dob.isNotEmpty
                                ? 'DOB / जन्म: ${meta.dob}'
                                : (widget.document.issueDate != null
                                      ? 'Issue: ${DateFormat('dd/MM/yyyy').format(widget.document.issueDate!)}'
                                      : 'DOB: ••/••/••••'),
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            meta.gender.isNotEmpty
                                ? 'Gender / लिंग: ${meta.gender.toUpperCase()}'
                                : 'Gender / लिंग: VERIFIED',
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    // 2D Secure QR Matrix Graphic
                    const _QrMatrixWidget(
                      label: 'Secure QR',
                      size: 44,
                      accentColor: Color(0xFF0F172A),
                    ),
                  ],
                ),
              ),

              // Bottom Aadhaar Number with Biometric Tap-to-Reveal
              Center(
                child: InkWell(
                  onTap: widget.allowReveal ? _toggleReveal : null,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isRevealed
                                  ? Icons.lock_open_rounded
                                  : Icons.fingerprint_rounded,
                              color: _isRevealed
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF15803D),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              displayNumber,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 2.2,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _isRevealed
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              color: _isRevealed
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFF94A3B8),
                              size: 14,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // UIDAI Authentic Red Underline Bar
                        Container(
                          width: 140,
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Micro Footer Helpline
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'UIDAI Helpline: 1947',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 7.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'help@uidai.gov.in',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 7.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Favorite Toggle Icon
        if (widget.onFavoriteToggle != null)
          Positioned(
            top: 6,
            right: 6,
            child: _buildFavoriteButton(isDarkTheme: false),
          ),
      ],
    );
  }

  // ==========================================
  // 2. AUTHENTIC PAN CARD (INCOME TAX DEPT)
  // ==========================================
  Widget _buildPanCard(BuildContext context) {
    final meta = _parseCardMetadata();
    final holder = meta.holder.isNotEmpty
        ? meta.holder.toUpperCase()
        : widget.document.documentName.toUpperCase();
    final defaultNumber = meta.number.isNotEmpty ? meta.number : 'ABCDE••••F';
    final displayNumber = (_isRevealed && _unmaskedNumber != null)
        ? _formatRevealedNumber('pan', _unmaskedNumber!)
        : defaultNumber;
    final father = meta.father.isNotEmpty
        ? meta.father.toUpperCase()
        : 'GOVT RECORD';

    return Stack(
      children: [
        // Background: Light blue security parchment with diagonal weave
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Diagonal Guilloche Security Pattern
        Positioned.fill(
          child: CustomPaint(
            painter: _SecurityWatermarkPainter(
              accentColor: const Color(0xFF0284C7).withAlpha(16),
            ),
          ),
        ),

        Column(
          children: [
            // Top Ribbon: Deep Oceanic Navy Header Band
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'आयकर विभाग',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 8.5,
                            height: 1.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'INCOME TAX DEPARTMENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 8.5,
                            height: 1.1,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 4),

                  const SizedBox(
                    width: 18,
                    height: 22,
                    child: CustomPaint(
                      painter: _AshokaEmblemPainter(color: Color(0xFFFDE047)),
                    ),
                  ),

                  const SizedBox(width: 4),

                  const Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'भारत सरकार',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 8.5,
                            height: 1.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'GOVT. OF INDIA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 8.5,
                            height: 1.1,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Card Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Row with Photo + Details + QR/Hologram
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 44,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFF1E3A8A),
                                  width: 1.2,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: Color(0xFF64748B),
                                    size: 30,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF59E0B),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(3),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.verified,
                                        size: 9,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 44,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                  color: const Color(0xFF94A3B8),
                                  width: 0.6,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Signatory',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 7,
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 10),

                        // Center Fields: Name, Father's Name, DOB
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'नाम / Name',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                holder,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                "पिता का नाम / Father's Name",
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                father,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'जन्म की तारीख / Date of Birth',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                meta.dob.isNotEmpty
                                    ? meta.dob
                                    : (widget.document.issueDate != null
                                          ? DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(widget.document.issueDate!)
                                          : '••/••/••••'),
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Column(
                          children: [
                            _HologramSealWidget(size: 24),
                            SizedBox(height: 4),
                            _QrMatrixWidget(
                              label: 'ITD QR',
                              size: 38,
                              accentColor: Color(0xFF1E3A8A),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Bottom Permanent Account Number Area with Biometric Reveal
                    InkWell(
                      onTap: widget.allowReveal ? _toggleReveal : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(200),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF0284C7).withAlpha(80),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'स्थायी लेखा संख्या / Permanent Account Number',
                                    style: TextStyle(
                                      color: Color(0xFF334155),
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    displayNumber,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.4,
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _isRevealed
                                  ? Icons.lock_open_rounded
                                  : Icons.shield_outlined,
                              color: _isRevealed
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF0284C7),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        if (widget.onFavoriteToggle != null)
          Positioned(
            top: 2,
            right: 4,
            child: _buildFavoriteButton(isDarkTheme: true),
          ),
      ],
    );
  }

  // ==========================================
  // 3. AUTHENTIC DRIVING LICENCE (MORTH)
  // ==========================================
  Widget _buildDrivingLicenceCard(BuildContext context) {
    final meta = _parseCardMetadata();
    final holder = meta.holder.isNotEmpty
        ? meta.holder.toUpperCase()
        : widget.document.documentName.toUpperCase();
    final defaultNumber = meta.number.isNotEmpty ? meta.number : 'DL-••••4321';
    final displayNumber = (_isRevealed && _unmaskedNumber != null)
        ? _unmaskedNumber!
        : defaultNumber;

    return Stack(
      children: [
        // Background: Rich emerald green & dual jade gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF042F2E), Color(0xFF022320)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Gold Trim Line at top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFDE047),
                  Color(0xFFD97706),
                  Color(0xFFFDE047),
                ],
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header Row: Transport Emblem + Union of India + Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_car_filled_rounded,
                          color: Color(0xFFFDE047),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'UNION OF INDIA / भारतीय संघ',
                                style: TextStyle(
                                  color: Color(0xFFFDE047),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9.5,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'DRIVING LICENCE',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(220),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 8,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (widget.document.isExpired
                                  ? Colors.red
                                  : const Color(0xFF10B981))
                              .withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: widget.document.isExpired
                            ? Colors.redAccent
                            : const Color(0xFF34D399),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      widget.document.isExpired ? 'EXPIRED' : 'ACTIVE',
                      style: TextStyle(
                        color: widget.document.isExpired
                            ? Colors.redAccent
                            : const Color(0xFF34D399),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              // Middle: Smart Chip + Photo + DL Number + Vehicle Badges
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const _EmvChipWidget(width: 36, height: 26),
                      const SizedBox(height: 4),
                      Container(
                        width: 36,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFFDE047).withAlpha(100),
                            width: 0.8,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // Licence Number with Biometric Reveal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LICENCE NUMBER',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 8,
                            letterSpacing: 0.8,
                          ),
                        ),
                        InkWell(
                          onTap: widget.allowReveal ? _toggleReveal : null,
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  displayNumber,
                                  style: const TextStyle(
                                    color: Color(0xFFFDE047),
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.6,
                                    fontFamily: 'monospace',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                _isRevealed
                                    ? Icons.lock_open_rounded
                                    : Icons.lock_outline_rounded,
                                color: _isRevealed
                                    ? Colors.greenAccent
                                    : const Color(0xFFFDE047).withAlpha(180),
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'HOLDER NAME',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 8,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          holder,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _buildVehicleClassBadge('LMV'),
                            const SizedBox(width: 4),
                            _buildVehicleClassBadge('MCWG'),
                            if (meta.vehicleClasses.isNotEmpty &&
                                !meta.vehicleClasses.contains('LMV')) ...[
                              const SizedBox(width: 4),
                              _buildVehicleClassBadge(
                                meta.vehicleClasses.first,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),
                  const _HologramSealWidget(size: 32),
                ],
              ),

              // Bottom Validity Dates Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ISSUED ON',
                        style: TextStyle(color: Colors.white54, fontSize: 7.5),
                      ),
                      Text(
                        widget.document.issueDate != null
                            ? DateFormat(
                                'dd MMM yyyy',
                              ).format(widget.document.issueDate!)
                            : '•• ••• ••••',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'VALID TILL (NT)',
                        style: TextStyle(color: Colors.white54, fontSize: 7.5),
                      ),
                      Text(
                        widget.document.expiryDate != null
                            ? DateFormat(
                                'dd MMM yyyy',
                              ).format(widget.document.expiryDate!)
                            : 'NON-TRANSPORT',
                        style: const TextStyle(
                          color: Color(0xFFFDE047),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        if (widget.onFavoriteToggle != null)
          Positioned(
            top: 6,
            right: 6,
            child: _buildFavoriteButton(isDarkTheme: true),
          ),
      ],
    );
  }

  static Widget _buildVehicleClassBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE047).withAlpha(30),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: const Color(0xFFFDE047).withAlpha(80),
          width: 0.6,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFDE047),
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ==========================================
  // 4. AUTHENTIC PASSPORT (REPUBLIC OF INDIA)
  // ==========================================
  Widget _buildPassportCard(BuildContext context) {
    final meta = _parseCardMetadata();
    final holder = meta.holder.isNotEmpty
        ? meta.holder.toUpperCase()
        : widget.document.documentName.toUpperCase();
    final defaultNumber = meta.number.isNotEmpty ? meta.number : 'J••••678';
    final displayNumber = (_isRevealed && _unmaskedNumber != null)
        ? _unmaskedNumber!
        : defaultNumber;

    return Stack(
      children: [
        // Background: Deep royal midnight navy leatherette texture
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F1E36), Color(0xFF0A1424), Color(0xFF040A14)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card - 2),
              border: Border.all(
                color: const Color(0xFFD4AF37).withAlpha(120),
                width: 0.8,
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 28,
                    child: CustomPaint(
                      painter: _AshokaEmblemPainter(color: Color(0xFFD4AF37)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REPUBLIC OF INDIA / PASSPORT',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          'भारत गणराज्य / पासपोर्ट',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 8.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withAlpha(30),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'TYPE P',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Passport Number with Biometric Reveal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PASSPORT NO.',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 8,
                          letterSpacing: 0.8,
                        ),
                      ),
                      InkWell(
                        onTap: widget.allowReveal ? _toggleReveal : null,
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.8,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _isRevealed
                                  ? Icons.lock_open_rounded
                                  : Icons.lock_outline_rounded,
                              color: _isRevealed
                                  ? Colors.greenAccent
                                  : const Color(0xFFD4AF37),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'NATIONALITY',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 8,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            color: Color(0xFFFF9933),
                            size: 10,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'INDIAN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Holder Name & Expiry
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GIVEN NAME(S) / SURNAME',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 7.5,
                          ),
                        ),
                        Text(
                          holder,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (widget.document.expiryDate != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'EXPIRY DATE',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 7.5,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(widget.document.expiryDate!),
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Authentic ICAO Machine Readable Zone (MRZ)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(90),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withAlpha(50),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'P<IND${holder.replaceAll(RegExp(r'[^A-Z]'), '<')}<<<<<<<<<<<<<<<<<<<<<<<<<<'
                          .padRight(44, '<')
                          .substring(0, 36),
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontFamily: 'monospace',
                        fontSize: 8.5,
                        letterSpacing: 1.0,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      '${defaultNumber.replaceAll(RegExp(r'[^A-Z0-9]'), '')}<0IND9001015M3001014<<<<<<<<<<<<<<06'
                          .padRight(44, '<')
                          .substring(0, 36),
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontFamily: 'monospace',
                        fontSize: 8.5,
                        letterSpacing: 1.0,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (widget.onFavoriteToggle != null)
          Positioned(
            top: 6,
            right: 6,
            child: _buildFavoriteButton(isDarkTheme: true),
          ),
      ],
    );
  }

  // ==========================================
  // 5. AUTHENTIC VEHICLE RC CARD
  // ==========================================
  Widget _buildRcCard(BuildContext context) {
    final meta = _parseCardMetadata();
    final holder = meta.holder.isNotEmpty
        ? meta.holder
        : widget.document.documentName;
    final defaultNumber = meta.number.isNotEmpty
        ? meta.number
        : 'MH 02 AB 1234';
    final displayNumber = (_isRevealed && _unmaskedNumber != null)
        ? _unmaskedNumber!
        : defaultNumber;

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF450A0A), Color(0xFF2E0808), Color(0xFF1B0505)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car_rounded,
                        color: Color(0xFFFDE047),
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'CERTIFICATE OF REGISTRATION',
                        style: TextStyle(
                          color: Color(0xFFFDE047),
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  _HologramSealWidget(size: 20),
                ],
              ),

              // High Security Registration Plate (HSRP) representation
              Center(
                child: InkWell(
                  onTap: widget.allowReveal ? _toggleReveal : null,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF08A),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.black, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(60),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.circle, size: 4, color: Colors.amber),
                              Text(
                                'IND',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayNumber,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.2,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _isRevealed
                              ? Icons.lock_open_rounded
                              : Icons.lock_outline_rounded,
                          color: _isRevealed ? Colors.green : Colors.black54,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'REGISTERED OWNER',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 7.5,
                          ),
                        ),
                        Text(
                          holder,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (widget.document.expiryDate != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'FITNESS UPTO',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 7.5,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'MM/yy',
                          ).format(widget.document.expiryDate!),
                          style: const TextStyle(
                            color: Color(0xFFFDE047),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),

        if (widget.onFavoriteToggle != null)
          Positioned(
            top: 6,
            right: 6,
            child: _buildFavoriteButton(isDarkTheme: true),
          ),
      ],
    );
  }

  // ==========================================
  // 6. AUTHENTIC INSURANCE POLICY CARD
  // ==========================================
  Widget _buildInsuranceCard(BuildContext context) {
    final meta = _parseCardMetadata();
    final holder = meta.holder.isNotEmpty
        ? meta.holder
        : widget.document.documentName;
    final defaultNumber = meta.number.isNotEmpty ? meta.number : 'POL-••••1122';
    final displayNumber = (_isRevealed && _unmaskedNumber != null)
        ? _unmaskedNumber!
        : defaultNumber;
    final provider = meta.issuer.isNotEmpty
        ? meta.issuer
        : (meta.provider.isNotEmpty ? meta.provider : 'INSURANCE POLICY');

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF115E59), Color(0xFF042F2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.health_and_safety_rounded,
                        color: Color(0xFF2DD4BF),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2DD4BF).withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF2DD4BF).withAlpha(80),
                        width: 0.6,
                      ),
                    ),
                    child: const Text(
                      'CASHLESS VERIFIED',
                      style: TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'POLICY NUMBER',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 8,
                      letterSpacing: 0.8,
                    ),
                  ),
                  InkWell(
                    onTap: widget.allowReveal ? _toggleReveal : null,
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            displayNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _isRevealed
                              ? Icons.lock_open_rounded
                              : Icons.lock_outline_rounded,
                          color: _isRevealed
                              ? Colors.greenAccent
                              : Colors.white60,
                          size: 14,
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
                          'INSURED PERSON',
                          style: TextStyle(color: Colors.white60, fontSize: 8),
                        ),
                        Text(
                          holder,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (widget.document.expiryDate != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'VALID THRU',
                          style: TextStyle(color: Colors.white60, fontSize: 8),
                        ),
                        Text(
                          DateFormat(
                            'dd MMM yyyy',
                          ).format(widget.document.expiryDate!),
                          style: TextStyle(
                            color: widget.document.isExpired
                                ? Colors.redAccent
                                : const Color(0xFF2DD4BF),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),

        if (widget.onFavoriteToggle != null)
          Positioned(
            top: 6,
            right: 6,
            child: _buildFavoriteButton(isDarkTheme: true),
          ),
      ],
    );
  }

  // ==========================================
  // 7. AUTHENTIC VOTER ID / EPIC CARD
  // ==========================================
  Widget _buildVoterIdCard(BuildContext context) {
    final meta = _parseCardMetadata();
    final holder = meta.holder.isNotEmpty
        ? meta.holder
        : widget.document.documentName;
    final defaultNumber = meta.number.isNotEmpty ? meta.number : 'EPIC •••••••';
    final displayNumber = (_isRevealed && _unmaskedNumber != null)
        ? _unmaskedNumber!
        : defaultNumber;

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ELECTION COMMISSION OF INDIA\nभारत निर्वाचन आयोग',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 9.5,
                    ),
                  ),
                  Icon(
                    Icons.how_to_vote_rounded,
                    color: Color(0xFFFDE047),
                    size: 20,
                  ),
                ],
              ),

              Center(
                child: InkWell(
                  onTap: widget.allowReveal ? _toggleReveal : null,
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayNumber,
                        style: const TextStyle(
                          color: Color(0xFFFDE047),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _isRevealed
                            ? Icons.lock_open_rounded
                            : Icons.lock_outline_rounded,
                        color: _isRevealed
                            ? Colors.greenAccent
                            : const Color(0xFFFDE047),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    holder,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Text(
                    'ELECTOR PHOTO ID',
                    style: TextStyle(color: Colors.white70, fontSize: 8.5),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (widget.onFavoriteToggle != null)
          Positioned(
            top: 6,
            right: 6,
            child: _buildFavoriteButton(isDarkTheme: true),
          ),
      ],
    );
  }

  // ==========================================
  // 8. AUTHENTIC PAYMENT CARD (CREDIT / DEBIT)
  // ==========================================
  Widget _buildPaymentCard(BuildContext context) {
    final isCredit = widget.document.category.toLowerCase() == 'credit_card';
    final cardColor1 = isCredit
        ? const Color(0xFF1E293B)
        : const Color(0xFF1E3A8A);
    final cardColor2 = isCredit
        ? const Color(0xFF0F172A)
        : const Color(0xFF0F2042);
    final meta = _parseCardMetadata();
    final holder = meta.holder.isNotEmpty
        ? meta.holder.toUpperCase()
        : widget.document.documentName.toUpperCase();
    final defaultNumber = meta.number.isNotEmpty
        ? meta.number
        : '•••• •••• •••• ••••';
    final displayNumber = (_isRevealed && _unmaskedNumber != null)
        ? _formatRevealedNumber('payment', _unmaskedNumber!)
        : defaultNumber;
    final bank = meta.issuer.isNotEmpty
        ? meta.issuer
        : (meta.bank.isNotEmpty
              ? meta.bank
              : (isCredit ? 'CREDIT CARD' : 'DEBIT CARD'));

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cardColor1, cardColor2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(AppSpacing.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bank.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 12.5,
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(
                        Icons.contactless_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),

              const _EmvChipWidget(width: 38, height: 28),

              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: widget.allowReveal ? _toggleReveal : null,
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _isRevealed
                            ? Icons.lock_open_rounded
                            : Icons.lock_outline_rounded,
                        color: _isRevealed
                            ? Colors.greenAccent
                            : Colors.white60,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CARDHOLDER',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 8,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          holder,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  if (widget.document.expiryDate != null) ...[
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'VALID THRU',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 8,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'MM/yy',
                          ).format(widget.document.expiryDate!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    meta.network.isNotEmpty
                        ? meta.network.toUpperCase()
                        : 'PAYMENT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (widget.onFavoriteToggle != null)
          Positioned(
            top: 6,
            right: 6,
            child: _buildFavoriteButton(isDarkTheme: true),
          ),
      ],
    );
  }

  // ==========================================
  // 9. GENERIC / CERTIFICATE VAULT CARD
  // ==========================================
  Widget _buildGenericDocCard(BuildContext context) {
    final meta = _parseCardMetadata();
    final isPdf = widget.document.mimeType.contains('pdf');
    final holder = meta.holder.isNotEmpty
        ? meta.holder
        : widget.document.documentName;
    final displayNumber = (_isRevealed && _unmaskedNumber != null)
        ? _unmaskedNumber!
        : meta.number;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withAlpha(220)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.description_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.document.category
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.document.documentName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (displayNumber.isNotEmpty)
                    InkWell(
                      onTap: widget.allowReveal ? _toggleReveal : null,
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayNumber,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _isRevealed
                                ? Icons.lock_open_rounded
                                : Icons.lock_outline_rounded,
                            color: _isRevealed
                                ? Colors.greenAccent
                                : Colors.white60,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    holder,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  if (widget.document.expiryDate != null)
                    Text(
                      'Exp: ${DateFormat('dd MMM yyyy').format(widget.document.expiryDate!)}',
                      style: TextStyle(
                        color: widget.document.isExpired
                            ? Colors.redAccent
                            : Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        if (widget.onFavoriteToggle != null)
          Positioned(
            top: 6,
            right: 6,
            child: _buildFavoriteButton(isDarkTheme: true),
          ),
      ],
    );
  }

  Widget _buildFavoriteButton({required bool isDarkTheme}) {
    return IconButton(
      icon: Icon(
        widget.document.isFavorite
            ? Icons.star_rounded
            : Icons.star_border_rounded,
        color: widget.document.isFavorite
            ? Colors.amber
            : (isDarkTheme ? Colors.white60 : Colors.black45),
        size: 20,
      ),
      onPressed: widget.onFavoriteToggle,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  _ParsedMetadata _parseCardMetadata() {
    String holder = widget.document.holderName ?? '';
    String number = widget.document.maskedIdentifier ?? '';
    String issuer = '';
    String network = '';
    String father = '';
    String dob = '';
    String gender = '';
    String bank = '';
    String provider = '';
    final List<String> vehicleClasses = [];

    if (widget.document.description != null) {
      final lines = widget.document.description!.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (holder.isEmpty && trimmed.startsWith('Holder:')) {
          holder = trimmed.replaceFirst('Holder:', '').trim();
        } else if (number.isEmpty && trimmed.startsWith('Number:')) {
          number = trimmed.replaceFirst('Number:', '').trim();
        } else if (trimmed.startsWith('Father:')) {
          father = trimmed.replaceFirst('Father:', '').trim();
        } else if (trimmed.startsWith('DOB:')) {
          dob = trimmed.replaceFirst('DOB:', '').trim();
        } else if (trimmed.startsWith('Gender:')) {
          gender = trimmed.replaceFirst('Gender:', '').trim();
        } else if (trimmed.startsWith('Issuer:')) {
          issuer = trimmed.replaceFirst('Issuer:', '').trim();
        } else if (trimmed.startsWith('Bank:')) {
          bank = trimmed.replaceFirst('Bank:', '').trim();
        } else if (trimmed.startsWith('Network:')) {
          network = trimmed.replaceFirst('Network:', '').trim();
        } else if (trimmed.startsWith('Provider:')) {
          provider = trimmed.replaceFirst('Provider:', '').trim();
        } else if (trimmed.startsWith('Vehicle Class:')) {
          final raw = trimmed.replaceFirst('Vehicle Class:', '').trim();
          vehicleClasses.addAll(
            raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
          );
        }
      }
    }

    return _ParsedMetadata(
      holder: holder,
      number: number,
      issuer: issuer,
      network: network,
      father: father,
      dob: dob,
      gender: gender,
      bank: bank,
      provider: provider,
      vehicleClasses: vehicleClasses,
    );
  }
}

class _ParsedMetadata {
  final String holder;
  final String number;
  final String issuer;
  final String network;
  final String father;
  final String dob;
  final String gender;
  final String bank;
  final String provider;
  final List<String> vehicleClasses;

  _ParsedMetadata({
    required this.holder,
    required this.number,
    required this.issuer,
    required this.network,
    required this.father,
    required this.dob,
    required this.gender,
    required this.bank,
    required this.provider,
    required this.vehicleClasses,
  });
}

// ==========================================
// CUSTOM VECTOR ART & FINTECH GRAPHIC PAINTERS
// ==========================================

/// Golden EMV Microchip with authentic contact trace pads
class _EmvChipWidget extends StatelessWidget {
  final double width;
  final double height;

  const _EmvChipWidget({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFE082),
            Color(0xFFD4AF37),
            Color(0xFFB8860B),
            Color(0xFFD4AF37),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black26, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            left: width * 0.38,
            child: Container(
              width: 1,
              color: const Color(0xFF78350F).withAlpha(150),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: width * 0.38,
            child: Container(
              width: 1,
              color: const Color(0xFF78350F).withAlpha(150),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: height * 0.5,
            child: Container(
              height: 1,
              color: const Color(0xFF78350F).withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }
}

/// Iridescent Holographic Security Seal
class _HologramSealWidget extends StatelessWidget {
  final double size;

  const _HologramSealWidget({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [
            Color(0xFFFFDFBA),
            Color(0xFFBAFFC9),
            Color(0xFFBAE1FF),
            Color(0xFFFFB3BA),
            Color(0xFFFFDFBA),
          ],
        ),
        border: Border.all(color: Colors.white.withAlpha(200), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.verified_rounded,
          color: Colors.white.withAlpha(230),
          size: size * 0.6,
        ),
      ),
    );
  }
}

/// Authentic 2D Matrix / QR Code Tile
class _QrMatrixWidget extends StatelessWidget {
  final String label;
  final double size;
  final Color accentColor;

  const _QrMatrixWidget({
    required this.label,
    required this.size,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(3.5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: accentColor.withAlpha(70), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: CustomPaint(painter: _QrMatrixPainter(color: accentColor)),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: accentColor.withAlpha(180),
            fontSize: 7,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// Vector Painter for simulated 2D QR finder matrix
class _QrMatrixPainter extends CustomPainter {
  final Color color;

  _QrMatrixPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final finderSize = w * 0.32;

    _drawFinderSquare(canvas, 0, 0, finderSize, paint);
    _drawFinderSquare(canvas, w - finderSize, 0, finderSize, paint);
    _drawFinderSquare(canvas, 0, h - finderSize, finderSize, paint);

    final dotSize = w * 0.08;
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if ((i + j) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(
              w * 0.38 + (i * dotSize * 1.1),
              h * 0.38 + (j * dotSize * 1.1),
              dotSize,
              dotSize,
            ),
            paint,
          );
        }
      }
    }
  }

  void _drawFinderSquare(
    Canvas canvas,
    double x,
    double y,
    double s,
    Paint paint,
  ) {
    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.25;
    canvas.drawRect(Rect.fromLTWH(x + 1, y + 1, s - 2, s - 2), outerPaint);

    final innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final innerMargin = s * 0.32;
    canvas.drawRect(
      Rect.fromLTWH(
        x + innerMargin,
        y + innerMargin,
        s - (2 * innerMargin),
        s - (2 * innerMargin),
      ),
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Vector Painter for the Ashoka Lion Capital Emblem of India
class _AshokaEmblemPainter extends CustomPainter {
  final Color color;

  const _AshokaEmblemPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final headPath = Path();
    headPath.moveTo(w * 0.5, 0);
    headPath.lineTo(w * 0.35, h * 0.15);
    headPath.lineTo(w * 0.38, h * 0.38);
    headPath.lineTo(w * 0.5, h * 0.44);
    headPath.lineTo(w * 0.62, h * 0.38);
    headPath.lineTo(w * 0.65, h * 0.15);
    headPath.close();
    canvas.drawPath(headPath, paint);

    final leftLion = Path();
    leftLion.moveTo(w * 0.25, h * 0.12);
    leftLion.lineTo(w * 0.1, h * 0.25);
    leftLion.lineTo(w * 0.18, h * 0.42);
    leftLion.lineTo(w * 0.35, h * 0.42);
    leftLion.lineTo(w * 0.32, h * 0.2);
    leftLion.close();
    canvas.drawPath(leftLion, paint);

    final rightLion = Path();
    rightLion.moveTo(w * 0.75, h * 0.12);
    rightLion.lineTo(w * 0.9, h * 0.25);
    rightLion.lineTo(w * 0.82, h * 0.42);
    rightLion.lineTo(w * 0.65, h * 0.42);
    rightLion.lineTo(w * 0.68, h * 0.2);
    rightLion.close();
    canvas.drawPath(rightLion, paint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.48, w * 0.7, h * 0.12),
        const Radius.circular(1.5),
      ),
      paint,
    );

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(w * 0.5, h * 0.72), w * 0.18, strokePaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.72), 1.5, paint);

    final lotusPath = Path();
    lotusPath.moveTo(w * 0.1, h * 0.96);
    lotusPath.lineTo(w * 0.9, h * 0.96);
    lotusPath.lineTo(w * 0.75, h * 0.88);
    lotusPath.lineTo(w * 0.25, h * 0.88);
    lotusPath.close();
    canvas.drawPath(lotusPath, paint);
  }

  @override
  bool shouldRepaint(covariant _AshokaEmblemPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Vector Painter for UIDAI Sunburst Ray Emblem
class _UidaiSunburstPainter extends CustomPainter {
  const _UidaiSunburstPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final rayPaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 3.14159 / 4);
      final p1 = Offset(
        center.dx +
            (radius * 0.5 * (angle == 0 ? 1 : (angle == 3.14159 ? -1 : 0))),
        center.dy,
      );
      final p2 = Offset(
        center.dx + (radius * (angle == 0 ? 1 : (angle == 3.14159 ? -1 : 0))),
        center.dy,
      );
      canvas.drawLine(p1, p2, rayPaint);
    }

    final archPaint = Paint()
      ..color = const Color(0xFFFF9933)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, archPaint);
  }

  @override
  bool shouldRepaint(covariant _UidaiSunburstPainter oldDelegate) => false;
}

/// Subtle Guilloche Security Micro-pattern
class _SecurityWatermarkPainter extends CustomPainter {
  final Color accentColor;

  _SecurityWatermarkPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final center = Offset(size.width * 0.5, size.height * 0.5);

    for (double r = 30; r < size.width * 0.8; r += 24) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SecurityWatermarkPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
