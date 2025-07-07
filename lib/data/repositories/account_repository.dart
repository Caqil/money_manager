// lib/data/repositories/account_repository.dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/account.dart';
import '../services/hive_service.dart';
import '../services/encryption_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

class AccountRepository {
  static const _uuid = Uuid();
  late final HiveService _hiveService;
  late final EncryptionService _encryptionService;

  AccountRepository({
    HiveService? hiveService,
    EncryptionService? encryptionService,
  }) {
    _hiveService = hiveService ?? HiveService();
    _encryptionService = encryptionService ?? EncryptionService();
  }

  Future<Box<Account>> get _accountsBox async {
    return await _hiveService.getBox<Account>(AppConstants.hiveBoxAccounts);
  }

  // Add account - FIXED with complete implementation
  Future<String> addAccount(Account account) async {
    try {
      // Validate account data before saving
      _validateAccount(account);

      final box = await _accountsBox;

      // Ensure box is open and accessible
      if (!box.isOpen) {
        throw DatabaseException(message: 'Account database is not available');
      }

      final id = account.id.isEmpty ? _uuid.v4() : account.id;
      final now = DateTime.now();

      final newAccount = account.copyWith(
        id: id,
        createdAt: account.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
            ? now
            : account.createdAt,
        updatedAt: now,
      );

      // Encrypt sensitive data if encryption is enabled
      final encryptedAccount = await _encryptAccountIfNeeded(newAccount);

      await box.put(id, encryptedAccount);

      print('✅ Account created successfully: ${newAccount.name} (ID: $id)');
      return id;
    } catch (e) {
      print('❌ Failed to add account: $e');
      if (e is ValidationException || e is DatabaseException) {
        rethrow;
      }
      throw DatabaseException(message: 'Failed to add account: $e');
    }
  }

  // Validate account data
  void _validateAccount(Account account) {
    if (account.name.trim().isEmpty) {
      throw ValidationException(message: 'Account name is required');
    }

    if (account.name.trim().length < 2) {
      throw ValidationException(
          message: 'Account name must be at least 2 characters');
    }

    if (account.currency.trim().isEmpty) {
      throw ValidationException(message: 'Currency is required');
    }

    // Additional validation for credit card accounts
    if (account.type == AccountType.creditCard && account.creditLimit != null) {
      if (account.creditLimit! <= 0) {
        throw ValidationException(message: 'Credit limit must be positive');
      }
    }
  }

  // Update account
  Future<void> updateAccount(Account account) async {
    try {
      _validateAccount(account);

      final box = await _accountsBox;

      if (!box.containsKey(account.id)) {
        throw AccountNotFoundException(accountId: account.id);
      }

      final updatedAccount = account.copyWith(updatedAt: DateTime.now());

      // Encrypt sensitive data if encryption is enabled
      final encryptedAccount = await _encryptAccountIfNeeded(updatedAccount);

      await box.put(account.id, encryptedAccount);

      print('✅ Account updated successfully: ${updatedAccount.name}');
    } catch (e) {
      print('❌ Failed to update account: $e');
      if (e is AccountNotFoundException || e is ValidationException) rethrow;
      throw DatabaseException(message: 'Failed to update account: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount(String id) async {
    try {
      final box = await _accountsBox;

      if (!box.containsKey(id)) {
        throw AccountNotFoundException(accountId: id);
      }

      await box.delete(id);
      print('✅ Account deleted successfully: $id');
    } catch (e) {
      print('❌ Failed to delete account: $e');
      if (e is AccountNotFoundException) rethrow;
      throw DatabaseException(message: 'Failed to delete account: $e');
    }
  }

  Future<void> transferBetweenAccounts(
    String fromAccountId,
    String toAccountId,
    double amount,
  ) async {
    try {
      if (amount <= 0) {
        throw InvalidAmountException(amount: amount);
      }

      // Use a transaction-like approach
      final fromAccount = await getAccountById(fromAccountId);
      final toAccount = await getAccountById(toAccountId);

      if (fromAccount == null) {
        throw AccountNotFoundException(accountId: fromAccountId);
      }
      if (toAccount == null) {
        throw AccountNotFoundException(accountId: toAccountId);
      }

      // Check insufficient funds for non-credit accounts
      if (fromAccount.type != AccountType.creditCard &&
          fromAccount.balance < amount) {
        throw InsufficientFundsException(
          available: fromAccount.balance,
          requested: amount,
        );
      }

      // Perform transfer
      await subtractFromAccountBalance(fromAccountId, amount);
      await addToAccountBalance(toAccountId, amount);
    } catch (e) {
      rethrow;
    }
  }

  // Add to account balance
  Future<void> addToAccountBalance(String accountId, double amount) async {
    try {
      final account = await getAccountById(accountId);
      if (account == null) {
        throw AccountNotFoundException(accountId: accountId);
      }

      final newBalance = account.balance + amount;
      await updateAccountBalance(accountId, newBalance);
    } catch (e) {
      if (e is AccountNotFoundException) rethrow;
      throw DatabaseException(message: 'Failed to add to account balance: $e');
    }
  }

  // Subtract from account balance
  Future<void> subtractFromAccountBalance(
      String accountId, double amount) async {
    try {
      final account = await getAccountById(accountId);
      if (account == null) {
        throw AccountNotFoundException(accountId: accountId);
      }

      final newBalance = account.balance - amount;

      // Check for insufficient funds for non-credit accounts
      if (account.type != AccountType.creditCard && newBalance < 0) {
        throw InsufficientFundsException(
          available: account.balance,
          requested: amount,
        );
      }

      await updateAccountBalance(accountId, newBalance);
    } catch (e) {
      if (e is AccountNotFoundException || e is InsufficientFundsException)
        rethrow;
      throw DatabaseException(
          message: 'Failed to subtract from account balance: $e');
    }
  }

  // Get account by ID
  Future<Account?> getAccountById(String id) async {
    try {
      final box = await _accountsBox;
      final account = box.get(id);

      if (account == null) return null;

      // Decrypt if needed
      return await _decryptAccountIfNeeded(account);
    } catch (e) {
      print('❌ Failed to get account: $e');
      throw DatabaseException(message: 'Failed to get account: $e');
    }
  }

  // Get all accounts
  Future<List<Account>> getAllAccounts() async {
    try {
      final box = await _accountsBox;
      final accounts = box.values.toList();

      // Decrypt all accounts if needed
      final decryptedAccounts = <Account>[];
      for (final account in accounts) {
        final decrypted = await _decryptAccountIfNeeded(account);
        decryptedAccounts.add(decrypted);
      }

      // Sort by creation date (newest first)
      decryptedAccounts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return decryptedAccounts;
    } catch (e) {
      print('❌ Failed to get accounts: $e');
      throw DatabaseException(message: 'Failed to get accounts: $e');
    }
  }

  // Get active accounts
  Future<List<Account>> getActiveAccounts() async {
    try {
      final allAccounts = await getAllAccounts();
      return allAccounts.where((account) => account.isActive).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get active accounts: $e');
    }
  }

  // Get accounts by type
  Future<List<Account>> getAccountsByType(AccountType type) async {
    try {
      final allAccounts = await getAllAccounts();
      return allAccounts.where((account) => account.type == type).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get accounts by type: $e');
    }
  }

  // Get accounts included in total
  Future<List<Account>> getAccountsIncludedInTotal() async {
    try {
      final allAccounts = await getAllAccounts();
      return allAccounts
          .where((account) => account.isActive && account.includeInTotal)
          .toList();
    } catch (e) {
      throw DatabaseException(
          message: 'Failed to get accounts included in total: $e');
    }
  }

  // Update account balance
  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    try {
      final account = await getAccountById(accountId);
      if (account == null) {
        throw AccountNotFoundException(accountId: accountId);
      }

      final updatedAccount = account.copyWith(
        balance: newBalance,
        updatedAt: DateTime.now(),
      );

      await updateAccount(updatedAccount);
    } catch (e) {
      if (e is AccountNotFoundException) rethrow;
      throw DatabaseException(message: 'Failed to update account balance: $e');
    }
  }

  // Deactivate account
  Future<void> deactivateAccount(String id) async {
    try {
      final account = await getAccountById(id);
      if (account == null) {
        throw AccountNotFoundException(accountId: id);
      }

      final deactivatedAccount = account.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      await updateAccount(deactivatedAccount);
    } catch (e) {
      if (e is AccountNotFoundException) rethrow;
      throw DatabaseException(message: 'Failed to deactivate account: $e');
    }
  }

  // Activate account
  Future<void> activateAccount(String id) async {
    try {
      final account = await getAccountById(id);
      if (account == null) {
        throw AccountNotFoundException(accountId: id);
      }

      final activatedAccount = account.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );

      await updateAccount(activatedAccount);
    } catch (e) {
      if (e is AccountNotFoundException) rethrow;
      throw DatabaseException(message: 'Failed to activate account: $e');
    }
  }

  // Clear all accounts
  Future<void> clearAllAccounts() async {
    try {
      final box = await _accountsBox;
      await box.clear();
      print('✅ All accounts cleared');
    } catch (e) {
      throw DatabaseException(message: 'Failed to clear accounts: $e');
    }
  }

  // Get accounts count
  Future<int> getAccountsCount() async {
    try {
      final box = await _accountsBox;
      return box.length;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get accounts count: $e');
    }
  }

  // Helper methods for encryption
  Future<Account> _encryptAccountIfNeeded(Account account) async {
    try {
      if (!_encryptionService.isEncryptionEnabled) {
        return account;
      }

      // Encrypt sensitive fields
      final encryptedBalance =
          await _encryptionService.encryptDouble(account.balance);
      final encryptedAccountNumber = account.accountNumber != null
          ? await _encryptionService.encryptString(account.accountNumber!)
          : null;

      return account.copyWith(
        metadata: {
          ...?account.metadata,
          'encrypted_balance': encryptedBalance,
          'encrypted_account_number': encryptedAccountNumber,
          'is_encrypted': true,
        },
      );
    } catch (e) {
      print('⚠️ Encryption failed, saving unencrypted: $e');
      // If encryption fails, save unencrypted (with warning)
      return account;
    }
  }

  Future<Account> _decryptAccountIfNeeded(Account account) async {
    try {
      if (!_encryptionService.isEncryptionEnabled ||
          account.metadata?['is_encrypted'] != true) {
        return account;
      }

      // Decrypt sensitive fields
      final encryptedBalance =
          account.metadata?['encrypted_balance'] as String?;
      final encryptedAccountNumber =
          account.metadata?['encrypted_account_number'] as String?;

      final decryptedBalance = encryptedBalance != null
          ? await _encryptionService.decryptDouble(encryptedBalance)
          : account.balance;

      final decryptedAccountNumber = encryptedAccountNumber != null
          ? await _encryptionService.decryptString(encryptedAccountNumber)
          : account.accountNumber;

      final newMetadata = account.metadata == null
          ? null
          : Map<String, dynamic>.from(account.metadata!);

      newMetadata?.remove('encrypted_balance');
      newMetadata?.remove('encrypted_account_number');
      newMetadata?.remove('is_encrypted');

      return account.copyWith(
        balance: decryptedBalance,
        accountNumber: decryptedAccountNumber,
        metadata: newMetadata?.isEmpty == true ? null : newMetadata,
      );
    } catch (e) {
      print('⚠️ Decryption failed, returning encrypted data: $e');
      // If decryption fails, return the account as-is
      return account;
    }
  }
}
