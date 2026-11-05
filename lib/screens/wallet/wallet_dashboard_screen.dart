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
import 'widgets/virtual_document_card.dart';
import 'widgets/transit_ticket_card.dart';

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
    _cardPageController = PageController(viewportFraction: 0.88);
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
            final passes = wallet.passes;
            final expiringDocs = docProvider.expiringDocuments.isNotEmpty
                ? docProvider.expiringDocuments
                : wallet.expiringDocuments;

            return RefreshIndicator(
              color: SpendzColors.tangerine,
              onRefresh: () async {
                await wallet.loadWallet();
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
                    // 0. Global Funky Top Header Bar
                    const SpendzTopBar(title: 'Wallet', category: 'OVERVIEW'),
                    const SizedBox(height: SpendzSpacing.sm),

                    // 1. Top Document Alert Banner
                    _buildTopAlertPill(context, expiringDocs),
                    const SizedBox(height: SpendzSpacing.md),

                    // 2. Indian Vault Header & Filter Chips
                    _buildVaultHeader(context, cards.length + documents.length),
                    const SizedBox(height: SpendzSpacing.md),

                    // 3. Spotlight Card Carousel
                    _buildCardsSection(context, cards, documents),
                    const SizedBox(height: SpendzSpacing.xl),

                    // 4. Official Cards Directory (Tap to inspect)
                    _buildOfficialCardsDirectory(context, cards, documents),
                    const SizedBox(height: SpendzSpacing.xl),

                    // 5. Travel & Transit Passes (Live upcoming trips & tickets)
                    _buildPassesSection(context, passes),
                    const SizedBox(height: SpendzSpacing.lg),

                    // 6. 256-Bit Hardware Encrypted Trust Badge
                    _buildHardwareEncryptedFooter(context),
                    const SizedBox(height: SpendzSpacing.hero),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── 1. TOP DOCUMENT ALERT BANNER ───────────────────────────────────────────
  Widget _buildTopAlertPill(
    BuildContext context,
    List<WalletDocumentModel> expiringDocs,
  ) {
    final first = expiringDocs.isNotEmpty ? expiringDocs.first : null;
    final title = first != null
        ? '${first.documentName} renewal due in ${first.expiryDate != null ? first.expiryDate!.difference(DateTime.now()).inDays : 14} days'
        : 'Driving Licence renewal due in 14 days';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Light amber matching Image 3
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFDE68A),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEA580C),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DOCUMENT ALERT',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9A3412),
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF78350F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (first != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DocumentPreviewScreen(document: first),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Driving Licence details loaded from vault 📄'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: SpendzColors.surfaceContainerHigh(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE68A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
              ),
              child: const Text(
                'Renew',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF78350F),
                ),
              ),
            ),
          ),
        ],
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
                  Icons.shield_outlined,
                  color: SpendzColors.tangerine,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  'Indian Vault',
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
                  child: Text(
                    '$totalCount Cards',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: SpendzColors.tertiarySky.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: SpendzColors.tertiarySky.withAlpha(80),
                  width: 0.8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 12,
                    color: SpendzColors.tertiarySky,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'DigiLocker Synced',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: SpendzColors.tertiarySky,
                    ),
                  ),
                ],
              ),
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
        color: isSelected ? SpendzColors.tangerine : SpendzColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? SpendzColors.tangerine : SpendzColors.border(context),
          width: 0.8,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: SpendzColors.tangerine.withAlpha(80),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
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
          color: isSelected ? Colors.white : SpendzColors.textPrimary(context),
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
    final List<_CardDeckItem> deckItems = [];

    // 1. All saved vault documents (Aadhaar, PAN, DL, Insurance, Passport, etc.)
    for (final doc in documents) {
      deckItems.add(
        _CardDeckItem(
          id: 'doc_${doc.id}',
          title: doc.documentName,
          subtitle: doc.category.replaceAll('_', ' ').toUpperCase(),
          icon: _getCategoryIcon(doc.category),
          color: _getCategoryColor(doc.category),
          widget: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreviewScreen(document: doc),
                ),
              );
              if (!mounted) return;
              await context.read<WalletProvider>().loadWallet();
              if (!mounted) return;
              await context.read<WalletDocumentProvider>().loadDocuments();
              if (mounted) setState(() {});
            },
            child: VirtualDocumentCard(
              document: doc,
              allowReveal: true,
              onFavoriteToggle: () {
                context.read<WalletProvider>().toggleDocumentFavorite(doc.id);
              },
            ),
          ),
        ),
      );
    }

    // 2. All payment cards (rendered using unified VirtualDocumentCard template)
    for (final card in cards) {
      final cardDoc = WalletDocumentModel(
        id: card.id,
        documentName: card.nickname.isNotEmpty
            ? card.nickname
            : '${card.issuerName} ${card.cardType}',
        category: card.cardType.toLowerCase().contains('credit')
            ? 'credit_card'
            : 'debit_card',
        holderName: card.cardholderName,
        maskedIdentifier: card.maskedNumber,
        description:
            'Holder: ${card.cardholderName}\nNumber: ${card.maskedNumber}\nExpires: ${card.expiryMonth}/${card.expiryYear}\nIssuer: ${card.issuerName}',
        issueDate: card.createdAt,
        createdAt: card.createdAt,
        updatedAt: card.updatedAt,
      );
      deckItems.add(
        _CardDeckItem(
          id: 'card_${card.id}',
          title: card.nickname.isNotEmpty
              ? card.nickname
              : '${card.issuerName} ${card.cardType}',
          subtitle: '•••• ${card.lastFour}',
          icon: Icons.credit_card_rounded,
          color: const Color(0xFF10B981),
          widget: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
              );
            },
            child: VirtualDocumentCard(
              document: cardDoc,
              allowReveal: true,
            ),
          ),
        ),
      );
    }

    // 3. Ensure all core card types (Aadhaar, PAN, DL, Insurance) are available
    final hasAadhaar = documents.any(
      (d) => d.category.toLowerCase().contains('aadhaar'),
    );
    final hasPan = documents.any(
      (d) => d.category.toLowerCase().contains('pan'),
    );
    final hasDl = documents.any(
      (d) =>
          d.category.toLowerCase().contains('driv') ||
          d.category.toLowerCase().contains('licen'),
    );
    final hasInsurance = documents.any(
      (d) => d.category.toLowerCase().contains('insur'),
    );

    if (!hasAadhaar) {
      final templateAadhaar = WalletDocumentModel(
        id: 'template_aadhaar',
        documentName: 'Aadhaar Card',
        category: 'aadhaar',
        holderName: 'GOVERNMENT OF INDIA',
        maskedIdentifier: '•••• •••• 9842',
        description: 'Holder: USER RECORD\nNumber: •••• •••• 9842',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      deckItems.add(
        _CardDeckItem(
          id: 'template_aadhaar',
          title: 'Aadhaar Card',
          subtitle: 'UIDAI Government ID',
          icon: Icons.badge_outlined,
          color: const Color(0xFFFF9933),
          widget: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DocumentPreviewScreen(document: templateAadhaar),
                ),
              );
              if (!mounted) return;
              await context.read<WalletProvider>().loadWallet();
              if (!mounted) return;
              await context.read<WalletDocumentProvider>().loadDocuments();
              if (mounted) setState(() {});
            },
            child: VirtualDocumentCard(
              document: templateAadhaar,
              allowReveal: true,
            ),
          ),
        ),
      );
    }

    if (!hasPan) {
      final templatePan = WalletDocumentModel(
        id: 'template_pan',
        documentName: 'Permanent Account Number',
        category: 'pan',
        holderName: 'INCOME TAX DEPT',
        maskedIdentifier: 'BKAPS••••K',
        description: 'Holder: USER RECORD\nNumber: BKAPS••••K',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      deckItems.add(
        _CardDeckItem(
          id: 'template_pan',
          title: 'Permanent Account Number',
          subtitle: 'Income Tax Dept Card',
          icon: Icons.credit_card_rounded,
          color: const Color(0xFF0284C7),
          widget: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreviewScreen(document: templatePan),
                ),
              );
              if (!mounted) return;
              await context.read<WalletProvider>().loadWallet();
              if (!mounted) return;
              await context.read<WalletDocumentProvider>().loadDocuments();
              if (mounted) setState(() {});
            },
            child: VirtualDocumentCard(
              document: templatePan,
              allowReveal: true,
            ),
          ),
        ),
      );
    }

    if (!hasDl) {
      final templateDl = WalletDocumentModel(
        id: 'template_dl',
        documentName: 'Driving Licence',
        category: 'driving_license',
        holderName: 'MOTOR VEHICLE DEPT',
        maskedIdentifier: 'DL-••••4321',
        description: 'Holder: USER RECORD\nNumber: DL-••••4321',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      deckItems.add(
        _CardDeckItem(
          id: 'template_dl',
          title: 'Driving Licence',
          subtitle: 'Tamil Nadu Transport Dept',
          icon: Icons.directions_car_rounded,
          color: const Color(0xFFEA580C),
          widget: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreviewScreen(document: templateDl),
                ),
              );
              if (!mounted) return;
              await context.read<WalletProvider>().loadWallet();
              if (!mounted) return;
              await context.read<WalletDocumentProvider>().loadDocuments();
              if (mounted) setState(() {});
            },
            child: VirtualDocumentCard(document: templateDl, allowReveal: true),
          ),
        ),
      );
    }

    if (!hasInsurance) {
      final templateInsurance = WalletDocumentModel(
        id: 'template_insurance',
        documentName: 'Health Insurance Card',
        category: 'insurance',
        holderName: 'POLICY HOLDER',
        maskedIdentifier: '•••••••••••••',
        description:
            'Holder: USER RECORD\nNumber: •••••••••••••\nProvider: HEALTH SHIELD',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      deckItems.add(
        _CardDeckItem(
          id: 'template_insurance',
          title: 'Health Insurance Card',
          subtitle: 'Group Medical Shield',
          icon: Icons.health_and_safety_rounded,
          color: const Color(0xFFFA7070),
          widget: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DocumentPreviewScreen(document: templateInsurance),
                ),
              );
              if (!mounted) return;
              await context.read<WalletProvider>().loadWallet();
              if (!mounted) return;
              await context.read<WalletDocumentProvider>().loadDocuments();
              if (mounted) setState(() {});
            },
            child: VirtualDocumentCard(
              document: templateInsurance,
              allowReveal: true,
            ),
          ),
        ),
      );
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
                        border: Border.all(
                          color: SpendzColors.border(context),
                          width: 0.8,
                        ),
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
                        border: Border.all(
                          color: SpendzColors.border(context),
                          width: 0.8,
                        ),
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
            const viewportFraction = 0.88;
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
                        border: Border.all(color: SpendzColors.border(context), width: 0.8),
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'aadhaar':
        return Icons.badge_outlined;
      case 'pan':
        return Icons.credit_card_rounded;
      case 'driving_licence':
      case 'driving_license':
        return Icons.directions_car_rounded;
      case 'insurance':
        return Icons.health_and_safety_rounded;
      case 'passport':
        return Icons.menu_book_rounded;
      case 'voter_id':
        return Icons.how_to_vote_rounded;
      case 'rc':
        return Icons.directions_car_filled_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'aadhaar':
        return const Color(0xFFFF9933);
      case 'pan':
        return const Color(0xFF0284C7);
      case 'driving_licence':
      case 'driving_license':
        return const Color(0xFFEA580C);
      case 'insurance':
        return const Color(0xFFFA7070);
      case 'passport':
        return const Color(0xFF1E3A8A);
      case 'voter_id':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF10B981);
    }
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
                              border: Border.all(
                                color: SpendzColors.border(context),
                                width: 0.8,
                              ),
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
    // Find documents or fallback to authentic models
    final aadhaarDoc = docs.firstWhere(
      (d) => d.category.toLowerCase().contains('aadhaar'),
      orElse: () => WalletDocumentModel(
        id: 'template_aadhaar',
        documentName: 'Aadhaar Card',
        category: 'aadhaar',
        holderName: 'Aarav Sharma',
        maskedIdentifier: '•••• •••• 9842',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final panDoc = docs.firstWhere(
      (d) => d.category.toLowerCase().contains('pan'),
      orElse: () => WalletDocumentModel(
        id: 'template_pan',
        documentName: 'PAN Card',
        category: 'pan',
        holderName: 'AARAV SHARMA',
        maskedIdentifier: 'BKAPS••••K',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final insuranceDoc = docs.firstWhere(
      (d) => d.category.toLowerCase().contains('insur'),
      orElse: () => WalletDocumentModel(
        id: 'template_insurance',
        documentName: 'Star Health Mediclaim',
        category: 'insurance',
        holderName: 'Aarav Sharma',
        maskedIdentifier: 'P/161200/01/2024',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final voterDoc = docs.firstWhere(
      (d) => d.category.toLowerCase().contains('voter'),
      orElse: () => WalletDocumentModel(
        id: 'template_voter',
        documentName: 'Voter ID (EPIC)',
        category: 'voter_id',
        holderName: 'Aarav Sharma',
        maskedIdentifier: 'XMB 7291048',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final passportDoc = docs.firstWhere(
      (d) => d.category.toLowerCase().contains('passport'),
      orElse: () => WalletDocumentModel(
        id: 'template_passport',
        documentName: 'Indian Passport',
        category: 'passport',
        holderName: 'Aarav Sharma',
        maskedIdentifier: 'Z4829189',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final debitCard = cards.isNotEmpty
        ? cards.first
        : WalletCardModel(
            id: 'sample_debit',
            nickname: 'Spendz Platinum Debit',
            cardholderName: 'AARAV SHARMA',
            maskedNumber: '•••• •••• •••• 7183',
            lastFour: '7183',
            issuerName: 'HDFC Bank',
            cardType: 'RuPay Platinum',
            expiryMonth: 12,
            expiryYear: 28,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

    final creditCard = cards.length > 1
        ? cards[1]
        : WalletCardModel(
            id: 'sample_credit',
            nickname: 'World Elite Credit',
            cardholderName: 'AARAV SHARMA',
            maskedNumber: '•••• •••• •••• 9012',
            lastFour: '9012',
            issuerName: 'Visa Infinite',
            cardType: 'World Elite Credit',
            expiryMonth: 10,
            expiryYear: 29,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

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

        // Item 1: Aadhaar Card
        _buildDirectoryCardItem(
          context: context,
          icon: Icons.fingerprint_rounded,
          iconBg: SpendzColors.tangerine.withAlpha(25),
          iconColor: SpendzColors.tangerine,
          title: 'Aadhaar Card',
          badgeText: 'UIDAI',
          badgeBg: SpendzColors.sunshineYellow,
          badgeColor: const Color(0xFF735500),
          subtitle: 'ID: •••• •••• 9842 • Biometric Locked',
          statusWidget: const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: SpendzColors.tangerine,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DocumentPreviewScreen(document: aadhaarDoc),
              ),
            );
          },
        ),
        const SizedBox(height: 10),

        // Item 2: PAN Card
        _buildDirectoryCardItem(
          context: context,
          icon: Icons.badge_outlined,
          iconBg: SpendzColors.tertiarySky.withAlpha(25),
          iconColor: SpendzColors.tertiarySky,
          title: 'PAN Card',
          badgeText: 'Linked',
          badgeBg: SpendzColors.tertiarySky.withAlpha(40),
          badgeColor: SpendzColors.tertiarySky,
          subtitle: 'PAN: BKAPS••••K • Income Tax Dept',
          statusWidget: const Icon(
            Icons.link_rounded,
            size: 18,
            color: SpendzColors.tertiarySky,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DocumentPreviewScreen(document: panDoc),
              ),
            );
          },
        ),
        const SizedBox(height: 10),

        // Item 3: Spendz Platinum Debit
        _buildDirectoryCardItem(
          context: context,
          icon: Icons.credit_card_rounded,
          iconBg: const Color(0xFF1E293B),
          iconColor: SpendzColors.sunshineYellow,
          title: 'Spendz Platinum Debit',
          badgeText: 'HDFC • RuPay',
          badgeBg: SpendzColors.surfaceContainerHigh(context),
          badgeColor: SpendzColors.textSecondary(context),
          subtitle: '•••• 7183 • Tap & Pay Active',
          statusWidget: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SpendzColors.tangerine,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CardDetailScreen(card: debitCard),
              ),
            );
          },
        ),
        const SizedBox(height: 10),

        // Item 4: World Elite Credit
        _buildDirectoryCardItem(
          context: context,
          icon: Icons.diamond_outlined,
          iconBg: SpendzColors.sunshineYellow.withAlpha(35),
          iconColor: const Color(0xFF735500),
          title: 'World Elite Credit',
          badgeText: 'Visa Infinite',
          badgeBg: SpendzColors.sunshineYellow,
          badgeColor: const Color(0xFF735500),
          subtitle: '•••• 9012 • ₹ 5L Limit • Active',
          statusWidget: const Icon(
            Icons.stars_rounded,
            size: 18,
            color: Color(0xFFB45309),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CardDetailScreen(card: creditCard),
              ),
            );
          },
        ),
        const SizedBox(height: 10),

        // Item 5: Star Health Mediclaim
        _buildDirectoryCardItem(
          context: context,
          icon: Icons.health_and_safety_rounded,
          iconBg: const Color(0xFFFEE2E2),
          iconColor: const Color(0xFFDC2626),
          title: 'Star Health Mediclaim',
          badgeText: 'Coverage',
          badgeBg: const Color(0xFFFEE2E2),
          badgeColor: const Color(0xFFDC2626),
          subtitle: '₹ 15L Cover • Policy: P/161200/...',
          statusWidget: const Icon(
            Icons.verified_rounded,
            size: 18,
            color: Color(0xFFDC2626),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DocumentPreviewScreen(document: insuranceDoc),
              ),
            );
          },
        ),
        const SizedBox(height: 10),

        // Item 6: Voter ID (EPIC)
        _buildDirectoryCardItem(
          context: context,
          icon: Icons.how_to_vote_outlined,
          iconBg: SpendzColors.surfaceContainerHigh(context),
          iconColor: SpendzColors.tertiarySky,
          title: 'Voter ID (EPIC)',
          badgeText: 'ECI Official',
          badgeBg: SpendzColors.surfaceContainerHigh(context),
          badgeColor: SpendzColors.textSecondary(context),
          subtitle: 'EPIC: XMB 7291048 • BLR South',
          statusWidget: null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DocumentPreviewScreen(document: voterDoc),
              ),
            );
          },
        ),
        const SizedBox(height: 10),

        // Item 7: Indian Passport
        _buildDirectoryCardItem(
          context: context,
          icon: Icons.public_rounded,
          iconBg: const Color(0xFF0F172A),
          iconColor: SpendzColors.sunshineYellow,
          title: 'Indian Passport',
          badgeText: 'Republic of India',
          badgeBg: SpendzColors.sunshineYellow,
          badgeColor: const Color(0xFF735500),
          subtitle: 'Z4829189 • Valid till Oct 2032',
          statusWidget: null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DocumentPreviewScreen(document: passportDoc),
              ),
            );
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
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: SpendzColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SpendzColors.border(context),
          width: 0.8,
        ),
        boxShadow: SpendzColors.clayDropShadow(context),
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
                                color: SpendzColors.textPrimary(context),
                              ),
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
                              borderRadius: BorderRadius.circular(10),
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
                          color: SpendzColors.textSecondary(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (statusWidget != null) ...[
                  const SizedBox(width: 6),
                  statusWidget,
                ],
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: SpendzColors.textSecondary(context),
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
      if (p.notes?.contains('8421-950-231') == true ||
          p.encryptedCodePath == '8421-950-231' ||
          p.id == 'sample_transit_pass') {
        return false;
      }
      if (p.passType != 'transit_ticket' && p.passType != 'boarding_pass') {
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
                  color: SpendzColors.tertiarySky,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: SpendzColors.tertiarySky.withAlpha(80),
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
              border: Border.all(
                color: SpendzColors.border(context),
                width: 0.8,
              ),
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

  // ─── 6. 256-BIT HARDWARE ENCRYPTED FOOTER TRUST BADGE ───────────────────────
  Widget _buildHardwareEncryptedFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SpendzColors.surfaceRecessed(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SpendzColors.border(context),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SpendzColors.tertiarySky.withAlpha(40),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: SpendzColors.tertiarySky,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '256-Bit Hardware Encrypted',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: SpendzColors.textPrimary(context),
                  ),
                ),
                Text(
                  'Govt standards compliant with Indian UIDAI & RBI guidelines',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10.5,
                    color: SpendzColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: SpendzColors.textSecondary(context),
          ),
        ],
      ),
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
                                  border: Border.all(
                                    color: SpendzColors.border(context),
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
                                  border: Border.all(
                                    color: SpendzColors.border(context),
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
                            border: Border.all(
                              color: const Color(0xFF10B981).withAlpha(80),
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
                          onPressed: () {
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

                            context.read<WalletProvider>().addPass(newPass);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Transit Ticket saved in Digital Passes!',
                                ),
                                backgroundColor: Color(0xFF047857),
                              ),
                            );
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
