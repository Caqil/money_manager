// lib/presentation/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/auth_service.dart';

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
      availableTypes: availableTypes,
      isEnabled: false,
      hasFingerprint: false,
      hasFaceID: false,
      hasIris: false,
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

// FIXED: Complete Auth notifier with proper method names
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _initializeAuthState();
  }

  // Initialize authentication state
  Future<void> _initializeAuthState() async {
    try {
      state = state.copyWith(isLoading: true);

      // Ensure AuthService is initialized
      // Note: AuthService should already be initialized in main.dart
      // If not initialized, the service methods will handle initialization internally

      // Check what authentication methods are enabled
      final isPinEnabled = _authService.isPinEnabled();
      final isBiometricEnabled = _authService.isBiometricEnabled();

      // User is NOT authenticated when app starts - they need to authenticate each session
      state = state.copyWith(
        isPinEnabled: isPinEnabled,
        isBiometricEnabled: isBiometricEnabled,
        isAuthenticated: false, // Always start unauthenticated
        isLoading: false,
        error: null,
      );

      print('🔑 Auth state initialized:');
      print('  PIN enabled: $isPinEnabled');
      print('  Biometric enabled: $isBiometricEnabled');
      print('  Authenticated: false (session start)');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('❌ Failed to initialize auth state: $e');
    }
  }

  // FIXED: Authenticate with PIN (method name that LoginScreen expects)
  Future<bool> authenticateWithPin(String pin) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final success = await _authService.verifyPin(pin);

      if (success) {
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
        );
        print('✅ PIN authentication successful');
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          error: 'Invalid PIN',
        );
        print('❌ PIN authentication failed');
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('❌ PIN authentication error: $e');
      return false;
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({String? reason}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final success = await _authService.authenticateWithBiometrics(
        reason: reason ?? 'Please authenticate to access your financial data',
      );

      if (success) {
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
        );
        print('✅ Biometric authentication successful');
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          error: 'Biometric authentication failed',
        );
        print('❌ Biometric authentication failed');
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('❌ Biometric authentication error: $e');
      return false;
    }
  }

  // Set up PIN
  Future<bool> setupPin(String pin) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _authService.setupPin(pin);

      state = state.copyWith(
        isPinEnabled: true,
        isAuthenticated: true, // Automatically authenticate after setup
        isLoading: false,
      );

      print('✅ PIN setup successful');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('❌ PIN setup failed: $e');
      return false;
    }
  }

  // Enable biometric authentication
  Future<bool> enableBiometric() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _authService.enableBiometric();

      state = state.copyWith(
        isBiometricEnabled: true,
        isLoading: false,
      );

      print('✅ Biometric enabled');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('❌ Failed to enable biometric: $e');
      return false;
    }
  }

  // Disable authentication methods
  Future<void> disablePin() async {
    try {
      await _authService.disablePin();
      state = state.copyWith(isPinEnabled: false);
      print('🔓 PIN disabled');
    } catch (e) {
      print('❌ Failed to disable PIN: $e');
    }
  }

  Future<void> disableBiometric() async {
    try {
      await _authService.disableBiometric();
      state = state.copyWith(isBiometricEnabled: false);
      print('🔓 Biometric disabled');
    } catch (e) {
      print('❌ Failed to disable biometric: $e');
    }
  }

  // Logout/unauthenticate
  void logout() {
    state = state.copyWith(isAuthenticated: false);
    print('🚪 User logged out');
  }

  // Force refresh auth state (useful after settings changes)
  Future<void> refreshAuthState() async {
    await _initializeAuthState();
  }

  // Reset authentication (for testing or account reset)
  Future<void> resetAuthentication() async {
    try {
      await _authService.resetAuthentication();
      state = const AuthState(); // Reset to initial state
      print('🔄 Authentication reset');
    } catch (e) {
      print('❌ Failed to reset authentication: $e');
    }
  }

  // Set authenticated state (internal use)
  void setAuthenticated(bool authenticated) {
    state = state.copyWith(isAuthenticated: authenticated);
  }

  // Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _authService.changePin(oldPin, newPin);

      state = state.copyWith(isLoading: false);

      print('✅ PIN changed successfully');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      print('❌ Failed to change PIN: $e');
      return false;
    }
  }

  // Get failed attempts count
  int getFailedAttempts() {
    return _authService.getFailedAttempts();
  }

  // Check lockout status
  Future<Duration?> getLockoutTime() async {
    return await _authService.getRemainingLockoutTime();
  }

  // Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}
