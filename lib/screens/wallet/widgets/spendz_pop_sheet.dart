import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../providers/wallet_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../widgets/wallet_card_widget.dart';
import '../documents_screen.dart';
import '../cards_screen.dart';
import '../card_detail_screen.dart';
import '../document_preview_screen.dart';
import '../../transactions/add_transaction_screen.dart';

class SpendzPopSheet extends StatelessWidget {
  const SpendzPopSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SpendzPopSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withAlpha(220),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withAlpha(35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          child: Consumer<WalletProvider>(
            builder: (context, wallet, child) {
              final favCards = wallet.favoriteCards.isNotEmpty ? wallet.favoriteCards : wallet.cards.take(2).toList();
              final favDocs = wallet.favoriteDocuments.isNotEmpty ? wallet.favoriteDocuments : wallet.documents.take(3).toList();
              final favPasses = wallet.favoritePasses.isNotEmpty ? wallet.favoritePasses : wallet.passes.take(1).toList();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(70),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'POP WALLET',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: AppColors.background,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Instant Access',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Action Shortcuts
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionPill(
                            icon: Icons.add,
                            label: 'Expense',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionPill(
                            icon: Icons.credit_card,
                            label: 'Cards',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CardsScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionPill(
                            icon: Icons.lock_rounded,
                            label: 'Vault',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Favorite Cards Carousel
                    if (favCards.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Favourite Cards', style: AppTextStyles.labelLarge),
                          Text('${favCards.length} ready', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 175,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: favCards.length,
                          itemBuilder: (context, index) {
                            final card = favCards[index];
                            return WalletCardWidget(
                              card: card,
                              isCompact: true,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
                                );
                              },
                              onFavoriteToggle: () => wallet.toggleCardFavorite(card.id),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Favorite Documents / Passes Quick List
                    if (favDocs.isNotEmpty) ...[
                      Text('Quick Documents', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 10),
                      Column(
                        children: favDocs.map((doc) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withAlpha(20)),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                              title: Text(doc.documentName, style: AppTextStyles.bodyMedium),
                              subtitle: Text(doc.category.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white54)),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white38),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => DocumentPreviewScreen(document: doc)),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Active Passes Quick QR
                    if (favPasses.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withAlpha(40)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: QrImageView(
                                data: favPasses.first.codeData.isNotEmpty ? favPasses.first.codeData : 'spendz-pass',
                                version: QrVersions.auto,
                                size: 36.0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    favPasses.first.title,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    'Code: ${favPasses.first.codeData}',
                                    style: const TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

