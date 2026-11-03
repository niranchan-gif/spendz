import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/wallet_document_model.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/glass_container.dart';
import 'card_detail_screen.dart';
import 'cards_screen.dart';
import 'document_preview_screen.dart';
import 'document_scanner_screen.dart';
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Add to Wallet', style: AppTextStyles.heading3),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.document_scanner_outlined, color: AppColors.primary),
                  ),
                  title: const Text('Scan Document (OCR)'),
                  subtitle: const Text('Auto edge detection, crop, OCR & encryption'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DocumentScannerScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.credit_card, color: AppColors.primary),
                  ),
                  title: const Text('Add Payment Card'),
                  subtitle: const Text('Store virtual card in Card Studio'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CardsScreen(openAddDialog: true)),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.file_upload_outlined, color: AppColors.primary),
                  ),
                  title: const Text('Import Existing File'),
                  subtitle: const Text('Import PDF or image into AES-256 vault'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DocumentsScreen(openAddDialog: true)),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Add Digital Pass / QR'),
                  subtitle: const Text('Save event ticket, boarding pass, or transit QR'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PassesScreen(openAddDialog: true)),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
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

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar / Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                                  style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary.withAlpha(60)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shield_rounded, size: 10, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'AES-256 Vault',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Card Studio • Smart Scanner • Secure Vault',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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
                              icon: const Icon(Icons.security, color: Colors.white70),
                              tooltip: 'Security Settings',
                            ),
                            IconButton(
                              onPressed: () => _showAddOptions(context),
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.add, color: AppColors.background, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Quick Actions Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _quickActionButton(
                            icon: Icons.document_scanner_outlined,
                            label: 'Scan Doc',
                            color: AppColors.primary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const DocumentScannerScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _quickActionButton(
                            icon: Icons.credit_card,
                            label: 'Add Card',
                            color: Colors.lightBlueAccent,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CardsScreen(openAddDialog: true)),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _quickActionButton(
                            icon: Icons.qr_code_2,
                            label: 'Add Pass',
                            color: Colors.amberAccent,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_busy_rounded, color: Colors.orange, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${expiringDocs.length} Document(s) Expiring Soon',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${expiringDocs.first.documentName} needs attention.',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
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
                              child: const Text('Review', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Section 1: Card Studio Carousel
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Card Studio', style: AppTextStyles.heading3),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CardsScreen()),
                            );
                          },
                          child: const Text('Manage Cards'),
                        ),
                      ],
                    ),
                  ),

                  if (cards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.credit_card_off_outlined, size: 36, color: Colors.white38),
                              const SizedBox(height: 8),
                              const Text('No cards stored yet', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CardsScreen(openAddDialog: true)),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.black,
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
                      height: 205,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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

                  const SizedBox(height: 24),

                  // Section 2: Document Vault Categories Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Document Vault', style: AppTextStyles.heading3),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                            );
                          },
                          child: const Text('Open Vault'),
                        ),
                      ],
                    ),
                  ),

                  // Categories Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCategoryGrid(context, documents),
                  ),

                  const SizedBox(height: 24),

                  // Section 3: Recent Vault Documents
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Documents', style: AppTextStyles.heading3),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                            );
                          },
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: documents.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.folder_open_outlined, size: 40, color: Colors.white24),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Vault is empty. Tap Scan Doc to get started.',
                                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white54),
                                  ),
                                ],
                              ),
                            ),
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

                  // Section 4: Favourites (if any)
                  if (favoriteCards.isNotEmpty || favoriteDocs.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Starred Favourites', style: AppTextStyles.heading3),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            if (favoriteCards.isNotEmpty) ...[
                              ListTile(
                                leading: const Icon(Icons.star, color: Colors.amber),
                                title: Text('${favoriteCards.length} Favourite Card(s)'),
                                subtitle: Text(favoriteCards.map((c) => c.nickname).join(', ')),
                                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CardsScreen()),
                                ),
                              ),
                            ],
                            if (favoriteDocs.isNotEmpty) ...[
                              if (favoriteCards.isNotEmpty) const Divider(color: Colors.white10),
                              ListTile(
                                leading: const Icon(Icons.star, color: Colors.amber),
                                title: Text('${favoriteDocs.length} Favourite Document(s)'),
                                subtitle: Text(favoriteDocs.map((d) => d.documentName).join(', ')),
                                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
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
            );
          },
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, i) {
        final cat = categories[i];
        final catId = cat['id'] as String;
        final count = docs.where((d) => d.category.toLowerCase() == catId).length;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DocumentsScreen()),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: count > 0 ? AppColors.primary.withAlpha(60) : Colors.white10,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat['icon'] as IconData,
                  color: count > 0 ? AppColors.primary : Colors.white54,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  cat['label'] as String,
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$count item${count == 1 ? "" : "s"}',
                  style: TextStyle(
                    fontSize: 9,
                    color: count > 0 ? AppColors.primary : Colors.white38,
                    fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
