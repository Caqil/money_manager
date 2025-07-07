import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../core/utils/date_utils.dart';

// Repository provider
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(),
);

// Transaction list provider
final transactionListProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<List<Transaction>>>(
  (ref) => TransactionNotifier(ref.read(transactionRepositoryProvider)),
);

// Filter state providers
final transactionTypeFilterProvider =
    StateProvider<TransactionType?>((ref) => null);
final transactionDateRangeFilterProvider =
    StateProvider<DateTimeRange?>((ref) => null);
final transactionCategoryFilterProvider = StateProvider<String?>((ref) => null);
final transactionAccountFilterProvider = StateProvider<String?>((ref) => null);
final transactionSearchQueryProvider = StateProvider<String>((ref) => '');

// Filtered transactions provider
final filteredTransactionsProvider = Provider<AsyncValue<List<Transaction>>>(
  (ref) {
    final transactions = ref.watch(transactionListProvider);
    final typeFilter = ref.watch(transactionTypeFilterProvider);
    final dateRangeFilter = ref.watch(transactionDateRangeFilterProvider);
    final categoryFilter = ref.watch(transactionCategoryFilterProvider);
    final accountFilter = ref.watch(transactionAccountFilterProvider);
    final searchQuery = ref.watch(transactionSearchQueryProvider);

    return transactions.when(
      data: (list) {
        var filtered = list.where((transaction) {
          // Type filter
          if (typeFilter != null && transaction.type != typeFilter) {
            return false;
          }

          // Date range filter
          if (dateRangeFilter != null) {
            if (transaction.date.isBefore(dateRangeFilter.start) ||
                transaction.date.isAfter(dateRangeFilter.end)) {
              return false;
            }
          }

          // Category filter
          if (categoryFilter != null && categoryFilter.isNotEmpty) {
            if (transaction.categoryId != categoryFilter) {
              return false;
            }
          }

          // Account filter
          if (accountFilter != null && accountFilter.isNotEmpty) {
            if (transaction.accountId != accountFilter &&
                transaction.transferToAccountId != accountFilter) {
              return false;
            }
          }

          // Search query filter
          if (searchQuery.isNotEmpty) {
            final notes = transaction.notes?.toLowerCase() ?? '';
            if (!notes.contains(searchQuery.toLowerCase())) {
              return false;
            }
          }

          return true;
        }).toList();

        // Sort by date (newest first)
        filtered.sort((a, b) => b.date.compareTo(a.date));

        return AsyncValue.data(filtered);
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Recent transactions provider
final recentTransactionsProvider =
    Provider.family<AsyncValue<List<Transaction>>, int>(
  (ref, limit) {
    final transactions = ref.watch(transactionListProvider);
    return transactions.when(
      data: (list) => AsyncValue.data(list.take(limit).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Transactions by date range provider
final transactionsByDateRangeProvider =
    FutureProvider.family<List<Transaction>, DateTimeRange>(
  (ref, dateRange) async {
    final repository = ref.read(transactionRepositoryProvider);
    return await repository.getTransactionsByDateRange(
      dateRange.start,
      dateRange.end,
    );
  },
);

// Transactions by account provider
final transactionsByAccountProvider =
    FutureProvider.family<List<Transaction>, String>(
  (ref, accountId) async {
    final repository = ref.read(transactionRepositoryProvider);
    return await repository.getTransactionsByAccount(accountId);
  },
);

// Transactions by category provider
final transactionsByCategoryProvider =
    FutureProvider.family<List<Transaction>, String>(
  (ref, categoryId) async {
    final repository = ref.read(transactionRepositoryProvider);
    return await repository.getTransactionsByCategory(categoryId);
  },
);

// Single transaction provider
final transactionProvider = Provider.family<AsyncValue<Transaction?>, String>(
  (ref, transactionId) {
    final transactions = ref.watch(transactionListProvider);
    return transactions.when(
      data: (list) {
        try {
          final transaction = list.firstWhere((t) => t.id == transactionId);
          return AsyncValue.data(transaction);
        } catch (e) {
          return const AsyncValue.data(null);
        }
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Transaction totals provider
final transactionTotalsProvider =
    FutureProvider.family<Map<TransactionType, double>, DateTimeRange?>(
  (ref, dateRange) async {
    final repository = ref.read(transactionRepositoryProvider);
    return await repository.getTotalAmountsByType(
      startDate: dateRange?.start,
      endDate: dateRange?.end,
    );
  },
);

// Current month transactions provider
final currentMonthTransactionsProvider = FutureProvider<List<Transaction>>(
  (ref) async {
    final now = DateTime.now();
    final dateRange = AppDateUtils.getCurrentMonth(now);
    final repository = ref.read(transactionRepositoryProvider);
    return await repository.getTransactionsByDateRange(
      dateRange.start,
      dateRange.end,
    );
  },
);

// Transaction operations state
class TransactionNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionRepository _repository;

  TransactionNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  // SAFE: Helper method to update state only if mounted
  void _safeSetState(AsyncValue<List<Transaction>> newState) {
    if (mounted) {
      state = newState;
    }
  }

  // Load all transactions
  Future<void> loadTransactions() async {
    try {
      _safeSetState(const AsyncValue.loading());
      final transactions = await _repository.getAllTransactions();
      _safeSetState(AsyncValue.data(transactions));
    } catch (error, stackTrace) {
      _safeSetState(AsyncValue.error(error, stackTrace));
    }
  }

  // Add transaction
  Future<String?> addTransaction(Transaction transaction) async {
    if (!mounted) return null;

    try {
      final id = await _repository.addTransaction(transaction);
      if (mounted) {
        await loadTransactions(); // Refresh list
      }
      return id;
    } catch (error, stackTrace) {
      _safeSetState(AsyncValue.error(error, stackTrace));
      return null;
    }
  }

  // Update transaction
  Future<bool> updateTransaction(Transaction transaction) async {
    if (!mounted) return false;

    try {
      await _repository.updateTransaction(transaction);
      if (mounted) {
        await loadTransactions(); // Refresh list
      }
      return true;
    } catch (error, stackTrace) {
      _safeSetState(AsyncValue.error(error, stackTrace));
      return false;
    }
  }

  // Delete transaction
  Future<bool> deleteTransaction(String id) async {
    if (!mounted) return false;

    try {
      await _repository.deleteTransaction(id);
      if (mounted) {
        await loadTransactions(); // Refresh list
      }
      return true;
    } catch (error, stackTrace) {
      _safeSetState(AsyncValue.error(error, stackTrace));
      return false;
    }
  }

  // Search transactions
  Future<List<Transaction>> searchTransactions(String query) async {
    if (!mounted) return [];

    try {
      return await _repository.searchTransactions(query);
    } catch (error, stackTrace) {
      _safeSetState(AsyncValue.error(error, stackTrace));
      return [];
    }
  }

  // Batch add transactions
  Future<bool> addTransactionsBatch(List<Transaction> transactions) async {
    if (!mounted) return false;

    try {
      await _repository.addTransactionsBatch(transactions);
      if (mounted) {
        await loadTransactions(); // Refresh list
      }
      return true;
    } catch (error, stackTrace) {
      _safeSetState(AsyncValue.error(error, stackTrace));
      return false;
    }
  }

  // Refresh transactions
  Future<void> refresh() async {
    if (mounted) {
      await loadTransactions();
    }
  }

  // Clear all filters
  void clearFilters(WidgetRef ref) {
    if (!mounted) return;

    ref.read(transactionTypeFilterProvider.notifier).state = null;
    ref.read(transactionDateRangeFilterProvider.notifier).state = null;
    ref.read(transactionCategoryFilterProvider.notifier).state = null;
    ref.read(transactionAccountFilterProvider.notifier).state = null;
    ref.read(transactionSearchQueryProvider.notifier).state = '';
  }
}
