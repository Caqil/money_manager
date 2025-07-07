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
import 'widgets/pin_input_widget.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  final bool isFirstTimeSetup;
  final bool showBiometricOption;

  const PinSetupScreen({
    super.key,
    this.isFirstTimeSetup = true,
    this.showBiometricOption = true,
  });

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen>
    with TickerProviderStateMixin {
  final GlobalKey<PinInputWidgetState> _pinInputKey = GlobalKey<PinInputWidgetState>();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  PinSetupStep _currentStep = PinSetupStep.initial;
  String _firstPin = '';
  String _confirmPin = '';
  String? _errorMessage;
  bool _isLoading = false;
  bool _enableBiometric = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
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
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onPinChanged(String pin) {
    setState(() {
      _errorMessage = null;
    });
  }

  void _onPinCompleted(String pin) {
    setState(() {
      _errorMessage = null;
    });

    switch (_currentStep) {
      case PinSetupStep.initial:
        _firstPin = pin;
        _nextStep(PinSetupStep.confirm);
        break;
      case PinSetupStep.confirm:
        _confirmPin = pin;
        _validateAndSetupPin();
        break;
    }
  }

  void _nextStep(PinSetupStep step) {
    setState(() {
      _currentStep = step;
    });

    // Reset animations for next step
    _slideController.reset();
    _slideController.forward();

    // Clear the current pin input
    Future.delayed(const Duration(milliseconds: 100), () {
      _pinInputKey.currentState?.clearPin();
    });
  }

  void _previousStep() {
    if (_currentStep == PinSetupStep.confirm) {
      setState(() {
        _currentStep = PinSetupStep.initial;
        _confirmPin = '';
        _errorMessage = null;
      });

      _slideController.reset();
      _slideController.forward();
      
      Future.delayed(const Duration(milliseconds: 100), () {
        _pinInputKey.currentState?.clearPin();
      });
    }
  }

  Future<void> _validateAndSetupPin() async {
    if (_firstPin != _confirmPin) {
      setState(() {
        _errorMessage = 'auth.pinMismatch'.tr();
      });
      _pinInputKey.currentState?.showError();
      return;
    }

    await _setupPin(_firstPin);
  }

  Future<void> _setupPin(String pin) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final success = await authNotifier.setupPin(pin);

      if (success) {
        // Setup biometric if enabled
        if (_enableBiometric) {
          await authNotifier.enableBiometric();
        }

        _showSuccessDialog();
      } else {
        setState(() {
          _errorMessage = 'errors.general'.tr();
          _isLoading = false;
        });
        _pinInputKey.currentState?.showError();
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
      _pinInputKey.currentState?.showError();
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is ValidationException) {
      return 'validation.invalidPin'.tr();
    } else if (error is AuthenticationException) {
      return 'auth.authenticationFailed'.tr();
    }
    return 'errors.general'.tr();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        icon: Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: AppDimensions.iconXl,
        ),
        title: 'common.success'.tr(),
        content: widget.isFirstTimeSetup
            ? 'auth.pinSetupSuccess'.tr()
            : 'auth.pinChangedSuccess'.tr(),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/dashboard');
            },
            child: Text('common.continue'.tr()),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case PinSetupStep.initial:
        return 'auth.setupPin'.tr();
      case PinSetupStep.confirm:
        return 'auth.confirmPin'.tr();
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case PinSetupStep.initial:
        return 'auth.setupPinSubtitle'.tr();
      case PinSetupStep.confirm:
        return 'auth.confirmPinSubtitle'.tr();
    }
  }

  Widget _buildHeader() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey(_currentStep),
        children: [
          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProgressDot(0, _currentStep.index >= 0),
              Container(
                width: 40,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
                decoration: BoxDecoration(
                  color: _currentStep.index >= 1
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              _buildProgressDot(1, _currentStep.index >= 1),
            ],
          ),
          
          const SizedBox(height: AppDimensions.spacingXl),
          
          // Title
          Text(
            _getStepTitle(),
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppDimensions.spacingS),
          
          // Subtitle
          Text(
            _getStepSubtitle(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(int index, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.primary.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildPinInput() {
    return SlideTransition(
      position: _slideAnimation,
      child: PinInputWidget(
        key: _pinInputKey,
        pinLength: 4,
        onChanged: _onPinChanged,
        onCompleted: _onPinCompleted,
        errorText: _errorMessage,
        autoFocus: true,
        enabled: !_isLoading,
      ),
    );
  }

  Widget _buildBiometricOption() {
    if (!widget.showBiometricOption || _currentStep != PinSetupStep.confirm) {
      return const SizedBox.shrink();
    }

    return Consumer(
      builder: (context, ref, child) {
        final biometricInfo = ref.watch(biometricAvailabilityProvider);
        
        return biometricInfo.when(
          data: (info) {
            if (!info.isAvailable) return const SizedBox.shrink();
            
            String biometricName = 'Biometric';
            if (info.hasFaceID) {
              biometricName = 'Face ID';
            } else if (info.hasFingerprint) {
              biometricName = 'Fingerprint';
            }
            
            return AnimatedOpacity(
              opacity: _isLoading ? 0.6 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingL,
                ),
                child: SwitchListTile(
                  title: Text(
                    'auth.enableBiometric'.tr(),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'auth.enableBiometricSubtitle'.tr(args: [biometricName]),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  value: _enableBiometric,
                  onChanged: _isLoading ? null : (value) {
                    setState(() {
                      _enableBiometric = value;
                    });
                  },
                  secondary: Icon(
                    info.hasFaceID ? Icons.face_rounded : Icons.fingerprint_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Row(
        children: [
          if (_currentStep == PinSetupStep.confirm) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingM,
                  ),
                ),
                child: Text('common.back'.tr()),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
          ],
          
          if (_currentStep == PinSetupStep.initial)
            Expanded(
              child: ElevatedButton(
                onPressed: (_firstPin.length == 4 && !_isLoading) 
                    ? () => _nextStep(PinSetupStep.confirm)
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingM,
                  ),
                ),
                child: Text('common.next'.tr()),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.isFirstTimeSetup ? 'auth.setupPin'.tr() : 'auth.changePin'.tr(),
        showBackButton: !widget.isFirstTimeSetup,
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    child: Column(
                      children: [
                        _buildHeader(),
                        
                        const SizedBox(height: AppDimensions.spacingXxl),
                        
                        _buildPinInput(),
                        
                        const SizedBox(height: AppDimensions.spacingXl),
                        
                        _buildBiometricOption(),
                      ],
                    ),
                  ),
                ),
                
                _buildActions(),
              ],
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

enum PinSetupStep {
  initial,
  confirm,
}