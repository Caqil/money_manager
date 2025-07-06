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
import '../services/encryption_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/date_utils.dart';

class TransactionRepository {
  static const _uuid = Uuid();
  late final HiveService _hiveService;
  late final EncryptionService _encryptionService;

  TransactionRepository({
    HiveService? hiveService,
    EncryptionService? encryptionService,
  }) {
    _hiveService = hiveService ?? HiveService();
    _encryptionService = encryptionService ?? EncryptionService();
  }

  // Get transactions box
  Future<Box<Transaction>> get _transactionsBox async {
    return await _hiveService.getBox<Transaction>(AppConstants.hiveBoxTransactions);
  }

  // Add transaction
  Future<String> addTransaction(Transaction transaction) async {
    try {
      final box = await _transactionsBox;
      final id = transaction.id.isEmpty ? _uuid.v4() : transaction.id;
      final now = DateTime.now();
      
      final newTransaction = transaction.copyWith(
        id: id,
        createdAt: transaction.createdAt == DateTime.fromMillisecondsSinceEpoch(0) 
            ? now 
            : transaction.createdAt,
        updatedAt: now,
      );

      // Encrypt sensitive data if encryption is enabled
      final encryptedTransaction = await _encryptTransactionIfNeeded(newTransaction);
      
      await box.put(id, encryptedTransaction);
      return id;
    } catch (e) {
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

      final updatedTransaction = transaction.copyWith(
        updatedAt: DateTime.now(),
      );

      // Encrypt sensitive data if encryption is enabled
      final encryptedTransaction = await _encryptTransactionIfNeeded(updatedTransaction);
      
      await box.put(transaction.id, encryptedTransaction);
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

      await box.delete(id);
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
      
      // Decrypt if needed
      return await _decryptTransactionIfNeeded(transaction);
    } catch (e) {
      throw DatabaseException(message: 'Failed to get transaction: $e');
    }
  }

  // Get all transactions
  Future<List<Transaction>> getAllTransactions() async {
    try {
      final box = await _transactionsBox;
      final transactions = box.values.toList();
      
      // Decrypt all transactions if needed
      final decryptedTransactions = <Transaction>[];
      for (final transaction in transactions) {
        final decrypted = await _decryptTransactionIfNeeded(transaction);
        decryptedTransactions.add(decrypted);
      }
      
      // Sort by date (newest first)
      decryptedTransactions.sort((a, b) => b.date.compareTo(a.date));
      
      return decryptedTransactions;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get transactions: $e');
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
        return transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
               transaction.date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get transactions by date range: $e');
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
      throw DatabaseException(message: 'Failed to get transactions by account: $e');
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
      throw DatabaseException(message: 'Failed to get transactions by category: $e');
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
      throw DatabaseException(message: 'Failed to get transactions by type: $e');
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
        totals[transaction.type] = (totals[transaction.type] ?? 0.0) + transaction.amount;
      }
      
      return totals;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get total amounts by type: $e');
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
          createdAt: transaction.createdAt == DateTime.fromMillisecondsSinceEpoch(0) 
              ? now 
              : transaction.createdAt,
          updatedAt: now,
        );
        
        final encryptedTransaction = await _encryptTransactionIfNeeded(newTransaction);
        transactionsMap[id] = encryptedTransaction;
      }
      
      await box.putAll(transactionsMap);
    } catch (e) {
      throw DatabaseException(message: 'Failed to add transactions batch: $e');
    }
  }

  // Helper methods for encryption
  Future<Transaction> _encryptTransactionIfNeeded(Transaction transaction) async {
    if (!_encryptionService.isEncryptionEnabled) {
      return transaction;
    }
    
    // Encrypt sensitive fields
    final encryptedAmount = await _encryptionService.encryptDouble(transaction.amount);
    final encryptedNotes = transaction.notes != null 
        ? await _encryptionService.encryptString(transaction.notes!)
        : null;
    
    return transaction.copyWith(
      // Store encrypted amount in metadata for now
      metadata: {
        'encrypted_amount': encryptedAmount,
        'encrypted_notes': encryptedNotes,
        'is_encrypted': true,
      },
    );
  }

  Future<Transaction> _decryptTransactionIfNeeded(Transaction transaction) async {
    if (!_encryptionService.isEncryptionEnabled || 
        transaction.metadata?['is_encrypted'] != true) {
      return transaction;
    }
    
    // Decrypt sensitive fields
    final encryptedAmount = transaction.metadata?['encrypted_amount'] as String?;
    final encryptedNotes = transaction.metadata?['encrypted_notes'] as String?;
    
    final decryptedAmount = encryptedAmount != null 
        ? await _encryptionService.decryptDouble(encryptedAmount)
        : transaction.amount;
    
    final decryptedNotes = encryptedNotes != null 
        ? await _encryptionService.decryptString(encryptedNotes)
        : transaction.notes;
    
    final updatedMetadata = transaction.metadata == null
        ? null
        : Map<String, dynamic>.from(transaction.metadata!);
    if (updatedMetadata != null) {
      updatedMetadata.remove('encrypted_amount');
      updatedMetadata.remove('encrypted_notes');
      updatedMetadata.remove('is_encrypted');
    }
    return transaction.copyWith(
      amount: decryptedAmount,
      notes: decryptedNotes,
      metadata: updatedMetadata,
    );
  }
}

