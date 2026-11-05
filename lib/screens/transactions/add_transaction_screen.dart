import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/spendz_colors.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../models/wallet_card_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/icon_mapper.dart';

/// Spendz Funky Claymorphism Add Transaction Screen.
/// Sculpted amount display hero, sunken merchant well, category pills,
/// interactive clay numeric keypad, and inflated gradient action button.
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _descriptionController = TextEditingController();
  String _amount = '0';
  String _selectedType = 'expense'; // 'expense', 'income', 'transfer'
  CategoryModel? _selectedCategory;
  WalletCardModel? _selectedCard;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'backspace') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (key == '.') {
        if (!_amount.contains('.')) {
          _amount += '.';
        }
      } else {
        if (_amount == '0') {
          _amount = key;
        } else {
          // Limit to 2 decimals
          if (_amount.contains('.')) {
            final parts = _amount.split('.');
            if (parts.length > 1 && parts[1].length >= 2) {
              return;
            }
          }
          if (_amount.length < 9) {
            _amount += key;
          }
        }
      }
    });
  }

  void _saveTransaction() {
    final parsedAmount = double.tryParse(_amount) ?? 0.0;
    if (parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final tx = TransactionModel(
      id: const Uuid().v4(),
      amount: parsedAmount,
      type: _selectedType,
      categoryId: _selectedCategory!.id,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      date: _selectedDate,
      source: 'manual',
      cardId: _selectedCard?.id,
      paymentMethod: _selectedCard != null
          ? '${_selectedCard!.issuerName} (${_selectedCard!.lastFour})'
          : 'Cash',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    context.read<TransactionProvider>().addTransaction(tx);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction saved ⚡️'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpendzColors.background(context),
      body: SafeArea(
        child: Consumer2<CategoryProvider, WalletProvider>(
          builder: (context, catProvider, walletProvider, child) {
            final categories = _selectedType == 'expense'
                ? catProvider.expenseCategories
                : catProvider.incomeCategories;

            if (_selectedCategory != null &&
                _selectedCategory!.type != 'both' &&
                _selectedCategory!.type != _selectedType) {
              _selectedCategory = null;
            }

            // Auto-select first category if none selected
            if (_selectedCategory == null && categories.isNotEmpty) {
              _selectedCategory = categories.first;
            }

            final cards = walletProvider.cards;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top dismiss bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: SpendzColors.surface(context),
                            shape: BoxShape.circle,
                            boxShadow: SpendzColors.clayDropShadow(context),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: SpendzColors.textPrimary(context),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'New Transaction',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: SpendzColors.textPrimary(context),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('💸', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                      const SizedBox(width: 42), // Balance spacer
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mode Tabs (Expense, Income, Transfer)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: SpendzColors.surfaceContainerLow(context),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                          blurStyle: BlurStyle.inner,
                        ),
                        BoxShadow(
                          color: Colors.white.withAlpha(200),
                          offset: const Offset(-2, -2),
                          blurRadius: 4,
                          blurStyle: BlurStyle.inner,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildModeTab(
                          'Expense',
                          'expense',
                          SpendzColors.tangerine,
                        ),
                        _buildModeTab(
                          'Income',
                          'income',
                          SpendzColors.tertiarySky,
                        ),
                        _buildModeTab(
                          'Transfer',
                          'transfer',
                          SpendzColors.sunshineYellow,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sculpted Amount Display Hero
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: SpendzColors.surface(context),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: SpendzColors.clayDropShadow(context),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: SpendzColors.tangerine,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _amount,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                color: SpendzColors.textPrimary(context),
                                letterSpacing: -1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_selectedCategory != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: SpendzColors.sunshineYellow.withAlpha(40),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('✨', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 5),
                                Text(
                                  'Category: ${_selectedCategory!.name}',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF735500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sunken Merchant & Note Input Well
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: SpendzColors.surfaceContainerLow(context),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                          blurStyle: BlurStyle.inner,
                        ),
                        BoxShadow(
                          color: Colors.white.withAlpha(220),
                          offset: const Offset(-2, -2),
                          blurRadius: 4,
                          blurStyle: BlurStyle.inner,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          size: 20,
                          color: SpendzColors.tangerine,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _descriptionController,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: SpendzColors.textPrimary(context),
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Where did you spend? (e.g. Starbucks)',
                              hintStyle: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: SpendzColors.textSecondary(context),
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category Horizontal Chips
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final cat = categories[idx];
                        final isSelected = _selectedCategory?.id == cat.id;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? SpendzColors.tangerine
                                  : SpendzColors.surface(context),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: SpendzColors.tangerine.withAlpha(
                                          90,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : SpendzColors.clayDropShadow(context),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  IconMapper.getIcon(cat.icon),
                                  size: 15,
                                  color: isSelected
                                      ? Colors.white
                                      : SpendzColors.textSecondary(context),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : SpendzColors.textPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2-Column Pods: Account & Date
                  Row(
                    children: [
                      // Account Selector Pod
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showAccountSelector(cards),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: SpendzColors.surface(context),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: SpendzColors.clayDropShadow(context),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.credit_card_rounded,
                                      size: 15,
                                      color: SpendzColors.tertiarySky,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Account',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: SpendzColors.textSecondary(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedCard != null
                                            ? '${_selectedCard!.issuerName} (••${_selectedCard!.lastFour})'
                                            : 'Cash / UPI',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: SpendzColors.textPrimary(
                                            context,
                                          ),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.expand_more_rounded,
                                      size: 16,
                                      color: SpendzColors.textSecondary(
                                        context,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Date & Time Pod
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: SpendzColors.surface(context),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: SpendzColors.clayDropShadow(context),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule_rounded,
                                      size: 15,
                                      color: SpendzColors.tangerine,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Date & Time',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: SpendzColors.textSecondary(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'dd MMM yyyy',
                                      ).format(_selectedDate),
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: SpendzColors.textPrimary(
                                          context,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 16,
                                      color: SpendzColors.textSecondary(
                                        context,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tactile Clay Numeric Keypad
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SpendzColors.surfaceContainerLow(context),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                          blurStyle: BlurStyle.inner,
                        ),
                        BoxShadow(
                          color: Colors.white.withAlpha(200),
                          offset: const Offset(-2, -2),
                          blurRadius: 4,
                          blurStyle: BlurStyle.inner,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildKey('1'),
                            const SizedBox(width: 8),
                            _buildKey('2'),
                            const SizedBox(width: 8),
                            _buildKey('3'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildKey('4'),
                            const SizedBox(width: 8),
                            _buildKey('5'),
                            const SizedBox(width: 8),
                            _buildKey('6'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildKey('7'),
                            const SizedBox(width: 8),
                            _buildKey('8'),
                            const SizedBox(width: 8),
                            _buildKey('9'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildKey('.'),
                            const SizedBox(width: 8),
                            _buildKey('0'),
                            const SizedBox(width: 8),
                            _buildKey('backspace', isAction: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Save Transaction ⚡️ Inflated Clay Button
                  GestureDetector(
                    onTap: _saveTransaction,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            SpendzColors.tangerine,
                            SpendzColors.sunshineYellow,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: SpendzColors.tangerine.withAlpha(120),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.white.withAlpha(180),
                            blurRadius: 3,
                            offset: const Offset(2, 2),
                            blurStyle: BlurStyle.inner,
                          ),
                          BoxShadow(
                            color: const Color(0xFF954A00).withAlpha(60),
                            blurRadius: 4,
                            offset: const Offset(-2, -2),
                            blurStyle: BlurStyle.inner,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Save Transaction',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text('⚡️', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeTab(String label, String mode, Color color) {
    final isSelected = _selectedType == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withAlpha(90),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.white.withAlpha(180),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                      blurStyle: BlurStyle.inner,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? (mode == 'transfer'
                        ? const Color(0xFF735500)
                        : Colors.white)
                  : SpendzColors.textSecondary(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String key, {bool isAction = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onKeyPress(key),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: SpendzColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: SpendzColors.clayDropShadow(
              context,
              blur: 12,
              offset: const Offset(0, 4),
            ),
          ),
          alignment: Alignment.center,
          child: isAction
              ? const Icon(
                  Icons.backspace_outlined,
                  size: 20,
                  color: SpendzColors.tangerine,
                )
              : Text(
                  key,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: SpendzColors.textPrimary(context),
                  ),
                ),
        ),
      ),
    );
  }

  void _showAccountSelector(List<WalletCardModel> cards) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SpendzColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
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
                  color: SpendzColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Account',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: SpendzColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.money_rounded,
                color: SpendzColors.tangerine,
              ),
              title: const Text('Cash / UPI'),
              trailing: _selectedCard == null
                  ? const Icon(
                      Icons.check_rounded,
                      color: SpendzColors.tangerine,
                    )
                  : null,
              onTap: () {
                setState(() => _selectedCard = null);
                Navigator.pop(ctx);
              },
            ),
            ...cards.map(
              (c) => ListTile(
                leading: const Icon(
                  Icons.credit_card_rounded,
                  color: SpendzColors.tertiarySky,
                ),
                title: Text('${c.issuerName} •••• ${c.lastFour}'),
                subtitle: Text(c.cardholderName),
                trailing: _selectedCard?.id == c.id
                    ? const Icon(
                        Icons.check_rounded,
                        color: SpendzColors.tangerine,
                      )
                    : null,
                onTap: () {
                  setState(() => _selectedCard = c);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
