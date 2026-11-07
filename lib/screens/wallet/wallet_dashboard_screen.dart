import 'package:flutter/material.dart';
import 'package:keybz/widgets/app_keyboard/app_keyboard.dart';
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
import '../../providers/wallet_card_provider.dart';
import '../../providers/wallet_document_provider.dart';
import 'card_detail_screen.dart';
import 'cards_screen.dart';
import 'document_creation_screen.dart';
import 'document_preview_screen.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                  imageAsset: 'assets/aadhar.png',
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
                  imageAsset: 'assets/credit_Debit.png',
                  title: 'Payment Card',
                  subtitle: 'Debit, credit, ATM, or membership card',
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
    String? imageAsset,
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
        child: imageAsset == null
            ? Icon(icon, size: 20, color: SpendzColors.primaryAccent(context))
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imageAsset,
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    icon,
                    size: 20,
                    color: SpendzColors.primaryAccent(context),
                  ),
                ),
              ),
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
            final cardProvider = context.watch<WalletCardProvider>();
            final cards = cardProvider.cards;
            final documents = docProvider.documents;
            final passProvider = context.watch<WalletPassProvider?>();
            final Map<String, WalletPassModel> allPassesMap = {};
            for (final p in wallet.passes) {
              allPassesMap[p.id] = p;
            }
            for (final p in passProvider?.passes ?? const <WalletPassModel>[]) {
              allPassesMap[p.id] = p;
            }
            final passes = allPassesMap.values.toList();

            return RefreshIndicator(
              color: SpendzColors.tangerine,
              onRefresh: () async {
                await Future.wait([
                  wallet.loadWallet(),
                  cardProvider.loadCards(),
                  docProvider.loadDocuments(),
                  if (passProvider != null) passProvider.loadPasses(),
                ]);
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
                    _buildVaultHeader(
                      context,
                      cards.length + documents.length,
                      cards.length,
                      documents.length,
                    ),
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
  Widget _buildVaultHeader(
    BuildContext context,
    int totalCount,
    int cardCount,
    int documentCount,
  ) {
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: SpendzColors.tangerine,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalCount Items',
                    style: const TextStyle(
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
              _buildVaultFilterPill(
                context,
                'All Cards ($totalCount)',
                isSelected: true,
              ),
              const SizedBox(width: 8),
              _buildVaultFilterPill(
                context,
                'Cards ($cardCount)',
                isSelected: false,
              ),
              const SizedBox(width: 8),
              _buildVaultFilterPill(
                context,
                'Documents ($documentCount)',
                isSelected: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVaultFilterPill(
    BuildContext context,
    String label, {
    required bool isSelected,
  }) {
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
    final licenceDoc = findDoc([
      'driving_licen',
      'driving_licen',
      'licen',
      'driv',
    ]);

    WalletCardModel? debitCard;
    WalletCardModel? creditCard;
    for (final c in cards) {
      final type = c.cardType.toLowerCase();
      final nickname = c.nickname.toLowerCase();
      final isCredit = type.contains('credit') || nickname.contains('credit');
      final isDebit = type.contains('debit') || nickname.contains('debit');
      if (isCredit && creditCard == null) {
        creditCard = c;
      } else if (isDebit && debitCard == null) {
        debitCard = c;
      }
    }
    final List<_CardDeckItem> deckItems = [
      if (aadhaarDoc != null)
        _CardDeckItem(
          id: 'spotlight_aadhaar',
          title: aadhaarDoc.documentName,
          subtitle: aadhaarDoc.holderName?.isNotEmpty == true
              ? aadhaarDoc.holderName!
              : 'UIDAI Government ID',
          icon: Icons.fingerprint_rounded,
          color: const Color(0xFFFF933E),
          widget: StitchSpotlightCard.fromDocument(
            document: aadhaarDoc,
            onTap: () => _openDocument(context, aadhaarDoc),
          ),
        ),
      if (panDoc != null)
        _CardDeckItem(
          id: 'spotlight_pan',
          title: panDoc.documentName,
          subtitle: panDoc.holderName?.isNotEmpty == true
              ? panDoc.holderName!
              : 'Income Tax Dept',
          icon: Icons.credit_card_rounded,
          color: const Color(0xFF2E6385),
          widget: StitchSpotlightCard.fromDocument(
            document: panDoc,
            onTap: () => _openDocument(context, panDoc),
          ),
        ),
      if (debitCard != null)
        _CardDeckItem(
          id: 'spotlight_debit',
          title: debitCard.nickname.isNotEmpty
              ? debitCard.nickname
              : debitCard.issuerName,
          subtitle: '${debitCard.issuerName} • ${debitCard.cardNetwork}',
          icon: Icons.credit_card_rounded,
          color: const Color(0xFF263143),
          widget: StitchSpotlightCard.fromCard(
            card: debitCard,
            onTap: () => _openCard(context, debitCard!),
          ),
        ),
      if (creditCard != null)
        _CardDeckItem(
          id: 'spotlight_credit',
          title: creditCard.nickname.isNotEmpty
              ? creditCard.nickname
              : creditCard.issuerName,
          subtitle: '${creditCard.issuerName} • ${creditCard.cardNetwork}',
          icon: Icons.diamond_rounded,
          color: const Color(0xFFFF933E),
          widget: StitchSpotlightCard.fromCard(
            card: creditCard,
            onTap: () => _openCard(context, creditCard!),
          ),
        ),
      if (insuranceDoc != null)
        _CardDeckItem(
          id: 'spotlight_mediclaim',
          title: insuranceDoc.documentName,
          subtitle: insuranceDoc.holderName?.isNotEmpty == true
              ? insuranceDoc.holderName!
              : 'Cashless Medi-Claim',
          icon: Icons.medical_services_rounded,
          color: const Color(0xFFBA1A1A),
          widget: StitchSpotlightCard.fromDocument(
            document: insuranceDoc,
            onTap: () => _openDocument(context, insuranceDoc),
          ),
        ),
      if (voterDoc != null)
        _CardDeckItem(
          id: 'spotlight_voter',
          title: voterDoc.documentName,
          subtitle: voterDoc.holderName?.isNotEmpty == true
              ? voterDoc.holderName!
              : 'ECI Official',
          icon: Icons.how_to_vote_rounded,
          color: const Color(0xFF2E6385),
          widget: StitchSpotlightCard.fromDocument(
            document: voterDoc,
            onTap: () => _openDocument(context, voterDoc),
          ),
        ),
      if (passportDoc != null)
        _CardDeckItem(
          id: 'spotlight_passport',
          title: passportDoc.documentName,
          subtitle: passportDoc.holderName?.isNotEmpty == true
              ? passportDoc.holderName!
              : 'Official Passport',
          icon: Icons.public_rounded,
          color: const Color(0xFF122238),
          widget: StitchSpotlightCard.fromDocument(
            document: passportDoc,
            onTap: () => _openDocument(context, passportDoc),
          ),
        ),
      if (licenceDoc != null)
        _CardDeckItem(
          id: 'spotlight_licence',
          title: licenceDoc.documentName,
          subtitle: licenceDoc.holderName?.isNotEmpty == true
              ? licenceDoc.holderName!
              : 'MoRTH — Union of India',
          icon: Icons.drive_eta_rounded,
          color: const Color(0xFF2E6385),
          widget: StitchSpotlightCard.fromDocument(
            document: licenceDoc,
            onTap: () => _openDocument(context, licenceDoc),
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
      if (licenceDoc != null) licenceDoc.id,
    };
    for (final customDoc in documents) {
      if (!matchedDocIds.contains(customDoc.id)) {
        deckItems.add(
          _CardDeckItem(
            id: 'doc_${customDoc.id}',
            title: customDoc.documentName,
            subtitle: customDoc.holderName?.isNotEmpty == true
                ? customDoc.holderName!
                : customDoc.category.toUpperCase(),
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

    if (_customCardOrder.isNotEmpty) {
      deckItems.sort((a, b) {
        final indexA = _customCardOrder.indexOf(a.id);
        final indexB = _customCardOrder.indexOf(b.id);
        if (indexA >= 0 && indexB >= 0) return indexA.compareTo(indexB);
        if (indexA >= 0) return -1;
        if (indexB >= 0) return 1;
        return 0;
      });
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

    if (deckItems.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spotlight',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: SpendzColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: SpendzSpacing.sm),
          Text(
            'Add a card or document to see it here.',
            style: SpendzTypography.caption(context),
          ),
          const SizedBox(height: SpendzSpacing.sm),
          SpendzButton(
            label: 'Add to Wallet',
            icon: Icons.add_rounded,
            isFullWidth: true,
            onPressed: () => _showAddOptions(context),
          ),
        ],
      );
    }

    if (_currentCardIndex >= cardWidgets.length) {
      _currentCardIndex = cardWidgets.length - 1;
      final validIndex = _currentCardIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _cardPageController.hasClients) {
          _cardPageController.jumpToPage(validIndex);
        }
      });
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
            final cardHeight = (cardWidth / 1.586).clamp(215.0, 250.0);
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
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: cardWidth,
                          height: cardWidth / 1.586,
                          child: cardWidgets[index],
                        ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: SpendzColors.surface(context),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_vert_rounded,
                            size: 14,
                            color: SpendzColors.textPrimary(context),
                          ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
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
                          Icon(
                            Icons.add_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
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

  void _openDocument(BuildContext context, WalletDocumentModel document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentPreviewScreen(document: document),
      ),
    );
  }

  void _openCard(BuildContext context, WalletCardModel card) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
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
    List<WalletDocumentModel> documents,
  ) {
    final items = <Widget>[
      ...documents.map((document) {
        final category = document.category.toLowerCase();
        final asset = category.contains('aadhaar')
            ? 'assets/aadhar.png'
            : category.contains('pan')
            ? 'assets/PAN.png'
            : category.contains('debit') || category.contains('credit')
            ? 'assets/credit_Debit.png'
            : category.contains('voter') || category.contains('epic')
            ? 'assets/voterid.png'
            : category.contains('passport')
            ? 'assets/passport.jpeg'
            : category.contains('insur') || category.contains('medic')
            ? 'assets/Insurance.png'
            : category.contains('licen') || category.contains('driv')
            ? 'assets/licence.png'
            : null;
        final identifier = document.maskedIdentifier?.trim();
        final subtitle = identifier?.isNotEmpty == true
            ? identifier!
            : document.holderName?.trim().isNotEmpty == true
            ? document.holderName!
            : document.category.replaceAll('_', ' ');

        return _buildLiveDirectoryItem(
          context: context,
          title: document.documentName,
          badge: document.category.replaceAll('_', ' ').toUpperCase(),
          subtitle: subtitle,
          imageAsset: asset,
          icon: Icons.description_outlined,
          onTap: () => _openDocument(context, document),
        );
      }),
      ...cards.map((card) {
        final title = card.nickname.trim().isNotEmpty
            ? card.nickname
            : card.issuerName;
        final details = <String>[
          if (card.maskedNumber.trim().isNotEmpty) card.maskedNumber,
          if (card.lastFour.isNotEmpty && card.maskedNumber.trim().isEmpty)
            '•••• ${card.lastFour}',
          card.cardType.toUpperCase(),
        ];
        final issuerAndNetwork = <String>[
          if (card.issuerName.trim().isNotEmpty) card.issuerName,
          if (card.cardNetwork.trim().isNotEmpty)
            card.cardNetwork.toUpperCase(),
        ];

        return _buildLiveDirectoryItem(
          context: context,
          title: title,
          badge: issuerAndNetwork.isEmpty
              ? card.cardType.toUpperCase()
              : issuerAndNetwork.join(' • '),
          subtitle: details.join(' • '),
          imageAsset: 'assets/credit_Debit.png',
          icon: Icons.credit_card_rounded,
          isPaymentCard: true,
          onTap: () => _openCard(context, card),
        );
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallet Directory',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: SpendzColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text(
            'Cards and documents you add will appear here.',
            style: SpendzTypography.caption(context),
          )
        else
          ...items.expand((item) => [item, const SizedBox(height: 10)]),
      ],
    );
  }

  Widget _buildLiveDirectoryItem({
    required BuildContext context,
    required String title,
    required String badge,
    required String subtitle,
    required String? imageAsset,
    required IconData icon,
    required VoidCallback onTap,
    bool isPaymentCard = false,
  }) {
    final tileColor = isPaymentCard
        ? SpendzColors.chartreuse
        : SpendzColors.pistachio;

    return Container(
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: SpendzColors.clayDropShadow(context, blur: 4),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: SpendzColors.cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: imageAsset == null
                      ? Icon(icon, size: 22, color: SpendzColors.espresso)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            imageAsset,
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Icon(
                              icon,
                              size: 22,
                              color: SpendzColors.espresso,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: SpendzColors.espresso,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              badge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: SpendzColors.espresso,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: SpendzColors.espressoMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: SpendzColors.espressoMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
            Expanded(
              child: Row(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Travel & Transit Passes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: SpendzColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showAddTransitTicketModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
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
                      AppTextFormField(
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
                      AppTextFormField(
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
                      AppTextFormField(
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
                                final date = await showDatePicker(
                                  context: modalCtx,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 30),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 730),
                                  ),
                                );
                                if (date != null) {
                                  setModalState(() => selectedDate = date);
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
                              await context.read<WalletProvider>().addPass(
                                newPass,
                              );
                              await context
                                  .read<WalletPassProvider>()
                                  .loadPasses();
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
