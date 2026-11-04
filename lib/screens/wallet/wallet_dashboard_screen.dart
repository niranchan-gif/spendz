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
import '../../presentation/widgets/spendz_app_bar.dart';
import '../../presentation/widgets/spendz_button.dart';
import '../../presentation/widgets/spendz_section_header.dart';
import '../../presentation/widgets/spendz_surface.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/wallet_document_provider.dart';
import 'card_detail_screen.dart';
import 'cards_screen.dart';
import 'document_creation_screen.dart';
import 'document_preview_screen.dart';
import 'documents_screen.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';

import 'passes_screen.dart';
import 'widgets/wallet_card_widget.dart';
import 'widgets/virtual_document_card.dart';
import 'widgets/transit_ticket_card.dart';

/// Spendz 2.0 Digital Wallet & Vault Screen.
/// Clean editorial interface for Payment Cards, Encrypted Documents, and Passes.
class WalletDashboardScreen extends StatefulWidget {
  const WalletDashboardScreen({super.key});

  @override
  State<WalletDashboardScreen> createState() => _WalletDashboardScreenState();
}

class _WalletDashboardScreenState extends State<WalletDashboardScreen> {
  late final PageController _cardPageController;
  int _currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _cardPageController = PageController(viewportFraction: 0.88);
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
      appBar: SpendzAppBar(
        title: 'Wallet & Vault',
        subtitle: 'AES-256-GCM Automated Vault',
        actions: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SpendzColors.surface(context),
              border: Border.all(color: SpendzColors.border(context), width: 1),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.add_rounded,
                size: 20,
                color: SpendzColors.primaryAccent(context),
              ),
              tooltip: 'Add item',
              onPressed: () => _showAddOptions(context),
            ),
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          final docProvider = context.watch<WalletDocumentProvider>();
          final cards = wallet.cards;
          // Use authoritative live vault documents list
          final documents = docProvider.documents.isNotEmpty
              ? docProvider.documents
              : wallet.documents;
          final passes = wallet.passes;
          final expiringDocs = docProvider.expiringDocuments.isNotEmpty
              ? docProvider.expiringDocuments
              : wallet.expiringDocuments;

          return RefreshIndicator(
            color: SpendzColors.primaryAccent(context),
            onRefresh: () async {
              await wallet.loadWallet();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: SpendzSpacing.lg,
                vertical: SpendzSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Expiry Intelligence Banner
                  if (expiringDocs.isNotEmpty) ...[
                    _buildExpiryIntelligenceBanner(context, expiringDocs),
                    const SizedBox(height: SpendzSpacing.lg),
                  ],

                  // 2. Card Collection Carousel (All Cards & Documents)
                  _buildCardsSection(context, cards, documents),
                  const SizedBox(height: SpendzSpacing.xl),

                  // 3. Document Vault Categories
                  _buildDocumentCategories(context, documents),
                  const SizedBox(height: SpendzSpacing.xl),

                  // 4. Digital Passes
                  _buildPassesSection(context, passes),
                  const SizedBox(height: SpendzSpacing.hero),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── 1. EXPIRY INTELLIGENCE BANNER ──────────────────────────────────────────
  Widget _buildExpiryIntelligenceBanner(
    BuildContext context,
    List<WalletDocumentModel> expiringDocs,
  ) {
    final first = expiringDocs.first;
    final isExpired = first.isExpired;

    return SpendzSurface(
      padding: const EdgeInsets.all(SpendzSpacing.md),
      borderColor: isExpired
          ? SpendzColors.expense.withAlpha(80)
          : SpendzColors.warning.withAlpha(80),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isExpired
                  ? SpendzColors.expense.withAlpha(25)
                  : SpendzColors.warning.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpired
                  ? Icons.error_outline_rounded
                  : Icons.warning_amber_rounded,
              size: 20,
              color: isExpired ? SpendzColors.expense : SpendzColors.warning,
            ),
          ),
          const SizedBox(width: SpendzSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired
                      ? '${first.documentName} Expired'
                      : '${first.documentName} Expiring Soon',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isExpired
                        ? SpendzColors.expense
                        : SpendzColors.warning,
                  ),
                ),
                Text(
                  isExpired
                      ? 'Action needed: renew document copy in your vault.'
                      : 'Expires in ${first.expiryDate != null ? first.expiryDate!.difference(DateTime.now()).inDays : 0} days.',
                  style: SpendzTypography.caption(context),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentPreviewScreen(document: first),
                ),
              );
            },
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }

  // ─── 2. ALL CARDS & VAULT COLLECTION (SEAMLESS SWIPE) ────────────────────────
  Widget _buildCardsSection(
    BuildContext context,
    List<WalletCardModel> cards,
    List<WalletDocumentModel> documents,
  ) {
    final List<Widget> cardWidgets = [];

    // 1. All saved vault documents (Aadhaar, PAN, DL, Insurance, Passport, etc.)
    for (final doc in documents) {
      cardWidgets.add(
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DocumentPreviewScreen(document: doc),
              ),
            );
            if (context.mounted) {
              await context.read<WalletProvider>().loadWallet();
              await context.read<WalletDocumentProvider>().loadDocuments();
              setState(() {});
            }
          },
          child: VirtualDocumentCard(
            document: doc,
            allowReveal: true,
            onFavoriteToggle: () {
              context.read<WalletProvider>().toggleDocumentFavorite(doc.id);
            },
          ),
        ),
      );
    }

    // 2. All payment cards
    for (final card in cards) {
      cardWidgets.add(
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
            );
          },
          child: WalletCardWidget(
            card: card,
            isCompact: false,
            allowReveal: true,
          ),
        ),
      );
    }

    // 3. Ensure all core card types (Aadhaar, PAN, DL, Insurance) are available
    final hasAadhaar = documents.any(
      (d) => d.category.toLowerCase() == 'aadhaar',
    );
    final hasPan = documents.any((d) => d.category.toLowerCase() == 'pan');
    final hasDl = documents.any(
      (d) =>
          d.category.toLowerCase() == 'driving_licence' ||
          d.category.toLowerCase() == 'driving_license',
    );
    final hasInsurance = documents.any(
      (d) => d.category.toLowerCase() == 'insurance',
    );

    if (!hasAadhaar) {
      cardWidgets.add(
        GestureDetector(
          onTap: () => _openCreateDoc(context, 'aadhaar'),
          child: VirtualDocumentCard(
            document: WalletDocumentModel(
              id: 'template_aadhaar',
              documentName: 'Aadhaar Card',
              category: 'aadhaar',
              holderName: 'GOVERNMENT OF INDIA',
              maskedIdentifier: '•••• •••• ••••',
              description: 'Holder: USER RECORD\nNumber: •••• •••• ••••',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            allowReveal: true,
          ),
        ),
      );
    }

    if (!hasPan) {
      cardWidgets.add(
        GestureDetector(
          onTap: () => _openCreateDoc(context, 'pan'),
          child: VirtualDocumentCard(
            document: WalletDocumentModel(
              id: 'template_pan',
              documentName: 'Permanent Account Number',
              category: 'pan',
              holderName: 'INCOME TAX DEPT',
              maskedIdentifier: '••••••••••',
              description: 'Holder: USER RECORD\nNumber: ••••••••••',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            allowReveal: true,
          ),
        ),
      );
    }

    if (!hasDl) {
      cardWidgets.add(
        GestureDetector(
          onTap: () => _openCreateDoc(context, 'driving_licence'),
          child: VirtualDocumentCard(
            document: WalletDocumentModel(
              id: 'template_dl',
              documentName: 'Driving Licence',
              category: 'driving_license',
              holderName: 'MOTOR VEHICLE DEPT',
              maskedIdentifier: '••••••••••••••',
              description: 'Holder: USER RECORD\nNumber: ••••••••••••••',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            allowReveal: true,
          ),
        ),
      );
    }

    if (!hasInsurance) {
      cardWidgets.add(
        GestureDetector(
          onTap: () => _openCreateDoc(context, 'insurance'),
          child: VirtualDocumentCard(
            document: WalletDocumentModel(
              id: 'template_insurance',
              documentName: 'Health Insurance Card',
              category: 'insurance',
              holderName: 'POLICY HOLDER',
              maskedIdentifier: '•••••••••••••',
              description:
                  'Holder: USER RECORD\nNumber: •••••••••••••\nProvider: HEALTH SHIELD',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            allowReveal: true,
          ),
        ),
      );
    }

    if (_currentCardIndex >= cardWidgets.length) {
      _currentCardIndex = cardWidgets.length - 1;
    }
    if (_currentCardIndex < 0) {
      _currentCardIndex = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SpendzSectionHeader(
          title: 'Card Collection & Vault',
          count: cardWidgets.length,
          actionLabel: 'Add Card / Doc',
          onAction: () => _showAddOptions(context),
        ),
        const SizedBox(height: SpendzSpacing.xs),

        // Clean Horizontal Swipe Carousel - ZERO 3D STACK / ZERO OVERLAPPING PEEKS
        LayoutBuilder(
          builder: (context, constraints) {
            final cardHeight = constraints.maxWidth / 1.586;
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
                    child: cardWidgets[index],
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(height: SpendzSpacing.sm),

        // Card Counter & Smooth Dot Indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpendzSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${_currentCardIndex + 1} of ${cardWidgets.length}',
                style: SpendzTypography.caption(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(cardWidgets.length, (idx) {
                  final isActive = idx == _currentCardIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: isActive ? 18.0 : 6.0,
                    height: 6.0,
                    decoration: BoxDecoration(
                      color: isActive
                          ? SpendzColors.primaryAccent(context)
                          : SpendzColors.border(context),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _currentCardIndex > 0
                        ? () {
                            _cardPageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        : null,
                  ),
                  const SizedBox(width: SpendzSpacing.sm),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _currentCardIndex < cardWidgets.length - 1
                        ? () {
                            _cardPageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openCreateDoc(BuildContext context, String category) async {
    final normalized = (category == 'driving_licence')
        ? 'driving_license'
        : category;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentCreationScreen(initialCategory: normalized),
      ),
    );
    if (context.mounted) {
      await context.read<WalletProvider>().loadWallet();
      await context.read<WalletDocumentProvider>().loadDocuments();
      setState(() {});
    }
  }

  // ─── 3. DOCUMENT VAULT CATEGORIES ───────────────────────────────────────────
  Widget _buildDocumentCategories(
    BuildContext context,
    List<WalletDocumentModel> docs,
  ) {
    final categories = [
      {'id': 'aadhaar', 'name': 'Aadhaar', 'icon': Icons.badge_outlined},
      {'id': 'pan', 'name': 'PAN Card', 'icon': Icons.credit_card_rounded},
      {
        'id': 'driving_licence',
        'name': 'Driving Licence',
        'icon': Icons.drive_eta_outlined,
      },
      {'id': 'passport', 'name': 'Passport', 'icon': Icons.public_rounded},
      {
        'id': 'voter_id',
        'name': 'Voter ID',
        'icon': Icons.how_to_vote_outlined,
      },
      {'id': 'other', 'name': 'Other Vault', 'icon': Icons.folder_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SpendzSectionHeader(
          title: 'Document Vault',
          count: docs.length,
          actionLabel: 'View All',
          onAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DocumentsScreen()),
            );
          },
        ),
        const SizedBox(height: SpendzSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: SpendzSpacing.md,
            mainAxisSpacing: SpendzSpacing.md,
            childAspectRatio: 2.1,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final catId = cat['id'] as String;
            final count = docs.where((d) {
              final c = d.category.toLowerCase();
              if (catId == 'driving_licence' || catId == 'driving_license') {
                return c == 'driving_licence' || c == 'driving_license';
              }
              return c == catId;
            }).length;

            return SpendzSurface(
              onTap: () {
                final matchingDocs = docs.where((d) {
                  final c = d.category.toLowerCase();
                  if (catId == 'driving_licence' ||
                      catId == 'driving_license') {
                    return c == 'driving_licence' || c == 'driving_license';
                  }
                  return c == catId;
                }).toList();
                if (matchingDocs.length == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DocumentPreviewScreen(document: matchingDocs.first),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentsScreen(initialCategory: catId),
                    ),
                  );
                }
              },
              padding: const EdgeInsets.symmetric(
                horizontal: SpendzSpacing.md,
                vertical: SpendzSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: SpendzColors.primaryAccent(context).withAlpha(20),
                      borderRadius: BorderRadius.circular(
                        SpendzSpacing.radiusSm,
                      ),
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      size: 18,
                      color: SpendzColors.primaryAccent(context),
                    ),
                  ),
                  const SizedBox(width: SpendzSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: SpendzColors.textPrimary(context),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          count == 0 ? 'Empty' : '$count saved',
                          style: SpendzTypography.caption(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── 4. DIGITAL PASSES & TRANSIT SECTION (FULL GREEN THEME) ─────────────────
  Widget _buildPassesSection(
    BuildContext context,
    List<WalletPassModel> passes,
  ) {
    final transitPasses = passes
        .where(
          (p) =>
              p.passType == 'transit_ticket' || p.passType == 'boarding_pass',
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SpendzSectionHeader(
          title: 'Digital Passes & Transit',
          count: transitPasses.isNotEmpty
              ? transitPasses.length
              : passes.length,
          actionLabel: 'Add Ticket',
          onAction: () => _showAddTransitTicketModal(context),
        ),
        const SizedBox(height: SpendzSpacing.xs),

        if (transitPasses.isNotEmpty)
          Column(
            children: transitPasses.map((pass) {
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
                  onDelete: () {
                    context.read<WalletProvider>().deletePass(pass.id);
                  },
                ),
              );
            }).toList(),
          )
        else
          SpendzSurface(
            padding: const EdgeInsets.symmetric(
              horizontal: SpendzSpacing.lg,
              vertical: SpendzSpacing.xl,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF047857).withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.airplane_ticket_outlined,
                      size: 28,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: SpendzSpacing.sm),
                  Text(
                    'No Digital Tickets Added',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: SpendzColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add your train, bus, or flight tickets with PNR, seat & document upload',
                    textAlign: TextAlign.center,
                    style: SpendzTypography.caption(context),
                  ),
                  const SizedBox(height: SpendzSpacing.md),
                  SpendzButton(
                    label: '+ Add Ticket',
                    icon: Icons.add_rounded,
                    isFullWidth: false,
                    height: 38,
                    onPressed: () => _showAddTransitTicketModal(context),
                  ),
                ],
              ),
            ),
          ),
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
                                : '8421-950-231';
                            final seat = seatController.text.trim().isNotEmpty
                                ? seatController.text.trim()
                                : 'B3 • Berth 42';
                            final carrier =
                                carrierController.text.trim().isNotEmpty
                                ? carrierController.text.trim()
                                : 'INDIAN RAILWAYS / IRCTC';
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
