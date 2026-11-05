import 'package:flutter/material.dart';
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
    final isDark = SpendzColors.isDark(context);
    final quietShadow = [
      BoxShadow(
        color: Colors.black.withAlpha(isDark ? 32 : 10),
        blurRadius: 10,
        offset: const Offset(0, 3),
        spreadRadius: -3,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpendzSpacing.sm,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: SpendzColors.surfaceElevated(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: quietShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/icon.png',
                        width: 23,
                        height: 23,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.savings_outlined,
                          color: SpendzColors.primaryAccent(context),
                          size: 21,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SPENDZ',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: SpendzColors.textPrimary(context),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onNotificationsTap ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'All notifications are up to date',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor:
                                SpendzColors.surfaceContainerHigh(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SpendzColors.surfaceElevated(context),
                      boxShadow: quietShadow,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 19,
                      color: SpendzColors.textSecondary(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onProfileTap ??
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SpendzColors.surfaceElevated(context),
                    boxShadow: quietShadow,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 19,
                    color: SpendzColors.primaryAccent(context),
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
