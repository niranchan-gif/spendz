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
import 'card_studio_theme.dart';

/// Premium Theme Selector Bottom Sheet for Spendz Card Studio 2.0.
class CardThemeSheet extends StatefulWidget {
  final WalletCardModel card;

  const CardThemeSheet({super.key, required this.card});

  static Future<void> show(BuildContext context, WalletCardModel card) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(context),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSheet),
      builder: (ctx) => CardThemeSheet(card: card),
    );
  }

  @override
  State<CardThemeSheet> createState() => _CardThemeSheetState();
}

class _CardThemeSheetState extends State<CardThemeSheet> {
  late CardStudioTheme _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = CardStudioTheme.getTheme(widget.card.themeGradient);
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
                        'Change Card Theme',
                        style: AppTextStyles.getHeading2(
                          context,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Select a distinctive visual identity',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.getTextSecondary(context),
                        ),
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
                    themeOverride: _selectedTheme,
                    isCompact: true,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                'Available Luxury Themes (8)',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Themes Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 2.1,
                ),
                itemCount: CardStudioTheme.allThemes.length,
                itemBuilder: (context, index) {
                  final theme = CardStudioTheme.allThemes[index];
                  final isSelected = theme.id == _selectedTheme.id;

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _selectedTheme = theme);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: theme.backgroundGradient,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.white : theme.foilBorder,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.primaryAccent.withAlpha(90),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primaryAccent,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(
                                      Icons.check,
                                      size: 8,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  theme.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  theme.primaryAccent
                                      .toARGB32()
                                      .toRadixString(16)
                                      .substring(2)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(160),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
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
                      label: 'Apply Theme',
                      onPressed: () async {
                        final provider = context.read<WalletCardProvider>();
                        final walletProvider = context.read<WalletProvider>();
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        await provider.updateCardTheme(
                          widget.card.id,
                          _selectedTheme.id,
                        );
                        if (context.mounted) {
                          walletProvider.loadWallet();
                          try {
                            messenger?.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Applied "${_selectedTheme.name}" theme',
                                ),
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
