import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/recurring_transaction.dart';
import '../services/hive_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

class RecurringTransactionRepository {
  static const _uuid = Uuid();
  late final HiveService _hiveService;

  RecurringTransactionRepository({HiveService? hiveService}) {
    _hiveService = hiveService ?? HiveService();
  }

  Future<Box<RecurringTransaction>> get _recurringTransactionsBox async {
    return await _hiveService.getBox<RecurringTransaction>(
        AppConstants.hiveBoxRecurringTransactions);
  }

  // Add recurring transaction
  Future<String> addRecurringTransaction(RecurringTransaction transaction) async {
    try {
      final box = await _recurringTransactionsBox;
      final id = transaction.id.isEmpty ? _uuid.v4() : transaction.id;
      final now = DateTime.now();
      
      final newTransaction = transaction.copyWith(
        id: id,
        createdAt: transaction.createdAt == DateTime.fromMillisecondsSinceEpoch(0) 
            ? now 
            : transaction.createdAt,
        updatedAt: now,
        nextExecution: transaction.nextExecution ?? _calculateNextExecution(transaction),
      );
      
      await box.put(id, newTransaction);
      return id;
    } catch (e) {
      throw DatabaseException(message: 'Failed to add recurring transaction: $e');
    }
  }

  // Update recurring transaction
  Future<void> updateRecurringTransaction(RecurringTransaction transaction) async {
    try {
      final box = await _recurringTransactionsBox;
      
      if (!box.containsKey(transaction.id)) {
        throw DatabaseException(message: 'Recurring transaction not found');
      }

      final updatedTransaction = transaction.copyWith(
        updatedAt: DateTime.now(),
        nextExecution: _calculateNextExecution(transaction),
      );
      
      await box.put(transaction.id, updatedTransaction);
    } catch (e) {
      throw DatabaseException(message: 'Failed to update recurring transaction: $e');
    }
  }

  // Delete recurring transaction
  Future<void> deleteRecurringTransaction(String id) async {
    try {
      final box = await _recurringTransactionsBox;
      
      if (!box.containsKey(id)) {
        throw DatabaseException(message: 'Recurring transaction not found');
      }

      await box.delete(id);
    } catch (e) {
      throw DatabaseException(message: 'Failed to delete recurring transaction: $e');
    }
  }

  // Get recurring transaction by ID
  Future<RecurringTransaction?> getRecurringTransactionById(String id) async {
    try {
      final box = await _recurringTransactionsBox;
      return box.get(id);
    } catch (e) {
      throw DatabaseException(message: 'Failed to get recurring transaction: $e');
    }
  }

  // Get all recurring transactions
  Future<List<RecurringTransaction>> getAllRecurringTransactions() async {
    try {
      final box = await _recurringTransactionsBox;
      final transactions = box.values.toList();
      
      // Sort by next execution date
      transactions.sort((a, b) {
        if (a.nextExecution == null && b.nextExecution == null) return 0;
        if (a.nextExecution == null) return 1;
        if (b.nextExecution == null) return -1;
        return a.nextExecution!.compareTo(b.nextExecution!);
      });
      
      return transactions;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get recurring transactions: $e');
    }
  }

  // Get active recurring transactions
  Future<List<RecurringTransaction>> getActiveRecurringTransactions() async {
    try {
      final allTransactions = await getAllRecurringTransactions();
      return allTransactions.where((transaction) => transaction.isActive).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get active recurring transactions: $e');
    }
  }

  // Get due recurring transactions
  Future<List<RecurringTransaction>> getDueRecurringTransactions() async {
    try {
      final activeTransactions = await getActiveRecurringTransactions();
      final now = DateTime.now();
      
      return activeTransactions.where((transaction) {
        if (transaction.nextExecution == null) return false;
        return transaction.nextExecution!.isBefore(now) ||
               transaction.nextExecution!.isAtSameMomentAs(now);
      }).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get due recurring transactions: $e');
    }
  }

  // Get upcoming recurring transactions
  Future<List<RecurringTransaction>> getUpcomingRecurringTransactions({
    int daysAhead = 7,
  }) async {
    try {
      final activeTransactions = await getActiveRecurringTransactions();
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: daysAhead));
      
      return activeTransactions.where((transaction) {
        if (transaction.nextExecution == null) return false;
        return transaction.nextExecution!.isAfter(now) &&
               transaction.nextExecution!.isBefore(futureDate);
      }).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get upcoming recurring transactions: $e');
    }
  }

  // Mark as executed
  Future<void> markAsExecuted(String id) async {
    try {
      final transaction = await getRecurringTransactionById(id);
      if (transaction == null) {
        throw DatabaseException(message: 'Recurring transaction not found');
      }
      
      final now = DateTime.now();
      final nextExecution = _calculateNextExecution(transaction);
      
      final updatedTransaction = transaction.copyWith(
        lastExecuted: now,
        nextExecution: nextExecution,
        updatedAt: now,
      );
      
      await updateRecurringTransaction(updatedTransaction);
    } catch (e) {
      throw DatabaseException(message: 'Failed to mark as executed: $e');
    }
  }

  // Deactivate recurring transaction
  Future<void> deactivateRecurringTransaction(String id) async {
    try {
      final transaction = await getRecurringTransactionById(id);
      if (transaction == null) {
        throw DatabaseException(message: 'Recurring transaction not found');
      }
      
      final deactivatedTransaction = transaction.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );
      
      await updateRecurringTransaction(deactivatedTransaction);
    } catch (e) {
      throw DatabaseException(message: 'Failed to deactivate recurring transaction: $e');
    }
  }

  // Activate recurring transaction
  Future<void> activateRecurringTransaction(String id) async {
    try {
      final transaction = await getRecurringTransactionById(id);
      if (transaction == null) {
        throw DatabaseException(message: 'Recurring transaction not found');
      }
      
      final activatedTransaction = transaction.copyWith(
        isActive: true,
        nextExecution: _calculateNextExecution(transaction),
        updatedAt: DateTime.now(),
      );
      
      await updateRecurringTransaction(activatedTransaction);
    } catch (e) {
      throw DatabaseException(message: 'Failed to activate recurring transaction: $e');
    }
  }

  // Clear all recurring transactions
  Future<void> clearAllRecurringTransactions() async {
    try {
      final box = await _recurringTransactionsBox;
      await box.clear();
    } catch (e) {
      throw DatabaseException(message: 'Failed to clear recurring transactions: $e');
    }
  }

  // Get recurring transactions count
  Future<int> getRecurringTransactionsCount() async {
    try {
      final box = await _recurringTransactionsBox;
      return box.length;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get recurring transactions count: $e');
    }
  }

  // Calculate next execution date
  DateTime? _calculateNextExecution(RecurringTransaction transaction) {
    if (!transaction.isActive) return null;
    
    final baseDate = transaction.lastExecuted ?? transaction.startDate;
    
    switch (transaction.frequency) {
      case RecurrenceFrequency.daily:
        return baseDate.add(Duration(days: transaction.intervalValue));
        
      case RecurrenceFrequency.weekly:
        return baseDate.add(Duration(days: 7 * transaction.intervalValue));
        
      case RecurrenceFrequency.monthly:
        return DateTime(
          baseDate.year,
          baseDate.month + transaction.intervalValue,
          transaction.dayOfMonth ?? baseDate.day,
        );
        
      case RecurrenceFrequency.quarterly:
        return DateTime(
          baseDate.year,
          baseDate.month + (3 * transaction.intervalValue),
          transaction.dayOfMonth ?? baseDate.day,
        );
        
      case RecurrenceFrequency.yearly:
        return DateTime(
          baseDate.year + transaction.intervalValue,
          baseDate.month,
          transaction.dayOfMonth ?? baseDate.day,
        );
        
      case RecurrenceFrequency.custom:
        // For custom frequency, we'd need more complex logic
        // For now, default to monthly
        return DateTime(
          baseDate.year,
          baseDate.month + 1,
          baseDate.day,
        );
    }
  }
}

