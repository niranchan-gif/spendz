import 'package:flutter/material.dart';

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

/// Floating, matte navigation dock with a quiet active state.
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F4D2), // Cream
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFE2E0BD), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F2C221E),
                blurRadius: 6,
                offset: Offset(2, 3),
              ),
              BoxShadow(
                color: Colors.white,
                blurRadius: 2,
                offset: Offset(-1, -1),
              ),
            ],
          ),
          child: Row(
            children: List.generate(destinations.length, (index) {
              final item = destinations[index];
              final selected = index == currentIndex;

              return Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFF19C79) // Coral Terracotta
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selected ? item.activeIcon : item.icon,
                            size: 20,
                            color: selected ? const Color(0xFF2C221E) : const Color(0xFF63564F),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 10,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w600,
                              color: selected ? const Color(0xFF2C221E) : const Color(0xFF63564F),
                              letterSpacing: 0.1,
                              height: 1.0,
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
