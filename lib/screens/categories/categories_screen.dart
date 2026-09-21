import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../providers/category_provider.dart';
import '../../models/category_model.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../utils/icon_mapper.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Income'),
            ],
          ),
        ),
        body: Consumer<CategoryProvider>(
          builder: (context, catProvider, child) {
            if (catProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              children: [
                _buildCategoryList(context, catProvider.expenseCategories),
                _buildCategoryList(context, catProvider.incomeCategories),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddCategoryDialog(context);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final color = Color(int.tryParse(cat.color) ?? AppColors.primary.value);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: color.withAlpha(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withAlpha(50), width: 1),
          ),
          child: ListTile(
            leading: Icon(IconMapper.getIcon(cat.icon), color: color, size: 28),
            title: Text(
              cat.name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            onLongPress: () {
              _showDeleteConfirmationDialog(context, cat);
            },
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, CategoryModel category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CategoryProvider>().deleteCategory(category.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Category deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final isExpenseNotifier = ValueNotifier<bool>(true);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Gym, Coffee',
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: isExpenseNotifier,
              builder: (context, isExpense, child) {
                return Row(
                  children: [
                    const Text('Type:'),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Expense'),
                      selected: isExpense,
                      onSelected: (selected) {
                        isExpenseNotifier.value = true;
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Income'),
                      selected: !isExpense,
                      onSelected: (selected) {
                        isExpenseNotifier.value = false;
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                final newCat = CategoryModel(
                  id: const Uuid().v4(),
                  name: newName,
                  icon: _getSuitableIcon(newName),
                  color: '0xFF9E9E9E', // Default grey color, or pick randomly
                  type: isExpenseNotifier.value ? 'expense' : 'income',
                  isDefault: false,
                  createdAt: DateTime.now(),
                );
                context.read<CategoryProvider>().addCategory(newCat);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category added')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
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
