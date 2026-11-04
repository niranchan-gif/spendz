import 'package:flutter/material.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';

class SpendzNavigationDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const SpendzNavigationDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Spendz 2.0 Custom Floating Bottom Dock Navigation.
class SpendzBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<SpendzNavigationDestination> destinations;

  const SpendzBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = SpendzColors.isDark(context);
    final accent = SpendzColors.primaryAccent(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141D17) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? SpendzColors.borderDark : SpendzColors.borderLight,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(80)
                : Colors.black.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: SpendzSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(destinations.length, (index) {
              final item = destinations[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(SpendzSpacing.radiusMd),
                    onTap: () => onTap(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accent.withAlpha(isDark ? 45 : 30)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                SpendzSpacing.radiusFull,
                              ),
                            ),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 22,
                              color: isSelected
                                  ? accent
                                  : SpendzColors.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? accent
                                  : SpendzColors.textSecondary(context),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
