import 'package:flutter/material.dart';
import 'package:keybz/widgets/app_keyboard/app_keyboard.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../database/transaction_dao.dart';
import '../../features/wallet/security/secure_number_service.dart';
import '../../features/wallet/security/wallet_key_service.dart';
import '../../models/transaction_model.dart';
import '../../models/wallet_card_model.dart';
import '../../providers/wallet_card_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/design_system/custom_dialog.dart';
import '../../widgets/design_system/empty_state.dart';
import '../../widgets/design_system/loading_state.dart';
import '../../widgets/design_system/primary_button.dart';
import '../../widgets/design_system/reusable_card.dart';
import 'widgets/stitch_spotlight_card.dart';

class CardDetailScreen extends StatefulWidget {
  final WalletCardModel card;

  const CardDetailScreen({super.key, required this.card});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late WalletCardModel _currentCard;
  final TransactionDao _transactionDao = TransactionDao();
  final SecureNumberService _secureNumberService = SecureNumberService();
  List<TransactionModel> _linkedTransactions = [];
  bool _isLoadingTransactions = true;

  @override
  void initState() {
    super.initState();
    _currentCard = widget.card;
    _loadLinkedTransactions();
  }

  Future<void> _loadLinkedTransactions() async {
    setState(() => _isLoadingTransactions = true);
    try {
      final txns = await _transactionDao.getTransactionsByCard(_currentCard.id);
      if (mounted) {
        setState(() {
          _linkedTransactions = txns;
          _isLoadingTransactions = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingTransactions = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final newFav = !_currentCard.isFavorite;
    final updated = _currentCard.copyWith(isFavorite: newFav);
    setState(() => _currentCard = updated);

    try {
      await context.read<WalletCardProvider>().toggleCardFavorite(
        _currentCard.id,
      );
      if (mounted) {
        context.read<WalletProvider>().loadWallet();
      }
    } catch (_) {}
  }

  void _showEditCardDialog() {
    final formKey = GlobalKey<FormState>();
    final nicknameController = TextEditingController(
      text: _currentCard.nickname,
    );
    final issuerController = TextEditingController(
      text: _currentCard.issuerName,
    );
    final cardholderController = TextEditingController(
      text: _currentCard.cardholderName,
    );
    final fullNumberController = TextEditingController();
    int expiryMonth = _currentCard.expiryMonth;
    int expiryYear = _currentCard.expiryYear;
    String cardType = _currentCard.cardType;
    String themeGradient = _currentCard.themeGradient;
    String cardLayoutId = _currentCard.cardLayoutId;

    final cardTypes = [
      'credit',
      'debit',
      'atm',
      'membership',
      'loyalty',
      'custom',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(context),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSheet),
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
                            'Edit Virtual Card',
                            style: AppTextStyles.getHeading2(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextFormField(
                        controller: nicknameController,
                        decoration: const InputDecoration(
                          labelText: 'Card Nickname',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextFormField(
                              controller: issuerController,
                              decoration: const InputDecoration(
                                labelText: 'Bank / Issuer',
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: cardType,
                              decoration: const InputDecoration(
                                labelText: 'Card Type',
                              ),
                              items: cardTypes.map((t) {
                                return DropdownMenuItem(
                                  value: t,
                                  child: Text(t.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => cardType = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextFormField(
                        controller: cardholderController,
                        decoration: const InputDecoration(
                          labelText: 'Cardholder Name',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextFormField(
                        controller: fullNumberController,
                        decoration: InputDecoration(
                          labelText: 'Update Full Card Number (Optional)',
                          hintText:
                              'Leave empty to preserve existing (${_currentCard.maskedNumber})',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: expiryMonth,
                              decoration: const InputDecoration(
                                labelText: 'Exp Month',
                              ),
                              items: List.generate(12, (i) => i + 1).map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(m.toString().padLeft(2, '0')),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => expiryMonth = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: expiryYear,
                              decoration: const InputDecoration(
                                labelText: 'Exp Year',
                              ),
                              items: List.generate(15, (i) => 24 + i).map((y) {
                                return DropdownMenuItem(
                                  value: y,
                                  child: Text('20$y'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => expiryYear = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(
                        label: 'Save Changes',
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final cardProvider = context
                                .read<WalletCardProvider>();
                            final walletProvider = context
                                .read<WalletProvider>();
                            final messenger = ScaffoldMessenger.of(context);

                            String lastFour = _currentCard.lastFour;
                            String maskedNumber = _currentCard.maskedNumber;

                            final rawInput = fullNumberController.text.trim();
                            if (rawInput.isNotEmpty) {
                              final clean = rawInput.replaceAll(
                                RegExp(r'\s+'),
                                '',
                              );
                              if (clean.length >= 4) {
                                lastFour = clean.substring(clean.length - 4);
                                maskedNumber = '•••• •••• •••• $lastFour';
                                try {
                                  await _secureNumberService.saveCardFullNumber(
                                    _currentCard.id,
                                    clean,
                                  );
                                } catch (_) {
                                  try {
                                    final keyService = WalletKeyService();
                                    await keyService
                                        .resetAndRegenerateMasterKey();
                                    await _secureNumberService
                                        .saveCardFullNumber(
                                          _currentCard.id,
                                          clean,
                                        );
                                  } catch (_) {}
                                }
                              }
                            }

                            final updated = _currentCard.copyWith(
                              nickname: nicknameController.text.trim(),
                              issuerName: issuerController.text.trim(),
                              cardholderName: cardholderController.text.trim(),
                              expiryMonth: expiryMonth,
                              expiryYear: expiryYear,
                              cardType: cardType,
                              themeGradient: themeGradient,
                              cardLayoutId: cardLayoutId,
                              lastFour: lastFour,
                              maskedNumber: maskedNumber,
                              updatedAt: DateTime.now(),
                            );

                            await cardProvider.updateCard(updated);
                            if (mounted) {
                              walletProvider.loadWallet();
                              setState(() => _currentCard = updated);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Card updated successfully'),
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

  Future<void> _deleteCard() async {
    final cardId = _currentCard.id;
    final cardProvider = context.read<WalletCardProvider>();
    final walletProvider = context.read<WalletProvider>();
    final nav = Navigator.of(context);

    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Card?',
      message:
          'This card will be removed from your wallet. Any associated transactions will remain safely preserved.',
      confirmLabel: 'Delete Card',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirm == true && mounted) {
      await _secureNumberService.deleteCardFullNumber(cardId);
      await cardProvider.deleteCard(cardId);
      if (mounted) {
        walletProvider.loadWallet();
        nav.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    double totalSpend = 0.0;
    for (final t in _linkedTransactions) {
      if (t.type == 'expense') totalSpend += t.amount;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4D2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F4D2),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C221E)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2C221E),
        ),
        title: Text(_currentCard.nickname),
        actions: [
          IconButton(
            icon: Icon(
              _currentCard.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: _currentCard.isFavorite
                  ? Colors.amber
                  : AppColors.getTextSecondary(context),
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditCardDialog,
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: AppColors.getError(context),
            ),
            onPressed: _deleteCard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Authentic Spotlight Card Presentation (Exact Replica of Wallet Spotlight)
            Center(
              child: AspectRatio(
                aspectRatio: 1.586,
                child: StitchSpotlightCard.fromCard(
                  card: _currentCard,
                  onTap: _showEditCardDialog,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Clay Action Buttons Row (Open, Share, Edit)
            Row(
              children: [
                Expanded(
                  child: _buildClayActionButton(
                    icon: Icons.folder_open_rounded,
                    label: 'Open',
                    backgroundColor: const Color(0xFFCBDFBD), // Pistachio
                    onTap: _openCardPdf,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildClayActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    backgroundColor: const Color(0xFFD4E09B), // Chartreuse
                    onTap: _shareCardDetails,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildClayActionButton(
                    icon: Icons.edit_note_rounded,
                    label: 'Edit',
                    backgroundColor: const Color(0xFFF19C79), // Terracotta
                    onTap: _showEditCardDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Metadata Summary Card
            ReusableCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                children: [
                  _buildMetaRow('Issuer Bank', _currentCard.issuerName),
                  Divider(color: AppColors.getDivider(context)),
                  _buildMetaRow('Cardholder', _currentCard.cardholderName),
                  Divider(color: AppColors.getDivider(context)),
                  _buildMetaRow(
                    'Card Type',
                    _currentCard.cardType.toUpperCase(),
                  ),
                  Divider(color: AppColors.getDivider(context)),
                  _buildMetaRow(
                    'Payment Network',
                    _currentCard.cardNetwork.toUpperCase(),
                  ),
                  Divider(color: AppColors.getDivider(context)),
                  _buildMetaRow(
                    'Expiry Date',
                    '${_currentCard.expiryMonth.toString().padLeft(2, '0')}/${_currentCard.expiryYear}',
                  ),
                  Divider(color: AppColors.getDivider(context)),
                  _buildMetaRow('Masked Number', _currentCard.maskedNumber),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Linked Transactions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Linked Transactions',
                  style: AppTextStyles.getHeading3(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                if (_linkedTransactions.isNotEmpty)
                  Text(
                    'Total: ${currencyFormat.format(totalSpend)}',
                    style: TextStyle(
                      color: AppColors.getPrimary(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (_isLoadingTransactions)
              const LoadingState(message: 'Loading linked activity...')
            else if (_linkedTransactions.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No Linked Transactions',
                message:
                    'Transactions tagged with this card will appear here automatically.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _linkedTransactions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final t = _linkedTransactions[i];
                  final isExpense = t.type == 'expense';
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: AppRadius.roundedMd,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color:
                                (isExpense
                                        ? AppColors.getError(context)
                                        : AppColors.getSuccess(context))
                                    .withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isExpense
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 16,
                            color: isExpense
                                ? AppColors.getError(context)
                                : AppColors.getSuccess(context),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.merchant ?? t.description ?? 'Transaction',
                                style: AppTextStyles.getBodyMedium(
                                  context,
                                ).copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                dateFormat.format(t.date),
                                style: AppTextStyles.getBodySmall(context),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isExpense ? '-' : '+'}${currencyFormat.format(t.amount)}',
                          style: TextStyle(
                            color: isExpense
                                ? AppColors.getError(context)
                                : AppColors.getSuccess(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _openCardPdf() async {
    // Cards don't have PDF attachments; show info snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No PDF attached to this card.'),
      ),
    );
  }

  Future<void> _shareCardDetails() async {
    final expYearStr = _currentCard.expiryYear.toString();
    final shortYear = expYearStr.length >= 2
        ? expYearStr.substring(expYearStr.length - 2)
        : expYearStr.padLeft(2, '0');
    final expiry =
        '${_currentCard.expiryMonth.toString().padLeft(2, '0')}/$shortYear';
    final text = 'Spendz Card Details:\n'
        'Bank: ${_currentCard.issuerName}\n'
        'Cardholder: ${_currentCard.cardholderName}\n'
        'Type: ${_currentCard.cardType.toUpperCase()} (${_currentCard.cardNetwork.toUpperCase()})\n'
        'Number: ${_currentCard.maskedNumber}\n'
        'Expiry: $expiry';
    
    // Note: Never share CVVs or full sensitive numbers
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: '${_currentCard.issuerName} Card Details',
      ),
    );
  }

  Widget _buildClayActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    const espresso = Color(0xFF2C221E);
    final bgColor = backgroundColor ?? const Color(0xFFF6F4D2);
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x332C221E),
              blurRadius: 6,
              offset: Offset(2, 3),
            ),
            BoxShadow(
              color: Colors.white,
              blurRadius: 2,
              offset: Offset(-1.5, -1.5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isEnabled ? espresso : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isEnabled ? espresso : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.getBodySmall(
              context,
            ).copyWith(color: AppColors.getTextSecondary(context)),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.getBodyMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
