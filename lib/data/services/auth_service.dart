import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/validation_helper.dart';

class AuthService {
  static AuthService? _instance;
  late final LocalAuthentication _localAuth;
  late final SharedPreferences _prefs;
  bool _isInitialized = false;

  AuthService._internal();

  factory AuthService() {
    _instance ??= AuthService._internal();
    return _instance!;
  }

  // Initialize auth service
  static Future<AuthService> init() async {
    try {
      final instance = AuthService();
      await instance._initialize();
      return instance;
    } catch (e) {
      throw AuthenticationException(
          message: 'Failed to initialize auth service: $e');
    }
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    _localAuth = LocalAuthentication();
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  // Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      if (!_isInitialized) await _initialize();

      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      if (!_isInitialized) await _initialize();

      if (await isBiometricAvailable()) {
        return await _localAuth.getAvailableBiometrics();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({
    String reason = 'Please authenticate to access your financial data',
  }) async {
    try {
      if (!_isInitialized) await _initialize();

      if (!await isBiometricAvailable()) {
        throw BiometricNotAvailableException();
      }

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );

      return isAuthenticated;
    } catch (e) {
      if (e is BiometricNotAvailableException) rethrow;
      throw AuthenticationFailedException();
    }
  }

  // Set up PIN
  Future<void> setupPin(String pin) async {
    try {
      if (!_isInitialized) await _initialize();

      if (!ValidationHelper.isValidPin(pin)) {
        throw ValidationException(message: 'Invalid PIN format');
      }

      final salt = _generateSalt();
      final hashedPin = _hashPin(pin, salt);

      await _prefs.setString(AppConstants.keyPinHash, hashedPin);
      await _prefs.setString('pin_salt', salt);
      await _prefs.setBool(AppConstants.keyPinEnabled, true);
      await _prefs.setInt('pin_attempts', 0);
      await _prefs.setInt('pin_locked_until', 0);
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw AuthenticationException(message: 'Failed to setup PIN: $e');
    }
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    try {
      if (!_isInitialized) await _initialize();

      if (!isPinEnabled()) {
        return false;
      }

      // Check if account is locked
      final lockoutExpiry = _prefs.getInt('pin_locked_until') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (lockoutExpiry > now) {
        final remainingMinutes = ((lockoutExpiry - now) / (1000 * 60)).ceil();
        throw AuthenticationException(
          message: 'Account locked. Try again in $remainingMinutes minutes.',
        );
      }

      final storedHash = _prefs.getString(AppConstants.keyPinHash);
      final salt = _prefs.getString('pin_salt');

      if (storedHash == null || salt == null) {
        return false;
      }

      final hashedPin = _hashPin(pin, salt);
      final isValid = hashedPin == storedHash;

      if (isValid) {
        // Reset failed attempts on successful authentication
        await _prefs.setInt('pin_attempts', 0);
        return true;
      } else {
        // Increment failed attempts
        final attempts = (_prefs.getInt('pin_attempts') ?? 0) + 1;
        await _prefs.setInt('pin_attempts', attempts);

        // Lock account after max attempts
        if (attempts >= AppConstants.maxLoginAttempts) {
          final lockUntil = now + AppConstants.lockoutDuration.inMilliseconds;
          await _prefs.setInt('pin_locked_until', lockUntil);
          await _prefs.setInt('pin_attempts', 0);

          throw AuthenticationException(
            message:
                'Too many failed attempts. Account locked for ${AppConstants.lockoutDuration.inMinutes} minutes.',
          );
        }

        return false;
      }
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      return false;
    }
  }

  // Change PIN
  Future<void> changePin(String oldPin, String newPin) async {
    try {
      if (!_isInitialized) await _initialize();

      if (!await verifyPin(oldPin)) {
        throw AuthenticationFailedException();
      }

      if (!ValidationHelper.isValidPin(newPin)) {
        throw ValidationException(message: 'Invalid new PIN format');
      }

      await setupPin(newPin);
    } catch (e) {
      if (e is AuthenticationFailedException || e is ValidationException)
        rethrow;
      throw AuthenticationException(message: 'Failed to change PIN: $e');
    }
  }

  // Remove PIN
  Future<void> removePin(String currentPin) async {
    try {
      if (!_isInitialized) await _initialize();

      if (!await verifyPin(currentPin)) {
        throw AuthenticationFailedException();
      }

      await _prefs.remove(AppConstants.keyPinHash);
      await _prefs.remove('pin_salt');
      await _prefs.setBool(AppConstants.keyPinEnabled, false);
      await _prefs.remove('pin_attempts');
      await _prefs.remove('pin_locked_until');
    } catch (e) {
      if (e is AuthenticationFailedException) rethrow;
      throw AuthenticationException(message: 'Failed to remove PIN: $e');
    }
  }

  // Enable biometric authentication
  Future<void> enableBiometric() async {
    try {
      if (!_isInitialized) await _initialize();

      if (!await isBiometricAvailable()) {
        throw BiometricNotAvailableException();
      }

      // Test biometric authentication before enabling
      final isAuthenticated = await authenticateWithBiometrics(
        reason: 'Verify your identity to enable biometric authentication',
      );

      if (!isAuthenticated) {
        throw AuthenticationFailedException();
      }

      await _prefs.setBool(AppConstants.keyBiometricEnabled, true);
    } catch (e) {
      rethrow;
    }
  }

  // Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      if (!_isInitialized) await _initialize();

      await _prefs.setBool(AppConstants.keyBiometricEnabled, false);
    } catch (e) {
      throw AuthenticationException(message: 'Failed to disable biometric: $e');
    }
  }

  // Check if PIN is enabled
  bool isPinEnabled() {
    return _prefs.getBool(AppConstants.keyPinEnabled) ?? false;
  }

  // Check if biometric is enabled
  bool isBiometricEnabled() {
    return _prefs.getBool(AppConstants.keyBiometricEnabled) ?? false;
  }

  // Check if any authentication method is enabled
  bool isAuthenticationEnabled() {
    return isPinEnabled() || isBiometricEnabled();
  }

  // Get remaining lockout time
  Duration? getRemainingLockoutTime() {
    final lockoutExpiry = _prefs.getInt('pin_locked_until') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (lockoutExpiry > now) {
      return Duration(milliseconds: lockoutExpiry - now);
    }

    return null;
  }

  // Get failed PIN attempts count
  int getFailedAttempts() {
    return _prefs.getInt('pin_attempts') ?? 0;
  }

  // Check if account is locked
  bool isAccountLocked() {
    final lockoutExpiry = _prefs.getInt('pin_locked_until') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return lockoutExpiry > now;
  }

  // Authenticate with available methods
  Future<bool> authenticate({
    String reason = 'Please authenticate to access your financial data',
  }) async {
    try {
      if (!_isInitialized) await _initialize();

      // Check if account is locked
      if (isAccountLocked()) {
        final remaining = getRemainingLockoutTime();
        if (remaining != null) {
          final minutes = remaining.inMinutes;
          throw AuthenticationException(
            message: 'Account locked. Try again in $minutes minutes.',
          );
        }
      }

      // Try biometric first if enabled and available
      if (isBiometricEnabled() && await isBiometricAvailable()) {
        try {
          return await authenticateWithBiometrics(reason: reason);
        } catch (e) {
          // Fall back to PIN if biometric fails and PIN is enabled
          if (!isPinEnabled()) rethrow;
          // PIN authentication would be handled by the UI layer
          return false;
        }
      }

      // If only PIN is enabled, PIN authentication would be handled by the UI layer
      return isPinEnabled();
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      throw AuthenticationFailedException();
    }
  }

  // Get authentication status
  Future<AuthStatus> getAuthStatus() async {
    try {
      if (!_isInitialized) await _initialize();

      if (!isAuthenticationEnabled()) {
        return AuthStatus.noAuthenticationSet;
      }

      final biometricAvailable = await isBiometricAvailable();

      if (isBiometricEnabled() && biometricAvailable && isPinEnabled()) {
        return AuthStatus.bothEnabled;
      } else if (isBiometricEnabled() && biometricAvailable) {
        return AuthStatus.biometricEnabled;
      } else if (isPinEnabled()) {
        return AuthStatus.pinEnabled;
      } else {
        return AuthStatus.noAuthenticationSet;
      }
    } catch (e) {
      return AuthStatus.noAuthenticationSet;
    }
  }

  // Reset all authentication
  Future<void> resetAuthentication() async {
    try {
      if (!_isInitialized) await _initialize();

      await _prefs.remove(AppConstants.keyPinHash);
      await _prefs.remove('pin_salt');
      await _prefs.setBool(AppConstants.keyPinEnabled, false);
      await _prefs.setBool(AppConstants.keyBiometricEnabled, false);
      await _prefs.remove('pin_attempts');
      await _prefs.remove('pin_locked_until');
    } catch (e) {
      throw AuthenticationException(
          message: 'Failed to reset authentication: $e');
    }
  }

  // Get biometric info for UI
  Future<BiometricInfo> getBiometricInfo() async {
    try {
      if (!_isInitialized) await _initialize();

      final isAvailable = await isBiometricAvailable();
      final types = await getAvailableBiometrics();

      return BiometricInfo(
        isAvailable: isAvailable,
        isEnabled: isBiometricEnabled(),
        availableTypes: types,
        hasFingerprint: types.contains(BiometricType.fingerprint),
        hasFaceID: types.contains(BiometricType.face),
        hasIris: types.contains(BiometricType.iris),
      );
    } catch (e) {
      return const BiometricInfo(
        isAvailable: false,
        isEnabled: false,
        availableTypes: [],
        hasFingerprint: false,
        hasFaceID: false,
        hasIris: false,
      );
    }
  }

  // Private helper methods
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Dispose service
  void dispose() {
    // Clean up resources if needed
  }
}

// Authentication status enum
enum AuthStatus {
  noAuthenticationSet,
  pinEnabled,
  biometricEnabled,
  bothEnabled,
}

// Biometric info class
class BiometricInfo {
  final bool isAvailable;
  final bool isEnabled;
  final List<BiometricType> availableTypes;
  final bool hasFingerprint;
  final bool hasFaceID;
  final bool hasIris;

  const BiometricInfo({
    required this.isAvailable,
    required this.isEnabled,
    required this.availableTypes,
    required this.hasFingerprint,
    required this.hasFaceID,
    required this.hasIris,
  });

  String get primaryBiometricName {
    if (hasFaceID) return 'Face ID';
    if (hasFingerprint) return 'Fingerprint';
    if (hasIris) return 'Iris';
    return 'Biometric';
  }

  bool get hasAnyBiometric => hasFingerprint || hasFaceID || hasIris;
}
