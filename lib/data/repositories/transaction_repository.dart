// ==========================================
// REPOSITORIES
// ==========================================

// ==========================================
// 1. lib/data/repositories/transaction_repository.dart
// ==========================================

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import '../services/hive_service.dart';
import 'account_repository.dart';
// TEMPORARILY DISABLED: Remove encryption service import to fix persistence issues
// import '../services/encryption_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

class TransactionRepository {
  static const _uuid = Uuid();
  late final HiveService _hiveService;
  late final AccountRepository _accountRepository;
  // TEMPORARILY DISABLED: Remove encryption service to fix persistence issues
  // late final EncryptionService _encryptionService;

  TransactionRepository({
    HiveService? hiveService,
    AccountRepository? accountRepository,
    // TEMPORARILY DISABLED: Remove encryption service parameter to fix persistence issues
    // EncryptionService? encryptionService, // Keep parameter for future use
  }) {
    _hiveService = hiveService ?? HiveService();
    _accountRepository = accountRepository ?? AccountRepository();
    // TEMPORARILY DISABLED: Don't initialize encryption service
    // _encryptionService = encryptionService ?? EncryptionService();
  }

  // Get transactions box
  Future<Box<Transaction>> get _transactionsBox async {
    return await _hiveService
        .getBox<Transaction>(AppConstants.hiveBoxTransactions);
  }

  // Add transaction
  Future<String> addTransaction(Transaction transaction) async {
    print('🔄 Repository: Starting addTransaction');
    print(
        '📝 Transaction: ID=${transaction.id}, Amount=${transaction.amount}, Type=${transaction.type}');

    try {
      print('📦 Getting transactions box...');
      final box = await _transactionsBox;
      print('✅ Got transactions box');

      final id = transaction.id.isEmpty ? _uuid.v4() : transaction.id;
      final now = DateTime.now();
      print('🆔 Generated ID: $id');

      final newTransaction = transaction.copyWith(
        id: id,
        createdAt:
            transaction.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
                ? now
                : transaction.createdAt,
        updatedAt: now,
      );
      print('🔄 Created new transaction object');

      // Encrypt sensitive data if encryption is enabled
      print('🔐 Encrypting transaction...');
      // TEMPORARILY SKIP ENCRYPTION FOR DEBUGGING
      final encryptedTransaction = newTransaction;
      // final encryptedTransaction = await _encryptTransactionIfNeeded(newTransaction);
      print('✅ Encryption completed (skipped for debugging)');

      print('💾 Storing transaction in box...');
      await box.put(id, encryptedTransaction);

      // Force flush to disk to ensure persistence
      print('💾 Flushing data to disk...');
      await box.flush();
      print('✅ Transaction stored and flushed successfully with ID: $id');

      // Update account balance based on transaction type
      print('💰 Updating account balance...');
      await _updateAccountBalanceForTransaction(encryptedTransaction,
          isAdd: true);
      print('✅ Account balance updated successfully');

      return id;
    } catch (e) {
      print('❌ Repository error: $e');
      throw DatabaseException(message: 'Failed to add transaction: $e');
    }
  }

  // Update transaction
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      final box = await _transactionsBox;

      if (!box.containsKey(transaction.id)) {
        throw TransactionNotFoundException(transactionId: transaction.id);
      }

      // Get the old transaction for balance reversal
      final oldTransaction = box.get(transaction.id);
      if (oldTransaction == null) {
        throw TransactionNotFoundException(transactionId: transaction.id);
      }

      final updatedTransaction = transaction.copyWith(
        updatedAt: DateTime.now(),
      );

      // TEMPORARILY DISABLED: Skip encryption to fix persistence issues
      // final encryptedTransaction = await _encryptTransactionIfNeeded(updatedTransaction);
      final encryptedTransaction = updatedTransaction;

      await box.put(transaction.id, encryptedTransaction);

      // Force flush to disk to ensure persistence
      await box.flush();

      // Update account balances: reverse old transaction, apply new one
      print('💰 Updating account balance for transaction update...');
      await _updateAccountBalanceForTransaction(oldTransaction, isAdd: false);
      await _updateAccountBalanceForTransaction(encryptedTransaction,
          isAdd: true);
      print('✅ Account balance updated successfully');
    } catch (e) {
      if (e is TransactionNotFoundException) rethrow;
      throw DatabaseException(message: 'Failed to update transaction: $e');
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    try {
      final box = await _transactionsBox;

      if (!box.containsKey(id)) {
        throw TransactionNotFoundException(transactionId: id);
      }

      // Get the transaction before deleting for balance reversal
      final transaction = box.get(id);
      if (transaction == null) {
        throw TransactionNotFoundException(transactionId: id);
      }

      await box.delete(id);

      // Force flush to disk to ensure persistence
      await box.flush();

      // Reverse the account balance changes
      print('💰 Reversing account balance for deleted transaction...');
      await _updateAccountBalanceForTransaction(transaction, isAdd: false);
      print('✅ Account balance updated successfully');
    } catch (e) {
      if (e is TransactionNotFoundException) rethrow;
      throw DatabaseException(message: 'Failed to delete transaction: $e');
    }
  }

  // Get transaction by ID
  Future<Transaction?> getTransactionById(String id) async {
    try {
      final box = await _transactionsBox;
      final transaction = box.get(id);

      if (transaction == null) return null;

      // TEMPORARILY DISABLED: Skip decryption to fix persistence issues
      // return await _decryptTransactionIfNeeded(transaction);
      return transaction;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get transaction: $e');
    }
  }

  // Get all transactions with optimized performance and lazy loading
  Future<List<Transaction>> getAllTransactions() async {
    try {
      print('📦 Repository: Getting transactions box...');
      final box = await _transactionsBox;
      print('✅ Repository: Got transactions box, has ${box.length} items');

      // Use more efficient bulk operations
      final transactions = <Transaction>[];
      final allValues = box.values;
      print('📋 Repository: Processing ${allValues.length} transactions...');

      // Process transactions asynchronously in smaller chunks
      await for (final chunk in _processInChunks(allValues, 50)) {
        for (final transaction in chunk) {
          try {
            // TEMPORARILY DISABLED: Skip decryption to fix persistence issues
            // final decrypted = await _decryptTransactionIfNeeded(transaction);
            final decrypted = transaction;
            transactions.add(decrypted);
          } catch (e) {
            print(
                '⚠️ Repository: Error processing transaction ${transaction.id}: $e');
            // Skip corrupted transactions but continue processing
            continue;
          }
        }

        // Give other tasks a chance to run
        await Future.delayed(const Duration(microseconds: 1));
      }

      // Pre-sort by date (newest first) for better performance in UI
      transactions.sort((a, b) => b.date.compareTo(a.date));
      print('✅ Repository: Returning ${transactions.length} transactions');

      return transactions;
    } catch (e) {
      print('❌ Repository: Error in getAllTransactions: $e');
      throw DatabaseException(message: 'Failed to get transactions: $e');
    }
  }

  // Helper method to process items in chunks
  Stream<List<Transaction>> _processInChunks(
      Iterable<Transaction> items, int chunkSize) async* {
    final list = items.toList();
    for (int i = 0; i < list.length; i += chunkSize) {
      yield list.skip(i).take(chunkSize).toList();
    }
  }

  // Get transactions by date range
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allTransactions = await getAllTransactions();

      return allTransactions.where((transaction) {
        return transaction.date
                .isAfter(startDate.subtract(const Duration(days: 1))) &&
            transaction.date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      throw DatabaseException(
          message: 'Failed to get transactions by date range: $e');
    }
  }

  // Get transactions by account
  Future<List<Transaction>> getTransactionsByAccount(String accountId) async {
    try {
      final allTransactions = await getAllTransactions();

      return allTransactions.where((transaction) {
        return transaction.accountId == accountId ||
            transaction.transferToAccountId == accountId;
      }).toList();
    } catch (e) {
      throw DatabaseException(
          message: 'Failed to get transactions by account: $e');
    }
  }

  // Get transactions by category
  Future<List<Transaction>> getTransactionsByCategory(String categoryId) async {
    try {
      final allTransactions = await getAllTransactions();

      return allTransactions.where((transaction) {
        return transaction.categoryId == categoryId;
      }).toList();
    } catch (e) {
      throw DatabaseException(
          message: 'Failed to get transactions by category: $e');
    }
  }

  // Get transactions by type
  Future<List<Transaction>> getTransactionsByType(TransactionType type) async {
    try {
      final allTransactions = await getAllTransactions();

      return allTransactions.where((transaction) {
        return transaction.type == type;
      }).toList();
    } catch (e) {
      throw DatabaseException(
          message: 'Failed to get transactions by type: $e');
    }
  }

  // Search transactions
  Future<List<Transaction>> searchTransactions(String query) async {
    try {
      final allTransactions = await getAllTransactions();
      final lowercaseQuery = query.toLowerCase();

      return allTransactions.where((transaction) {
        final notes = transaction.notes?.toLowerCase() ?? '';
        return notes.contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to search transactions: $e');
    }
  }

  // Get recent transactions
  Future<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    try {
      final allTransactions = await getAllTransactions();

      return allTransactions.take(limit).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get recent transactions: $e');
    }
  }

  // Get transactions count
  Future<int> getTransactionsCount() async {
    try {
      final box = await _transactionsBox;
      return box.length;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get transactions count: $e');
    }
  }

  // Get total income/expense amounts
  Future<Map<TransactionType, double>> getTotalAmountsByType({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<Transaction> transactions;

      if (startDate != null && endDate != null) {
        transactions = await getTransactionsByDateRange(startDate, endDate);
      } else {
        transactions = await getAllTransactions();
      }

      final totals = <TransactionType, double>{
        TransactionType.income: 0.0,
        TransactionType.expense: 0.0,
        TransactionType.transfer: 0.0,
      };

      for (final transaction in transactions) {
        totals[transaction.type] =
            (totals[transaction.type] ?? 0.0) + transaction.amount;
      }

      return totals;
    } catch (e) {
      throw DatabaseException(
          message: 'Failed to get total amounts by type: $e');
    }
  }

  // Clear all transactions
  Future<void> clearAllTransactions() async {
    try {
      final box = await _transactionsBox;
      await box.clear();
    } catch (e) {
      throw DatabaseException(message: 'Failed to clear transactions: $e');
    }
  }

  // Batch operations
  Future<void> addTransactionsBatch(List<Transaction> transactions) async {
    try {
      final box = await _transactionsBox;
      final transactionsMap = <String, Transaction>{};

      for (final transaction in transactions) {
        final id = transaction.id.isEmpty ? _uuid.v4() : transaction.id;
        final now = DateTime.now();

        final newTransaction = transaction.copyWith(
          id: id,
          createdAt:
              transaction.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
                  ? now
                  : transaction.createdAt,
          updatedAt: now,
        );

        // TEMPORARILY DISABLED: Skip encryption to fix persistence issues
        // final encryptedTransaction = await _encryptTransactionIfNeeded(newTransaction);
        final encryptedTransaction = newTransaction;
        transactionsMap[id] = encryptedTransaction;
      }

      await box.putAll(transactionsMap);

      // Force flush to disk to ensure persistence
      await box.flush();
    } catch (e) {
      throw DatabaseException(message: 'Failed to add transactions batch: $e');
    }
  }

  // Helper method to update account balance based on transaction
  Future<void> _updateAccountBalanceForTransaction(
    Transaction transaction, {
    required bool isAdd,
  }) async {
    try {
      switch (transaction.type) {
        case TransactionType.income:
          if (isAdd) {
            // Adding income increases account balance
            await _accountRepository.addToAccountBalance(
              transaction.accountId,
              transaction.amount,
            );
            print(
                '✅ Added ${transaction.amount} to account ${transaction.accountId} (income)');
          } else {
            // Removing income decreases account balance
            await _accountRepository.subtractFromAccountBalance(
              transaction.accountId,
              transaction.amount,
            );
            print(
                '✅ Subtracted ${transaction.amount} from account ${transaction.accountId} (income reversal)');
          }
          break;

        case TransactionType.expense:
          if (isAdd) {
            // Adding expense decreases account balance
            await _accountRepository.subtractFromAccountBalance(
              transaction.accountId,
              transaction.amount,
            );
            print(
                '✅ Subtracted ${transaction.amount} from account ${transaction.accountId} (expense)');
          } else {
            // Removing expense increases account balance
            await _accountRepository.addToAccountBalance(
              transaction.accountId,
              transaction.amount,
            );
            print(
                '✅ Added ${transaction.amount} to account ${transaction.accountId} (expense reversal)');
          }
          break;

        case TransactionType.transfer:
          if (transaction.transferToAccountId == null ||
              transaction.transferToAccountId!.isEmpty) {
            throw DatabaseException(
              message: 'Transfer transaction missing destination account',
            );
          }

          if (isAdd) {
            // Adding transfer: subtract from source, add to destination
            await _accountRepository.subtractFromAccountBalance(
              transaction.accountId,
              transaction.amount,
            );
            await _accountRepository.addToAccountBalance(
              transaction.transferToAccountId!,
              transaction.amount,
            );
            print(
                '✅ Transferred ${transaction.amount} from ${transaction.accountId} to ${transaction.transferToAccountId}');
          } else {
            // Removing transfer: add back to source, subtract from destination
            await _accountRepository.addToAccountBalance(
              transaction.accountId,
              transaction.amount,
            );
            await _accountRepository.subtractFromAccountBalance(
              transaction.transferToAccountId!,
              transaction.amount,
            );
            print(
                '✅ Reversed transfer of ${transaction.amount} from ${transaction.accountId} to ${transaction.transferToAccountId}');
          }
          break;
      }
    } catch (e) {
      print('❌ Failed to update account balance: $e');
      throw DatabaseException(
        message: 'Failed to update account balance for transaction: $e',
      );
    }
  }
}
