import 'package:flutter/material.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';

/// Funky Claymorphism Global Top Header Bar for Spendz 2.0.
/// Renders the [ SPENDZ ] orange pill, OVERVIEW/Screen Title,
/// white circular notification bell, and yellow/brown avatar ring.
class SpendzTopBar extends StatelessWidget {
  final String title;
  final String category;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  const SpendzTopBar({
    super.key,
    required this.title,
    this.category = 'OVERVIEW',
    this.onNotificationsTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = SpendzColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpendzSpacing.sm,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: SPENDZ Pill + Screen Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: SpendzColors.tangerine,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: SpendzColors.tangerine.withAlpha(isDark ? 80 : 100),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.white.withAlpha(160),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        'assets/icon.png',
                        width: 16,
                        height: 16,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.savings_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'SPENDZ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: SpendzColors.textSecondary(context),
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: SpendzColors.textPrimary(context),
                      letterSpacing: -0.4,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: Notifications Button + Avatar
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
                            content: const Text('All notifications are up to date! ✨'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: SpendzColors.surfaceContainerHigh(context),
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
                      color: SpendzColors.surface(context),
                      border: Border.all(
                        color: SpendzColors.border(context),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 40 : 10),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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

              // Brown/Yellow Circular Avatar
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SpendzColors.sunshineYellow,
                    boxShadow: [
                      BoxShadow(
                        color: SpendzColors.sunshineYellow.withAlpha(80),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF735500),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
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

