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
import '../../widgets/glass/glass.dart';
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
          content: Text('Transaction saved successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final emerald = AppColors.getEmeraldAccent(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100),
              physics: const BouncingScrollPhysics(),
              children: [
                // Type Selector Capsule
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.getGlassBackground(context),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppColors.getGlassBorder(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = 'expense'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedType == 'expense'
                                  ? AppColors.error.withAlpha(isDark ? 50 : 25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: _selectedType == 'expense'
                                    ? AppColors.error.withAlpha(120)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 16,
                                  color: _selectedType == 'expense' ? AppColors.error : textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Expense',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: _selectedType == 'expense' ? FontWeight.w700 : FontWeight.w500,
                                    color: _selectedType == 'expense' ? AppColors.error : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = 'income'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedType == 'income'
                                  ? emerald.withAlpha(isDark ? 50 : 25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: _selectedType == 'income'
                                    ? emerald
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 16,
                                  color: _selectedType == 'income' ? emerald : textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Income',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: _selectedType == 'income' ? FontWeight.w700 : FontWeight.w500,
                                    color: _selectedType == 'income' ? emerald : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Amount Field
                GlassInputField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  label: 'Amount (₹)',
                  hint: '0.00',
                  prefixIcon: Icon(Icons.currency_rupee_rounded, color: emerald),
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
                  dropdownColor: isDark ? const Color(0xFF14231B) : Colors.white,
                  style: TextStyle(color: textPrimary, fontSize: 14.5, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: textSecondary, fontSize: 13),
                    prefixIcon: Icon(Icons.category_outlined, color: emerald, size: 20),
                    filled: true,
                    fillColor: AppColors.getGlassBackground(context),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: AppColors.getGlassBorder(context), width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: emerald, width: 1.5),
                    ),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.name, style: AppTextStyles.labelMedium.copyWith(color: textPrimary)),
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
                    dropdownColor: isDark ? const Color(0xFF14231B) : Colors.white,
                    style: TextStyle(color: textPrimary, fontSize: 14.5, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Linked Payment Card (Optional)',
                      labelStyle: TextStyle(color: textSecondary, fontSize: 13),
                      prefixIcon: Icon(Icons.credit_card_rounded, color: emerald, size: 20),
                      filled: true,
                      fillColor: AppColors.getGlassBackground(context),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: AppColors.getGlassBorder(context), width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: emerald, width: 1.5),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<WalletCardModel>(
                        value: null,
                        child: Text('None / Cash / UPI', style: TextStyle(color: textPrimary)),
                      ),
                      ...cards.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text('${c.nickname} •••• ${c.lastFour}', style: TextStyle(color: textPrimary)),
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
                GlassInputField(
                  controller: _descriptionController,
                  label: 'Description / Merchant (Optional)',
                  hint: 'e.g. Starbucks, Zomato, Rent',
                  prefixIcon: Icon(Icons.description_outlined, color: emerald, size: 20),
                ),

                const SizedBox(height: AppSpacing.md),

                // Date Picker Tile
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs + 2),
                      decoration: BoxDecoration(
                        color: emerald.withAlpha(25),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(Icons.calendar_today_rounded, color: emerald, size: 18),
                    ),
                    title: Text(
                      'Transaction Date',
                      style: AppTextStyles.caption.copyWith(color: textSecondary),
                    ),
                    subtitle: Text(
                      DateFormat('EEE, dd MMMM yyyy').format(_selectedDate),
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
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
