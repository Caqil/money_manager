import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic details;

  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

// Database Failures
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.code = 'DATABASE_FAILURE',
    super.details,
  });
}

class TransactionFailure extends DatabaseFailure {
  const TransactionFailure({
    required super.message,
    super.code = 'TRANSACTION_FAILURE',
    super.details,
  });
}

class AccountFailure extends DatabaseFailure {
  const AccountFailure({
    required super.message,
    super.code = 'ACCOUNT_FAILURE',
    super.details,
  });
}

class BudgetFailure extends DatabaseFailure {
  const BudgetFailure({
    required super.message,
    super.code = 'BUDGET_FAILURE',
    super.details,
  });
}

class CategoryFailure extends DatabaseFailure {
  const CategoryFailure({
    required super.message,
    super.code = 'CATEGORY_FAILURE',
    super.details,
  });
}

// Validation Failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_FAILURE',
    super.details,
  });
}

class InputValidationFailure extends ValidationFailure {
  final Map<String, String> fieldErrors;

  const InputValidationFailure({
    required super.message,
    required this.fieldErrors,
    super.code = 'INPUT_VALIDATION_FAILURE',
  }) : super(details: fieldErrors);
}

// File Failures
class FileFailure extends Failure {
  const FileFailure({
    required super.message,
    super.code = 'FILE_FAILURE',
    super.details,
  });
}

class ImportFailure extends FileFailure {
  const ImportFailure({
    required super.message,
    super.code = 'IMPORT_FAILURE',
    super.details,
  });
}

class ExportFailure extends FileFailure {
  const ExportFailure({
    required super.message,
    super.code = 'EXPORT_FAILURE',
    super.details,
  });
}

// Authentication Failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.message,
    super.code = 'AUTH_FAILURE',
    super.details,
  });
}

class BiometricFailure extends AuthenticationFailure {
  const BiometricFailure({
    required super.message,
    super.code = 'BIOMETRIC_FAILURE',
    super.details,
  });
}

// Encryption Failures
class EncryptionFailure extends Failure {
  const EncryptionFailure({
    required super.message,
    super.code = 'ENCRYPTION_FAILURE',
    super.details,
  });
}

// Network Failures (for future use)
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code = 'NETWORK_FAILURE',
    super.details,
  });
}

// Permission Failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code = 'PERMISSION_FAILURE',
    super.details,
  });
}

// Unknown Failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unknown error occurred',
    super.code = 'UNKNOWN_FAILURE',
    super.details,
  });
}

