import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'core/constants/app_constants.dart';
import 'core/enums/app_theme.dart';
import 'core/utils/logger.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/routes/app_router.dart';
import 'presentation/widgets/common/loading_widget.dart';

class MoneyManagerApp extends ConsumerStatefulWidget {
  const MoneyManagerApp({super.key});

  @override
  ConsumerState<MoneyManagerApp> createState() => _MoneyManagerAppState();
}

class _MoneyManagerAppState extends ConsumerState<MoneyManagerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load initial settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(settingsStateProvider.notifier).loadSettings();
      AppLogger.info('Money Manager app started');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.info('App lifecycle state changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _onAppResumed() {
    AppLogger.info('App resumed');
    // Refresh data, check for updates, etc.
  }

  void _onAppPaused() {
    AppLogger.info('App paused');
    // Save state, pause timers, etc.
  }

  void _onAppDetached() {
    AppLogger.info('App detached');
    // Clean up resources
  }

  @override
  Widget build(BuildContext context) {
    // Watch theme mode from settings
    final themeMode = ref.watch(currentThemeModeProvider);
    final settingsState = ref.watch(settingsStateProvider);

    return ShadApp.router(
      // App metadata
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      themeMode: themeMode,

      // Localization
      localizationsDelegates: [
        ...context.localizationDelegates,
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Navigation observers
      builder: (context, child) => _AppBuilder(
        child: child,
        settingsState: settingsState,
      ),

      // Error handling
      onGenerateTitle: (context) => 'app.name'.tr(),
    );
  }
}

/// App builder with global wrappers
class _AppBuilder extends StatelessWidget {
  final Widget? child;
  final SettingsState settingsState;

  const _AppBuilder({
    required this.child,
    required this.settingsState,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dismiss keyboard when tapping outside
      onTap: () {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          currentFocus.focusedChild?.unfocus();
        }
      },
      child: Stack(
        children: [
          // Main app content
          if (child != null) _ErrorBoundary(child: child!),

          // Global loading overlay
          if (settingsState.isLoading)
            LoadingOverlay(
              isLoading: settingsState.isLoading,
              child: const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

/// Error boundary to catch and handle widget errors
class _ErrorBoundary extends StatefulWidget {
  final Widget child;

  const _ErrorBoundary({required this.child});

  @override
  State<_ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<_ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();

    // Set up Flutter error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.error(
        'Flutter error caught by error boundary',
        details.exception,
        details.stack,
      );

      setState(() {
        _error = details.exception;
        _stackTrace = details.stack;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorScreen(
        error: _error!,
        stackTrace: _stackTrace,
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
      );
    }

    return widget.child;
  }
}

/// Error screen for runtime errors
class _ErrorScreen extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback onRetry;

  const _ErrorScreen({
    required this.error,
    required this.stackTrace,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.errorContainer,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'errors.general'.tr(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'errors.tryAgain'.tr(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      AppRouter.router.go('/');
                    },
                    child: Text('navigation.home'.tr()),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text('common.retry'.tr()),
                  ),
                ],
              ),
              if (kDebugMode && stackTrace != null) ...[
                const SizedBox(height: 32),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      'Error: $error\n\nStack trace:\n$stackTrace',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
