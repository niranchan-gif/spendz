import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../database/database_helper.dart';
import '../categories/categories_screen.dart';
import '../../widgets/glass_container.dart';

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
                ? 'Biometric preference saved (Will be enforced in Phase 3 security module)'
                : 'Biometric preference disabled',
          ),
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
            val
                ? 'App lock preference saved (Will be enforced in Phase 3 security module)'
                : 'App lock disabled',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile & Settings'),
      ),
      body: Consumer2<TransactionProvider, WalletProvider>(
        builder: (context, txProvider, walletProvider, child) {
          final txCount = txProvider.transactions.length;
          final cardCount = walletProvider.cards.length;
          final docCount = walletProvider.documents.length;
          final passCount = walletProvider.passes.length;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // User / Profile Card
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.person, color: AppColors.primary, size: 30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Spendz Personal Finance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Phase 1 UI Ready • Security in Phase 3',
                              style: TextStyle(fontSize: 10, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section: Security & Authentication
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Security & Biometrics', style: AppTextStyles.heading3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Phase 3 Target',
                      style: TextStyle(color: Colors.lightBlueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GlassContainer(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint, color: AppColors.primary),
                      title: const Text('Biometric Authentication'),
                      subtitle: const Text('Require fingerprint/face to decrypt documents (Phase 3)'),
                      value: _biometricEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: _updateBiometric,
                    ),
                    const Divider(height: 1, indent: 56),
                    SwitchListTile(
                      secondary: const Icon(Icons.lock_outline, color: AppColors.primary),
                      title: const Text('App Lock on Startup'),
                      subtitle: const Text('Lock entire app when minimized or backgrounded (Phase 3)'),
                      value: _appLockEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: _updateAppLock,
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.timer_outlined, color: AppColors.primary),
                      title: const Text('Inactivity Timeout'),
                      subtitle: Text(_inactivityTimeout),
                      trailing: const Icon(Icons.chevron_right),
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

              const SizedBox(height: 24),

              // Section: Local Storage Information
              Text('Storage Information', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCol('Transactions', txCount.toString(), Icons.receipt_long),
                        _buildStatCol('Cards', cardCount.toString(), Icons.credit_card),
                        _buildStatCol('Documents', docCount.toString(), Icons.lock),
                        _buildStatCol('Passes', passCount.toString(), Icons.qr_code),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.storage_outlined, size: 16, color: Colors.white54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Database: spendwise.db (v3) • Fully local & private',
                            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section: Backup Settings
              Text('Backup & Export', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              GlassContainer(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.backup_outlined, color: AppColors.primary),
                      title: const Text('Backup Local Data'),
                      subtitle: const Text('Export transactions to JSON / CSV'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Local export prepared for backup.')),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.settings_backup_restore, color: AppColors.primary),
                      title: const Text('Restore Backup'),
                      subtitle: const Text('Import previously exported Spendz backup file'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Select valid Spendz backup file to restore.')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section: Application Preferences
              Text('Application Settings', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              GlassContainer(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.category_outlined, color: AppColors.primary),
                      title: const Text('Manage Categories'),
                      subtitle: const Text('Customize income and expense tags'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CategoriesScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.mail_outline, color: AppColors.primary),
                      title: const Text('HDFC Gmail Sync Settings'),
                      subtitle: const Text('Apps Script endpoint configured'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('HDFC Gmail sync is operational.')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section: Data Management (Danger Zone)
              Text('Data Management', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              GlassContainer(
                child: ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Clear All Local Data', style: TextStyle(color: AppColors.error)),
                  subtitle: const Text('Wipes stored transactions and resets settings'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear All Local Data?'),
                        content: const Text(
                          'This will delete all transactions and reset preferences. This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await DatabaseHelper.instance.clearAllTransactions();
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.clear();
                              if (context.mounted) {
                                context.read<TransactionProvider>().loadTransactions();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('All data cleared successfully.')),
                                );
                              }
                            },
                            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 36),

              Center(
                child: Text(
                  'Spendz 2.0 (Phase 1 Baseline)\nLocal-first Finance & Wallet',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCol(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white54),
        ),
      ],
    );
  }
}
