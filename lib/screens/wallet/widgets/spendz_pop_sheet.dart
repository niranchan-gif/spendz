import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/wallet_provider.dart';
import '../../../app/theme/spendz_colors.dart';
import '../../../app/theme/spendz_spacing.dart';
import '../../../presentation/widgets/spendz_surface.dart';
import '../../../presentation/widgets/spendz_button.dart';
import '../widgets/wallet_card_widget.dart';
import '../documents_screen.dart';
import '../cards_screen.dart';
import '../card_detail_screen.dart';
import '../document_preview_screen.dart';
import '../../transactions/add_transaction_screen.dart';

/// Funky Claymorphism Pop-Up Bottom Sheet for Spendz.
///
/// Features pill-shaped drag handle, inflated clay cards, bouncy quick actions,
/// and smooth background scrim.
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
    final isDark = SpendzColors.isDark(context);
    final surfaceColor = SpendzColors.surface(context);
    final textPrimary = SpendzColors.textPrimary(context);
    final textSecondary = SpendzColors.textSecondary(context);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32), // rounded-3xl
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(120)
                : const Color(0xFF1E293B).withAlpha(35),
            blurRadius: 36,
            offset: const Offset(0, -12),
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(60)
                : const Color(0xFF1E293B).withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Consumer<WalletProvider>(
          builder: (context, wallet, child) {
            final favCards = wallet.favoriteCards.isNotEmpty
                ? wallet.favoriteCards
                : wallet.cards.take(2).toList();
            final favDocs = wallet.favoriteDocuments.isNotEmpty
                ? wallet.favoriteDocuments
                : wallet.documents.take(3).toList();

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpendzSpacing.lg,
                vertical: SpendzSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clay Pill Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: textSecondary.withAlpha(70),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: SpendzSpacing.md),

                  // Header with Puffy Clay Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: SpendzColors.tangerine,
                              borderRadius: BorderRadius.circular(
                                SpendzSpacing.radiusFull,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: SpendzColors.tangerine.withAlpha(80),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.flash_on_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'QUICK VAULT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Spendz Hub',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: textSecondary,
                          size: 22,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpendzSpacing.md),

                  // Quick Action Clay Buttons (Add, Send, Receive)
                  Row(
                    children: [
                      Expanded(
                        child: SpendzButton.primary(
                          label: 'Add Expense',
                          icon: Icons.add_circle_outline_rounded,
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddTransactionScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SpendzButton.tonal(
                          label: 'Cards Vault',
                          icon: Icons.wallet_rounded,
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CardsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpendzSpacing.lg),

                  // Favorite Payment Cards Section
                  if (favCards.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Cards',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CardsScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: SpendzColors.tangerine,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpendzSpacing.sm),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: favCards.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final card = favCards[index];
                          return SizedBox(
                            width: 190,
                            child: WalletCardWidget(
                              card: card,
                              isCompact: true,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CardDetailScreen(card: card),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: SpendzSpacing.md),
                  ],

                  // Favorite Documents Section
                  if (favDocs.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Identity & Vault',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DocumentsScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'All Docs',
                            style: TextStyle(
                              color: SpendzColors.tangerine,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpendzSpacing.sm),
                    ...favDocs.map(
                      (doc) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: SpendzSurface(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DocumentPreviewScreen(document: doc),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: SpendzColors.tangerine.withAlpha(20),
                                  borderRadius: BorderRadius.circular(
                                    SpendzSpacing.radiusMd,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.badge_outlined,
                                  size: 20,
                                  color: SpendzColors.tangerine,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc.documentName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      doc.category
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: SpendzSpacing.md),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
