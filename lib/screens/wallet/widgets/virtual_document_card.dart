import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/wallet_document_model.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_radius.dart';

/// Interactive, high-fidelity virtual document card for the digital document wallet.
/// Supports category-specific layouts for Payment Cards, Aadhaar, PAN, DL, Passport,
/// Insurance, Voter ID, and Certificates.
class VirtualDocumentCard extends StatelessWidget {
  final WalletDocumentModel document;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool showShadow;

  const VirtualDocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onFavoriteToggle,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        // Standard ID-1 card aspect ratio ~1.586
        final cardHeight = cardWidth / 1.586;

        return Container(
          width: cardWidth,
          height: cardHeight,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card + 4),
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.card + 4),
            child: InkWell(
              onTap: onTap,
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
    switch (document.category.toLowerCase()) {
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

  // --- Payment Card (Debit / Credit) ---
  Widget _buildPaymentCard(BuildContext context) {
    final isCredit = document.category.toLowerCase() == 'credit_card';
    final cardColor1 = isCredit ? const Color(0xFF1E293B) : const Color(0xFF1E3A8A);
    final cardColor2 = isCredit ? const Color(0xFF0F172A) : const Color(0xFF0F2042);
    final (holder, number, bank, network) = _parseCardMetadata();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor1, cardColor2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Bank Name, Chip, Network
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bank.isNotEmpty ? bank.toUpperCase() : (isCredit ? 'CREDIT CARD' : 'DEBIT CARD'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 13,
                ),
              ),
              Row(
                children: [
                  if (onFavoriteToggle != null)
                    IconButton(
                      icon: Icon(
                        document.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                        color: document.isFavorite ? Colors.amber : Colors.white60,
                        size: 20,
                      ),
                      onPressed: onFavoriteToggle,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.contactless_rounded, color: Colors.white70, size: 20),
                ],
              ),
            ],
          ),

          // Metallic Chip
          Container(
            width: 38,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFDF7A), Color(0xFFD4AF37), Color(0xFFB8860B)],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black26),
            ),
          ),

          // Card Number
          Text(
            number.isNotEmpty ? number : '•••• •••• •••• ••••',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.2,
            ),
          ),

          // Bottom Row: Holder & Expiry
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CARDHOLDER', style: TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 0.8)),
                  Text(
                    holder.isNotEmpty ? holder.toUpperCase() : document.documentName.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (document.expiryDate != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('VALID THRU', style: TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 0.8)),
                    Text(
                      DateFormat('MM/yy').format(document.expiryDate!),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              Text(
                network.isNotEmpty ? network.toUpperCase() : 'PAYMENT',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Aadhaar Card ---
  Widget _buildAadhaarCard(BuildContext context) {
    final (holder, number, _, _) = _parseCardMetadata();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFBFBFB),
      ),
      child: Column(
        children: [
          // Tricolor Header
          Container(
            height: 5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // UIDAI Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('भारत सरकार', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11)),
                          Text('Government of India', style: TextStyle(color: Colors.black54, fontSize: 10)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF138808).withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('UIDAI', style: TextStyle(color: Color(0xFF138808), fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),

                  // Middle: Holder Name & Details
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(Icons.person, color: Colors.grey, size: 30),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              holder.isNotEmpty ? holder : document.documentName,
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (document.issueDate != null)
                              Text(
                                'Issue: ${DateFormat('dd/MM/yyyy').format(document.issueDate!)}',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                              ),
                            const Text(
                              'मेरा आधार, मेरी पहचान',
                              style: TextStyle(color: Color(0xFFB91C1C), fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Bottom: Aadhaar Number
                  Center(
                    child: Text(
                      number.isNotEmpty ? number : '•••• •••• ••••',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 2.0,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- PAN Card ---
  Widget _buildPanCard(BuildContext context) {
    final (holder, number, _, _) = _parseCardMetadata();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'आयकर विभाग\nINCOME TAX DEPARTMENT',
                  style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  'भारत सरकार\nGOVT. OF INDIA',
                  textAlign: TextAlign.end,
                  style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          Center(
            child: Column(
              children: [
                const Text(
                  'PERMANENT ACCOUNT NUMBER CARD',
                  style: TextStyle(color: Color(0xFF0F172A), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                Text(
                  number.isNotEmpty ? number : 'ABCDE 1234F',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NAME', style: TextStyle(color: Color(0xFF475569), fontSize: 8)),
                  Text(
                    holder.isNotEmpty ? holder.toUpperCase() : document.documentName.toUpperCase(),
                    style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              const Icon(Icons.verified_rounded, color: Color(0xFF0284C7), size: 24),
            ],
          ),
        ],
      ),
    );
  }

  // --- Driving Licence ---
  Widget _buildDrivingLicenceCard(BuildContext context) {
    final (holder, number, _, _) = _parseCardMetadata();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF042F2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.directions_car_rounded, color: Colors.amber, size: 18),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'UNION OF INDIA DRIVING LICENCE',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (document.expiryDate != null)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: document.isExpired ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    document.isExpired ? 'EXPIRED' : 'VALID',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),

          Text(
            number.isNotEmpty ? number : 'DL-•••••••••••••',
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontFamily: 'monospace',
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LICENCE HOLDER', style: TextStyle(color: Colors.white54, fontSize: 8)),
                    Text(
                      holder.isNotEmpty ? holder.toUpperCase() : document.documentName.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (document.expiryDate != null) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('VALID TILL', style: TextStyle(color: Colors.white54, fontSize: 8)),
                    Text(
                      DateFormat('dd MMM yyyy').format(document.expiryDate!),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- Passport ---
  Widget _buildPassportCard(BuildContext context) {
    final (holder, number, _, _) = _parseCardMetadata();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F1E36), Color(0xFF0A1120)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'REPUBLIC OF INDIA / PASSPORT',
                  style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.public_rounded, color: Color(0xFFD4AF37), size: 18),
            ],
          ),

          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFFD4AF37), size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PASSPORT NO.', style: TextStyle(color: Colors.white54, fontSize: 8)),
                    Text(
                      number.isNotEmpty ? number : 'P•••••••',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontFamily: 'monospace',
                      ),
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
                    const Text('GIVEN NAME', style: TextStyle(color: Colors.white54, fontSize: 8)),
                    Text(
                      holder.isNotEmpty ? holder.toUpperCase() : document.documentName.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text('INDIAN', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // --- Insurance Card ---
  Widget _buildInsuranceCard(BuildContext context) {
    final (holder, number, provider, _) = _parseCardMetadata();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  provider.isNotEmpty ? provider.toUpperCase() : 'INSURANCE POLICY',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 20),
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('POLICY NUMBER', style: TextStyle(color: Colors.white70, fontSize: 8)),
              Text(
                number.isNotEmpty ? number : 'POL-••••••••',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  holder.isNotEmpty ? holder : document.documentName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (document.expiryDate != null) ...[
                const SizedBox(width: 8),
                Text(
                  'Exp: ${DateFormat('dd MMM yy').format(document.expiryDate!)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- Voter ID Card ---
  Widget _buildVoterIdCard(BuildContext context) {
    final (holder, number, _, _) = _parseCardMetadata();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF475569), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
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
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
              ),
              Icon(Icons.how_to_vote_rounded, color: Colors.white70, size: 20),
            ],
          ),

          Center(
            child: Text(
              number.isNotEmpty ? number : 'EPIC •••••••',
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontFamily: 'monospace',
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                holder.isNotEmpty ? holder : document.documentName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Text('ELECTOR PHOTO ID', style: TextStyle(color: Colors.white70, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  // --- Vehicle RC Card ---
  Widget _buildRcCard(BuildContext context) {
    final (holder, number, _, _) = _parseCardMetadata();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFF431407)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REGISTRATION CERTIFICATE',
                style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              Icon(Icons.directions_car_filled_rounded, color: Colors.white70, size: 20),
            ],
          ),

          Center(
            child: Text(
              number.isNotEmpty ? number : 'MH •• •• ••••',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontFamily: 'monospace',
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                holder.isNotEmpty ? holder : document.documentName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              if (document.expiryDate != null)
                Text(
                  'Fit Till: ${DateFormat('MM/yy').format(document.expiryDate!)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Generic / Certificate Card ---
  Widget _buildGenericDocCard(BuildContext context) {
    final (holder, number, issuer, _) = _parseCardMetadata();
    final isPdf = document.mimeType.contains('pdf');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withAlpha(220),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
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
                    isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    document.category.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ],
              ),
              if (onFavoriteToggle != null)
                IconButton(
                  icon: Icon(
                    document.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: document.isFavorite ? Colors.amber : Colors.white60,
                    size: 20,
                  ),
                  onPressed: onFavoriteToggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.documentName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (number.isNotEmpty)
                Text(
                  number,
                  style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
                ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                holder.isNotEmpty ? holder : (issuer.isNotEmpty ? issuer : 'Spendz Vault'),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              if (document.expiryDate != null)
                Text(
                  'Exp: ${DateFormat('dd MMM yyyy').format(document.expiryDate!)}',
                  style: TextStyle(
                    color: document.isExpired ? Colors.redAccent : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  (String holder, String number, String issuer, String network) _parseCardMetadata() {
    String holder = document.holderName ?? '';
    String number = document.maskedIdentifier ?? '';
    String issuer = '';
    String network = '';

    if (document.description != null) {
      final lines = document.description!.split('\n');
      for (final line in lines) {
        if (holder.isEmpty && line.startsWith('Holder:')) {
          holder = line.replaceFirst('Holder:', '').trim();
        } else if (number.isEmpty && line.startsWith('Number:')) {
          number = line.replaceFirst('Number:', '').trim();
        } else if (line.startsWith('Issuer:') || line.startsWith('Bank:')) {
          issuer = line.replaceFirst(RegExp(r'^(Issuer|Bank):'), '').trim();
        } else if (line.startsWith('Network:')) {
          network = line.replaceFirst('Network:', '').trim();
        }
      }
    }

    return (holder, number, issuer, network);
  }
}
