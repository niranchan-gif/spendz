import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class DocumentCategoryItem {
  final String key;
  final String label;
  final IconData icon;

  const DocumentCategoryItem({required this.key, required this.label, required this.icon});
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
    DocumentCategoryItem(key: 'all', label: 'All', icon: Icons.grid_view_rounded),
    DocumentCategoryItem(key: 'aadhaar', label: 'Aadhaar', icon: Icons.fingerprint_rounded),
    DocumentCategoryItem(key: 'pan', label: 'PAN', icon: Icons.badge_outlined),
    DocumentCategoryItem(key: 'driving_license', label: 'Licence', icon: Icons.drive_eta_outlined),
    DocumentCategoryItem(key: 'passport', label: 'Passport', icon: Icons.flight_takeoff_rounded),
    DocumentCategoryItem(key: 'rc', label: 'Vehicle RC', icon: Icons.directions_car_filled_outlined),
    DocumentCategoryItem(key: 'insurance', label: 'Insurance', icon: Icons.verified_user_outlined),
    DocumentCategoryItem(key: 'college_id', label: 'ID Card', icon: Icons.school_outlined),
    DocumentCategoryItem(key: 'certificate', label: 'Certificates', icon: Icons.workspace_premium_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = categories[index];
          final isSelected = selectedCategory.toLowerCase() == item.key.toLowerCase();

          return ChoiceChip(
            showCheckmark: false,
            selected: isSelected,
            avatar: Icon(
              item.icon,
              size: 16,
              color: isSelected ? AppColors.background : AppColors.primary,
            ),
            label: Text(item.label),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.background : Colors.white70,
            ),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.white.withAlpha(20),
                width: 1,
              ),
            ),
            onSelected: (_) => onSelected(item.key),
          );
        },
      ),
    );
  }
}
