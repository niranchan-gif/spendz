import 'package:flutter/material.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';
import '../../screens/profile/profile_screen.dart';

/// Compact Spendz brand header with a visible, page-specific title.
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
    final dark = SpendzColors.isDark(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpendzSpacing.xs,
        vertical: SpendzSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: SpendzColors.tangerine,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withAlpha(190)),
              boxShadow: [
                BoxShadow(
                  color: SpendzColors.tangerineDeep.withAlpha(dark ? 55 : 32),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.white.withAlpha(dark ? 18 : 210),
                  blurRadius: 2,
                  offset: const Offset(-1, -1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Image.asset(
                  'assets/icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.savings_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.55,
                color: SpendzColors.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _HeaderAction(
            icon: Icons.notifications_none_rounded,
            label: 'Notifications',
            onTap: onNotificationsTap,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onProfileTap ?? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SpendzColors.clayYellow,
                border: Border.all(color: Colors.white.withAlpha(220)),
                boxShadow: [
                  BoxShadow(
                    color: SpendzColors.sunshineDeep.withAlpha(28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 19,
                color: SpendzColors.inkSlate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _HeaderAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SpendzColors.surface(context),
              border: Border.all(color: SpendzColors.border(context)),
              boxShadow: SpendzColors.clayDropShadow(
                context,
                blur: 10,
                offset: const Offset(0, 3),
              ),
            ),
            child: Icon(
              icon,
              size: 19,
              color: SpendzColors.textSecondary(context),
            ),
          ),
        ),
      ),
    );
  }
}
