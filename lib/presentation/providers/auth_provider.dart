import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../data/services/auth_service.dart';
import '../../core/errors/exceptions.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(),
);

// Authentication state provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);

// Biometric availability provider
final biometricAvailabilityProvider = FutureProvider<BiometricInfo>(
  (ref) async {
    final authService = ref.read(authServiceProvider);

    final isAvailable = await authService.isBiometricAvailable();
    final availableTypes = await authService.getAvailableBiometrics();

    return BiometricInfo(
      isAvailable: isAvailable,
      availableTypes: availableTypes, isEnabled: false, hasFingerprint: false, hasFaceID: false, hasIris: false,
    );
  },
);

// Authentication status provider
final authStatusProvider = FutureProvider<AuthStatus>(
  (ref) async {
    final authService = ref.read(authServiceProvider);
    return await authService.getAuthStatus();
  },
);

// Auth state
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final bool isPinEnabled;
  final bool isBiometricEnabled;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.isPinEnabled = false,
    this.isBiometricEnabled = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool? isPinEnabled,
    bool? isBiometricEnabled,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkAuthStatus();
  }

  // Check current authentication status
  Future<void> _checkAuthStatus() async {
    try {
      final isPinEnabled = _authService.isPinEnabled();
      final isBiometricEnabled = _authService.isBiometricEnabled();

      state = state.copyWith(
        isPinEnabled: isPinEnabled,
        isBiometricEnabled: isBiometricEnabled,
        isAuthenticated: false, // Always start unauthenticated
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({String? reason}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final success = await _authService.authenticateWithBiometrics(
        reason: reason ?? 'Please authenticate to access your financial data',
      );

      state = state.copyWith(
        isAuthenticated: success,
        isLoading: false,
      );

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final success = await _authService.verifyPin(pin);

      state = state.copyWith(
        isAuthenticated: success,
        isLoading: false,
        error: success ? null : 'Invalid PIN',
      );

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Setup PIN
  Future<bool> setupPin(String pin) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _authService.setupPin(pin);

      state = state.copyWith(
        isLoading: false,
        isPinEnabled: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _authService.changePin(oldPin, newPin);

      state = state.copyWith(isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Remove PIN
  Future<bool> removePin(String currentPin) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _authService.removePin(currentPin);

      state = state.copyWith(
        isLoading: false,
        isPinEnabled: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Enable biometric authentication
  Future<bool> enableBiometric() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _authService.enableBiometric();

      state = state.copyWith(
        isLoading: false,
        isBiometricEnabled: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Disable biometric authentication
  Future<bool> disableBiometric() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _authService.disableBiometric();

      state = state.copyWith(
        isLoading: false,
        isBiometricEnabled: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Logout
  void logout() {
    state = state.copyWith(isAuthenticated: false);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Reset authentication
  Future<bool> resetAuthentication() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _authService.resetAuthentication();

      state = const AuthState();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}
