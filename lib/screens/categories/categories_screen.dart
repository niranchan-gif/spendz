import 'package:flutter/material.dart';
import 'package:keybz/widgets/app_keyboard/app_keyboard.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/spendz_colors.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../utils/icon_mapper.dart';

/// SPENDZ Categories Screen.
/// Matte Claymorphism design with dual drop shadows, zero borders,
/// 5-color pastel palette, tactile tab pills, and bespoke category creator.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _selectedTabIndex = 0; // 0: Expenses, 1: Income

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpendzColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCBDFBD), // Pistachio
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1F2C221E),
                            blurRadius: 4,
                            offset: Offset(1.5, 2.5),
                          ),
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 1.5,
                            offset: Offset(-1, -1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.arrowLeft,
                        size: 20,
                        color: Color(0xFF2C221E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Categories',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2C221E),
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Organize expenses & cashflows',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF63564F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAddCategorySheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF19C79), // Terracotta
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F2C221E),
                            blurRadius: 4,
                            offset: Offset(1.5, 2.5),
                          ),
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 1.5,
                            offset: Offset(-1, -1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.plus,
                            size: 16,
                            color: Color(0xFF2C221E),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2C221E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tactile Segmented Clay Tabs (Expenses / Income)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F4D2),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F2C221E),
                      offset: Offset(1.5, 1.5),
                      blurRadius: 3,
                      blurStyle: BlurStyle.inner,
                    ),
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(-1, -1),
                      blurRadius: 2,
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildTabPill(
                      index: 0,
                      label: 'Expenses',
                      icon: LucideIcons.trendingDown,
                      activeColor: const Color(0xFFF19C79), // Terracotta
                    ),
                    _buildTabPill(
                      index: 1,
                      label: 'Income',
                      icon: LucideIcons.trendingUp,
                      activeColor: const Color(0xFFD4E09B), // Chartreuse
                    ),
                  ],
                ),
              ),
            ),

            // Category List Content
            Expanded(
              child: Consumer<CategoryProvider>(
                builder: (context, catProvider, _) {
                  if (catProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF19C79),
                      ),
                    );
                  }

                  final categories = _selectedTabIndex == 0
                      ? catProvider.expenseCategories
                      : catProvider.incomeCategories;

                  if (categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFCBDFBD),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x1F2C221E),
                                  blurRadius: 5,
                                  offset: Offset(2, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.folderClosed,
                              size: 28,
                              color: Color(0xFF2C221E),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _selectedTabIndex == 0
                                ? 'No expense categories'
                                : 'No income categories',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C221E),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap "+ Add" above to create one',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              color: Color(0xFF63564F),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return _buildCategoryItem(context, cat);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill({
    required int index,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x1F2C221E),
                      blurRadius: 4,
                      offset: Offset(1.5, 2.5),
                    ),
                    BoxShadow(
                      color: Colors.white,
                      blurRadius: 1.5,
                      offset: Offset(-1, -1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? const Color(0xFF2C221E)
                    : const Color(0xFF63564F),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? const Color(0xFF2C221E)
                      : const Color(0xFF63564F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, CategoryModel cat) {
    final colorVal = int.tryParse(cat.color) ?? 0xFFCBDFBD;
    final catColor = Color(colorVal);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4D2), // Cream
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2C221E),
            blurRadius: 4,
            offset: Offset(1.5, 2.5),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 1.5,
            offset: Offset(-1, -1),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withAlpha(50),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  IconMapper.getIcon(cat.icon),
                  color: const Color(0xFF2C221E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.name,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C221E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cat.isDefault ? 'Standard Category' : 'Custom Category',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF63564F),
                      ),
                    ),
                  ],
                ),
              ),
              if (!cat.isDefault)
                GestureDetector(
                  onTap: () => _confirmDeleteCategory(context, cat),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCBDFBD),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1F2C221E),
                          blurRadius: 3,
                          offset: Offset(1, 1.5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.trash2,
                      color: Color(0xFFA44A3F), // Brick
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, CategoryModel cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF6F4D2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete "${cat.name}"?',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C221E),
          ),
        ),
        content: const Text(
          'Transactions with this category will remain preserved.',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            color: Color(0xFF63564F),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                color: Color(0xFF63564F),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              context.read<CategoryProvider>().deleteCategory(cat.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Category deleted'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFFF19C79),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFA44A3F), // Brick
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F2C221E),
                    blurRadius: 4,
                    offset: Offset(1.5, 2.5),
                  ),
                ],
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF6F4D2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = _selectedTabIndex == 0 ? 'expense' : 'income';
    String selectedColor = '0xFFD4E09B'; // Warm Chartreuse

    final paletteColors = [
      '0xFFD4E09B', // Chartreuse
      '0xFFF19C79', // Terracotta
      '0xFFCBDFBD', // Pistachio
      '0xFFA44A3F', // Brick
      '0xFF4C6B22', // Olive
      '0xFF2E6385', // Slate Cyan
      '0xFFE6C587', // Champagne
      '0xFF819889', // Sage
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF6F4D2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBDFBD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'New Category',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C221E),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Name Input Well
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBDFBD),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F2C221E),
                        offset: Offset(1.5, 1.5),
                        blurRadius: 3,
                        blurStyle: BlurStyle.inner,
                      ),
                      BoxShadow(
                        color: Colors.white,
                        offset: Offset(-1, -1),
                        blurRadius: 2,
                        blurStyle: BlurStyle.inner,
                      ),
                    ],
                  ),
                  child: AppTextFormField(
                    controller: nameController,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C221E),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Category name (e.g. Gym, Travel, Coffee)',
                      hintStyle: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        color: Color(0xFF63564F),
                      ),
                      icon: Icon(
                        LucideIcons.tag,
                        size: 18,
                        color: Color(0xFF2C221E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Type Toggle (Expense / Income)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBDFBD),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F2C221E),
                        offset: Offset(1.5, 1.5),
                        blurRadius: 2,
                        blurStyle: BlurStyle.inner,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedType = 'expense'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedType == 'expense'
                                  ? const Color(0xFFF19C79)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Expense',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2C221E),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedType = 'income'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedType == 'income'
                                  ? const Color(0xFFD4E09B)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Income',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2C221E),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Color Palette Selector
                const Text(
                  'Color Tint',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF63564F),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: paletteColors.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, idx) {
                      final hex = paletteColors[idx];
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
                            boxShadow: [
                              if (isSelected)
                                const BoxShadow(
                                  color: Color(0x332C221E),
                                  blurRadius: 4,
                                  offset: Offset(1, 2),
                                ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(
                                  LucideIcons.check,
                                  color: Color(0xFF2C221E),
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Create Action Button
                GestureDetector(
                  onTap: () {
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
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Category created'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Color(0xFFF19C79),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF19C79),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F2C221E),
                          blurRadius: 5,
                          offset: Offset(2, 3),
                        ),
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 1.5,
                          offset: Offset(-1, -1),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Create Category',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2C221E),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getSuitableIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('food') ||
        lower.contains('coffee') ||
        lower.contains('eat') ||
        lower.contains('burger') ||
        lower.contains('drink') ||
        lower.contains('tea')) {
      return 'restaurant';
    } else if (lower.contains('car') ||
        lower.contains('gas') ||
        lower.contains('fuel') ||
        lower.contains('transit') ||
        lower.contains('bus') ||
        lower.contains('cab') ||
        lower.contains('taxi')) {
      return 'directions_car';
    } else if (lower.contains('shop') ||
        lower.contains('cloth') ||
        lower.contains('mall')) {
      return 'shopping_bag';
    } else if (lower.contains('health') ||
        lower.contains('doc') ||
        lower.contains('med') ||
        lower.contains('gym')) {
      return 'local_hospital';
    } else if (lower.contains('game') ||
        lower.contains('movie') ||
        lower.contains('fun')) {
      return 'movie';
    } else if (lower.contains('house') ||
        lower.contains('rent') ||
        lower.contains('home')) {
      return 'house';
    } else if (lower.contains('bill') || lower.contains('util')) {
      return 'receipt';
    } else if (lower.contains('salary') ||
        lower.contains('pay') ||
        lower.contains('wage')) {
      return 'work';
    } else if (lower.contains('gift') || lower.contains('present')) {
      return 'card_giftcard';
    }
    return 'category';
  }
}
