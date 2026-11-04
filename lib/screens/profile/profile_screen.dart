import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/theme_provider.dart';
import '../../database/database_helper.dart';
import '../categories/categories_screen.dart';
import '../wallet/wallet_security_settings_screen.dart';
import '../../widgets/glass/glass.dart';
import '../../widgets/design_system/custom_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _biometricEnabled = false;
  bool _appLockEnabled = false;
  String _inactivityTimeout = '5 minutes';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      _inactivityTimeout = prefs.getString('inactivity_timeout') ?? '5 minutes';
    });
  }

  Future<void> _updateBiometric(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', val);
    if (!mounted) return;
    setState(() {
      _biometricEnabled = val;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          val
              ? 'Biometric authentication enabled for document decryption.'
              : 'Biometric authentication disabled.',
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _updateAppLock(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_lock_enabled', val);
    if (!mounted) return;
    setState(() {
      _appLockEnabled = val;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          val ? 'App lock on launch enabled.' : 'App lock disabled.',
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emerald = AppColors.getEmeraldAccent(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                120,
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                // Minimal Editorial Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preferences',
                            style: AppTextStyles.caption.copyWith(
                              color: emerald,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Profile & Settings',
                            style: AppTextStyles.headingMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      GlassIconButton(
                        icon: Icons.shield_outlined,
                        tooltip: 'Security Settings',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const WalletSecuritySettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Glass Hero Profile Banner
                GlassPanel(
                  padding: const EdgeInsets.all(AppSpacing.card),
                  glowColor: AppColors.primary,
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primary, emerald],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(
                                isDark ? 80 : 50,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Spendz 2.0',
                              style: AppTextStyles.headingSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Encrypted Finance & Digital Wallet',
                              style: AppTextStyles.caption.copyWith(
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: emerald.withAlpha(isDark ? 30 : 25),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xs,
                                ),
                                border: Border.all(
                                  color: emerald.withAlpha(70),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    size: 10,
                                    color: emerald,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Hardware Keystore & AES-256 Active',
                                    style: AppTextStyles.caption.copyWith(
                                      color: emerald,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 9.5,
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
                ),

                const SizedBox(height: AppSpacing.xl),

                // Appearance & Theme Section
                GlassSection(
                  title: 'Appearance',
                  subtitle: 'Select interface appearance and palette',
                  padding: EdgeInsets.zero,
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              color: emerald,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Theme Mode',
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            _buildThemeOption(
                              context: context,
                              mode: ThemeMode.system,
                              label: 'System',
                              icon: Icons.brightness_auto_rounded,
                              currentMode: themeProvider.themeMode,
                              onSelect: () =>
                                  themeProvider.setThemeMode(ThemeMode.system),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _buildThemeOption(
                              context: context,
                              mode: ThemeMode.light,
                              label: 'Light',
                              icon: Icons.light_mode_rounded,
                              currentMode: themeProvider.themeMode,
                              onSelect: () =>
                                  themeProvider.setThemeMode(ThemeMode.light),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _buildThemeOption(
                              context: context,
                              mode: ThemeMode.dark,
                              label: 'Dark',
                              icon: Icons.dark_mode_rounded,
                              currentMode: themeProvider.themeMode,
                              onSelect: () =>
                                  themeProvider.setThemeMode(ThemeMode.dark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Security & Biometrics Section
                GlassSection(
                  title: 'Security & Keystore',
                  subtitle: 'Biometric authorization and local encryption keys',
                  padding: EdgeInsets.zero,
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 2,
                          ),
                          leading: _buildIconBox(
                            context,
                            Icons.shield_outlined,
                          ),
                          title: Text(
                            'Vault Security & Hardware Keystore',
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'AES-256-GCM status, hardware keys, and auto-lock',
                            style: AppTextStyles.caption.copyWith(
                              color: textSecondary,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: textSecondary,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const WalletSecuritySettingsScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(
                          height: 1,
                          indent: 56,
                          color: AppColors.getGlassBorder(context),
                        ),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 2,
                          ),
                          secondary: _buildIconBox(
                            context,
                            Icons.fingerprint_rounded,
                          ),
                          title: Text(
                            'Biometric Authentication',
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Fingerprint / Face ID to reveal sensitive numbers and decrypt cards',
                            style: AppTextStyles.caption.copyWith(
                              color: textSecondary,
                            ),
                          ),
                          value: _biometricEnabled,
                          activeThumbColor: emerald,
                          onChanged: _updateBiometric,
                        ),
                        Divider(
                          height: 1,
                          indent: 56,
                          color: AppColors.getGlassBorder(context),
                        ),
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 2,
                          ),
                          secondary: _buildIconBox(
                            context,
                            Icons.lock_outline_rounded,
                          ),
                          title: Text(
                            'App Lock on Startup',
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Prompt passcode/biometrics when opening Spendz',
                            style: AppTextStyles.caption.copyWith(
                              color: textSecondary,
                            ),
                          ),
                          value: _appLockEnabled,
                          activeThumbColor: emerald,
                          onChanged: _updateAppLock,
                        ),
                        Divider(
                          height: 1,
                          indent: 56,
                          color: AppColors.getGlassBorder(context),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 2,
                          ),
                          leading: _buildIconBox(context, Icons.timer_outlined),
                          title: Text(
                            'Inactivity Timeout',
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            _inactivityTimeout,
                            style: AppTextStyles.caption.copyWith(
                              color: emerald,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: textSecondary,
                          ),
                          onTap: () => _showInactivityDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Application Preferences Section
                GlassSection(
                  title: 'Preferences & Sync',
                  subtitle: 'Categories and automatic parsing settings',
                  padding: EdgeInsets.zero,
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 2,
                          ),
                          leading: _buildIconBox(
                            context,
                            Icons.category_outlined,
                          ),
                          title: Text(
                            'Manage Categories',
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Customize income and expense classification tags',
                            style: AppTextStyles.caption.copyWith(
                              color: textSecondary,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: textSecondary,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategoriesScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(
                          height: 1,
                          indent: 56,
                          color: AppColors.getGlassBorder(context),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 2,
                          ),
                          leading: _buildIconBox(
                            context,
                            Icons.mail_outline_rounded,
                          ),
                          title: Text(
                            'HDFC Gmail Sync Settings',
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Automated parser for HDFC debit and credit transaction emails',
                            style: AppTextStyles.caption.copyWith(
                              color: textSecondary,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: textSecondary,
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'HDFC Gmail sync is operational.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Danger Zone Section
                GlassSection(
                  title: 'Data Management',
                  subtitle: 'Reset storage or purge local cache',
                  padding: EdgeInsets.zero,
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    border: Border.all(color: AppColors.error.withAlpha(60)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(AppSpacing.xs + 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(25),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Clear All Local Data',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      subtitle: Text(
                        'Wipes stored transactions and resets app preferences',
                        style: AppTextStyles.caption.copyWith(
                          color: textSecondary,
                        ),
                      ),
                      onTap: () async {
                        final txProvider = context.read<TransactionProvider>();
                        final messenger = ScaffoldMessenger.of(context);

                        final confirm = await CustomDialog.showConfirmation(
                          context: context,
                          title: 'Clear All Local Data?',
                          message:
                              'This will delete all transactions and reset preferences. This action cannot be undone.',
                          confirmLabel: 'Clear All',
                          isDestructive: true,
                          icon: Icons.warning_amber_rounded,
                        );

                        if (confirm == true && mounted) {
                          await DatabaseHelper.instance.clearAllTransactions();
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          if (mounted) {
                            txProvider.loadTransactions();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'All local data cleared successfully.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Editorial Brand & Security Badge
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getGlassBackground(context),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: AppColors.getGlassBorder(context),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 14,
                              color: emerald,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Spendz 2.0 • Hardware Keystore & AES-256-GCM',
                              style: AppTextStyles.caption.copyWith(
                                color: textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Private • Offline-First • Zero Cloud Telemetry',
                        style: AppTextStyles.caption.copyWith(
                          color: textSecondary.withAlpha(120),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeMode mode,
    required String label,
    required IconData icon,
    required ThemeMode currentMode,
    required VoidCallback onSelect,
  }) {
    final isSelected = currentMode == mode;
    final emerald = AppColors.getEmeraldAccent(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? emerald.withAlpha(35)
                      : AppColors.primary.withAlpha(20))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? emerald : AppColors.getGlassBorder(context),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? emerald : textSecondary),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? textPrimary : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox(BuildContext context, IconData icon) {
    final emerald = AppColors.getEmeraldAccent(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: emerald.withAlpha(isDark ? 30 : 22),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: emerald, size: 20),
    );
  }

  void _showInactivityDialog(BuildContext context) {
    GlassDialog.show(
      context: context,
      title: 'Inactivity Timeout',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: ['Immediate', '1 minute', '5 minutes', '15 minutes'].map((t) {
          final isSelected = _inactivityTimeout == t;
          return ListTile(
            title: Text(
              t,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.getEmeraldAccent(context) : null,
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_rounded,
                    color: AppColors.getEmeraldAccent(context),
                  )
                : null,
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('inactivity_timeout', t);
              if (!mounted) return;
              setState(() => _inactivityTimeout = t);
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
