import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/wallet/security/wallet_auth_service.dart';
import '../../features/wallet/security/wallet_key_service.dart';
import '../../features/wallet/services/document_vault_service.dart';
import '../../widgets/glass_container.dart';

class WalletSecuritySettingsScreen extends StatefulWidget {
  const WalletSecuritySettingsScreen({super.key});

  @override
  State<WalletSecuritySettingsScreen> createState() => _WalletSecuritySettingsScreenState();
}

class _WalletSecuritySettingsScreenState extends State<WalletSecuritySettingsScreen> {
  final WalletKeyService _keyService = WalletKeyService();
  final DocumentVaultService _vaultService = DocumentVaultService();

  bool _hasHardwareKey = false;
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSecurityStatus();
  }

  Future<void> _loadSecurityStatus() async {
    setState(() => _isLoading = true);
    final authService = context.read<WalletAuthService>();

    final hasKey = await _keyService.hasMasterKey();
    final canBio = await authService.canCheckBiometrics();
    final bios = await authService.getAvailableBiometrics();

    if (mounted) {
      setState(() {
        _hasHardwareKey = hasKey;
        _canCheckBiometrics = canBio;
        _availableBiometrics = bios;
        _isLoading = false;
      });
    }
  }

  String _formatBiometricList() {
    if (_availableBiometrics.isEmpty) {
      return _canCheckBiometrics ? 'Device Screen Lock (PIN/Passcode)' : 'Not enrolled or unavailable';
    }
    return _availableBiometrics.map((b) {
      switch (b) {
        case BiometricType.fingerprint:
          return 'Fingerprint';
        case BiometricType.face:
          return 'Face ID / Facial Recognition';
        case BiometricType.iris:
          return 'Iris Scanner';
        case BiometricType.strong:
          return 'Strong Biometric';
        case BiometricType.weak:
          return 'Weak Biometric';
      }
    }).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<WalletAuthService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Vault & Security Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Cryptographic Engine Card
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock_outline, color: AppColors.primary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AES-256-GCM Cryptographic Vault', style: AppTextStyles.labelLarge),
                                const SizedBox(height: 2),
                                Text(
                                  'Authenticated encryption with 96-bit nonces',
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Colors.white12),
                      _buildInfoRow('Cipher', 'AES-256 in Galois/Counter Mode (GCM)'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Key Length', '256 bits (32 bytes)'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Authentication Tag', '128 bits with AAD verification'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Hardware Key Protection Card
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.memory, color: AppColors.primary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hardware Security Module', style: AppTextStyles.labelLarge),
                                const SizedBox(height: 2),
                                Text(
                                  'Android Keystore / iOS Keychain',
                                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _hasHardwareKey ? Icons.check_circle : Icons.shield_outlined,
                            color: _hasHardwareKey ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _hasHardwareKey
                            ? 'Master vault key is protected by platform hardware-backed secure storage and never exposed in logs or plaintext.'
                            : 'Master key will be generated securely inside Keystore/Keychain upon importing your first document.',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Biometrics & App Lock Section
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Biometric & Access Controls', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.fingerprint, color: AppColors.primary),
                        title: const Text('Available Biometrics'),
                        subtitle: Text(
                          _formatBiometricList(),
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ),
                      const Divider(height: 16, color: Colors.white12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Lock Vault on App Background'),
                        subtitle: const Text(
                          'Requires authentication immediately when returning to the app',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        value: authService.lockOnBackground,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          authService.lockOnBackground = val;
                        },
                      ),
                      const Divider(height: 16, color: Colors.white12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Inactivity Timeout'),
                        subtitle: Text(
                          _getTimeoutLabel(authService.inactivityTimeoutSeconds),
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showTimeoutPicker(context, authService),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sandbox Sanitization Card
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sandbox & Cache Maintenance', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Spendz clears temporary decrypted previews automatically. You can also manually wipe the preview cache at any time.',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                        ),
                        icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                        label: const Text('Wipe Temporary Preview Cache'),
                        onPressed: () async {
                          await _vaultService.cleanupAllTemporaryFiles();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Temporary preview cache wiped clean.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _getTimeoutLabel(int seconds) {
    if (seconds <= 0) return 'Immediate (Always lock)';
    if (seconds < 60) return '$seconds seconds';
    final minutes = seconds ~/ 60;
    return '$minutes minute${minutes > 1 ? 's' : ''}';
  }

  void _showTimeoutPicker(BuildContext context, WalletAuthService authService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Select Auto-Lock Timeout', style: AppTextStyles.heading3),
              ),
              _buildTimeoutTile(ctx, authService, 0, 'Immediate'),
              _buildTimeoutTile(ctx, authService, 30, '30 seconds'),
              _buildTimeoutTile(ctx, authService, 60, '1 minute'),
              _buildTimeoutTile(ctx, authService, 300, '5 minutes'),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeoutTile(BuildContext ctx, WalletAuthService authService, int seconds, String label) {
    final isSelected = authService.inactivityTimeoutSeconds == seconds;
    return ListTile(
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        authService.inactivityTimeoutSeconds = seconds;
        Navigator.pop(ctx);
      },
    );
  }
}
