import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/errors/exceptions.dart';
import '../../providers/auth_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkLockoutStatus();
    _tryBiometricLogin();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _lockoutController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _lockoutAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _lockoutController,
      curve: Curves.easeInOut,
    ));

    // Start animations
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

  void _checkLockoutStatus() {
    final authService = ref.read(authServiceProvider);
    final lockoutTime = authService.getRemainingLockoutTime();

    if (lockoutTime != null) {
      setState(() {
        _lockoutTime = lockoutTime;
        _showBiometric = false;
      });
      _startLockoutTimer();
      _lockoutController.forward();
    }
  }

  void _startLockoutTimer() {
    if (_lockoutTime == null) return;

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _lockoutTime != null) {
        final remaining = _lockoutTime! - const Duration(seconds: 1);
        if (remaining.inSeconds <= 0) {
          setState(() {
            _lockoutTime = null;
            _showBiometric = true;
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

  Future<void> _tryBiometricLogin() async {
    final authState = ref.read(authStateProvider);
    if (!authState.isBiometricEnabled) return;

    // Small delay to let the screen settle
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted && _showBiometric) {
      _authenticateWithBiometric();
    }
  }

  void _onPinChanged(String pin) {
    setState(() {
      _currentPin = pin;
      _errorMessage = null;
    });
  }

  void _onPinCompleted(String pin) {
    _authenticateWithPin(pin);
  }

  Future<void> _authenticateWithPin(String pin) async {
    if (_lockoutTime != null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final success = await authNotifier.verifyPin(pin);

      if (success) {
        _onAuthenticationSuccess();
      } else {
        _onAuthenticationFailed('auth.invalidPin'.tr());
      }
    } catch (e) {
      _onAuthenticationFailed(_getErrorMessage(e));
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_lockoutTime != null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final success = await authNotifier.authenticateWithBiometrics();

      if (success) {
        _onAuthenticationSuccess();
      } else {
        _onAuthenticationFailed('auth.authenticationFailed'.tr());
        setState(() {
          _showBiometric = false;
        });
      }
    } catch (e) {
      _onAuthenticationFailed(_getErrorMessage(e));
      setState(() {
        _showBiometric = false;
      });
    }
  }

  void _onAuthenticationSuccess() {
    // Navigate to intended destination
    final redirectPath = widget.redirectPath ?? '/dashboard';
    context.go(redirectPath);
  }

  void _onAuthenticationFailed(String message) {
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });

    _pinInputKey.currentState?.showError();
    _pinInputKey.currentState?.clearPin();

    // Check if account is now locked
    _checkLockoutStatus();
  }

  String _getErrorMessage(dynamic error) {
    if (error is AuthenticationException) {
      if (error.message.contains('locked')) {
        return error.message;
      }
      return 'auth.invalidPin'.tr();
    } else if (error is BiometricNotAvailableException) {
      return 'auth.biometricNotAvailable'.tr();
    }
    return 'errors.general'.tr();
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        icon: Icon(
          Icons.help_outline_rounded,
          color: AppColors.warning,
          size: AppDimensions.iconXl,
        ),
        title: 'auth.forgotPin'.tr(),
        content: 'auth.forgotPinMessage'.tr(),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetAuthentication();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text('auth.resetApp'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAuthentication() async {
    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      await authNotifier.resetAuthentication();

      // Navigate to onboarding
      context.go('/onboarding');
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
      onPressed: _isLoading ? null : _showForgotPinDialog,
      child: Text(
        'auth.forgotPin'.tr(),
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFailedAttemptsInfo() {
    final authService = ref.read(authServiceProvider);
    final failedAttempts = authService.getFailedAttempts();

    if (failedAttempts == 0 || _lockoutTime != null) {
      return const SizedBox.shrink();
    }

    final maxAttempts =
        5; // This should come from AppConstants.maxLoginAttempts
    final remainingAttempts = maxAttempts - failedAttempts;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: AppDimensions.iconS,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            'auth.attemptsRemaining'.tr(args: [remainingAttempts.toString()]),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: '',
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
                      child: Column(
                        children: [
                          const SizedBox(height: AppDimensions.spacingXl),
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
