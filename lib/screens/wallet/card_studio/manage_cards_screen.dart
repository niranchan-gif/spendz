import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../providers/wallet_card_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../widgets/design_system/custom_dialog.dart';
import '../../../widgets/design_system/empty_state.dart';
import '../../../features/wallet/security/secure_number_service.dart';
import 'card_studio_theme.dart';
import 'card_studio_layout.dart';
import 'card_theme_sheet.dart';
import 'card_layout_sheet.dart';
import '../card_detail_screen.dart';

/// Manage Cards Screen for Spendz Card Studio 2.0.
/// Allows reordering, setting default card, editing, theme & layout customization,
/// and removal with instant synchronization to Card Studio.
class ManageCardsScreen extends StatelessWidget {
  const ManageCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: Text('Manage Cards', style: AppTextStyles.getHeading2(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Drag handles to reorder cards in your stack',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Long-press & drag the handles to reorder cards in Card Studio.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<WalletCardProvider>(
        builder: (context, cardProvider, child) {
          final cards = cardProvider.cards;

          if (cards.isEmpty) {
            return EmptyState(
              icon: Icons.credit_card_off_rounded,
              title: 'No Cards to Manage',
              message: 'Add payment cards in Card Studio to reorder and customize them.',
              actionLabel: 'Go Back',
              onAction: () => Navigator.pop(context),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved Collection (${cards.length})',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                    Text(
                      'Hold & drag to reorder',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                  itemCount: cards.length,
                  // ignore: deprecated_member_use
                  onReorder: (oldIndex, newIndex) async {
                    await cardProvider.reorderCards(oldIndex, newIndex);
                    if (context.mounted) {
                      context.read<WalletProvider>().loadWallet();
                    }
                  },
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    final theme = CardStudioTheme.getTheme(card.themeGradient);
                    final layout = CardStudioLayout.getLayout(card.cardLayoutId);

                    return Container(
                      key: ValueKey(card.id),
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: card.isDefault
                              ? AppColors.getPrimary(context)
                              : AppColors.getBorder(context),
                          width: card.isDefault ? 1.8 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Theme indicator pill
                                Container(
                                  width: 44,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    gradient: theme.backgroundGradient,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: theme.foilBorder),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.credit_card,
                                      size: 16,
                                      color: theme.textColor.withAlpha(220),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),

                                // Card Title & Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              card.nickname.isNotEmpty ? card.nickname : card.issuerName,
                                              style: AppTextStyles.getBodyLarge(context).copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (card.isDefault) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.getPrimary(context).withAlpha(25),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.getPrimary(context)),
                                              ),
                                              child: Text(
                                                'DEFAULT',
                                                style: TextStyle(
                                                  color: AppColors.getPrimary(context),
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${card.issuerName} • ${card.cardType.toUpperCase()} •••• ${card.lastFour}',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.getTextSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Drag Handle
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.drag_handle_rounded,
                                      color: AppColors.getTextSecondary(context).withAlpha(140),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Divider(height: 18),

                            // Theme & Layout Pills + Actions
                            Row(
                              children: [
                                // Theme chip
                                InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => CardThemeSheet.show(context, card),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.primaryAccent.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: theme.primaryAccent.withAlpha(60)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: theme.primaryAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          theme.name,
                                          style: TextStyle(
                                            color: AppColors.getTextPrimary(context),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Layout chip
                                InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => CardLayoutSheet.show(context, card),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.getBackground(context),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.getBorder(context)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(layout.icon, size: 11, color: AppColors.getTextSecondary(context)),
                                        const SizedBox(width: 4),
                                        Text(
                                          layout.name,
                                          style: TextStyle(
                                            color: AppColors.getTextSecondary(context),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const Spacer(),

                                // Set Default Star/Radio Action
                                if (!card.isDefault)
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                                    tooltip: 'Set as Default Card',
                                    onPressed: () async {
                                      await cardProvider.setDefaultCard(card.id);
                                      if (context.mounted) {
                                        context.read<WalletProvider>().loadWallet();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${card.nickname} set as default card'),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      }
                                    },
                                  ),

                                // Favorite Star
                                IconButton(
                                  icon: Icon(
                                    card.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                                    size: 20,
                                    color: card.isFavorite ? Colors.amber : null,
                                  ),
                                  tooltip: 'Toggle Favorite',
                                  onPressed: () async {
                                    await cardProvider.toggleCardFavorite(card.id);
                                    if (context.mounted) {
                                      context.read<WalletProvider>().loadWallet();
                                    }
                                  },
                                ),

                                // Edit Card
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 19),
                                  tooltip: 'Edit Card',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
                                    );
                                  },
                                ),

                                // Delete Card
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.error),
                                  tooltip: 'Delete Card',
                                  onPressed: () async {
                                    final confirm = await CustomDialog.showConfirmation(
                                      context: context,
                                      title: 'Remove Card?',
                                      message: 'Are you sure you want to remove "${card.nickname}" from your wallet?',
                                      confirmLabel: 'Remove',
                                      isDestructive: true,
                                      icon: Icons.delete_outline_rounded,
                                    );

                                    if (confirm == true && context.mounted) {
                                      final sec = SecureNumberService();
                                      await sec.deleteCardFullNumber(card.id);
                                      await cardProvider.deleteCard(card.id);
                                      if (context.mounted) {
                                        context.read<WalletProvider>().loadWallet();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Card removed'),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
