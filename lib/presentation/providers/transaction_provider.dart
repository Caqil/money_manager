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

// Cached and optimized filtered transactions provider
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
        // Early return if no filters applied and already sorted
        if (typeFilter == null &&
            dateRangeFilter == null &&
            (categoryFilter == null || categoryFilter.isEmpty) &&
            (accountFilter == null || accountFilter.isEmpty) &&
            searchQuery.isEmpty) {
          return AsyncValue.data(list);
        }

        // Use more efficient filtering with early exits
        final filtered = <Transaction>[];
        final searchLower = searchQuery.toLowerCase();

        for (final transaction in list) {
          // Type filter - fastest check first
          if (typeFilter != null && transaction.type != typeFilter) continue;

          // Category filter
          if (categoryFilter != null && categoryFilter.isNotEmpty) {
            if (transaction.categoryId != categoryFilter) continue;
          }

          // Account filter
          if (accountFilter != null && accountFilter.isNotEmpty) {
            if (transaction.accountId != accountFilter &&
                transaction.transferToAccountId != accountFilter) continue;
          }

          // Date range filter
          if (dateRangeFilter != null) {
            if (transaction.date.isBefore(dateRangeFilter.start) ||
                transaction.date.isAfter(dateRangeFilter.end)) continue;
          }

          // Search query filter - most expensive check last
          if (searchQuery.isNotEmpty) {
            final notes = transaction.notes?.toLowerCase() ?? '';
            if (!notes.contains(searchLower)) continue;
          }

          filtered.add(transaction);
        }

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

// Paginated transactions provider for better performance
final paginatedTransactionsProvider =
    Provider.family<AsyncValue<List<Transaction>>, int>((ref, pageSize) {
  final transactions = ref.watch(filteredTransactionsProvider);

  return transactions.when(
    data: (list) {
      // Limit the initial load to reduce lag
      final limitedList = list.take(pageSize).toList();
      return AsyncValue.data(limitedList);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

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
  } // Load all transactions with caching

  Future<void> loadTransactions() async {
    try {
      print('🔄 Loading transactions...');
      _safeSetState(const AsyncValue.loading());

      print('📦 Calling repository getAllTransactions...');
      final transactions = await _repository.getAllTransactions();
      print('✅ Got ${transactions.length} transactions from repository');

      // Pre-sort transactions by date (newest first) for better performance
      transactions.sort((a, b) => b.date.compareTo(a.date));
      print('✅ Transactions sorted by date');

      // Debug: Print first few transactions if any exist
      if (transactions.isNotEmpty) {
        print('📋 Sample transactions:');
        for (int i = 0; i < transactions.length && i < 3; i++) {
          final t = transactions[i];
          print(
              '  ${i + 1}. ID: ${t.id}, Amount: ${t.amount}, Type: ${t.type}, Date: ${t.date}');
        }
      } else {
        print('⚠️ No transactions found in database');
      }

      _safeSetState(AsyncValue.data(transactions));
      print('✅ Transactions loaded successfully');
    } catch (error, stackTrace) {
      print('❌ Error loading transactions: $error');
      print('📍 Stack trace: $stackTrace');
      _safeSetState(AsyncValue.error(error, stackTrace));
    }
  }

  // Add transaction with optimistic update
  Future<String?> addTransaction(Transaction transaction) async {
    if (!mounted) {
      print('❌ TransactionNotifier not mounted');
      return null;
    }

    print('🔄 Starting addTransaction in provider');
    print(
        '📝 Transaction: ID=${transaction.id}, Amount=${transaction.amount}, Type=${transaction.type}');

    try {
      // Skip optimistic update on slower platforms to prevent UI freezing
      // Just perform the database operation directly
      print('💾 Calling repository addTransaction...');
      final id = await _repository.addTransaction(transaction);
      print('✅ Repository returned ID: $id');

      if (mounted && id.isNotEmpty) {
        // Only refresh if needed - add the new transaction to the list efficiently
        final currentState = state;
        if (currentState is AsyncData<List<Transaction>>) {
          print('📋 Adding transaction to current list');
          final currentList = List<Transaction>.from(currentState.value);
          final newTransactionWithId = transaction.copyWith(id: id);
          currentList.insert(0, newTransactionWithId); // Add to beginning
          _safeSetState(AsyncValue.data(currentList));
          print('✅ Transaction added to local state');
        }
        return id;
      } else if (mounted) {
        print('⚠️ ID is empty or not mounted, refreshing list');
        // Fallback: refresh the entire list if something went wrong
        await loadTransactions();
        return null;
      }

      return id.isNotEmpty ? id : null;
    } catch (error, stackTrace) {
      print('❌ Error in addTransaction: $error');
      print('📍 Stack trace: $stackTrace');

      // On error, refresh the list to ensure consistency
      if (mounted) {
        await loadTransactions();
        _safeSetState(AsyncValue.error(error, stackTrace));
      }
      return null;
    }
  }

  // Update transaction with optimistic update
  Future<bool> updateTransaction(Transaction transaction) async {
    if (!mounted) return false;

    try {
      // Optimistic update - update in local state immediately
      final currentState = state;
      if (currentState is AsyncData<List<Transaction>>) {
        final currentList = List<Transaction>.from(currentState.value);
        final index = currentList.indexWhere((t) => t.id == transaction.id);
        if (index != -1) {
          currentList[index] = transaction;
          _safeSetState(AsyncValue.data(currentList));
        }
      }

      // Perform actual database operation
      await _repository.updateTransaction(transaction);
      return true;
    } catch (error, stackTrace) {
      // Rollback optimistic update on error
      if (mounted) {
        await loadTransactions();
        _safeSetState(AsyncValue.error(error, stackTrace));
      }
      return false;
    }
  }

  // Delete transaction with optimistic update
  Future<bool> deleteTransaction(String id) async {
    if (!mounted) return false;

    try {
      // Optimistic update - remove from local state immediately
      final currentState = state;
      if (currentState is AsyncData<List<Transaction>>) {
        final currentList = List<Transaction>.from(currentState.value);
        currentList.removeWhere((t) => t.id == id);
        _safeSetState(AsyncValue.data(currentList));
      }

      // Perform actual database operation
      await _repository.deleteTransaction(id);
      return true;
    } catch (error, stackTrace) {
      // Rollback optimistic update on error
      if (mounted) {
        await loadTransactions();
        _safeSetState(AsyncValue.error(error, stackTrace));
      }
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
