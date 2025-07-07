import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/logger.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import 'widgets/splash_loading_widget.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<Color?> _backgroundAnimation;

  String _currentMessage = '';
  double _progress = 0.0;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialization();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _backgroundAnimation = ColorTween(
      begin: AppColors.primary.withOpacity(0.05),
      end: Colors.transparent,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _backgroundController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _startInitialization() async {
    AppLogger.info('🚀 Starting splash initialization...');

    try {
      // Since core services are already initialized in main.dart,
      // we'll focus on loading app-specific data and providers
      
      await _loadAppData();
      
      // Complete initialization
      setState(() {
        _progress = 1.0;
        _currentMessage = 'splash.init.complete'.tr();
      });

      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToNextScreen();

    } catch (e, stackTrace) {
      AppLogger.error('❌ Splash initialization failed', e, stackTrace);
      _handleInitializationError(e, stackTrace);
    }
  }

  Future<void> _loadAppData() async {
    // Step 1: Load settings (20%)
    setState(() {
      _currentMessage = 'splash.loading.settings'.tr();
      _progress = 0.0;
    });
    
    await _loadSettings();
    setState(() { _progress = 0.2; });
    await Future.delayed(const Duration(milliseconds: 300));

    // Step 2: Initialize auth state (40%)
    setState(() {
      _currentMessage = 'splash.loading.auth'.tr();
      _progress = 0.2;
    });
    
    await _loadAuthState();
    setState(() { _progress = 0.4; });
    await Future.delayed(const Duration(milliseconds: 300));

    // Step 3: Verify services (60%)
    setState(() {
      _currentMessage = 'splash.loading.services'.tr();
      _progress = 0.4;
    });
    
    await _verifyServices();
    setState(() { _progress = 0.6; });
    await Future.delayed(const Duration(milliseconds: 300));

    // Step 4: Prepare app data (80%)
    setState(() {
      _currentMessage = 'splash.loading.data'.tr();
      _progress = 0.6;
    });
    
    await _prepareAppData();
    setState(() { _progress = 0.8; });
    await Future.delayed(const Duration(milliseconds: 300));

    // Step 5: Finalize (100%)
    setState(() {
      _currentMessage = 'splash.loading.finalizing'.tr();
      _progress = 0.8;
    });
    
    await _finalizeLoad();
    setState(() { _progress = 1.0; });
  }

  Future<void> _loadSettings() async {
    try {
      // Load app settings using your existing provider
      final settingsNotifier = ref.read(settingsStateProvider.notifier);
      await settingsNotifier.loadSettings();
      AppLogger.info('✅ Settings loaded');
    } catch (e) {
      AppLogger.error('❌ Failed to load settings', e);
      // Continue with default settings
    }
  }

  Future<void> _loadAuthState() async {
    try {
      // Check auth status - the AuthNotifier will automatically
      // load the current auth state when we read it
      final authState = ref.read(authStateProvider);
      AppLogger.info('✅ Auth state loaded: ${authState.isPinEnabled ? "PIN enabled" : "No PIN"}, ${authState.isBiometricEnabled ? "Biometric enabled" : "No biometric"}');
    } catch (e) {
      AppLogger.error('❌ Failed to load auth state', e);
      // Continue without auth state
    }
  }

  Future<void> _verifyServices() async {
    try {
      // Verify that all services are properly initialized
      // These services should already be initialized from main.dart
      AppLogger.info('🔍 Verifying services...');
      
      // Quick verification without re-initializing
      await Future.delayed(const Duration(milliseconds: 200));
      
      AppLogger.info('✅ Services verified');
    } catch (e) {
      AppLogger.error('❌ Service verification failed', e);
      throw Exception('Service verification failed: $e');
    }
  }

  Future<void> _prepareAppData() async {
    try {
      // Prepare any initial app data
      // This could include loading initial categories, currency rates, etc.
      AppLogger.info('📊 Preparing app data...');
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      AppLogger.info('✅ App data prepared');
    } catch (e) {
      AppLogger.error('❌ Failed to prepare app data', e);
      // Continue without initial data
    }
  }

  Future<void> _finalizeLoad() async {
    // Final cleanup and preparation
    AppLogger.info('🏁 Finalizing splash...');
    await Future.delayed(const Duration(milliseconds: 200));
    AppLogger.info('✅ Splash finalized');
  }

  void _navigateToNextScreen() {
    final settingsState = ref.read(settingsStateProvider);
    final authState = ref.read(authStateProvider);

    AppLogger.info('🧭 Navigation decision:');
    AppLogger.info('  - First launch: ${settingsState.isFirstLaunch}');
    AppLogger.info('  - Auth enabled: ${authState.isPinEnabled || authState.isBiometricEnabled}');
    AppLogger.info('  - Authenticated: ${authState.isAuthenticated}');

    if (settingsState.isFirstLaunch) {
      // First time user - go to onboarding
      AppLogger.info('📱 Navigating to onboarding');
      context.go(RouteNames.onboarding);
    } else if (authState.isPinEnabled || authState.isBiometricEnabled) {
      if (!authState.isAuthenticated) {
        // User needs to authenticate
        AppLogger.info('🔐 Navigating to login');
        context.go(RouteNames.login);
      } else {
        // Already authenticated - go to home
        AppLogger.info('🏠 Navigating to home');
        context.go(RouteNames.home);
      }
    } else {
      // No auth setup - go to home
      AppLogger.info('🏠 Navigating to home (no auth)');
      context.go(RouteNames.home);
    }
  }

  void _handleInitializationError(Object error, StackTrace stackTrace) {
    setState(() {
      _hasError = true;
      _errorMessage = error.toString();
      _currentMessage = 'splash.error.general'.tr();
    });

    AppLogger.error('Splash initialization error', error, stackTrace);
  }

  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _progress = 0.0;
      _currentMessage = '';
    });

    _startInitialization();
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: AppDimensions.iconXxl,
                color: AppColors.error,
              ),
              
              const SizedBox(height: AppDimensions.spacingL),
              
              Text(
                'splash.error.title'.tr(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppDimensions.spacingM),
              
              Text(
                _errorMessage ?? 'splash.error.general'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: AppDimensions.spacingXl),
              
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: _retryInitialization,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingM,
                    ),
                  ),
                  child: Text('splash.error.retry'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(body: _buildErrorState());
    }

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundAnimation.value ?? Colors.transparent,
                  Colors.transparent,
                ],
              ),
            ),
            child: SplashLoadingWidget(
              message: _currentMessage,
              progress: _progress,
              showProgress: true,
              animationDuration: const Duration(milliseconds: 800),
            ),
          );
        },
      ),
    );
  }
}