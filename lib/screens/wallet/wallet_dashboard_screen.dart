import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/wallet_document_model.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/design_system/reusable_card.dart';
import '../../widgets/design_system/section_header.dart';
import '../../widgets/design_system/empty_state.dart';
import '../../widgets/design_system/app_bottom_sheet.dart';
import 'card_detail_screen.dart';
import 'cards_screen.dart';
import 'document_preview_screen.dart';
import 'document_creation_screen.dart';
import 'documents_screen.dart';
import 'passes_screen.dart';
import 'wallet_security_settings_screen.dart';
import 'widgets/document_vault_tile.dart';
import 'widgets/wallet_card_widget.dart';

class WalletDashboardScreen extends StatefulWidget {
  const WalletDashboardScreen({super.key});

  @override
  State<WalletDashboardScreen> createState() => _WalletDashboardScreenState();
}

class _WalletDashboardScreenState extends State<WalletDashboardScreen> {
  void _showAddOptions(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      title: 'Add to Wallet',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAddOptionTile(
            context: context,
            icon: Icons.badge_outlined,
            title: 'Add Document',
            subtitle: 'Manual entry, virtual ID card & attachment copy',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DocumentCreationScreen()),
              );
            },
          ),
          _buildAddOptionTile(
            context: context,
            icon: Icons.credit_card_rounded,
            title: 'Add Payment Card',
            subtitle: 'Store virtual card in Card Studio',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CardsScreen(openAddDialog: true)),
              );
            },
          ),
          _buildAddOptionTile(
            context: context,
            icon: Icons.file_upload_outlined,
            title: 'Import Existing File',
            subtitle: 'Import PDF or image into AES-256 vault',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DocumentsScreen(openAddDialog: true)),
              );
            },
          ),
          _buildAddOptionTile(
            context: context,
            icon: Icons.qr_code_2_rounded,
            title: 'Add Digital Pass / QR',
            subtitle: 'Save event ticket, boarding pass, or transit QR',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PassesScreen(openAddDialog: true)),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(25),
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
          border: Border.all(color: AppColors.primary.withAlpha(50)),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.getTextPrimary(context),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.getTextSecondary(context),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.getTextSecondary(context),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Consumer<WalletProvider>(
          builder: (context, wallet, child) {
            final cards = wallet.cards;
            final documents = wallet.documents;
            final expiringDocs = wallet.expiringDocuments;
            final favoriteCards = cards.where((c) => c.isFavorite).toList();
            final favoriteDocs = documents.where((d) => d.isFavorite).toList();

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await wallet.loadWallet();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    _buildHeader(context),

                    // Quick Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: _quickActionButton(
                              context: context,
                              icon: Icons.add_circle_outline_rounded,
                              label: 'Add Doc',
                              color: AppColors.primary,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const DocumentCreationScreen()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _quickActionButton(
                              context: context,
                              icon: Icons.credit_card_rounded,
                              label: 'Add Card',
                              color: AppColors.info,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CardsScreen(openAddDialog: true)),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _quickActionButton(
                              context: context,
                              icon: Icons.qr_code_2_rounded,
                              label: 'Add Pass',
                              color: AppColors.warning,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PassesScreen(openAddDialog: true)),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expiry Intelligence Banner
                    if (expiringDocs.isNotEmpty)
                      _buildExpiryBanner(context, expiringDocs),

                    const SizedBox(height: AppSpacing.md),

                    // Section 1: Card Studio Carousel
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: SectionHeader(
                        title: 'Card Studio',
                        actionLabel: 'Manage Cards',
                        onActionPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CardsScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    if (cards.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: ReusableCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.credit_card_off_outlined,
                                  size: 36,
                                  color: AppColors.getTextSecondary(context).withAlpha(120),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'No cards stored yet',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.getTextSecondary(context),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CardsScreen(openAddDialog: true)),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                  ),
                                  child: const Text('Add Card to Studio'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          itemCount: cards.length,
                          itemBuilder: (context, index) {
                            final card = cards[index];
                            return WalletCardWidget(
                              card: card,
                              onFavoriteToggle: () => wallet.toggleCardFavorite(card.id),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
                                );
                              },
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: AppSpacing.xl),

                    // Section 2: Document Vault Categories Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: SectionHeader(
                        title: 'Document Vault',
                        actionLabel: 'Open Vault',
                        onActionPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: _buildCategoryGrid(context, documents),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Section 3: Recent Vault Documents
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: SectionHeader(
                        title: 'Recent Documents',
                        actionLabel: 'See All',
                        onActionPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: documents.isEmpty
                          ? EmptyState(
                              icon: Icons.folder_open_outlined,
                              title: 'Vault is Empty',
                              subtitle: 'Tap Add Doc to securely store your personal IDs and documents.',
                              actionLabel: 'Add Document',
                              onActionPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const DocumentCreationScreen()),
                                );
                              },
                            )
                          : Column(
                              children: documents.take(3).map((doc) {
                                return DocumentVaultTile(
                                  document: doc,
                                  onFavoriteToggle: () => wallet.toggleDocumentFavorite(doc.id),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DocumentPreviewScreen(document: doc),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                    ),

                    // Section 4: Starred Favorites
                    if (favoriteCards.isNotEmpty || favoriteDocs.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: SectionHeader(
                          title: 'Starred Favourites',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: ReusableCard(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          child: Column(
                            children: [
                              if (favoriteCards.isNotEmpty)
                                ListTile(
                                  leading: const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                                  title: Text(
                                    '${favoriteCards.length} Favourite Card(s)',
                                    style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    favoriteCards.map((c) => c.nickname).join(', '),
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.getTextSecondary(context)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.getTextSecondary(context),
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CardsScreen()),
                                  ),
                                ),
                              if (favoriteDocs.isNotEmpty) ...[
                                if (favoriteCards.isNotEmpty)
                                  Divider(height: 1, indent: 56, color: AppColors.getBorder(context)),
                                ListTile(
                                  leading: const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                                  title: Text(
                                    '${favoriteDocs.length} Favourite Document(s)',
                                    style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    favoriteDocs.map((d) => d.documentName).join(', '),
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.getTextSecondary(context)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.getTextSecondary(context),
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Digital Wallet',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.getTextPrimary(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      border: Border.all(color: AppColors.primary.withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_rounded, size: 10, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'AES-256 Vault',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Card Studio • Smart Scanner • Secure Vault',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WalletSecuritySettingsScreen()),
                  );
                },
                icon: Icon(
                  Icons.security_rounded,
                  color: AppColors.getTextSecondary(context),
                  size: 22,
                ),
                tooltip: 'Security Settings',
              ),
              IconButton(
                onPressed: () => _showAddOptions(context),
                icon: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryBanner(BuildContext context, List<WalletDocumentModel> expiringDocs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withAlpha(20),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.warning.withAlpha(70)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_busy_rounded, color: AppColors.warning, size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${expiringDocs.length} Document(s) Expiring Soon',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${expiringDocs.first.documentName} needs renewal attention.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.getTextSecondary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                );
              },
              child: Text(
                'Review',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final surfaceColor = AppColors.getSurface(context);
    final borderColor = AppColors.getBorder(context);
    final textPrimary = AppColors.getTextPrimary(context);

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, List<WalletDocumentModel> docs) {
    final categories = [
      {'id': 'aadhaar', 'label': 'Aadhaar', 'icon': Icons.badge_outlined},
      {'id': 'pan', 'label': 'PAN Card', 'icon': Icons.credit_card},
      {'id': 'driving_license', 'label': 'Driving Lic.', 'icon': Icons.directions_car_outlined},
      {'id': 'passport', 'label': 'Passport', 'icon': Icons.flight_outlined},
      {'id': 'rc', 'label': 'Vehicle RC', 'icon': Icons.speed_outlined},
      {'id': 'insurance', 'label': 'Insurance', 'icon': Icons.security_outlined},
      {'id': 'college_id', 'label': 'Student ID', 'icon': Icons.school_outlined},
      {'id': 'certificate', 'label': 'Certificates', 'icon': Icons.workspace_premium_outlined},
    ];

    final surfaceColor = AppColors.getSurface(context);
    final borderColor = AppColors.getBorder(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemBuilder: (context, i) {
        final cat = categories[i];
        final catId = cat['id'] as String;
        final count = docs.where((d) => d.category.toLowerCase() == catId).length;

        return Material(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DocumentsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs + 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: count > 0 ? AppColors.primary.withAlpha(70) : borderColor,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    color: count > 0 ? AppColors.primary : textSecondary,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat['label'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count item${count == 1 ? "" : "s"}',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 9,
                      color: count > 0 ? AppColors.primary : textSecondary.withAlpha(150),
                      fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
