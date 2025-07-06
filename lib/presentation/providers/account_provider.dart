import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/account.dart';
import '../../data/repositories/account_repository.dart';
import '../../core/errors/exceptions.dart';

// Repository provider
final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(),
);

// Account list provider
final accountListProvider = StateNotifierProvider<AccountNotifier, AsyncValue<List<Account>>>(
  (ref) => AccountNotifier(ref.read(accountRepositoryProvider)),
);

// Active accounts provider
final activeAccountsProvider = Provider<AsyncValue<List<Account>>>(
  (ref) {
    final accounts = ref.watch(accountListProvider);
    return accounts.when(
      data: (list) => AsyncValue.data(list.where((account) => account.isActive).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Accounts by type provider
final accountsByTypeProvider = Provider.family<AsyncValue<List<Account>>, AccountType>(
  (ref, type) {
    final accounts = ref.watch(accountListProvider);
    return accounts.when(
      data: (list) => AsyncValue.data(list.where((account) => account.type == type).toList()),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Single account provider
final accountProvider = Provider.family<AsyncValue<Account?>, String>(
  (ref, accountId) {
    final accounts = ref.watch(accountListProvider);
    return accounts.when(
      data: (list) {
        try {
          final account = list.firstWhere((account) => account.id == accountId);
          return AsyncValue.data(account);
        } catch (e) {
          return const AsyncValue.data(null);
        }
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Total balance provider
final totalBalanceProvider = Provider.family<AsyncValue<double>, String>(
  (ref, currency) {
    final accounts = ref.watch(accountListProvider);
    return accounts.when(
      data: (list) {
        try {
          final total = list
              .where((account) => account.isActive && 
                     account.includeInTotal && 
                     account.currency == currency)
              .fold(0.0, (sum, account) => sum + account.balance);
          return AsyncValue.data(total);
        } catch (e) {
          return AsyncValue.error(e, StackTrace.current);
        }
      },
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Account balance provider for specific account
final accountBalanceProvider = Provider.family<AsyncValue<double>, String>(
  (ref, accountId) {
    final account = ref.watch(accountProvider(accountId));
    return account.when(
      data: (acc) => AsyncValue.data(acc?.balance ?? 0.0),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Available balance provider (considers credit limits)
final availableBalanceProvider = Provider.family<AsyncValue<double>, String>(
  (ref, accountId) {
    final account = ref.watch(accountProvider(accountId));
    return account.when(
      data: (acc) => AsyncValue.data(acc?.availableBalance ?? 0.0),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
  },
);

// Account operations state
class AccountNotifier extends StateNotifier<AsyncValue<List<Account>>> {
  final AccountRepository _repository;

  AccountNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadAccounts();
  }

  // Load all accounts
  Future<void> loadAccounts() async {
    try {
      state = const AsyncValue.loading();
      final accounts = await _repository.getAllAccounts();
      state = AsyncValue.data(accounts);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Add account
  Future<String?> addAccount(Account account) async {
    try {
      final id = await _repository.addAccount(account);
      await loadAccounts(); // Refresh list
      return id;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  // Update account
  Future<bool> updateAccount(Account account) async {
    try {
      await _repository.updateAccount(account);
      await loadAccounts(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount(String id) async {
    try {
      await _repository.deleteAccount(id);
      await loadAccounts(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Update account balance
  Future<bool> updateAccountBalance(String accountId, double newBalance) async {
    try {
      await _repository.updateAccountBalance(accountId, newBalance);
      await loadAccounts(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Transfer between accounts
  Future<bool> transferBetweenAccounts(
    String fromAccountId,
    String toAccountId,
    double amount,
  ) async {
    try {
      await _repository.transferBetweenAccounts(fromAccountId, toAccountId, amount);
      await loadAccounts(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Activate/Deactivate account
  Future<bool> toggleAccountStatus(String id, bool isActive) async {
    try {
      if (isActive) {
        await _repository.activateAccount(id);
      } else {
        await _repository.deactivateAccount(id);
      }
      await loadAccounts(); // Refresh list
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Refresh accounts
  Future<void> refresh() async {
    await loadAccounts();
  }
}


