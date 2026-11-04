import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/wallet/security/secure_number_service.dart';
import '../../features/wallet/security/wallet_key_service.dart';
import '../../models/wallet_card_model.dart';
import '../../providers/wallet_card_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/design_system/empty_state.dart';
import '../../widgets/design_system/primary_button.dart';
import 'card_detail_screen.dart';
import 'widgets/wallet_card_widget.dart';

class CardsScreen extends StatefulWidget {
  final bool openAddDialog;

  const CardsScreen({super.key, this.openAddDialog = false});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  String _selectedFilter = 'all';
  final SecureNumberService _secureNumberService = SecureNumberService();

  @override
  void initState() {
    super.initState();
    if (widget.openAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddCardDialog(context);
      });
    }
  }

  void _showAddCardDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nicknameController = TextEditingController();
    final issuerController = TextEditingController();
    final cardholderController = TextEditingController();
    final lastFourController = TextEditingController();
    final fullNumberController = TextEditingController();
    int expiryMonth = 12;
    int expiryYear = 28;
    String cardType = 'credit';
    String cardNetwork = 'visa';
    String themeGradient = 'emerald';

    final themes = ['emerald', 'midnight', 'obsidian', 'amethyst', 'crimson', 'amber'];
    final cardTypes = ['credit', 'debit', 'atm', 'membership', 'loyalty', 'custom'];
    final networks = ['visa', 'mastercard', 'rupay', 'amex'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.roundedSheet,
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(
                bottom: bottomInset + AppSpacing.card,
                left: AppSpacing.card,
                right: AppSpacing.card,
                top: AppSpacing.card,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add Card to Studio',
                            style: AppTextStyles.getHeading2(context).copyWith(fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.getPrimary(context).withAlpha(15),
                          borderRadius: AppRadius.roundedMd,
                          border: Border.all(color: AppColors.getPrimary(context).withAlpha(35)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.shield_outlined, color: AppColors.getPrimary(context), size: 18),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Spendz never stores CVVs or PINs. Stored full numbers are AES-256-GCM encrypted and revealed only via biometrics.',
                                style: AppTextStyles.getBodySmall(context).copyWith(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: nicknameController,
                        decoration: const InputDecoration(
                          labelText: 'Card Nickname (e.g. Daily Spender)',
                          prefixIcon: Icon(Icons.label_outline, size: 18),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: issuerController,
                              decoration: const InputDecoration(
                                labelText: 'Bank / Issuer (e.g. HDFC)',
                                prefixIcon: Icon(Icons.account_balance_outlined, size: 18),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: cardType,
                              decoration: const InputDecoration(labelText: 'Card Type'),
                              items: cardTypes.map((t) {
                                return DropdownMenuItem(value: t, child: Text(t.toUpperCase()));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => cardType = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: cardholderController,
                        decoration: const InputDecoration(
                          labelText: 'Cardholder Name',
                          prefixIcon: Icon(Icons.person_outline, size: 18),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: lastFourController,
                              decoration: const InputDecoration(
                                labelText: 'Last 4 Digits',
                                hintText: '4821',
                                prefixIcon: Icon(Icons.credit_card, size: 18),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              validator: (v) {
                                if (v == null || v.length != 4) return 'Enter 4 digits';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: cardNetwork,
                              decoration: const InputDecoration(labelText: 'Network'),
                              items: networks.map((net) {
                                return DropdownMenuItem(value: net, child: Text(net.toUpperCase()));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => cardNetwork = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: fullNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Full Card Number (Encrypted Hardware Storage)',
                          hintText: 'Optional — for biometric tap reveal',
                          prefixIcon: Icon(Icons.lock_outline_rounded, size: 18),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: expiryMonth,
                              decoration: const InputDecoration(labelText: 'Exp Month'),
                              items: List.generate(12, (i) => i + 1).map((m) {
                                return DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0')));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => expiryMonth = val);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: expiryYear,
                              decoration: const InputDecoration(labelText: 'Exp Year'),
                              items: List.generate(15, (i) => 24 + i).map((y) {
                                return DropdownMenuItem(value: y, child: Text('20$y'));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => expiryYear = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Card Theme', style: AppTextStyles.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        children: themes.map((th) {
                          final isSelected = themeGradient == th;
                          return ChoiceChip(
                            label: Text(th.toUpperCase()),
                            selected: isSelected,
                            onSelected: (_) => setModalState(() => themeGradient = th),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(
                        label: 'Save Card to Wallet',
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final cardProvider = context.read<WalletCardProvider>();
                            final walletProvider = context.read<WalletProvider>();
                            final messenger = ScaffoldMessenger.of(context);

                            final last4 = lastFourController.text.trim();
                            final cardId = const Uuid().v4();

                            final rawFull = fullNumberController.text.trim();
                            if (rawFull.isNotEmpty) {
                              try {
                                await _secureNumberService.saveCardFullNumber(cardId, rawFull);
                              } catch (_) {
                                try {
                                  final keyService = WalletKeyService();
                                  await keyService.resetAndRegenerateMasterKey();
                                  await _secureNumberService.saveCardFullNumber(cardId, rawFull);
                                } catch (_) {}
                              }
                            }

                            final card = WalletCardModel(
                              id: cardId,
                              nickname: nicknameController.text.trim(),
                              issuerName: issuerController.text.trim(),
                              cardholderName: cardholderController.text.trim(),
                              maskedNumber: '•••• •••• •••• $last4',
                              lastFour: last4,
                              expiryMonth: expiryMonth,
                              expiryYear: expiryYear,
                              cardType: cardType,
                              cardNetwork: cardNetwork,
                              themeGradient: themeGradient,
                              isFavorite: false,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );

                            await cardProvider.addCard(card);
                            if (mounted) {
                              walletProvider.loadWallet();
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Card added to Card Studio!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          }
                        },
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

  void _openCardDetail(BuildContext context, WalletCardModel card) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardDetailScreen(card: card),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: Text('Card Studio', style: AppTextStyles.getHeading2(context)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: AppColors.getPrimary(context)),
            tooltip: 'Add Card',
            onPressed: () => _showAddCardDialog(context),
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          final allCards = wallet.cards;
          final filteredCards = _selectedFilter == 'all'
              ? allCards
              : (_selectedFilter == 'favorite'
                  ? allCards.where((c) => c.isFavorite).toList()
                  : allCards.where((c) => c.cardType.toLowerCase() == _selectedFilter).toList());

          return Column(
            children: [
              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All Cards (${allCards.length})'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('favorite', 'Favorites'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('credit', 'Credit'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('debit', 'Debit'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('loyalty', 'Loyalty'),
                  ],
                ),
              ),

              // Cards List
              Expanded(
                child: filteredCards.isEmpty
                    ? EmptyState(
                        icon: Icons.credit_card_off_rounded,
                        title: 'No Cards in Studio',
                        message: 'Add debit, credit, or membership cards for organized tracking.',
                        actionLabel: 'Add Your First Card',
                        onAction: () => _showAddCardDialog(context),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                        itemCount: filteredCards.length,
                        itemBuilder: (context, index) {
                          final card = filteredCards[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Center(
                              child: WalletCardWidget(
                                card: card,
                                onTap: () => _openCardDetail(context, card),
                                onFavoriteToggle: () {
                                  context.read<WalletCardProvider>().toggleCardFavorite(card.id);
                                  context.read<WalletProvider>().loadWallet();
                                },
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

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = key),
      selectedColor: AppColors.getPrimary(context).withAlpha(30),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.getPrimary(context) : AppColors.getTextSecondary(context),
      ),
    );
  }
}
