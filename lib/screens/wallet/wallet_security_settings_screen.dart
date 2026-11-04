import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/wallet/security/wallet_auth_service.dart';
import '../../features/wallet/security/wallet_key_service.dart';
import '../../features/wallet/services/document_vault_service.dart';
import '../../widgets/design_system/reusable_card.dart';
import '../../widgets/design_system/app_bottom_sheet.dart';

class WalletSecuritySettingsScreen extends StatefulWidget {
  const WalletSecuritySettingsScreen({super.key});

  @override
  State<WalletSecuritySettingsScreen> createState() =>
      _WalletSecuritySettingsScreenState();
}

class _WalletSecuritySettingsScreenState
    extends State<WalletSecuritySettingsScreen> {
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
      return _canCheckBiometrics
          ? 'Device Screen Lock (PIN/Passcode)'
          : 'Not enrolled or unavailable';
    }
    return _availableBiometrics
        .map((b) {
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
        })
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<WalletAuthService>();
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Vault & Security Settings')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              physics: const BouncingScrollPhysics(),
              children: [
                // Cryptographic Engine Card
                ReusableCard(
                  padding: const EdgeInsets.all(AppSpacing.card),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xs + 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AES-256-GCM Cryptographic Vault',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Authenticated encryption with 96-bit nonces',
                                  style: AppTextStyles.caption.copyWith(
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Divider(height: 1, color: AppColors.getBorder(context)),
                      const SizedBox(height: AppSpacing.md),
                      _buildInfoRow(
                        context,
                        'Cipher',
                        'AES-256 in Galois/Counter Mode (GCM)',
                      ),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        context,
                        'Key Length',
                        '256 bits (32 bytes)',
                      ),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        context,
                        'Authentication Tag',
                        '128 bits with AAD verification',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Hardware Key Protection Card
                ReusableCard(
                  padding: const EdgeInsets.all(AppSpacing.card),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xs + 2),
                            decoration: BoxDecoration(
                              color:
                                  (_hasHardwareKey
                                          ? AppColors.success
                                          : AppColors.warning)
                                      .withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.memory_rounded,
                              color: _hasHardwareKey
                                  ? AppColors.success
                                  : AppColors.warning,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hardware Security Module',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Android Keystore / iOS Keychain',
                                  style: AppTextStyles.caption.copyWith(
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _hasHardwareKey
                                ? Icons.check_circle_rounded
                                : Icons.shield_outlined,
                            color: _hasHardwareKey
                                ? AppColors.success
                                : AppColors.warning,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _hasHardwareKey
                            ? 'Master vault key is protected by platform hardware-backed secure storage and never exposed in logs or plaintext.'
                            : 'Master key will be generated securely inside Keystore/Keychain upon importing your first document.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (!_hasHardwareKey)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.key_rounded, size: 18),
                          label: const Text('Initialize Encryption Key Now'),
                          onPressed: () async {
                            try {
                              await _keyService.getOrCreateMasterKey(
                                hasExistingVaultDocuments: () => false,
                              );
                              await _loadSecurityStatus();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Master encryption key generated and verified!',
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Initialization error: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                        )
                      else
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Reset Vault Security Keys'),
                          onPressed: _showResetVaultDialog,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Biometrics & App Lock Section
                ReusableCard(
                  padding: const EdgeInsets.all(AppSpacing.card),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biometric & Access Controls',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.fingerprint_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          'Available Biometrics',
                          style: AppTextStyles.labelLarge,
                        ),
                        subtitle: Text(
                          _formatBiometricList(),
                          style: AppTextStyles.caption.copyWith(
                            color: textSecondary,
                          ),
                        ),
                      ),
                      Divider(height: 1, color: AppColors.getBorder(context)),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Lock Vault on App Background',
                          style: AppTextStyles.labelLarge,
                        ),
                        subtitle: Text(
                          'Requires authentication immediately when returning to the app',
                          style: AppTextStyles.caption.copyWith(
                            color: textSecondary,
                          ),
                        ),
                        value: authService.lockOnBackground,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          authService.lockOnBackground = val;
                        },
                      ),
                      Divider(height: 1, color: AppColors.getBorder(context)),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Inactivity Timeout',
                          style: AppTextStyles.labelLarge,
                        ),
                        subtitle: Text(
                          _getTimeoutLabel(
                            authService.inactivityTimeoutSeconds,
                          ),
                          style: AppTextStyles.caption.copyWith(
                            color: textSecondary,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: textSecondary,
                        ),
                        onTap: () => _showTimeoutPicker(context, authService),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Sandbox Sanitization Card
                ReusableCard(
                  padding: const EdgeInsets.all(AppSpacing.card),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sandbox & Cache Maintenance',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Spendz clears temporary decrypted previews automatically. You can also manually wipe the preview cache at any time.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        icon: const Icon(
                          Icons.cleaning_services_outlined,
                          size: 18,
                        ),
                        label: const Text('Wipe Temporary Preview Cache'),
                        onPressed: () async {
                          await _vaultService.cleanupAllTemporaryFiles();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Temporary preview cache wiped clean.',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.getTextSecondary(context),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(context),
          ),
        ),
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
    AppBottomSheet.show(
      context: context,
      title: 'Select Auto-Lock Timeout',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeoutTile(context, authService, 0, 'Immediate (Always lock)'),
          _buildTimeoutTile(context, authService, 30, '30 seconds'),
          _buildTimeoutTile(context, authService, 60, '1 minute'),
          _buildTimeoutTile(context, authService, 300, '5 minutes'),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildTimeoutTile(
    BuildContext ctx,
    WalletAuthService authService,
    int seconds,
    String label,
  ) {
    final isSelected = authService.inactivityTimeoutSeconds == seconds;
    return ListTile(
      title: Text(label, style: AppTextStyles.labelMedium),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        authService.inactivityTimeoutSeconds = seconds;
        Navigator.pop(ctx);
      },
    );
  }

  Future<void> _showResetVaultDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Vault Security Keys?'),
        content: const Text(
          'This will purge unrecoverable encrypted documents and generate a fresh hardware-backed 256-bit encryption key in secure storage.\n\n'
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Reset Vault',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _vaultService.resetVault();
        await _loadSecurityStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Vault reset complete. Fresh master key initialized!',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vault reset failed: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }
}
