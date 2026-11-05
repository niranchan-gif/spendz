import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';
import '../../app/theme/spendz_typography.dart';
import '../../database/database_helper.dart';
import '../../presentation/widgets/spendz_section_header.dart';
import '../../presentation/widgets/spendz_surface.dart';
import '../../presentation/widgets/spendz_top_bar.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../categories/categories_screen.dart';

/// Spendz 2.0 Profile, Preferences, and Security Screen.
/// Clean editorial interface for appearance, biometrics, sync, and storage.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpendzColors.background(context),
      body: SafeArea(
        bottom: false,
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: SpendzSpacing.lg,
                vertical: SpendzSpacing.sm,
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                const SpendzTopBar(title: 'Profile'),
                const SizedBox(height: SpendzSpacing.sm),

                // 1. Profile Hero Banner
                _buildProfileHero(context),
                const SizedBox(height: SpendzSpacing.xl),

                // 2. Data & Categories Section
                _buildPreferencesSection(context),
              const SizedBox(height: SpendzSpacing.xl),

              // 5. Danger Zone / Data Management
              _buildDangerZone(context),
              const SizedBox(height: SpendzSpacing.xl),

              // 6. Security Footer
              _buildFooter(context),
              const SizedBox(height: SpendzSpacing.hero),
            ],
          );
        },
      ),
    ),
  );
}

  Widget _buildProfileHero(BuildContext context) {
    final accent = SpendzColors.primaryAccent(context);

    return SpendzSurface(
      isElevated: true,
      padding: const EdgeInsets.all(SpendzSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SpendzColors.forestGreen,
            ),
            child: const Center(
              child: Text(
                'S',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: SpendzSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spendz 2.0',
                  style: SpendzTypography.headingSmall(context),
                ),
                const SizedBox(height: 2),
                Text(
                  'Encrypted Finance & Digital Wallet',
                  style: SpendzTypography.caption(context),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(25),
                    borderRadius: BorderRadius.circular(SpendzSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 10, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        'AES-256-GCM Active',
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SpendzSectionHeader(title: 'Preferences & Sync'),
        const SizedBox(height: SpendzSpacing.xs),
        SpendzSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: SpendzColors.olive.withAlpha(20),
                    borderRadius: BorderRadius.circular(SpendzSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.category_outlined,
                    size: 18,
                    color: SpendzColors.olive,
                  ),
                ),
                title: Text(
                  'Manage Categories',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SpendzColors.textPrimary(context),
                  ),
                ),
                subtitle: Text(
                  'Customize income and expense tags',
                  style: SpendzTypography.caption(context),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                  );
                },
              ),
              Divider(height: 1, color: SpendzColors.border(context)),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: SpendzColors.info.withAlpha(20),
                    borderRadius: BorderRadius.circular(SpendzSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    size: 18,
                    color: SpendzColors.info,
                  ),
                ),
                title: Text(
                  'HDFC Gmail Sync',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SpendzColors.textPrimary(context),
                  ),
                ),
                subtitle: Text(
                  'Operational • Auto-detects debit & credit alerts',
                  style: SpendzTypography.caption(context),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: SpendzColors.income.withAlpha(25),
                    borderRadius: BorderRadius.circular(
                      SpendzSpacing.radiusFull,
                    ),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: SpendzColors.income,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pushNamed(context, '/import-review');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SpendzSectionHeader(title: 'Data Management'),
        const SizedBox(height: SpendzSpacing.xs),
        SpendzSurface(
          padding: EdgeInsets.zero,
          borderColor: SpendzColors.expense.withAlpha(60),
          child: ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: SpendzColors.expense.withAlpha(20),
                borderRadius: BorderRadius.circular(SpendzSpacing.radiusSm),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: SpendzColors.expense,
              ),
            ),
            title: const Text(
              'Clear All Local Data',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: SpendzColors.expense,
              ),
            ),
            subtitle: Text(
              'Wipes stored transactions and resets preferences',
              style: SpendzTypography.caption(context),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: SpendzColors.surface(context),
                  title: const Text('Clear All Local Data?'),
                  content: const Text(
                    'This will erase all recorded transactions and reset preferences. This action cannot be reversed.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(color: SpendzColors.expense),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                await DatabaseHelper.instance.clearAllTransactions();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  context.read<TransactionProvider>().loadTransactions();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All local transactions cleared.'),
                    ),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 13,
                  color: SpendzColors.primaryAccent(context),
                ),
                const SizedBox(width: 5),
                Text(
                  'Spendz 2.0 • Hardware Keystore & AES-256-GCM',
                  style: SpendzTypography.caption(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Private • Offline-First • Zero Cloud Telemetry',
            style: TextStyle(
              fontSize: 10,
              color: SpendzColors.textSecondary(context).withAlpha(140),
            ),
          ),
        ],
      ),
    );
  }
}
