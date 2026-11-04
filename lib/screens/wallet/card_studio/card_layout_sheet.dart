import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../models/wallet_card_model.dart';
import '../../../providers/wallet_card_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../widgets/design_system/primary_button.dart';
import '../../../widgets/design_system/secondary_button.dart';
import 'card_canvas_widget.dart';
import 'card_studio_layout.dart';

/// Premium Card Layout Selector Bottom Sheet for Spendz Card Studio 2.0.
class CardLayoutSheet extends StatefulWidget {
  final WalletCardModel card;

  const CardLayoutSheet({super.key, required this.card});

  static Future<void> show(BuildContext context, WalletCardModel card) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(context),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSheet),
      builder: (ctx) => CardLayoutSheet(card: card),
    );
  }

  @override
  State<CardLayoutSheet> createState() => _CardLayoutSheetState();
}

class _CardLayoutSheetState extends State<CardLayoutSheet> {
  late CardStudioLayout _selectedLayout;

  @override
  void initState() {
    super.initState();
    _selectedLayout = CardStudioLayout.getLayout(widget.card.cardLayoutId);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: bottomInset + AppSpacing.card,
          left: AppSpacing.card,
          right: AppSpacing.card,
          top: AppSpacing.md,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Card Layout',
                        style: AppTextStyles.getHeading2(context).copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Customize typography & element composition',
                        style: AppTextStyles.caption.copyWith(color: AppColors.getTextSecondary(context)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Live Miniature Card Preview
              Center(
                child: SizedBox(
                  width: 300,
                  height: 185,
                  child: CardCanvasWidget(
                    card: widget.card,
                    layoutOverride: _selectedLayout,
                    isCompact: true,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'Available Design Layouts (5)',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Layouts List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: CardStudioLayout.allLayouts.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final layout = CardStudioLayout.allLayouts[index];
                  final isSelected = layout.id == _selectedLayout.id;

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _selectedLayout = layout);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.getPrimary(context).withAlpha(20)
                            : AppColors.getBackground(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.getPrimary(context)
                              : AppColors.getBorder(context),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.getPrimary(context).withAlpha(40)
                                  : AppColors.getSurface(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              layout.icon,
                              color: isSelected
                                  ? AppColors.getPrimary(context)
                                  : AppColors.getTextSecondary(context),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  layout.name,
                                  style: AppTextStyles.getBodyMedium(context).copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppColors.getPrimary(context)
                                        : AppColors.getTextPrimary(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  layout.description,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.getTextSecondary(context),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected
                                ? AppColors.getPrimary(context)
                                : AppColors.getTextSecondary(context).withAlpha(90),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Apply Layout',
                      onPressed: () async {
                        final provider = context.read<WalletCardProvider>();
                        final walletProvider = context.read<WalletProvider>();
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        await provider.updateCardLayout(widget.card.id, _selectedLayout.id);
                        if (context.mounted) {
                          walletProvider.loadWallet();
                          try {
                            messenger?.showSnackBar(
                              SnackBar(
                                content: Text('Applied "${_selectedLayout.name}" layout'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } catch (_) {}
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
