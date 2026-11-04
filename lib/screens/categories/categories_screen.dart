import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../providers/category_provider.dart';
import '../../models/category_model.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_text_styles.dart';
import '../../utils/icon_mapper.dart';
import '../../widgets/design_system/empty_state.dart';
import '../../widgets/design_system/app_bottom_sheet.dart';
import '../../widgets/design_system/app_form_field.dart';
import '../../widgets/design_system/primary_button.dart';
import '../../widgets/design_system/custom_dialog.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Categories'),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.getTextSecondary(context),
            labelStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: AppTextStyles.labelLarge,
            tabs: const [
              Tab(text: 'Expenses'),
              Tab(text: 'Income'),
            ],
          ),
        ),
        body: Consumer<CategoryProvider>(
          builder: (context, catProvider, child) {
            if (catProvider.isLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            return TabBarView(
              children: [
                _buildCategoryList(context, catProvider.expenseCategories, isExpense: true),
                _buildCategoryList(context, catProvider.incomeCategories, isExpense: false),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'categories_add_fab',
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Category', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _showAddCategorySheet(context),
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, List<CategoryModel> categories, {required bool isExpense}) {
    if (categories.isEmpty) {
      return Center(
        child: EmptyState(
          icon: isExpense ? Icons.shopping_bag_outlined : Icons.account_balance_wallet_outlined,
          title: isExpense ? 'No Expense Categories' : 'No Income Categories',
          subtitle: 'Create customized categories to organize your financial transactions.',
          actionLabel: 'Add Category',
          onActionPressed: () => _showAddCategorySheet(context),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final color = Color(int.tryParse(cat.color) ?? AppColors.primary.toARGB32());
        final surfaceColor = AppColors.getSurface(context);
        final borderColor = AppColors.getBorder(context);

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: borderColor),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                  border: Border.all(color: color.withAlpha(50)),
                ),
                child: Icon(IconMapper.getIcon(cat.icon), color: color, size: 22),
              ),
              title: Text(
                cat.name,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              subtitle: Text(
                cat.isDefault ? 'Standard Category' : 'Custom Category',
                style: AppTextStyles.caption.copyWith(color: AppColors.getTextSecondary(context)),
              ),
              trailing: cat.isDefault
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                      onPressed: () => _confirmDeleteCategory(context, cat),
                    ),
              onLongPress: () {
                if (!cat.isDefault) {
                  _confirmDeleteCategory(context, cat);
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context, CategoryModel category) async {
    final confirm = await CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Category?',
      message: 'Are you sure you want to delete "${category.name}"? Transactions associated with this category will remain preserved.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirm == true && context.mounted) {
      context.read<CategoryProvider>().deleteCategory(category.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category deleted'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showAddCategorySheet(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = 'expense';
    String selectedColor = '0xFF4CAF50';

    final colors = [
      '0xFF4CAF50', // Green
      '0xFF2196F3', // Blue
      '0xFFFF9800', // Orange
      '0xFFE91E63', // Pink
      '0xFF9C27B0', // Purple
      '0xFF00BCD4', // Cyan
      '0xFFFF5722', // Deep Orange
      '0xFF607D8B', // Blue Grey
    ];

    AppBottomSheet.show(
      context: context,
      title: 'Add New Category',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppFormField(
                controller: nameController,
                label: 'Category Name',
                hint: 'e.g. Gym, Coffee, Subscriptions',
                prefixIcon: Icons.category_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Category Type', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Expense')),
                  ButtonSegment(value: 'income', label: Text('Income')),
                ],
                selected: {selectedType},
                style: ButtonStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                  ),
                ),
                onSelectionChanged: (Set<String> newSelection) {
                  setModalState(() {
                    selectedType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Select Color', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: colors.length,
                  separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final hex = colors[index];
                    final color = Color(int.parse(hex));
                    final isSelected = selectedColor == hex;

                    return GestureDetector(
                      onTap: () => setModalState(() => selectedColor = hex),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withAlpha(120), blurRadius: 8, spreadRadius: 1)]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Create Category',
                icon: Icons.check_rounded,
                onPressed: () {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty) {
                    final newCat = CategoryModel(
                      id: const Uuid().v4(),
                      name: newName,
                      icon: _getSuitableIcon(newName),
                      color: selectedColor,
                      type: selectedType,
                      isDefault: false,
                      createdAt: DateTime.now(),
                    );
                    context.read<CategoryProvider>().addCategory(newCat);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category created!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _getSuitableIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('food') || lower.contains('coffee') || lower.contains('eat') || lower.contains('burger') || lower.contains('drink')) {
      return 'restaurant';
    } else if (lower.contains('car') || lower.contains('gas') || lower.contains('fuel') || lower.contains('transit') || lower.contains('taxi')) {
      return 'directions_car';
    } else if (lower.contains('shop') || lower.contains('cloth') || lower.contains('mall')) {
      return 'shopping_bag';
    } else if (lower.contains('health') || lower.contains('doc') || lower.contains('med') || lower.contains('gym')) {
      return 'local_hospital';
    } else if (lower.contains('game') || lower.contains('movie') || lower.contains('fun')) {
      return 'movie';
    } else if (lower.contains('house') || lower.contains('rent') || lower.contains('home')) {
      return 'house';
    } else if (lower.contains('bill') || lower.contains('util')) {
      return 'receipt';
    } else if (lower.contains('salary') || lower.contains('pay') || lower.contains('wage')) {
      return 'work';
    } else if (lower.contains('gift') || lower.contains('present')) {
      return 'card_giftcard';
    }
    return 'category';
  }
}
