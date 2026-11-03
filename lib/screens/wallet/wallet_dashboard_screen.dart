import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../widgets/glass_container.dart';
import 'widgets/wallet_card_widget.dart';
import 'widgets/document_category_chip.dart';
import 'widgets/document_vault_tile.dart';
import 'cards_screen.dart';
import 'documents_screen.dart';
import 'passes_screen.dart';

class WalletDashboardScreen extends StatefulWidget {
  const WalletDashboardScreen({super.key});

  @override
  State<WalletDashboardScreen> createState() => _WalletDashboardScreenState();
}

class _WalletDashboardScreenState extends State<WalletDashboardScreen> {
  String _selectedCategory = 'all';

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
                    child: const Icon(Icons.credit_card, color: AppColors.primary),
                  ),
                  title: const Text('Add Payment Card'),
                  subtitle: const Text('Store virtual debit/credit card info securely'),
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
                    child: const Icon(Icons.lock_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Add Encrypted Document'),
                  subtitle: const Text('Import Aadhaar, PAN, DL, RC, or Passport'),
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
            final documents = wallet.getDocumentsByCategory(_selectedCategory);
            final expiringDocs = wallet.expiringDocuments;
            final passes = wallet.passes;

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
                                    color: Colors.white.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withAlpha(40)),
                                  ),
                                  child: const Text(
                                    'Phase 1 UI Preview',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cards, Vault Documents & Digital Passes',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
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
                  ),

                  // Expiring Soon Reminder Banner
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
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
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
                                    'Check ${expiringDocs.first.documentName} expiration.',
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
                              child: const Text('Review', style: TextStyle(color: Colors.orange, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Section 1: Payment Cards Carousel
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Payment Cards', style: AppTextStyles.heading3),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CardsScreen()),
                            );
                          },
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                  ),

                  if (cards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.credit_card_off_outlined, size: 40, color: Colors.white38),
                              const SizedBox(height: 8),
                              const Text('No cards stored yet', style: TextStyle(color: Colors.white70)),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CardsScreen(openAddDialog: true)),
                                  );
                                },
                                child: const Text('Add Your First Card'),
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
                                MaterialPageRoute(builder: (_) => const CardsScreen()),
                              );
                            },
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Section 2: Document Vault
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

                  const SizedBox(height: 6),

                  // Category Filter Chips
                  DocumentCategoryChips(
                    selectedCategory: _selectedCategory,
                    onSelected: (cat) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // Documents List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: documents.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No documents in this category',
                                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white54),
                              ),
                            ),
                          )
                        : Column(
                            children: documents.take(4).map((doc) {
                              return DocumentVaultTile(
                                document: doc,
                                onFavoriteToggle: () => wallet.toggleDocumentFavorite(doc.id),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Section 3: Digital Passes
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Digital Passes & QR', style: AppTextStyles.heading3),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PassesScreen()),
                            );
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: passes.isEmpty
                        ? GlassContainer(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text('No digital passes saved.'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const PassesScreen(openAddDialog: true)),
                                    );
                                  },
                                  child: const Text('Add Pass'),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: passes.map((pass) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withAlpha(20)),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.qr_code, color: AppColors.primary),
                                  ),
                                  title: Text(pass.title, style: AppTextStyles.labelLarge),
                                  subtitle: Text(
                                    '${pass.issuer ?? 'Digital Pass'} • ${pass.codeFormat}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      pass.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: pass.isFavorite ? Colors.amber : Colors.white54,
                                    ),
                                    onPressed: () => wallet.togglePassFavorite(pass.id),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const PassesScreen()),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
