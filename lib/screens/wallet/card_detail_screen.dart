import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../database/transaction_dao.dart';
import '../../models/transaction_model.dart';
import '../../models/wallet_card_model.dart';
import '../../providers/wallet_card_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/glass_container.dart';
import 'widgets/wallet_card_widget.dart';

class CardDetailScreen extends StatefulWidget {
  final WalletCardModel card;

  const CardDetailScreen({super.key, required this.card});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late WalletCardModel _currentCard;
  final TransactionDao _transactionDao = TransactionDao();
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
      await context.read<WalletCardProvider>().toggleCardFavorite(_currentCard.id);
      if (mounted) {
        context.read<WalletProvider>().loadWallet();
      }
    } catch (_) {}
  }

  void _showEditCardDialog() {
    final formKey = GlobalKey<FormState>();
    final nicknameController = TextEditingController(text: _currentCard.nickname);
    final issuerController = TextEditingController(text: _currentCard.issuerName);
    final cardholderController = TextEditingController(text: _currentCard.cardholderName);
    int expiryMonth = _currentCard.expiryMonth;
    int expiryYear = _currentCard.expiryYear;
    String cardType = _currentCard.cardType;
    String themeGradient = _currentCard.themeGradient;

    final themes = ['emerald', 'midnight', 'obsidian', 'amethyst', 'crimson', 'amber'];
    final cardTypes = ['credit', 'debit', 'atm', 'membership', 'loyalty', 'custom'];

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
                          Text('Edit Virtual Card', style: AppTextStyles.heading3),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nicknameController,
                        decoration: const InputDecoration(labelText: 'Card Nickname'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: issuerController,
                              decoration: const InputDecoration(labelText: 'Bank / Issuer'),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cardholderController,
                        decoration: const InputDecoration(labelText: 'Cardholder Name'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                      const SizedBox(height: 16),
                      const Text('Card Gradient Theme', style: TextStyle(fontSize: 13, color: Colors.white70)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: themes.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final th = themes[i];
                            final isSelected = themeGradient == th;
                            return GestureDetector(
                              onTap: () => setModalState(() => themeGradient = th),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.white24,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  th.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final updated = _currentCard.copyWith(
                              nickname: nicknameController.text.trim(),
                              issuerName: issuerController.text.trim(),
                              cardholderName: cardholderController.text.trim(),
                              cardType: cardType,
                              expiryMonth: expiryMonth,
                              expiryYear: expiryYear,
                              themeGradient: themeGradient,
                              updatedAt: DateTime.now(),
                            );
                            final cardProvider = context.read<WalletCardProvider>();
                            final walletProvider = context.read<WalletProvider>();
                            await cardProvider.updateCard(updated);
                            walletProvider.loadWallet();
                            if (mounted) {
                              setState(() => _currentCard = updated);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Save Changes'),
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

  Future<void> _deleteCard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Card?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This card will be removed from your wallet. Any associated transactions will be safely preserved with unlinked card reference.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<WalletCardProvider>().deleteCard(_currentCard.id);
      if (mounted) {
        context.read<WalletProvider>().loadWallet();
        Navigator.of(context).pop();
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_currentCard.nickname, style: AppTextStyles.heading3),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _currentCard.isFavorite ? Icons.star : Icons.star_border,
              color: _currentCard.isFavorite ? Colors.amber : Colors.white70,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditCardDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _deleteCard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Widget Display
            Center(
              child: WalletCardWidget(
                card: _currentCard,
                onTap: _showEditCardDialog,
              ),
            ),
            const SizedBox(height: 16),

            // Non-payment Security Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(40)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Spendz never stores CVVs, PINs, or banking credentials. This virtual card is used exclusively for personal expense organization and cannot independently process financial payments.',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card Metadata Summary
            GlassContainer(
              child: Column(
                children: [
                  _buildMetaRow('Issuer Bank', _currentCard.issuerName),
                  const Divider(color: Colors.white10),
                  _buildMetaRow('Cardholder', _currentCard.cardholderName),
                  const Divider(color: Colors.white10),
                  _buildMetaRow('Card Type', _currentCard.cardType.toUpperCase()),
                  const Divider(color: Colors.white10),
                  _buildMetaRow('Payment Network', _currentCard.cardNetwork.toUpperCase()),
                  const Divider(color: Colors.white10),
                  _buildMetaRow('Expiry Date', '${_currentCard.expiryMonth.toString().padLeft(2, '0')}/${_currentCard.expiryYear}'),
                  const Divider(color: Colors.white10),
                  _buildMetaRow('Masked Number', _currentCard.maskedNumber),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Linked Transactions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Linked Transactions', style: AppTextStyles.heading3),
                if (_linkedTransactions.isNotEmpty)
                  Text(
                    'Total: ${currencyFormat.format(totalSpend)}',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoadingTransactions)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (_linkedTransactions.isEmpty)
              GlassContainer(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 40, color: Colors.white.withAlpha(50)),
                        const SizedBox(height: 8),
                        const Text(
                          'No transactions linked to this card yet',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Transactions tagged with this card will appear here automatically.',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isExpense ? Colors.red.withAlpha(20) : Colors.green.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isExpense ? Colors.redAccent : Colors.greenAccent,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.merchant ?? t.description ?? 'Transaction',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateFormat.format(t.date),
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isExpense ? "-" : "+"}${currencyFormat.format(t.amount)}',
                          style: TextStyle(
                            color: isExpense ? Colors.white : Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          Text(value, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
