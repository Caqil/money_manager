// lib/presentation/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/errors/exceptions.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/custom_dialog.dart';
import 'widgets/biometric_button.dart';
import 'widgets/pin_input_widget.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? redirectPath;

  const LoginScreen({
    super.key,
    this.redirectPath,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final GlobalKey<PinInputWidgetState> _pinInputKey =
      GlobalKey<PinInputWidgetState>();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _lockoutController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _lockoutAnimation;

  String _currentPin = '';
  String? _errorMessage;
  bool _isLoading = false;
  bool _showBiometric = true;
  Duration? _lockoutTime;
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Use addPostFrameCallback to ensure the widget is built before checking lockout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLockoutStatusSafely();
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _lockoutController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _lockoutAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _lockoutController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _lockoutController.dispose();
    super.dispose();
  }

  // FIXED: Safe method to check lockout status
  Future<void> _checkLockoutStatusSafely() async {
    try {
      // Use the AuthService through the provider safely
      final authService = ref.read(authServiceProvider);

      // Check if service is initialized using the public getter
      if (!authService.isInitialized) {
        // Service not initialized - this shouldn't happen if main.dart is fixed
        print('Warning: AuthService not initialized in login screen');
        return;
      }

      final lockoutTime = await authService.getRemainingLockoutTime();

      if (mounted) {
        setState(() {
          _lockoutTime = lockoutTime;
        });

        if (lockoutTime != null) {
          _startLockoutTimer();
        }
      }
    } catch (e) {
      // If there's still an error, log it but don't crash the app
      print('Error checking lockout status: $e');

      // Optionally show an error message to the user
      if (mounted) {
        setState(() {
          _errorMessage =
              'Unable to check authentication status. Please try again.';
        });
      }
    }
  }

  void _startLockoutTimer() {
    if (_lockoutTime != null) {
      _lockoutController.forward();
      // Update lockout time every second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _lockoutTime != null) {
          final remaining = _lockoutTime! - const Duration(seconds: 1);
          if (remaining.inSeconds <= 0) {
            setState(() {
              _lockoutTime = null;
            });
            _lockoutController.reverse();
          } else {
            setState(() {
              _lockoutTime = remaining;
            });
            _startLockoutTimer();
          }
        }
      });
    }
  }

  void _onPinChanged(String pin) {
    setState(() {
      _currentPin = pin;
      _errorMessage = null;
    });
  }

  void _onPinCompleted(String pin) {
    _verifyPin();
  }

  // FIXED: Updated to use AuthNotifier's authenticateWithPin method
  Future<void> _verifyPin() async {
    if (_currentPin.length != 4) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the AuthNotifier's authenticateWithPin method (not verifyPin)
      final authNotifier = ref.read(authStateProvider.notifier);
      final isValid = await authNotifier.authenticateWithPin(_currentPin);

      if (mounted) {
        if (isValid) {
          context.go(widget.redirectPath ?? RouteNames.home);
        } else {
          setState(() {
            _errorMessage = 'auth.invalidPin'.tr();
            _failedAttempts++;
            _currentPin = '';
          });

          _pinInputKey.currentState?.deactivate();

          // Check for lockout after failed attempt
          await _checkLockoutStatusSafely();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().contains('locked')) {
            _errorMessage = e.toString();
            _lockoutTime = const Duration(minutes: 30);
            _startLockoutTimer();
          } else {
            _errorMessage = 'auth.error'.tr();
          }
          _currentPin = '';
        });
        _pinInputKey.currentState?.deactivate();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // FIXED: Helper method to safely access biometric authentication
  Future<void> _authenticateWithBiometrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the AuthNotifier's authenticateWithBiometrics method
      final authNotifier = ref.read(authStateProvider.notifier);
      final isAuthenticated = await authNotifier.authenticateWithBiometrics();

      if (mounted) {
        if (isAuthenticated) {
          context.go(widget.redirectPath ?? RouteNames.home);
        } else {
          setState(() {
            _errorMessage = 'auth.biometricFailed'.tr();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'auth.biometricError'.tr();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onAuthenticationSuccess() {
    context.go(widget.redirectPath ?? RouteNames.home);
  }

  Future<void> _resetAuthentication() async {
    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      await authNotifier.resetAuthentication();

      // Navigate to onboarding
      context.go(RouteNames.onboarding);
    } catch (e) {
      // Show error
      setState(() {
        _errorMessage = 'errors.general'.tr();
      });
    }
  }

  Widget _buildAppIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.account_balance_wallet_rounded,
        size: AppDimensions.iconL,
        color: Colors.white,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        _buildAppIcon(),
        const SizedBox(height: AppDimensions.spacingL),
        Text(
          'app.name'.tr(),
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          'auth.welcomeBack'.tr(),
          style: AppTextStyles.bodyLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLockoutMessage() {
    if (_lockoutTime == null) return const SizedBox.shrink();

    final minutes = _lockoutTime!.inMinutes;
    final seconds = _lockoutTime!.inSeconds % 60;

    return FadeTransition(
      opacity: _lockoutAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: AppColors.error.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_clock_rounded,
              color: AppColors.error,
              size: AppDimensions.iconM,
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'auth.accountLocked'.tr(),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'auth.tryAgainIn'.tr(args: [
                      minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s'
                    ]),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinInput() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          Text(
            'auth.enterPin'.tr(),
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          PinInputWidget(
            key: _pinInputKey,
            pinLength: 4,
            onChanged: _onPinChanged,
            onCompleted: _onPinCompleted,
            errorText: _errorMessage,
            enabled: !_isLoading && _lockoutTime == null,
            autoFocus: _lockoutTime == null,
          ),
        ],
      ),
    );
  }

  Widget _buildFailedAttemptsInfo() {
    if (_failedAttempts == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Text(
        'auth.failedAttempts'.tr(args: [_failedAttempts.toString()]),
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.error.withOpacity(0.7),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBiometricButton() {
    final authState = ref.watch(authStateProvider);

    if (!authState.isBiometricEnabled ||
        !_showBiometric ||
        _lockoutTime != null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: BiometricButton(
        onSuccess: _onAuthenticationSuccess,
        onError: (error) {
          setState(() {
            _errorMessage = error;
            _showBiometric = false;
          });
        },
        enabled: !_isLoading,
        style: BiometricButtonStyle.outlined,
        width: double.infinity,
      ),
    );
  }

  Widget _buildForgotPinButton() {
    if (_lockoutTime != null) return const SizedBox.shrink();

    return TextButton(
      onPressed: _isLoading ? null : _resetAuthentication,
      child: Text(
        'auth.forgotPin'.tr(),
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: AppDimensions.spacingXxl),
                          _buildHeader(),
                          const SizedBox(height: AppDimensions.spacingXxl),
                          _buildLockoutMessage(),
                          if (_lockoutTime == null) ...[
                            const SizedBox(height: AppDimensions.spacingL),
                            _buildPinInput(),
                            const SizedBox(height: AppDimensions.spacingL),
                            _buildFailedAttemptsInfo(),
                            const SizedBox(height: AppDimensions.spacingXl),
                            _buildBiometricButton(),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_lockoutTime == null) _buildForgotPinButton(),
                  const SizedBox(height: AppDimensions.spacingL),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: LoadingWidget(),
              ),
            ),
        ],
      ),
    );
  }
}
