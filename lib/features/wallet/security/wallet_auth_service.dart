import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum AuthStatus {
  locked,
  unlocked,
  authenticating,
  error,
}

enum AuthFailureReason {
  userCanceled,
  biometricsNotAvailable,
  notEnrolled,
  passcodeNotSet,
  tooManyAttempts,
  other,
}

/// Service handling biometric (fingerprint/Face ID) and device credential authentication
/// for Spendz Vault access, with auto-lock and inactivity timeout management.
class WalletAuthService extends ChangeNotifier {
  final LocalAuthentication _localAuth;

  AuthStatus _status = AuthStatus.locked;
  DateTime? _lastActivityTime;
  int _inactivityTimeoutSeconds = 60; // Default 1 minute
  bool _lockOnBackground = true;
  String? _lastErrorMessage;
  AuthFailureReason? _lastFailureReason;

  WalletAuthService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  AuthStatus get status => _status;
  bool get isUnlocked => _status == AuthStatus.unlocked;
  int get inactivityTimeoutSeconds => _inactivityTimeoutSeconds;
  bool get lockOnBackground => _lockOnBackground;
  String? get lastErrorMessage => _lastErrorMessage;
  AuthFailureReason? get lastFailureReason => _lastFailureReason;

  set inactivityTimeoutSeconds(int seconds) {
    _inactivityTimeoutSeconds = seconds;
    notifyListeners();
  }

  set lockOnBackground(bool value) {
    _lockOnBackground = value;
    notifyListeners();
  }

  /// Checks if the hardware supports biometrics or device credentials.
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Lists available biometric types on the device (e.g. fingerprint, face).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authenticates the user using biometric or device PIN/passcode fallback.
  Future<bool> authenticate({
    String localizedReason = 'Unlock Spendz Vault to access encrypted documents',
  }) async {
    // If already unlocked and within timeout, record activity and return true
    if (isUnlocked && !hasTimedOut()) {
      recordActivity();
      return true;
    }

    _status = AuthStatus.authenticating;
    _lastErrorMessage = null;
    _lastFailureReason = null;
    notifyListeners();

    try {
      final isSupported = await canCheckBiometrics();
      if (!isSupported) {
        _status = AuthStatus.locked;
        _lastFailureReason = AuthFailureReason.biometricsNotAvailable;
        _lastErrorMessage = 'Biometric authentication is not supported or device passcode is not configured.';
        notifyListeners();
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false, // Allows device PIN/pattern fallback
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        _status = AuthStatus.unlocked;
        recordActivity();
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.locked;
        _lastFailureReason = AuthFailureReason.userCanceled;
        _lastErrorMessage = 'Authentication cancelled by user.';
        notifyListeners();
        return false;
      }
    } on LocalAuthException catch (e) {
      _status = AuthStatus.error;
      switch (e.code) {
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          _lastFailureReason = AuthFailureReason.biometricsNotAvailable;
          _lastErrorMessage = 'Biometric hardware is currently not available.';
          break;
        case LocalAuthExceptionCode.noBiometricsEnrolled:
          _lastFailureReason = AuthFailureReason.notEnrolled;
          _lastErrorMessage = 'No biometrics are set up on this device.';
          break;
        case LocalAuthExceptionCode.noCredentialsSet:
          _lastFailureReason = AuthFailureReason.passcodeNotSet;
          _lastErrorMessage = 'Device passcode or screen lock has not been configured.';
          break;
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          _lastFailureReason = AuthFailureReason.tooManyAttempts;
          _lastErrorMessage = 'Too many failed authentication attempts. Please try again later or use device passcode.';
          break;
        case LocalAuthExceptionCode.userCanceled:
          _lastFailureReason = AuthFailureReason.userCanceled;
          _lastErrorMessage = 'Authentication cancelled by user.';
          break;
        default:
          _lastFailureReason = AuthFailureReason.other;
          _lastErrorMessage = e.description ?? 'Authentication failed.';
      }
      notifyListeners();
      return false;
    } on PlatformException catch (e) {
      _status = AuthStatus.error;
      _lastFailureReason = AuthFailureReason.other;
      _lastErrorMessage = e.message ?? 'Authentication failed.';
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _lastFailureReason = AuthFailureReason.other;
      _lastErrorMessage = 'Unexpected authentication error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Records timestamp of recent user interaction.
  void recordActivity([DateTime? timestamp]) {
    _lastActivityTime = timestamp ?? DateTime.now();
  }

  /// Checks if the inactivity timeout period has elapsed.
  bool hasTimedOut() {
    if (_lastActivityTime == null) return true;
    final elapsed = DateTime.now().difference(_lastActivityTime!).inSeconds;
    return elapsed > _inactivityTimeoutSeconds;
  }

  /// Checks timeout and locks vault if expired.
  void checkInactivityTimeout() {
    if (isUnlocked && hasTimedOut()) {
      lockVault();
    }
  }

  /// Handler when application enters background.
  void onAppPaused() {
    if (_lockOnBackground) {
      lockVault();
    }
  }

  /// Locks the vault immediately and wipes active session state.
  void lockVault() {
    _status = AuthStatus.locked;
    _lastActivityTime = null;
    notifyListeners();
  }
}
