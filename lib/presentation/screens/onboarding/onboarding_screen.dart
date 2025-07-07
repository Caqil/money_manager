// lib/presentation/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';
import '../../routes/route_names.dart';
import '../auth/pin_setup_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _buttonController;
  late Animation<double> _buttonAnimation;

  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasCompleted = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Welcome to Money Manager',
      subtitle: 'Your Personal Finance Companion',
      description:
          'Take control of your finances with our comprehensive money management app.',
    ),
    OnboardingPage(
      icon: Icons.trending_up_rounded,
      title: 'Powerful Features',
      subtitle: 'Everything You Need',
      description:
          'Track transactions, create budgets, and get insights to make better financial decisions.',
    ),
    OnboardingPage(
      icon: Icons.security_rounded,
      title: 'Bank-Level Security',
      subtitle: 'Your Data is Safe',
      description:
          'Your financial data is protected with PIN codes and encrypted local storage.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _buttonAnimation = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    );
    _buttonController.forward();

    print('🎯 OnboardingScreen: Initialized');

    // Debug check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugCurrentState();
    });
  }

  Future<void> _debugCurrentState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch =
          prefs.getBool(AppConstants.keyIsFirstLaunch) ?? true;
      print('🔍 OnboardingScreen: Current isFirstLaunch = $isFirstLaunch');
    } catch (e) {
      print('❌ OnboardingScreen: Error checking state: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_isLoading || _hasCompleted) return;

    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_isLoading || _hasCompleted) return;

    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // COMPLETELY NEW APPROACH: Navigate to setup completion screen
  Future<void> _completeOnboarding() async {
    if (_hasCompleted) return;
    _hasCompleted = true;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🚀 OnboardingScreen: Starting completion...');

      // Show PIN setup dialog first
      final shouldSetupPin = await _showPinSetupDialog();

      if (shouldSetupPin && mounted) {
        print('🔐 OnboardingScreen: Setting up PIN...');
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PinSetupScreen(
              isFirstTimeSetup: true,
            ),
          ),
        );
      }

      if (mounted) {
        print('🔧 OnboardingScreen: Updating state...');

        // STEP 1: Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.keyIsFirstLaunch, false);

        // Force commit on Android
        try {
          await prefs.commit();
        } catch (e) {
          print('⚠️ Commit not available: $e');
        }

        // Set additional safety indicators
        await prefs.setBool('app_setup_completed', true);
        await prefs.setInt('setup_completion_timestamp',
            DateTime.now().millisecondsSinceEpoch);

        // STEP 2: Update providers
        try {
          final settingsNotifier = ref.read(settingsStateProvider.notifier);
          await settingsNotifier.setIsFirstLaunch(false);
          await settingsNotifier.loadSettings();
          print('✅ OnboardingScreen: Providers updated');
        } catch (e) {
          print('⚠️ OnboardingScreen: Provider update failed: $e');
        }

        // STEP 3: Wait to ensure persistence
        await Future.delayed(const Duration(milliseconds: 500));

        // STEP 4: Verify the changes
        final verification = prefs.getBool(AppConstants.keyIsFirstLaunch);
        print(
            '🔍 OnboardingScreen: Final verification: isFirstLaunch = $verification');

        if (verification != false) {
          throw Exception('State update verification failed!');
        }

        print('✅ OnboardingScreen: Setup completed successfully!');

        // STEP 5: Navigate to home using go_router
        if (mounted) {
          print('🏠 OnboardingScreen: Navigating to home...');
          context.go(RouteNames.home);
          print('✅ OnboardingScreen: Navigation completed!');
        }
      }
    } catch (e, stackTrace) {
      print('❌ OnboardingScreen: Error during completion: $e');
      print('StackTrace: $stackTrace');
      _hasCompleted = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _completeOnboarding(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showPinSetupDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Security Setup'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Would you like to set up a PIN to secure your financial data?'),
                SizedBox(height: 16),
                Text(
                  'This is optional. You can set it up later in settings.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Skip for Now'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Set Up PIN'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousPage,
                child: const Text('Back'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextPage,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_currentPage == _pages.length - 1
                      ? 'Get Started'
                      : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isLoading,
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      if (!_isLoading) {
                        setState(() {
                          _currentPage = index;
                        });
                        _buttonController.reset();
                        _buttonController.forward();
                      }
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.paddingL),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: Icon(
                                  page.icon,
                                  size: 60,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                page.title,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                page.subtitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                page.description,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildPageIndicator(),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Setting up your app...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class OnboardingCompletionScreen extends ConsumerStatefulWidget {
  const OnboardingCompletionScreen({super.key});

  @override
  ConsumerState<OnboardingCompletionScreen> createState() =>
      _OnboardingCompletionScreenState();
}

class _OnboardingCompletionScreenState
    extends ConsumerState<OnboardingCompletionScreen> {
  @override
  void initState() {
    super.initState();
    print('🏁 OnboardingCompletionScreen: Starting...');

    // Start the completion process immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _completeSetup();
    });
  }

  Future<void> _completeSetup() async {
    try {
      print('🔧 OnboardingCompletionScreen: Updating state...');

      // STEP 1: Update SharedPreferences with multiple methods
      final prefs = await SharedPreferences.getInstance();

      // Method 1: Standard setBool
      await prefs.setBool(AppConstants.keyIsFirstLaunch, false);

      // Method 2: Force commit (Android)
      try {
        await prefs.commit();
      } catch (e) {
        print('⚠️ Commit not available: $e');
      }

      // Method 3: Set multiple indicators for safety
      await prefs.setBool('app_setup_completed', true);
      await prefs.setInt(
          'setup_completion_timestamp', DateTime.now().millisecondsSinceEpoch);

      // STEP 2: Verify the changes
      final verification1 = prefs.getBool(AppConstants.keyIsFirstLaunch);
      final verification2 = prefs.getBool('app_setup_completed');

      print('🔍 OnboardingCompletionScreen: Verification:');
      print('  isFirstLaunch: $verification1');
      print('  setupCompleted: $verification2');

      if (verification1 != false || verification2 != true) {
        throw Exception('State update verification failed!');
      }

      // STEP 3: Update providers
      try {
        final settingsNotifier = ref.read(settingsStateProvider.notifier);
        await settingsNotifier.setIsFirstLaunch(false);
        await settingsNotifier.loadSettings(); // Force reload
        print('✅ OnboardingCompletionScreen: Providers updated');
      } catch (e) {
        print('⚠️ OnboardingCompletionScreen: Provider update failed: $e');
      }

      // STEP 4: Wait to ensure persistence
      await Future.delayed(const Duration(milliseconds: 1000));

      // STEP 5: Final verification
      final finalCheck1 = prefs.getBool(AppConstants.keyIsFirstLaunch);
      final finalCheck2 = prefs.getBool('app_setup_completed');

      print('🔍 OnboardingCompletionScreen: Final verification:');
      print('  isFirstLaunch: $finalCheck1');
      print('  setupCompleted: $finalCheck2');

      if (finalCheck1 != false || finalCheck2 != true) {
        throw Exception('Final verification failed!');
      }

      print('✅ OnboardingCompletionScreen: All checks passed!');

      // STEP 6: Navigate to home using go_router (FIXED)
      if (mounted) {
        print('🏠 OnboardingCompletionScreen: Navigating to home...');

        // FIXED: Use go_router's declarative navigation instead of imperative
        // This clears the entire navigation stack and goes to home
        context.go(RouteNames.home);

        print('✅ OnboardingCompletionScreen: Navigation completed!');
      }
    } catch (e, stackTrace) {
      print('❌ OnboardingCompletionScreen: Setup failed!');
      print('Error: $e');
      print('StackTrace: $stackTrace');

      if (mounted) {
        // FIXED: Also use go_router for error navigation
        // Show error dialog and then navigate back to onboarding
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Setup Error'),
            content: Text('Failed to complete setup: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  context.go(RouteNames.onboarding); // Go back to onboarding
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 24),
            Text(
              'Completing Setup...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This will only take a moment',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;

  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}
