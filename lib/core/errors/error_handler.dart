import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../utils/logger.dart';

class ErrorHandler {
  ErrorHandler._();

  static void handleError(Object error, StackTrace stackTrace) {
    AppLogger.error('Unhandled error', error, stackTrace);

    // In debug mode, show the error details
    if (kDebugMode) {
      FlutterError.presentError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Money Manager',
          context: ErrorDescription('Unhandled error'),
        ),
      );
    }

    // Report to crash analytics service if available
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  static void showErrorDialog(BuildContext context, Object error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(
          kDebugMode
              ? error.toString()
              : 'An unexpected error occurred. Please try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, Object error) {
    final sonner = ShadSonner.of(context);
    sonner.show(
      ShadToast(
        description: Text(
          kDebugMode
              ? error.toString()
              : 'An unexpected error occurred. Please try again.',
        ),
      ),
    );
  }
}
