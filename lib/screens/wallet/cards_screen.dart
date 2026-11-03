import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/wallet_provider.dart';
import '../../models/wallet_card_model.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import 'widgets/wallet_card_widget.dart';

class CardsScreen extends StatefulWidget {
  final bool openAddDialog;

  const CardsScreen({super.key, this.openAddDialog = false});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
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
    int expiryMonth = 12;
    int expiryYear = 28;
    String cardType = 'credit';
    String cardNetwork = 'visa';
    String themeGradient = 'emerald';

    final themes = ['emerald', 'midnight', 'obsidian', 'amethyst', 'crimson', 'amber'];
    final cardTypes = ['credit', 'debit', 'atm', 'membership', 'loyalty'];
    final networks = ['visa', 'mastercard', 'rupay', 'amex'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
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
                          Text('Add Payment Card', style: AppTextStyles.heading3),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withAlpha(40)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: AppColors.primary, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Spendz never stores CVVs, PINs, or banking credentials.',
                                style: TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nicknameController,
                        decoration: const InputDecoration(
                          labelText: 'Card Nickname (e.g. My Shopping Card)',
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: issuerController,
                              decoration: const InputDecoration(
                                labelText: 'Bank / Issuer (e.g. HDFC)',
                                prefixIcon: Icon(Icons.account_balance_outlined),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: cardType,
                              decoration: const InputDecoration(labelText: 'Type'),
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cardholderController,
                        decoration: const InputDecoration(
                          labelText: 'Cardholder Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: lastFourController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              decoration: const InputDecoration(
                                labelText: 'Last 4 Digits',
                                prefixIcon: Icon(Icons.credit_card),
                                counterText: '',
                              ),
                              validator: (v) {
                                if (v == null || v.length != 4) return 'Enter 4 digits';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue: cardNetwork,
                              decoration: const InputDecoration(labelText: 'Network'),
                              items: networks.map((n) {
                                return DropdownMenuItem(value: n, child: Text(n.toUpperCase()));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => cardNetwork = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: expiryYear,
                              decoration: const InputDecoration(labelText: 'Exp Year (20xx)'),
                              items: List.generate(15, (i) => 25 + i).map((y) {
                                return DropdownMenuItem(value: y, child: Text('20$y'));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => expiryYear = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Card Color Theme', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: themes.map((theme) {
                          final isSelected = themeGradient == theme;
                          return ChoiceChip(
                            label: Text(theme.toUpperCase()),
                            selected: isSelected,
                            onSelected: (_) {
                              setModalState(() => themeGradient = theme);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final last4 = lastFourController.text.trim();
                              final card = WalletCardModel(
                                id: const Uuid().v4(),
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

                              context.read<WalletProvider>().addCard(card);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Card added to Spendz Wallet!')),
                              );
                            }
                          },
                          child: const Text('Save Card'),
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

  void _showCardDetails(BuildContext context, WalletCardModel card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: WalletCardWidget(card: card, isCompact: true),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.star_rounded, color: Colors.amber),
                  title: Text(card.isFavorite ? 'Remove from Favourites' : 'Add to Favourites'),
                  onTap: () {
                    context.read<WalletProvider>().toggleCardFavorite(card.id);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Delete Card', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    context.read<WalletProvider>().deleteCard(card.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Card removed from wallet.')),
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
      appBar: AppBar(
        title: const Text('Payment Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Card',
            onPressed: () => _showAddCardDialog(context),
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          final cards = wallet.cards;

          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.credit_card_off, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text('No Cards Found', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  const Text('Add debit, credit, or loyalty cards.', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _showAddCardDialog(context),
                    child: const Text('Add Card'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: WalletCardWidget(
                    card: card,
                    onFavoriteToggle: () => wallet.toggleCardFavorite(card.id),
                    onTap: () => _showCardDetails(context, card),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
