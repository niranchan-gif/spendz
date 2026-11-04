import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';

class DocumentCategoryItem {
  final String key;
  final String label;
  final IconData icon;

  const DocumentCategoryItem({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class DocumentCategoryChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const DocumentCategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  static const List<DocumentCategoryItem> categories = [
    DocumentCategoryItem(
      key: 'all',
      label: 'All',
      icon: Icons.grid_view_rounded,
    ),
    DocumentCategoryItem(
      key: 'identity',
      label: 'Identity',
      icon: Icons.badge_outlined,
    ),
    DocumentCategoryItem(
      key: 'banking',
      label: 'Banking',
      icon: Icons.payment_rounded,
    ),
    DocumentCategoryItem(
      key: 'driving',
      label: 'Driving',
      icon: Icons.directions_car_outlined,
    ),
    DocumentCategoryItem(
      key: 'travel',
      label: 'Travel',
      icon: Icons.flight_takeoff_rounded,
    ),
    DocumentCategoryItem(
      key: 'insurance',
      label: 'Insurance',
      icon: Icons.health_and_safety_outlined,
    ),
    DocumentCategoryItem(
      key: 'others',
      label: 'Others',
      icon: Icons.folder_open_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppColors.getSurface(context);
    final borderColor = AppColors.getBorder(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: categories.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = categories[index];
          final isSelected =
              selectedCategory.toLowerCase() == item.key.toLowerCase();

          return ChoiceChip(
            showCheckmark: false,
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: surfaceColor,
            elevation: isSelected ? 2 : 0,
            pressElevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.full),
              side: BorderSide(
                color: isSelected ? AppColors.primary : borderColor,
                width: 1,
              ),
            ),
            avatar: Icon(
              item.icon,
              size: 16,
              color: isSelected ? Colors.white : textSecondary,
            ),
            label: Text(
              item.label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? Colors.white : textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            onSelected: (_) => onSelected(item.key),
          );
        },
      ),
    );
  }
}
