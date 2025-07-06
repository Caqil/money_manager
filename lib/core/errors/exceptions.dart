abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}

// Database Exceptions
class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.code,
    super.details,
  });
}

class TransactionNotFoundException extends DatabaseException {
   TransactionNotFoundException({
    required String transactionId,
  }) : super(
          message: 'Transaction not found',
          code: 'TRANSACTION_NOT_FOUND',
          details: {'transactionId': transactionId},
        );
}

class AccountNotFoundException extends DatabaseException {
   AccountNotFoundException({
    required String accountId,
  }) : super(
          message: 'Account not found',
          code: 'ACCOUNT_NOT_FOUND',
          details: {'accountId': accountId},
        );
}

class BudgetNotFoundException extends DatabaseException {
   BudgetNotFoundException({
    required String budgetId,
  }) : super(
          message: 'Budget not found',
          code: 'BUDGET_NOT_FOUND',
          details: {'budgetId': budgetId},
        );
}

class CategoryNotFoundException extends DatabaseException {
   CategoryNotFoundException({
    required String categoryId,
  }) : super(
          message: 'Category not found',
          code: 'CATEGORY_NOT_FOUND',
          details: {'categoryId': categoryId},
        );
}

// Validation Exceptions
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    super.details,
  });
}

class InvalidAmountException extends ValidationException {
  InvalidAmountException({
    required double amount,
  }) : super(
          message: 'Invalid amount',
          details: {'amount': amount},
        );
}

class InsufficientFundsException extends ValidationException {
  InsufficientFundsException({
    required double available,
    required double requested,
  }) : super(
          message: 'Insufficient funds',
          code: 'INSUFFICIENT_FUNDS',
          details: {
            'available': available,
            'requested': requested,
          },
        );
}

// File Exceptions
class FileException extends AppException {
  const FileException({
    required super.message,
    super.code = 'FILE_ERROR',
    super.details,
  });
}

class FileNotFoundAppException extends FileException {
   FileNotFoundAppException({
    required String filePath,
  }) : super(
          message: 'File not found',
          code: 'FILE_NOT_FOUND',
          details: {'filePath': filePath},
        );
}

class FileSizeExceededException extends FileException {
   FileSizeExceededException({
    required int maxSize,
    required int actualSize,
  }) : super(
          message: 'File size exceeded',
          code: 'FILE_SIZE_EXCEEDED',
          details: {
            'maxSize': maxSize,
            'actualSize': actualSize,
          },
        );
}

// Authentication Exceptions
class AuthenticationException extends AppException {
  const AuthenticationException({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.details,
  });
}

class BiometricNotAvailableException extends AuthenticationException {
  const BiometricNotAvailableException()
      : super(
          message: 'Biometric authentication not available',
          code: 'BIOMETRIC_NOT_AVAILABLE',
        );
}

class AuthenticationFailedException extends AuthenticationException {
  const AuthenticationFailedException()
      : super(
          message: 'Authentication failed',
          code: 'AUTH_FAILED',
        );
}

// Encryption Exceptions
class EncryptionException extends AppException {
  const EncryptionException({
    required super.message,
    super.code = 'ENCRYPTION_ERROR',
    super.details,
  });
}

class DecryptionException extends AppException {
  const DecryptionException({
    required super.message,
    super.code = 'DECRYPTION_ERROR',
    super.details,
  });
}

// Network Exceptions (for future use)
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.details,
  });
}

class NoInternetException extends NetworkException {
  const NoInternetException()
      : super(
          message: 'No internet connection',
          code: 'NO_INTERNET',
        );
}

// Permission Exceptions
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code = 'PERMISSION_ERROR',
    super.details,
  });
}

class StoragePermissionDeniedException extends PermissionException {
  const StoragePermissionDeniedException()
      : super(
          message: 'Storage permission denied',
          code: 'STORAGE_PERMISSION_DENIED',
        );
}

class CameraPermissionDeniedException extends PermissionException {
  const CameraPermissionDeniedException()
      : super(
          message: 'Camera permission denied',
          code: 'CAMERA_PERMISSION_DENIED',
        );
}
