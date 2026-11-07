import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';
import '../../screens/profile/profile_screen.dart';

/// Minimal Spendz header with a matte brand surface and quiet controls.
class SpendzTopBar extends StatelessWidget {
  final String title;
  final String category;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  const SpendzTopBar({
    super.key,
    required this.title,
    this.category = '',
    this.onNotificationsTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    const quietShadow = [
      BoxShadow(
        color: Color(0x1F2C221E),
        blurRadius: 4,
        offset: Offset(1.5, 2.5),
      ),
      BoxShadow(color: Colors.white, blurRadius: 1.5, offset: Offset(-1, -1)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpendzSpacing.sm,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/launcher/spendz_banner.png',
              height: 38,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/banner.png',
                height: 38,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF19C79),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'SPENDZ',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: Color(0xFF2C221E),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap:
                      onNotificationsTap ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'All notifications are up to date',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: SpendzColors.surfaceContainerHigh(
                              context,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFCBDFBD), // Pistachio
                      boxShadow: quietShadow,
                    ),
                    child: const Icon(
                      LucideIcons.bell,
                      size: 18,
                      color: Color(0xFF2C221E),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap:
                    onProfileTap ??
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFD4E09B), // Chartreuse
                    boxShadow: quietShadow,
                  ),
                  child: const Icon(
                    LucideIcons.user,
                    size: 18,
                    color: Color(0xFF2C221E),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
