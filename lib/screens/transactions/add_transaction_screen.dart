import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../models/wallet_card_model.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_text_styles.dart';
import '../../widgets/design_system/app_form_field.dart';
import '../../widgets/design_system/primary_button.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'expense';
  CategoryModel? _selectedCategory;
  WalletCardModel? _selectedCard;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      final tx = TransactionModel(
        id: const Uuid().v4(),
        amount: double.parse(_amountController.text),
        type: _selectedType,
        categoryId: _selectedCategory!.id,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        date: _selectedDate,
        source: 'manual',
        cardId: _selectedCard?.id,
        paymentMethod: _selectedCard != null ? '${_selectedCard!.issuerName} (${_selectedCard!.lastFour})' : 'Cash',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      context.read<TransactionProvider>().addTransaction(tx);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction saved!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppColors.getSurface(context);
    final borderColor = AppColors.getBorder(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: Consumer2<CategoryProvider, WalletProvider>(
        builder: (context, catProvider, walletProvider, child) {
          final categories = _selectedType == 'expense'
              ? catProvider.expenseCategories
              : catProvider.incomeCategories;

          if (_selectedCategory != null &&
              _selectedCategory!.type != 'both' &&
              _selectedCategory!.type != _selectedType) {
            _selectedCategory = null;
          }

          final cards = walletProvider.cards;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              physics: const BouncingScrollPhysics(),
              children: [
                // Type Selector
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'expense',
                      label: Text('Expense'),
                      icon: Icon(Icons.arrow_upward_rounded),
                    ),
                    ButtonSegment(
                      value: 'income',
                      label: Text('Income'),
                      icon: Icon(Icons.arrow_downward_rounded),
                    ),
                  ],
                  selected: {_selectedType},
                  style: ButtonStyle(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                    ),
                  ),
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Amount
                AppFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  label: 'Amount (₹)',
                  hint: '0.00',
                  prefixIcon: Icons.currency_rupee_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter amount';
                    if (double.tryParse(value) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Category Dropdown
                DropdownButtonFormField<CategoryModel>(
                  initialValue: _selectedCategory,
                  dropdownColor: surfaceColor,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category_outlined),
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.name, style: AppTextStyles.labelMedium),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  },
                  validator: (val) => val == null ? 'Select category' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Optional Linked Payment Card
                if (cards.isNotEmpty) ...[
                  DropdownButtonFormField<WalletCardModel>(
                    initialValue: _selectedCard,
                    dropdownColor: surfaceColor,
                    decoration: InputDecoration(
                      labelText: 'Linked Payment Card (Optional)',
                      prefixIcon: const Icon(Icons.credit_card_rounded),
                      filled: true,
                      fillColor: surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<WalletCardModel>(
                        value: null,
                        child: Text('None / Cash / UPI'),
                      ),
                      ...cards.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text('${c.nickname} •••• ${c.lastFour}'),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedCard = val;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Description
                AppFormField(
                  controller: _descriptionController,
                  label: 'Description / Merchant (Optional)',
                  hint: 'e.g. Starbucks, Zomato, Rent',
                  prefixIcon: Icons.description_outlined,
                ),
                const SizedBox(height: AppSpacing.md),

                // Date Picker Tile
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: borderColor),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                    title: Text(
                      'Date',
                      style: AppTextStyles.caption.copyWith(color: textSecondary),
                    ),
                    subtitle: Text(
                      DateFormat('EEE, dd MMMM yyyy').format(_selectedDate),
                      style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Save Button
                PrimaryButton(
                  label: 'Save Transaction',
                  icon: Icons.check_rounded,
                  onPressed: _saveTransaction,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
