import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';
import '../../app/theme/spendz_typography.dart';
import '../../models/wallet_card_model.dart';
import '../../models/wallet_document_model.dart';
import '../../models/wallet_pass_model.dart';
import '../../presentation/widgets/spendz_button.dart';
import '../../presentation/widgets/spendz_top_bar.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/wallet_document_provider.dart';
import 'card_detail_screen.dart';
import 'cards_screen.dart';
import 'document_creation_screen.dart';
import 'document_preview_screen.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'passes_screen.dart';
import 'widgets/transit_ticket_card.dart';
import 'widgets/stitch_spotlight_card.dart';
import '../../providers/wallet_pass_provider.dart';

/// Spendz 2.0 Digital Wallet & Vault Screen.
/// Clean editorial interface for Payment Cards, Encrypted Documents, and Passes.
class WalletDashboardScreen extends StatefulWidget {
  const WalletDashboardScreen({super.key});

  @override
  State<WalletDashboardScreen> createState() => _WalletDashboardScreenState();
}

class _CardDeckItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget widget;

  const _CardDeckItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.widget,
  });
}

class _WalletDashboardScreenState extends State<WalletDashboardScreen> {
  late final PageController _cardPageController;
  int _currentCardIndex = 0;
  List<String> _customCardOrder = [];

  @override
  void initState() {
    super.initState();
    _cardPageController = PageController(viewportFraction: 0.94);
    _loadCardOrder();
  }

  Future<void> _loadCardOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('spendz_wallet_card_order');
      if (saved != null && mounted) {
        setState(() {
          _customCardOrder = saved;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveCardOrder(List<String> order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('spendz_wallet_card_order', order);
    } catch (_) {}
  }

  @override
  void dispose() {
    _cardPageController.dispose();
    super.dispose();
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SpendzColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SpendzSpacing.radiusXl),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SpendzSpacing.xl,
              vertical: SpendzSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SpendzColors.textSecondary(context).withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: SpendzSpacing.md),
                Text(
                  'Add to Wallet',
                  style: SpendzTypography.headingMedium(context),
                ),
                const SizedBox(height: SpendzSpacing.sm),
                _buildAddOptionTile(
                  context: ctx,
                  icon: Icons.badge_outlined,
                  title: 'Official Document',
                  subtitle: 'Aadhaar, PAN, Passport, Driving Licence',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DocumentCreationScreen(),
                      ),
                    );
                  },
                ),
                _buildAddOptionTile(
                  context: ctx,
                  icon: Icons.credit_card_rounded,
                  title: 'Payment Card',
                  subtitle: 'Customize banking card in Card Studio',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CardsScreen(openAddDialog: true),
                      ),
                    );
                  },
                ),
                _buildAddOptionTile(
                  context: ctx,
                  icon: Icons.qr_code_2_rounded,
                  title: 'Digital Pass / QR',
                  subtitle: 'Transit QR, event pass, or ticket',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PassesScreen(openAddDialog: true),
                      ),
                    );
                  },
                ),
                const SizedBox(height: SpendzSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: SpendzColors.primaryAccent(context).withAlpha(25),
          borderRadius: BorderRadius.circular(SpendzSpacing.radiusMd),
        ),
        child: Icon(icon, size: 20, color: SpendzColors.primaryAccent(context)),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: SpendzColors.textPrimary(context),
        ),
      ),
      subtitle: Text(subtitle, style: SpendzTypography.caption(context)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpendzColors.background(context),
      body: SafeArea(
        child: Consumer<WalletProvider>(
          builder: (context, wallet, _) {
            final docProvider = context.watch<WalletDocumentProvider>();
            final cards = wallet.cards;
            // Combine live vault documents from all providers
            final Map<String, WalletDocumentModel> allDocsMap = {};
            for (final d in wallet.documents) {
              allDocsMap[d.id] = d;
            }
            for (final d in docProvider.documents) {
              allDocsMap[d.id] = d;
            }
            final documents = allDocsMap.values.toList();
            final passProvider = context.watch<WalletPassProvider>();
            final Map<String, WalletPassModel> allPassesMap = {};
            for (final p in wallet.passes) {
              allPassesMap[p.id] = p;
            }
            for (final p in passProvider.passes) {
              allPassesMap[p.id] = p;
            }
            final passes = allPassesMap.values.toList();

            return RefreshIndicator(
              color: SpendzColors.tangerine,
              onRefresh: () async {
                await wallet.loadWallet();
                await docProvider.loadDocuments();
                await passProvider.loadPasses();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: SpendzSpacing.lg,
                  vertical: SpendzSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 0. Global Funky Top Header Bar (No OVERVIEW category)
                    const SpendzTopBar(title: 'Wallet'),
                    const SizedBox(height: SpendzSpacing.sm),

                    // 1. Vault Header & Filter Chips (Renamed to Wallet, removed DigiLocker Synced)
                    _buildVaultHeader(context, 7),
                    const SizedBox(height: SpendzSpacing.md),

                    // 2. Spotlight Card Carousel (The 7 Authentic Stitch Cards)
                    _buildCardsSection(context, cards, documents),
                    const SizedBox(height: SpendzSpacing.xl),

                    // 3. Official Cards Directory (Tap to inspect)
                    _buildOfficialCardsDirectory(context, cards, documents),
                    const SizedBox(height: SpendzSpacing.xl),

                    // 4. Travel & Transit Passes (Live upcoming trips & tickets)
                    _buildPassesSection(context, passes),
                    const SizedBox(height: SpendzSpacing.xl),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── 2. INDIAN VAULT HEADER & FILTER CHIPS ──────────────────────────────────
  Widget _buildVaultHeader(BuildContext context, int totalCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: SpendzColors.tangerine,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  'Wallet',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: SpendzColors.textPrimary(context),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: SpendzColors.tangerine,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '7 Cards',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildVaultFilterPill(context, 'All Cards ($totalCount)', isSelected: true),
              const SizedBox(width: 8),
              _buildVaultFilterPill(context, 'Identity (4)', isSelected: false),
              const SizedBox(width: 8),
              _buildVaultFilterPill(context, 'Finance & Banking (2)', isSelected: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVaultFilterPill(BuildContext context, String label, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF19C79) : const Color(0xFFCBDFBD),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected
            ? const [
                BoxShadow(
                  color: Color(0x1F2C221E),
                  blurRadius: 4,
                  offset: Offset(1.5, 2.5),
                ),
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 1.5,
                  offset: Offset(-1, -1),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? const Color(0xFFF6F4D2) : const Color(0xFF2C221E),
        ),
      ),
    );
  }

  // ─── 2. ALL CARDS & VAULT COLLECTION (SEAMLESS SWIPE & REARRANGE) ─────────
  Widget _buildCardsSection(
    BuildContext context,
    List<WalletCardModel> cards,
    List<WalletDocumentModel> documents,
  ) {
    WalletDocumentModel? findDoc(List<String> keywords) {
      for (final doc in documents) {
        final cat = doc.category.toLowerCase();
        final name = doc.documentName.toLowerCase();
        for (final k in keywords) {
          if (cat.contains(k) || name.contains(k)) return doc;
        }
      }
      return null;
    }

    final aadhaarDoc = findDoc(['aadhaar']);
    final panDoc = findDoc(['pan']);
    final insuranceDoc = findDoc(['insur', 'medic', 'health']);
    final voterDoc = findDoc(['voter', 'epic']);
    final passportDoc = findDoc(['passport']);

    WalletCardModel? debitCard;
    WalletCardModel? creditCard;
    for (final c in cards) {
      final isCredit = c.cardType.toLowerCase().contains('credit') || c.nickname.toLowerCase().contains('credit');
      if (isCredit && creditCard == null) {
        creditCard = c;
      } else if (!isCredit && debitCard == null) {
        debitCard = c;
      }
    }
    debitCard ??= cards.isNotEmpty ? cards.first : null;
    if (creditCard == null && cards.length > 1) {
      creditCard = cards[1];
    }

    final List<_CardDeckItem> deckItems = [
      _CardDeckItem(
        id: 'spotlight_aadhaar',
        title: aadhaarDoc?.documentName ?? 'Aadhaar Card',
        subtitle: aadhaarDoc != null
            ? (aadhaarDoc.holderName?.isNotEmpty == true ? aadhaarDoc.holderName! : 'UIDAI Government ID')
            : 'Tap to Add & Encrypt',
        icon: Icons.fingerprint_rounded,
        color: const Color(0xFFFF933E),
        widget: aadhaarDoc != null
            ? StitchSpotlightCard.fromDocument(
                document: aadhaarDoc,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentPreviewScreen(document: aadhaarDoc),
                    ),
                  );
                },
              )
            : StitchSpotlightCard(
                cardType: StitchCardType.aadhaar,
                holderName: 'Tap to Add Aadhaar',
                maskedNumber: '•••• •••• ••••',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DocumentCreationScreen(initialCategory: 'aadhaar'),
                    ),
                  );
                },
              ),
      ),
      _CardDeckItem(
        id: 'spotlight_pan',
        title: panDoc?.documentName ?? 'PAN Card',
        subtitle: panDoc != null
            ? (panDoc.holderName?.isNotEmpty == true ? panDoc.holderName! : 'Income Tax Dept')
            : 'Tap to Add & Encrypt',
        icon: Icons.credit_card_rounded,
        color: const Color(0xFF2E6385),
        widget: panDoc != null
            ? StitchSpotlightCard.fromDocument(
                document: panDoc,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentPreviewScreen(document: panDoc),
                    ),
                  );
                },
              )
            : StitchSpotlightCard(
                cardType: StitchCardType.pan,
                holderName: 'Tap to Add PAN Card',
                maskedNumber: '••••••••••',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DocumentCreationScreen(initialCategory: 'pan'),
                    ),
                  );
                },
              ),
      ),
      _CardDeckItem(
        id: 'spotlight_debit',
        title: debitCard?.nickname ?? 'Spendz Platinum Debit',
        subtitle: debitCard != null
            ? '${debitCard.issuerName} • ${debitCard.cardNetwork}'
            : 'Tap to Add Debit Card',
        icon: Icons.credit_card_rounded,
        color: const Color(0xFF263143),
        widget: debitCard != null
            ? StitchSpotlightCard.fromCard(
                card: debitCard,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CardDetailScreen(card: debitCard!),
                    ),
                  );
                },
              )
            : StitchSpotlightCard(
                cardType: StitchCardType.debit,
                holderName: 'Tap to Add Debit Card',
                maskedNumber: '•••• •••• •••• ••••',
                issuer: 'Debit Card',
                expiry: 'MM/YY',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CardsScreen(openAddDialog: true),
                    ),
                  );
                },
              ),
      ),
      _CardDeckItem(
        id: 'spotlight_credit',
        title: creditCard?.nickname ?? 'World Elite Credit',
        subtitle: creditCard != null
            ? '${creditCard.issuerName} • ${creditCard.cardNetwork}'
            : 'Tap to Add Credit Card',
        icon: Icons.diamond_rounded,
        color: const Color(0xFFFF933E),
        widget: creditCard != null
            ? StitchSpotlightCard.fromCard(
                card: creditCard,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CardDetailScreen(card: creditCard!),
                    ),
                  );
                },
              )
            : StitchSpotlightCard(
                cardType: StitchCardType.credit,
                holderName: 'Tap to Add Credit Card',
                maskedNumber: '•••• •••• •••• ••••',
                issuer: 'Credit Card',
                expiry: 'MM/YY',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CardsScreen(openAddDialog: true),
                    ),
                  );
                },
              ),
      ),
      _CardDeckItem(
        id: 'spotlight_mediclaim',
        title: insuranceDoc?.documentName ?? 'Star Health Mediclaim',
        subtitle: insuranceDoc != null
            ? (insuranceDoc.holderName?.isNotEmpty == true ? insuranceDoc.holderName! : 'Cashless Medi-Claim')
            : 'Tap to Add & Encrypt',
        icon: Icons.medical_services_rounded,
        color: const Color(0xFFBA1A1A),
        widget: insuranceDoc != null
            ? StitchSpotlightCard.fromDocument(
                document: insuranceDoc,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentPreviewScreen(document: insuranceDoc),
                    ),
                  );
                },
              )
            : StitchSpotlightCard(
                cardType: StitchCardType.mediclaim,
                holderName: 'Tap to Add Health Insurance',
                policyNumber: '••••••••••••',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DocumentCreationScreen(initialCategory: 'insurance'),
                    ),
                  );
                },
              ),
      ),
      _CardDeckItem(
        id: 'spotlight_voter',
        title: voterDoc?.documentName ?? 'Voter ID (EPIC)',
        subtitle: voterDoc != null
            ? (voterDoc.holderName?.isNotEmpty == true ? voterDoc.holderName! : 'ECI Official')
            : 'Tap to Add & Encrypt',
        icon: Icons.how_to_vote_rounded,
        color: const Color(0xFF2E6385),
        widget: voterDoc != null
            ? StitchSpotlightCard.fromDocument(
                document: voterDoc,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentPreviewScreen(document: voterDoc),
                    ),
                  );
                },
              )
            : StitchSpotlightCard(
                cardType: StitchCardType.voterId,
                holderName: 'Tap to Add Voter ID',
                epicNumber: '••••••••••',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DocumentCreationScreen(initialCategory: 'voter_id'),
                    ),
                  );
                },
              ),
      ),
      _CardDeckItem(
        id: 'spotlight_passport',
        title: passportDoc?.documentName ?? 'Indian Passport',
        subtitle: passportDoc != null
            ? (passportDoc.holderName?.isNotEmpty == true ? passportDoc.holderName! : 'Official Passport')
            : 'Tap to Add & Encrypt',
        icon: Icons.public_rounded,
        color: const Color(0xFF122238),
        widget: passportDoc != null
            ? StitchSpotlightCard.fromDocument(
                document: passportDoc,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentPreviewScreen(document: passportDoc),
                    ),
                  );
                },
              )
            : StitchSpotlightCard(
                cardType: StitchCardType.passport,
                holderName: 'Tap to Add Passport',
                passportNumber: '••••••••',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DocumentCreationScreen(initialCategory: 'passport'),
                    ),
                  );
                },
              ),
      ),
    ];

    // Include any additional custom documents
    final matchedDocIds = {
      if (aadhaarDoc != null) aadhaarDoc.id,
      if (panDoc != null) panDoc.id,
      if (insuranceDoc != null) insuranceDoc.id,
      if (voterDoc != null) voterDoc.id,
      if (passportDoc != null) passportDoc.id,
    };
    for (final customDoc in documents) {
      if (!matchedDocIds.contains(customDoc.id)) {
        deckItems.add(
          _CardDeckItem(
            id: 'doc_${customDoc.id}',
            title: customDoc.documentName,
            subtitle: customDoc.holderName?.isNotEmpty == true ? customDoc.holderName! : customDoc.category.toUpperCase(),
            icon: Icons.description_rounded,
            color: const Color(0xFF2E6385),
            widget: StitchSpotlightCard.fromDocument(
              document: customDoc,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentPreviewScreen(document: customDoc),
                  ),
                );
              },
            ),
          ),
        );
      }
    }

    // Include any additional custom cards
    final matchedCardIds = {
      if (debitCard != null) debitCard.id,
      if (creditCard != null) creditCard.id,
    };
    for (final customCard in cards) {
      if (!matchedCardIds.contains(customCard.id)) {
        deckItems.add(
          _CardDeckItem(
            id: 'card_${customCard.id}',
            title: customCard.nickname,
            subtitle: '${customCard.issuerName} • ${customCard.cardNetwork}',
            icon: Icons.credit_card_rounded,
            color: const Color(0xFF263143),
            widget: StitchSpotlightCard.fromCard(
              card: customCard,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardDetailScreen(card: customCard),
                  ),
                );
              },
            ),
          ),
        );
      }
    }

    // Sort according to custom card order if set
    if (_customCardOrder.isNotEmpty) {
      deckItems.sort((a, b) {
        final idxA = _customCardOrder.indexOf(a.id);
        final idxB = _customCardOrder.indexOf(b.id);
        if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
        if (idxA != -1) return -1;
        if (idxB != -1) return 1;
        return 0;
      });
    }

    final cardWidgets = deckItems.map((e) => e.widget).toList();

    if (_currentCardIndex >= cardWidgets.length) {
      _currentCardIndex = cardWidgets.length - 1;
    }
    if (_currentCardIndex < 0) {
      _currentCardIndex = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Spotlight Card Header with < > Navigation matching Image 3
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: SpendzColors.tangerine,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SPOTLIGHT CARD ${_currentCardIndex + 1} OF ${cardWidgets.length}',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: SpendzColors.textSecondary(context),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _currentCardIndex > 0
                        ? () {
                            _cardPageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        : null,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SpendzColors.surface(context),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 18,
                        color: _currentCardIndex > 0
                            ? SpendzColors.textPrimary(context)
                            : SpendzColors.textSecondary(context).withAlpha(80),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _currentCardIndex < cardWidgets.length - 1
                        ? () {
                            _cardPageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        : null,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SpendzColors.surface(context),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: _currentCardIndex < cardWidgets.length - 1
                            ? SpendzColors.textPrimary(context)
                            : SpendzColors.textSecondary(context).withAlpha(80),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: SpendzSpacing.xs),

        // Clean Horizontal Swipe Carousel - Exact 1.586 ID-1 Card Aspect Ratio Replica
        LayoutBuilder(
          builder: (context, constraints) {
            const viewportFraction = 0.94;
            final cardWidth = constraints.maxWidth * viewportFraction - 8;
            final cardHeight = cardWidth / 1.586;
            return SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _cardPageController,
                itemCount: cardWidgets.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentCardIndex = index);
                  HapticFeedback.selectionClick();
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1.586,
                        child: cardWidgets[index],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(height: SpendzSpacing.sm),

        // Under Carousel: Smooth Dot Indicators + Reorder & Add Card Pills
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dot indicators
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(cardWidgets.length, (idx) {
                  final isActive = idx == _currentCardIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: isActive ? 20.0 : 6.0,
                    height: 6.0,
                    decoration: BoxDecoration(
                      color: isActive
                          ? SpendzColors.tangerine
                          : SpendzColors.border(context),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showRearrangeCardsModal(context, deckItems),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: SpendzColors.surface(context),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_vert_rounded, size: 14, color: SpendzColors.textPrimary(context)),
                          const SizedBox(width: 4),
                          Text(
                            'Reorder',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: SpendzColors.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showAddOptions(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: SpendzColors.tangerine,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: SpendzColors.tangerine.withAlpha(80),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'Add Card',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
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
            ],
          ),
        ),
      ],
    );
  }

  void _showRearrangeCardsModal(
    BuildContext context,
    List<_CardDeckItem> items,
  ) {
    final reorderList = List<_CardDeckItem>.from(items);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SpendzColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SpendzSpacing.radiusXl),
        ),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: SpendzSpacing.lg,
                  vertical: SpendzSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: SpendzColors.textSecondary(
                            context,
                          ).withAlpha(80),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: SpendzSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rearrange Cards',
                              style: SpendzTypography.headingMedium(context),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Drag handles to reorder your wallet carousel',
                              style: SpendzTypography.caption(context),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpendzSpacing.md),
                    Expanded(
                      child: ReorderableListView.builder(
                        itemCount: reorderList.length,
                        onReorder: (oldIndex, newIndex) {
                          setModalState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = reorderList.removeAt(oldIndex);
                            reorderList.insert(newIndex, item);
                          });
                          final updatedOrder = reorderList
                              .map((i) => i.id)
                              .toList();
                          setState(() {
                            _customCardOrder = updatedOrder;
                          });
                          _saveCardOrder(updatedOrder);
                        },
                        itemBuilder: (ctx, idx) {
                          final item = reorderList[idx];
                          return Container(
                            key: ValueKey(item.id),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: SpendzColors.background(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: item.color.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: item.color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: SpendzColors.textPrimary(
                                            context,
                                          ),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: SpendzColors.textSecondary(
                                            context,
                                          ),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ReorderableDragStartListener(
                                  index: idx,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.drag_handle_rounded,
                                      color: SpendzColors.textSecondary(
                                        context,
                                      ),
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: SpendzSpacing.sm),
                    SpendzButton(
                      label: 'Done',
                      icon: Icons.check_rounded,
                      isFullWidth: true,
                      onPressed: () {
                        if (_cardPageController.hasClients) {
                          _cardPageController.jumpToPage(0);
                        }
                        setState(() {
                          _currentCardIndex = 0;
                        });
                        Navigator.pop(modalCtx);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── 4. OFFICIAL CARDS DIRECTORY matching Image 3 ───────────────────────────
  Widget _buildOfficialCardsDirectory(
    BuildContext context,
    List<WalletCardModel> cards,
    List<WalletDocumentModel> docs,
  ) {
    WalletDocumentModel? findDoc(List<String> keywords) {
      for (final doc in docs) {
        final cat = doc.category.toLowerCase();
        final name = doc.documentName.toLowerCase();
        for (final k in keywords) {
          if (cat.contains(k) || name.contains(k)) return doc;
        }
      }
      return null;
    }

    final aadhaarDoc = findDoc(['aadhaar']);
    final panDoc = findDoc(['pan']);
    final insuranceDoc = findDoc(['insur', 'medic', 'health']);
    final voterDoc = findDoc(['voter', 'epic']);
    final passportDoc = findDoc(['passport']);

    WalletCardModel? debitCard;
    WalletCardModel? creditCard;
    for (final c in cards) {
      final isCredit = c.cardType.toLowerCase().contains('credit') || c.nickname.toLowerCase().contains('credit');
      if (isCredit && creditCard == null) {
        creditCard = c;
      } else if (!isCredit && debitCard == null) {
        debitCard = c;
      }
    }
    debitCard ??= cards.isNotEmpty ? cards.first : null;
    if (creditCard == null && cards.length > 1) {
      creditCard = cards[1];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Official Cards Directory',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: SpendzColors.textPrimary(context),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Tap to inspect',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: SpendzColors.textSecondary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Item 1: Aadhaar Card (Cream Matte Clay)
        _buildDirectoryCardItem(
          context: context,
          tileBg: const Color(0xFFF6F4D2), // Cream
          tileBorder: const Color(0xFFE2E0BD),
          icon: Icons.fingerprint_rounded,
          iconBg: const Color(0xFFF19C79), // Coral
          iconColor: const Color(0xFF2C221E),
          title: aadhaarDoc?.documentName ?? 'Aadhaar Card',
          badgeText: 'UIDAI',
          badgeBg: const Color(0xFFD4E09B), // Chartreuse
          badgeColor: const Color(0xFF2C221E),
          subtitle: aadhaarDoc != null
              ? 'ID: ${aadhaarDoc.maskedIdentifier != null && aadhaarDoc.maskedIdentifier!.isNotEmpty ? aadhaarDoc.maskedIdentifier : "•••• ••••"} • Biometric Locked'
              : 'Not linked • Tap to add',
          statusWidget: Icon(
            aadhaarDoc != null ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
            size: 18,
            color: const Color(0xFFF19C79),
          ),
          onTap: () {
            if (aadhaarDoc != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreviewScreen(document: aadhaarDoc),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DocumentCreationScreen(initialCategory: 'aadhaar'),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        // Item 2: PAN Card (Pistachio Matte Clay)
        _buildDirectoryCardItem(
          context: context,
          tileBg: const Color(0xFFCBDFBD), // Pistachio
          tileBorder: const Color(0xFFB5CCA7),
          icon: Icons.badge_outlined,
          iconBg: const Color(0xFFD4E09B), // Chartreuse
          iconColor: const Color(0xFF2C221E),
          title: panDoc?.documentName ?? 'PAN Card',
          badgeText: 'Linked',
          badgeBg: const Color(0xFFF6F4D2), // Cream
          badgeColor: const Color(0xFF2C221E),
          subtitle: panDoc != null
              ? 'PAN: ${panDoc.maskedIdentifier != null && panDoc.maskedIdentifier!.isNotEmpty ? panDoc.maskedIdentifier : "••••••••••"} • Income Tax Dept'
              : 'Not linked • Tap to link',
          statusWidget: Icon(
            panDoc != null ? Icons.link_rounded : Icons.add_circle_outline_rounded,
            size: 18,
            color: const Color(0xFF4C6B22),
          ),
          onTap: () {
            if (panDoc != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreviewScreen(document: panDoc),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DocumentCreationScreen(initialCategory: 'pan'),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        // Item 3: Spendz Platinum Debit (Deep Crimson Brick Matte Clay)
        _buildDirectoryCardItem(
          context: context,
          tileBg: const Color(0xFFA44A3F), // Deep Crimson Brick
          tileBorder: const Color(0xFF883B32),
          textColor: const Color(0xFFF6F4D2),
          subtitleColor: const Color(0xFFF6F4D2).withAlpha(200),
          icon: Icons.credit_card_rounded,
          iconBg: const Color(0xFFD4E09B), // Chartreuse
          iconColor: const Color(0xFF2C221E),
          title: debitCard?.nickname ?? 'Spendz Platinum Debit',
          badgeText: debitCard != null ? '${debitCard.issuerName} • ${debitCard.cardNetwork}' : 'RuPay Platinum',
          badgeBg: const Color(0xFFF6F4D2),
          badgeColor: const Color(0xFFA44A3F),
          subtitle: debitCard != null
              ? '${debitCard.maskedNumber.isNotEmpty ? debitCard.maskedNumber : "•••• " + debitCard.lastFour} • Tap & Pay Active'
              : 'Not added • Tap to add',
          statusWidget: debitCard != null
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFD4E09B),
                  ),
                )
              : const Icon(
                  Icons.add_circle_outline_rounded,
                  size: 18,
                  color: Color(0xFFF6F4D2),
                ),
          onTap: () {
            if (debitCard != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CardDetailScreen(card: debitCard!),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CardsScreen(openAddDialog: true),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        // Item 4: World Elite Credit (Warm Chartreuse Matte Clay)
        _buildDirectoryCardItem(
          context: context,
          tileBg: const Color(0xFFD4E09B), // Chartreuse
          tileBorder: const Color(0xFFBFCC85),
          icon: Icons.diamond_outlined,
          iconBg: const Color(0xFFF19C79), // Coral
          iconColor: const Color(0xFF2C221E),
          title: creditCard?.nickname ?? 'World Elite Credit',
          badgeText: creditCard != null ? '${creditCard.issuerName} • ${creditCard.cardNetwork}' : 'Visa Infinite',
          badgeBg: const Color(0xFFA44A3F),
          badgeColor: const Color(0xFFF6F4D2),
          subtitle: creditCard != null
              ? '${creditCard.maskedNumber.isNotEmpty ? creditCard.maskedNumber : "•••• " + creditCard.lastFour} • Active'
              : 'Not added • Tap to add',
          statusWidget: Icon(
            creditCard != null ? Icons.stars_rounded : Icons.add_circle_outline_rounded,
            size: 18,
            color: const Color(0xFFA44A3F),
          ),
          onTap: () {
            if (creditCard != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CardDetailScreen(card: creditCard!),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CardsScreen(openAddDialog: true),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        // Item 5: Star Health Mediclaim (Coral Terracotta Matte Clay)
        _buildDirectoryCardItem(
          context: context,
          tileBg: const Color(0xFFF19C79), // Coral Terracotta
          textColor: const Color(0xFF2C221E),
          subtitleColor: const Color(0xFF4A3B32),
          icon: Icons.health_and_safety_rounded,
          iconBg: const Color(0xFFF6F4D2), // Cream
          iconColor: const Color(0xFFA44A3F), // Brick
          title: insuranceDoc?.documentName ?? 'Star Health Mediclaim',
          badgeText: 'Coverage',
          badgeBg: const Color(0xFFF6F4D2),
          badgeColor: const Color(0xFFA44A3F),
          subtitle: insuranceDoc != null
              ? 'Policy: ${insuranceDoc.maskedIdentifier != null && insuranceDoc.maskedIdentifier!.isNotEmpty ? insuranceDoc.maskedIdentifier : "Active"} • Cashless Medi-Claim'
              : 'Not added • Tap to add',
          statusWidget: Icon(
            insuranceDoc != null ? Icons.verified_rounded : Icons.add_circle_outline_rounded,
            size: 18,
            color: const Color(0xFF2C221E),
          ),
          onTap: () {
            if (insuranceDoc != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreviewScreen(document: insuranceDoc),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DocumentCreationScreen(initialCategory: 'insurance'),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        // Item 6: Voter ID (EPIC) (Pistachio Matte Clay)
        _buildDirectoryCardItem(
          context: context,
          tileBg: const Color(0xFFCBDFBD), // Pistachio
          tileBorder: const Color(0xFFB5CCA7),
          icon: Icons.how_to_vote_outlined,
          iconBg: const Color(0xFFF6F4D2), // Cream
          iconColor: const Color(0xFF2C221E),
          title: voterDoc?.documentName ?? 'Voter ID (EPIC)',
          badgeText: 'ECI Official',
          badgeBg: const Color(0xFFD4E09B),
          badgeColor: const Color(0xFF2C221E),
          subtitle: voterDoc != null
              ? 'EPIC: ${voterDoc.maskedIdentifier != null && voterDoc.maskedIdentifier!.isNotEmpty ? voterDoc.maskedIdentifier : "Verified"} • ECI Official'
              : 'Not added • Tap to add',
          statusWidget: Icon(
            voterDoc != null ? Icons.how_to_vote_rounded : Icons.add_circle_outline_rounded,
            size: 18,
            color: const Color(0xFF4C6B22),
          ),
          onTap: () {
            if (voterDoc != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreviewScreen(document: voterDoc),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DocumentCreationScreen(initialCategory: 'voter_id'),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        // Item 7: Indian Passport (Deep Crimson Brick Matte Clay)
        _buildDirectoryCardItem(
          context: context,
          tileBg: const Color(0xFFA44A3F), // Deep Crimson Brick
          tileBorder: const Color(0xFF883B32),
          textColor: const Color(0xFFF6F4D2),
          subtitleColor: const Color(0xFFF6F4D2).withAlpha(200),
          icon: Icons.public_rounded,
          iconBg: const Color(0xFFF6F4D2),
          iconColor: const Color(0xFFA44A3F),
          title: passportDoc?.documentName ?? 'Indian Passport',
          badgeText: 'Passport',
          badgeBg: const Color(0xFFD4E09B),
          badgeColor: const Color(0xFF2C221E),
          subtitle: passportDoc != null
              ? '${passportDoc.maskedIdentifier != null && passportDoc.maskedIdentifier!.isNotEmpty ? passportDoc.maskedIdentifier : "Valid"} • Official Passport'
              : 'Not added • Tap to add',
          statusWidget: Icon(
            passportDoc != null ? Icons.public_rounded : Icons.add_circle_outline_rounded,
            size: 18,
            color: const Color(0xFFD4E09B),
          ),
          onTap: () {
            if (passportDoc != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreviewScreen(document: passportDoc),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DocumentCreationScreen(initialCategory: 'passport'),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildDirectoryCardItem({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    required String subtitle,
    Widget? statusWidget,
    Color? tileBg,
    Color? tileBorder,
    Color? textColor,
    Color? subtitleColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: tileBg ?? SpendzColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2C221E),
            blurRadius: 5,
            offset: Offset(2, 3),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 1.5,
            offset: Offset(-1, -1),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: textColor ?? SpendzColors.textPrimary(context),
                              ),
                              maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor ?? SpendzColors.textSecondary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (statusWidget != null) statusWidget,
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: (textColor ?? SpendzColors.textSecondary(context)).withAlpha(120),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 5. TRAVEL & TRANSIT PASSES SECTION matching Image 3 ────────────────────
  Widget _buildPassesSection(
    BuildContext context,
    List<WalletPassModel> passes,
  ) {
    // Filter valid user transit passes and auto-purge tickets 24h past journey
    final now = DateTime.now();
    final userTransitPasses = passes.where((p) {
      if (p.id == 'sample_transit_pass') {
        return false;
      }
      final journeyTime = p.validUntil ?? p.createdAt;
      // Auto-purge passes older than 24 hours from travel/departure time
      if (now.isAfter(journeyTime.add(const Duration(hours: 24)))) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SpendzColors.tertiarySky.withAlpha(35),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_outlined,
                    color: SpendzColors.tertiarySky,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Travel & Transit Passes',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: SpendzColors.textPrimary(context),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Live upcoming trips & tickets',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: SpendzColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _showAddTransitTicketModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF19C79), // Coral Terracotta
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F2C221E),
                      blurRadius: 4,
                      offset: Offset(1.5, 2.5),
                    ),
                    BoxShadow(
                      color: Colors.white,
                      blurRadius: 1.5,
                      offset: Offset(-1, -1),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      'Add Pass',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
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
        const SizedBox(height: 12),

        // If no user tickets available, show clean empty state
        if (userTransitPasses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: SpendzColors.surface(context),
              borderRadius: BorderRadius.circular(24),
              boxShadow: SpendzColors.clayDropShadow(context),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: SpendzColors.tangerine.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.confirmation_number_outlined,
                    color: SpendzColors.tangerine,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'No tickets available',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SpendzColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap "+ Add Pass" to add your train, flight, or bus ticket.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: SpendzColors.textSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _showAddTransitTicketModal(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: SpendzColors.tangerine,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: SpendzColors.tangerine.withAlpha(60),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Add Pass',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
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
          )
        else
          // User Custom Added Transit Passes (with 24h purge & doc upload)
          ...userTransitPasses.map((pass) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TransitTicketCard(
                pass: pass,
                onDocUploaded: (path) async {
                  final updated = pass.copyWith(
                    encryptedCodePath: path,
                    notes: '${pass.notes ?? ""}\nDoc: $path',
                    updatedAt: DateTime.now(),
                  );
                  await context.read<WalletProvider>().updatePass(updated);
                },
                onDelete: () async {
                  await context.read<WalletProvider>().deletePass(pass.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ticket deleted successfully'),
                        backgroundColor: SpendzColors.expense,
                      ),
                    );
                  }
                },
              ),
            );
          }),
      ],
    );
  }



  void _showAddTransitTicketModal(BuildContext context) {
    final carrierController = TextEditingController();
    final pnrController = TextEditingController();
    final seatController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));
    TimeOfDay selectedTime = const TimeOfDay(hour: 6, minute: 30);
    String? pickedDocPath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SpendzColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SpendzSpacing.radiusXl),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final dateFormat = DateFormat('dd MMM yyyy');

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: SpendzSpacing.xl,
                  right: SpendzSpacing.xl,
                  top: SpendzSpacing.lg,
                  bottom:
                      MediaQuery.of(modalCtx).viewInsets.bottom +
                      SpendzSpacing.lg,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: SpendzColors.textSecondary(
                              context,
                            ).withAlpha(80),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: SpendzSpacing.md),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF047857).withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.train_rounded,
                              color: Color(0xFF10B981),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: SpendzSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Transit / Travel Ticket',
                                style: SpendzTypography.headingMedium(context),
                              ),
                              Text(
                                'Full green boarding pass with PNR & Seat',
                                style: SpendzTypography.caption(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: SpendzSpacing.lg),

                      // Carrier Field
                      TextField(
                        controller: carrierController,
                        decoration: InputDecoration(
                          labelText: 'Carrier / Transport Authority',
                          hintText: 'e.g. Indian Railways / Air India',
                          prefixIcon: const Icon(
                            Icons.directions_transit_rounded,
                          ),
                          filled: true,
                          fillColor: SpendzColors.surface(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              SpendzSpacing.radiusMd,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: SpendzSpacing.md),

                      // PNR Field
                      TextField(
                        controller: pnrController,
                        decoration: InputDecoration(
                          labelText: 'PNR Number',
                          hintText: 'e.g. 8421-950-231',
                          prefixIcon: const Icon(
                            Icons.confirmation_number_outlined,
                          ),
                          filled: true,
                          fillColor: SpendzColors.surface(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              SpendzSpacing.radiusMd,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: SpendzSpacing.md),

                      // Seat Field
                      TextField(
                        controller: seatController,
                        decoration: InputDecoration(
                          labelText: 'Seat / Berth Number',
                          hintText: 'e.g. B3 • Berth 42',
                          prefixIcon: const Icon(Icons.event_seat_rounded),
                          filled: true,
                          fillColor: SpendzColors.surface(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              SpendzSpacing.radiusMd,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: SpendzSpacing.md),

                      // Date & Time Picker Row
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: modalCtx,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 30),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (d != null) {
                                  setModalState(() => selectedDate = d);
                                }
                              },
                              borderRadius: BorderRadius.circular(
                                SpendzSpacing.radiusMd,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: SpendzColors.surface(context),
                                  borderRadius: BorderRadius.circular(
                                    SpendzSpacing.radiusMd,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dateFormat.format(selectedDate),
                                      style: SpendzTypography.body(context),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: SpendzSpacing.sm),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: modalCtx,
                                  initialTime: selectedTime,
                                );
                                if (t != null) {
                                  setModalState(() => selectedTime = t);
                                }
                              },
                              borderRadius: BorderRadius.circular(
                                SpendzSpacing.radiusMd,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: SpendzColors.surface(context),
                                  borderRadius: BorderRadius.circular(
                                    SpendzSpacing.radiusMd,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      selectedTime.format(modalCtx),
                                      style: SpendzTypography.body(context),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SpendzSpacing.md),

                      // Document Upload Row
                      InkWell(
                        onTap: () async {
                          final files = await FilePicker.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                          );
                          if (files.isNotEmpty && files.first.path != null) {
                            setModalState(
                              () => pickedDocPath = files.first.path!,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(
                          SpendzSpacing.radiusMd,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF047857).withAlpha(20),
                            borderRadius: BorderRadius.circular(
                              SpendzSpacing.radiusMd,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.upload_file_rounded,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: SpendzSpacing.md),
                              Expanded(
                                child: Text(
                                  pickedDocPath != null
                                      ? 'Attached: ${pickedDocPath!.split(Platform.pathSeparator).last}'
                                      : 'Upload Ticket Document (PDF / Image)',
                                  style: TextStyle(
                                    color: pickedDocPath != null
                                        ? Colors.white
                                        : const Color(0xFFD1FAE5),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                  maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: SpendzSpacing.xl),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF047857),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                SpendzSpacing.radiusMd,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text(
                            'Save Transit Ticket',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          onPressed: () async {
                            final pnr = pnrController.text.trim().isNotEmpty
                                ? pnrController.text.trim()
                                : 'PNR-${const Uuid().v4().substring(0, 8).toUpperCase()}';
                            final seat = seatController.text.trim().isNotEmpty
                                ? seatController.text.trim()
                                : 'Confirmed';
                            final carrier =
                                carrierController.text.trim().isNotEmpty
                                ? carrierController.text.trim()
                                : 'Travel Ticket';
                            final timeStr = selectedTime.format(modalCtx);

                            final newPass = WalletPassModel(
                              id: const Uuid().v4(),
                              title: carrier,
                              passType: 'transit_ticket',
                              encryptedCodePath: pickedDocPath ?? pnr,
                              codeFormat: 'QR_CODE',
                              issuer: carrier,
                              validUntil: DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              ),
                              notes:
                                  'PNR: $pnr\nSeat: $seat\nTime: $timeStr${pickedDocPath != null ? "\nDoc: $pickedDocPath" : ""}',
                              isFavorite: true,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );

                            try {
                              await context.read<WalletProvider>().addPass(newPass);
                              await context.read<WalletPassProvider>().loadPasses();
                              await context.read<WalletProvider>().loadWallet();
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Transit Ticket saved in Digital Passes!',
                                    ),
                                    backgroundColor: Color(0xFF047857),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to save ticket: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
