// lib/data/services/auth_service.dart
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

  // FIXED: Add public getter for initialization status
  bool get isInitialized => _isInitialized;

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
      throw AuthenticationException(message: 'PIN verification failed: $e');
    }
  }

  // Check if PIN is enabled
  bool isPinEnabled() {
    try {
      if (!_isInitialized) {
        // If not initialized, we can't check PIN status safely
        return false;
      }
      return _prefs.getBool(AppConstants.keyPinEnabled) ?? false;
    } catch (e) {
      print('Error checking PIN status: $e');
      return false;
    }
  }

  // Check if biometric is enabled
  bool isBiometricEnabled() {
    try {
      if (!_isInitialized) {
        return false;
      }
      return _prefs.getBool(AppConstants.keyBiometricEnabled) ?? false;
    } catch (e) {
      print('Error checking biometric status: $e');
      return false;
    }
  }

  // FIXED: Get remaining lockout time safely
  Future<Duration?> getRemainingLockoutTime() async {
    try {
      // Ensure initialization before accessing _prefs
      if (!_isInitialized) {
        await _initialize();
      }

      final lockoutExpiry = _prefs.getInt('pin_locked_until') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (lockoutExpiry > now) {
        final remainingMs = lockoutExpiry - now;
        return Duration(milliseconds: remainingMs);
      }

      return null;
    } catch (e) {
      // Log the error but don't crash
      print('Error getting lockout time: $e');
      return null;
    }
  }

  // ADDED: Enable biometric authentication
  Future<void> enableBiometric() async {
    try {
      if (!_isInitialized) await _initialize();

      // Check if biometric is available
      if (!await isBiometricAvailable()) {
        throw AuthenticationException(
          message: 'Biometric authentication is not available on this device',
        );
      }

      await _prefs.setBool(AppConstants.keyBiometricEnabled, true);
    } catch (e) {
      throw AuthenticationException(
        message: 'Failed to enable biometric authentication: $e',
      );
    }
  }

  // ADDED: Disable PIN authentication
  Future<void> disablePin() async {
    try {
      if (!_isInitialized) await _initialize();

      await _prefs.setBool(AppConstants.keyPinEnabled, false);
      await _prefs.remove(AppConstants.keyPinHash);
      await _prefs.remove('pin_salt');
      await _prefs.setInt('pin_attempts', 0);
      await _prefs.setInt('pin_locked_until', 0);
    } catch (e) {
      throw AuthenticationException(
        message: 'Failed to disable PIN: $e',
      );
    }
  }

  // ADDED: Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      if (!_isInitialized) await _initialize();

      await _prefs.setBool(AppConstants.keyBiometricEnabled, false);
    } catch (e) {
      throw AuthenticationException(
        message: 'Failed to disable biometric authentication: $e',
      );
    }
  }

  // ADDED: Reset all authentication (for account reset or testing)
  Future<void> resetAuthentication() async {
    try {
      if (!_isInitialized) await _initialize();

      await _prefs.setBool(AppConstants.keyPinEnabled, false);
      await _prefs.setBool(AppConstants.keyBiometricEnabled, false);
      await _prefs.remove(AppConstants.keyPinHash);
      await _prefs.remove('pin_salt');
      await _prefs.setInt('pin_attempts', 0);
      await _prefs.setInt('pin_locked_until', 0);
    } catch (e) {
      throw AuthenticationException(
        message: 'Failed to reset authentication: $e',
      );
    }
  }

  // ADDED: Check if any authentication method is enabled
  bool hasAuthenticationEnabled() {
    return isPinEnabled() || isBiometricEnabled();
  }

  // ADDED: Get authentication methods summary
  Map<String, bool> getAuthenticationStatus() {
    return {
      'pin_enabled': isPinEnabled(),
      'biometric_enabled': isBiometricEnabled(),
      'any_enabled': hasAuthenticationEnabled(),
    };
  }

  // ADDED: Get auth status safely
  Future<AuthStatus> getAuthStatus() async {
    try {
      if (!_isInitialized) {
        await _initialize();
      }

      return AuthStatus(
        isPinEnabled: isPinEnabled(),
        isBiometricEnabled: isBiometricEnabled(),
        isLocked: await getRemainingLockoutTime() != null,
      );
    } catch (e) {
      print('Error getting auth status: $e');
      return const AuthStatus(
        isPinEnabled: false,
        isBiometricEnabled: false,
        isLocked: false,
      );
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

  // Get failed PIN attempts count
  int getFailedAttempts() {
    try {
      if (!_isInitialized) return 0;
      return _prefs.getInt('pin_attempts') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Change PIN
  Future<void> changePin(String oldPin, String newPin) async {
    try {
      if (!_isInitialized) await _initialize();

      // Verify old PIN first
      if (!await verifyPin(oldPin)) {
        throw AuthenticationException(message: 'Current PIN is incorrect');
      }

      // Set new PIN
      await setupPin(newPin);
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      throw AuthenticationException(message: 'Failed to change PIN: $e');
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

// ADDED: Auth status class
class AuthStatus {
  final bool isPinEnabled;
  final bool isBiometricEnabled;
  final bool isLocked;

  const AuthStatus({
    required this.isPinEnabled,
    required this.isBiometricEnabled,
    required this.isLocked,
  });
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
