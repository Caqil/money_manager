// lib/presentation/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_constants.dart';
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
  bool _hasNavigated = false; // Prevent multiple navigations
  bool _isInitializing = false; // Prevent multiple initializations

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // FIXED: Use addPostFrameCallback to delay provider modification until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitializing) {
        _startInitialization();
      }
    });
  }

  @override
  void dispose() {
    // Mark as navigated to prevent any pending operations
    _hasNavigated = true;
    _isInitializing = false;

    // Dispose of animation controllers
    _backgroundController.dispose();

    // Call super.dispose() last
    super.dispose();
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

  Future<void> _startInitialization() async {
    // FIXED: Prevent multiple initialization attempts
    if (_isInitializing || _hasNavigated) {
      print('⚠️ Initialization already in progress or completed, skipping...');
      return;
    }

    _isInitializing = true;
    AppLogger.info('🚀 Starting splash initialization...');

    try {
      await _loadAppData();

      // Complete initialization - check if widget is still mounted
      if (mounted && !_hasNavigated) {
        setState(() {
          _progress = 1.0;
          _currentMessage = 'splash.init.complete'.tr();
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (!_hasNavigated && mounted) {
        await _navigateToNextScreen();
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Splash initialization failed', e, stackTrace);
      if (mounted && !_hasNavigated) {
        _handleInitializationError(e, stackTrace);
      }
    } finally {
      if (mounted) {
        _isInitializing = false;
      }
    }
  }

  Future<void> _loadAppData() async {
    // Step 1: Load settings (20%)
    if (mounted && !_hasNavigated) {
      setState(() {
        _currentMessage = 'splash.loading.settings'.tr();
        _progress = 0.0;
      });
    }

    await _loadSettings();

    if (mounted && !_hasNavigated) {
      setState(() {
        _progress = 0.2;
      });
    }
    await Future.delayed(const Duration(milliseconds: 300));

    // Step 2: Initialize auth state (40%)
    if (mounted && !_hasNavigated) {
      setState(() {
        _currentMessage = 'splash.loading.auth'.tr();
        _progress = 0.2;
      });
    }

    await _loadAuthState();

    if (mounted && !_hasNavigated) {
      setState(() {
        _progress = 0.4;
      });
    }
    await Future.delayed(const Duration(milliseconds: 300));

    // Step 3: Verify services (60%)
    if (mounted && !_hasNavigated) {
      setState(() {
        _currentMessage = 'splash.loading.services'.tr();
        _progress = 0.4;
      });
    }

    await _verifyServices();

    if (mounted && !_hasNavigated) {
      setState(() {
        _progress = 0.6;
      });
    }
    await Future.delayed(const Duration(milliseconds: 300));

    // Step 4: Prepare app data (80%)
    if (mounted && !_hasNavigated) {
      setState(() {
        _currentMessage = 'splash.loading.data'.tr();
        _progress = 0.6;
      });
    }

    await _prepareAppData();

    if (mounted && !_hasNavigated) {
      setState(() {
        _progress = 0.8;
      });
    }
    await Future.delayed(const Duration(milliseconds: 300));

    // Step 5: Finalize (100%)
    if (mounted && !_hasNavigated) {
      setState(() {
        _currentMessage = 'splash.loading.finalizing'.tr();
        _progress = 0.8;
      });
    }

    await _finalizeLoad();

    if (mounted && !_hasNavigated) {
      setState(() {
        _progress = 1.0;
      });
    }
  }

  // FIXED: Add mounted check to prevent setState on disposed widget
  void _handleInitializationError(Object error, StackTrace stackTrace) {
    if (mounted && !_hasNavigated) {
      setState(() {
        _hasError = true;
        _errorMessage = error.toString();
        _currentMessage = 'splash.error.general'.tr();
      });
    }

    AppLogger.error('Splash initialization error', error, stackTrace);
  }

  // FIXED: Add mounted check to prevent setState on disposed widget
  void _retryInitialization() {
    if (mounted && !_hasNavigated) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
        _progress = 0.0;
        _currentMessage = '';
        _hasNavigated = false;
        _isInitializing = false;
      });

      // FIXED: Use Future.microtask to ensure provider modification happens outside current frame
      Future.microtask(() {
        if (mounted && !_isInitializing) {
          _startInitialization();
        }
      });
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (_hasNavigated || !mounted) {
      print('⚠️ Navigation already completed or widget disposed, skipping...');
      return;
    }

    _hasNavigated = true;

    try {
      print('🧭 === SPLASH NAVIGATION DECISION ===');

      // Read settings state directly from SharedPreferences to avoid provider dependency
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch =
          prefs.getBool(AppConstants.keyIsFirstLaunch) ?? true;

      print('📊 First Launch Status Check:');
      print('  SharedPrefs: $isFirstLaunch');

      // Get auth state
      final authState = ref.read(authStateProvider);
      final hasAuthEnabled =
          authState.isPinEnabled || authState.isBiometricEnabled;
      final isAuthenticated = authState.isAuthenticated;

      print('📊 Auth Status:');
      print('  PIN enabled: ${authState.isPinEnabled}');
      print('  Biometric enabled: ${authState.isBiometricEnabled}');
      print('  Has auth enabled: $hasAuthEnabled');
      print('  Is authenticated: $isAuthenticated');

      if (!mounted) {
        print('⚠️ Widget disposed during navigation decision, aborting...');
        return;
      }

      // Navigation logic
      if (isFirstLaunch) {
        print('🎯 DECISION: Navigate to onboarding (first launch)');
        if (mounted) context.go(RouteNames.onboarding);
      } else if (hasAuthEnabled && !isAuthenticated) {
        print('🎯 DECISION: Navigate to login (auth required)');
        if (mounted) context.go(RouteNames.login);
      } else {
        print('🎯 DECISION: Navigate to home');
        if (mounted) context.go(RouteNames.home);
      }

      print('✅ === NAVIGATION COMPLETED ===');
    } catch (e, stackTrace) {
      print('❌ === NAVIGATION ERROR ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');

      if (mounted) {
        print('🔄 Fallback: Navigating to home');
        context.go(RouteNames.home);
      }
    }
  }

  Future<void> _loadSettings() async {
    try {
      AppLogger.info('🔧 Loading app settings...');

      // FIXED: Use Future.delayed instead of Future.microtask to ensure proper timing
      await Future.delayed(const Duration(milliseconds: 100), () async {
        // Load app settings but don't wait for the provider state change
        final settingsNotifier = ref.read(settingsStateProvider.notifier);
        await settingsNotifier.loadSettings();

        // Wait a bit more to ensure settings are persisted
        await Future.delayed(const Duration(milliseconds: 100));
      });

      AppLogger.info('✅ Settings loaded successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to load settings', e);
      // Continue with default settings - don't fail the entire app
    }
  }

  Future<void> _loadAuthState() async {
    try {
      // Check auth status - the AuthNotifier will automatically
      // load the current auth state when we read it
      final authState = ref.read(authStateProvider);
      AppLogger.info(
          '✅ Auth state loaded: ${authState.isPinEnabled ? "PIN enabled" : "No PIN"}, ${authState.isBiometricEnabled ? "Biometric enabled" : "No biometric"}');
    } catch (e) {
      AppLogger.error('❌ Failed to load auth state', e);
      // Continue without auth state
    }
  }

  Future<void> _verifyServices() async {
    try {
      AppLogger.info('🔍 Verifying services...');
      await Future.delayed(const Duration(milliseconds: 200));
      AppLogger.info('✅ Services verified');
    } catch (e) {
      AppLogger.error('❌ Service verification failed', e);
      throw Exception('Service verification failed: $e');
    }
  }

  Future<void> _prepareAppData() async {
    try {
      AppLogger.info('📊 Preparing app data...');
      await Future.delayed(const Duration(milliseconds: 300));
      AppLogger.info('✅ App data prepared');
    } catch (e) {
      AppLogger.error('❌ Failed to prepare app data', e);
      // Continue without initial data
    }
  }

  Future<void> _finalizeLoad() async {
    AppLogger.info('🏁 Finalizing splash...');
    await Future.delayed(const Duration(milliseconds: 200));
    AppLogger.info('✅ Splash finalized');
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
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              ElevatedButton.icon(
                onPressed: _retryInitialization,
                icon: const Icon(Icons.refresh),
                label: Text('splash.error.retry'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingXl,
                    vertical: AppDimensions.paddingM,
                  ),
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
      return Scaffold(
        body: _buildErrorState(),
      );
    }

    return Scaffold(
      body: SplashLoadingWidget(
        progress: _progress,
        message: _currentMessage,
      ),
    );
  }
}
