import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/theme_provider.dart';
import '../../database/database_helper.dart';
import '../categories/categories_screen.dart';
import '../wallet/wallet_security_settings_screen.dart';
import '../../widgets/design_system/reusable_card.dart';
import '../../widgets/design_system/section_header.dart';
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
    setState(() {
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      _inactivityTimeout = prefs.getString('inactivity_timeout') ?? '5 minutes';
    });
  }

  Future<void> _updateBiometric(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', val);
    setState(() {
      _biometricEnabled = val;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            val
                ? 'Biometric authentication enabled for document decryption.'
                : 'Biometric authentication disabled.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _updateAppLock(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_lock_enabled', val);
    setState(() {
      _appLockEnabled = val;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            val ? 'App lock on launch enabled.' : 'App lock disabled.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: Consumer3<TransactionProvider, WalletProvider, ThemeProvider>(
        builder: (context, txProvider, walletProvider, themeProvider, child) {
          final txCount = txProvider.transactions.length;
          final cardCount = walletProvider.cards.length;
          final docCount = walletProvider.documents.length;
          final passCount = walletProvider.passes.length;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            physics: const BouncingScrollPhysics(),
            children: [
              // User Profile Banner Card
              ReusableCard(
                padding: const EdgeInsets.all(AppSpacing.card),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, color: AppColors.primary, size: 30),
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
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Local Encrypted Finance & Digital Wallet',
                            style: AppTextStyles.caption.copyWith(color: textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              'SQLite v4 • Hardware Keystore Active',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Theme Mode Selector Card
              SectionHeader(title: 'Appearance'),
              const SizedBox(height: AppSpacing.xs),
              ReusableCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.palette_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Theme Mode',
                          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_rounded),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_rounded),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_rounded),
                        ),
                      ],
                      selected: {themeProvider.themeMode},
                      style: ButtonStyle(
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                        ),
                      ),
                      onSelectionChanged: (Set<ThemeMode> newMode) {
                        themeProvider.setThemeMode(newMode.first);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Security & Biometrics
              SectionHeader(title: 'Security & Biometrics'),
              const SizedBox(height: AppSpacing.xs),
              ReusableCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
                      title: Text(
                        'Vault Security & Hardware Keystore',
                        style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'AES-256-GCM status, hardware keys, and auto-lock',
                        style: AppTextStyles.caption.copyWith(color: textSecondary),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletSecuritySettingsScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 56, color: AppColors.getBorder(context)),
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                      title: Text(
                        'Biometric Authentication',
                        style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Require fingerprint/face to decrypt vault and reveal card numbers',
                        style: AppTextStyles.caption.copyWith(color: textSecondary),
                      ),
                      value: _biometricEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: _updateBiometric,
                    ),
                    Divider(height: 1, indent: 56, color: AppColors.getBorder(context)),
                    SwitchListTile(
                      secondary: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                      title: Text(
                        'App Lock on Startup',
                        style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Prompt passcode/biometrics when opening Spendz',
                        style: AppTextStyles.caption.copyWith(color: textSecondary),
                      ),
                      value: _appLockEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: _updateAppLock,
                    ),
                    Divider(height: 1, indent: 56, color: AppColors.getBorder(context)),
                    ListTile(
                      leading: const Icon(Icons.timer_outlined, color: AppColors.primary),
                      title: Text(
                        'Inactivity Timeout',
                        style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _inactivityTimeout,
                        style: AppTextStyles.caption.copyWith(color: textSecondary),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => SimpleDialog(
                            title: const Text('Select Inactivity Timeout'),
                            children: ['Immediate', '1 minute', '5 minutes', '15 minutes'].map((t) {
                              return SimpleDialogOption(
                                child: Text(t),
                                onPressed: () async {
                                  final navigator = Navigator.of(ctx);
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('inactivity_timeout', t);
                                  if (!mounted) return;
                                  setState(() => _inactivityTimeout = t);
                                  navigator.pop();
                                },
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Storage Information Grid
              SectionHeader(title: 'Storage & Health'),
              const SizedBox(height: AppSpacing.xs),
              ReusableCard(
                padding: const EdgeInsets.all(AppSpacing.card),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCol(context, 'Transactions', txCount.toString(), Icons.receipt_long_rounded),
                        _buildStatCol(context, 'Cards', cardCount.toString(), Icons.credit_card_rounded),
                        _buildStatCol(context, 'Documents', docCount.toString(), Icons.shield_rounded),
                        _buildStatCol(context, 'Passes', passCount.toString(), Icons.qr_code_2_rounded),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Divider(height: 1, color: AppColors.getBorder(context)),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.storage_rounded, size: 16, color: textSecondary),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Database: spendwise.db (v4) • Local & Private Encrypted',
                            style: AppTextStyles.caption.copyWith(color: textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Application Preferences
              SectionHeader(title: 'Application Preferences'),
              const SizedBox(height: AppSpacing.xs),
              ReusableCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.category_outlined, color: AppColors.primary),
                      title: Text(
                        'Manage Categories',
                        style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Customize income and expense classification tags',
                        style: AppTextStyles.caption.copyWith(color: textSecondary),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CategoriesScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 56, color: AppColors.getBorder(context)),
                    ListTile(
                      leading: const Icon(Icons.mail_outline_rounded, color: AppColors.primary),
                      title: Text(
                        'HDFC Gmail Sync Settings',
                        style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Automated parser for HDFC debit and credit transaction emails',
                        style: AppTextStyles.caption.copyWith(color: textSecondary),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('HDFC Gmail sync is operational.')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Danger Zone
              SectionHeader(title: 'Data Management'),
              const SizedBox(height: AppSpacing.xs),
              ReusableCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  title: Text(
                    'Clear All Local Data',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  subtitle: Text(
                    'Wipes stored transactions and resets app preferences',
                    style: AppTextStyles.caption.copyWith(color: textSecondary),
                  ),
                  onTap: () async {
                    final txProvider = context.read<TransactionProvider>();
                    final messenger = ScaffoldMessenger.of(context);

                    final confirm = await CustomDialog.showConfirmation(
                      context: context,
                      title: 'Clear All Local Data?',
                      message: 'This will delete all transactions and reset preferences. This action cannot be undone.',
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
                          const SnackBar(content: Text('All local data cleared successfully.')),
                        );
                      }
                    }
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Text(
                  'Spendz 2.0 • Fintech & Digital Wallet\nHardware Keystore & AES-256-GCM Vault',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: textSecondary.withAlpha(120)),
                ),
              ),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCol(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs + 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.getTextSecondary(context)),
        ),
      ],
    );
  }
}
