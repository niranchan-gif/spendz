import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/wallet/security/wallet_auth_service.dart';

/// Reusable biometric-guarded field that displays masked numbers by default
/// and reveals protected full numbers only upon biometric authentication,
/// with automatic session expiration and background re-masking.
class SecureProtectedField extends StatefulWidget {
  final String maskedValue;
  final Future<String?> Function() onRetrieveProtectedValue;
  final String label;
  final int sessionTimeoutSeconds;
  final TextStyle? textStyle;
  final bool showCopyButton;

  const SecureProtectedField({
    super.key,
    required this.maskedValue,
    required this.onRetrieveProtectedValue,
    this.label = 'Card Number',
    this.sessionTimeoutSeconds = 30,
    this.textStyle,
    this.showCopyButton = false,
  });

  @override
  State<SecureProtectedField> createState() => _SecureProtectedFieldState();
}

class _SecureProtectedFieldState extends State<SecureProtectedField>
    with WidgetsBindingObserver {
  bool _isRevealed = false;
  bool _isAuthenticating = false;
  String? _revealedValue;
  Timer? _sessionTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clearProtectedState();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Re-mask immediately when app goes to background
      _maskValue();
    }
  }

  void _clearProtectedState() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _revealedValue = null;
    _remainingSeconds = 0;
    _isRevealed = false;
  }

  void _maskValue() {
    if (mounted) {
      setState(() {
        _clearProtectedState();
      });
    } else {
      _clearProtectedState();
    }
  }

  Future<void> _handleRevealTap() async {
    if (_isRevealed) {
      _maskValue();
      return;
    }

    final authService = context.read<WalletAuthService>();
    setState(() => _isAuthenticating = true);

    try {
      final success = await authService.authenticate(
        localizedReason: 'Authenticate with biometrics or passcode to reveal ${widget.label}',
      );

      if (!mounted) return;

      if (success) {
        final fullValue = await widget.onRetrieveProtectedValue();
        if (!mounted) return;

        if (fullValue != null && fullValue.isNotEmpty) {
          setState(() {
            _isRevealed = true;
            _revealedValue = fullValue;
            _remainingSeconds = widget.sessionTimeoutSeconds;
            _isAuthenticating = false;
          });

          _sessionTimer?.cancel();
          _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (!mounted) {
              timer.cancel();
              return;
            }
            if (_remainingSeconds <= 1) {
              _maskValue();
            } else {
              setState(() => _remainingSeconds--);
            }
          });
        } else {
          setState(() => _isAuthenticating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No full number stored on device for this entry.'),
            ),
          );
        }
      } else {
        setState(() => _isAuthenticating = false);
        if (authService.lastErrorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authService.lastErrorMessage!),
              backgroundColor: AppColors.getError(context),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = _isRevealed && _revealedValue != null
        ? _revealedValue!
        : widget.maskedValue;
    final defaultStyle = widget.textStyle ?? AppTextStyles.cardNumber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(45),
        borderRadius: AppRadius.roundedMd,
        border: Border.all(
          color: _isRevealed
              ? AppColors.getPrimary(context).withAlpha(120)
              : Colors.white.withAlpha(25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      widget.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withAlpha(150),
                      ),
                    ),
                    if (_isRevealed) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.getWarning(context).withAlpha(35),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.getWarning(context).withAlpha(60),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Expires in ${_remainingSeconds}s',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getWarning(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayValue,
                    style: defaultStyle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Reveal / Hide Button with biometric trigger
          InkWell(
            onTap: _isAuthenticating ? null : _handleRevealTap,
            borderRadius: AppRadius.roundedSm,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs + 2),
              decoration: BoxDecoration(
                color: _isRevealed
                    ? AppColors.getPrimary(context).withAlpha(35)
                    : Colors.white.withAlpha(20),
                borderRadius: AppRadius.roundedSm,
                border: Border.all(
                  color: _isRevealed
                      ? AppColors.getPrimary(context).withAlpha(60)
                      : Colors.white.withAlpha(30),
                ),
              ),
              child: _isAuthenticating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      _isRevealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: _isRevealed ? AppColors.getPrimary(context) : Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

