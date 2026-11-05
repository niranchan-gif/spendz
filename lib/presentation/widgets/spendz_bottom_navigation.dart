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

/// Spendz Funky Claymorphism Floating Bottom Dock Navigation.
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2D) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E2B40) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(90)
                : const Color(0xFF1E293B).withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(50)
                : const Color(0xFF1E293B).withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
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
                    borderRadius: BorderRadius.circular(
                      SpendzSpacing.radiusFull,
                    ),
                    onTap: () => onTap(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutBack,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? SpendzColors.tangerine
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                SpendzSpacing.radiusFull,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: SpendzColors.tangerine.withAlpha(
                                          isDark ? 80 : 90,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 22,
                              color: isSelected
                                  ? Colors.white
                                  : SpendzColors.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? (isDark
                                        ? Colors.white
                                        : SpendzColors.tangerineDeep)
                                  : SpendzColors.textSecondary(context),
                              letterSpacing: 0.2,
                            ),
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
