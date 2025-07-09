import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import '../models/split_expense.dart';
import '../models/badge.dart';

class HiveService {
  static HiveService? _instance;
  static final Map<String, Box> _openBoxes = {};

  HiveService._internal();

  factory HiveService() {
    _instance ??= HiveService._internal();
    return _instance!;
  }

  // Initialize Hive
  static Future<void> init() async {
    try {
      await Hive.initFlutter();

      // Initialize all boxes with proper types
      await _openAllBoxes();
    } catch (e) {
      throw DatabaseException(message: 'Failed to initialize Hive: $e');
    }
  }

  // Open all required boxes with proper types
  static Future<void> _openAllBoxes() async {
    try {
      print('📦 HiveService: Opening all boxes...');

      // Open typed boxes for models
      await _openTypedBox<Account>(AppConstants.hiveBoxAccounts);
      print('✅ Opened accounts box');

      await _openTypedBox<Transaction>(AppConstants.hiveBoxTransactions);
      print('✅ Opened transactions box');

      await _openTypedBox<Budget>(AppConstants.hiveBoxBudgets);
      print('✅ Opened budgets box');

      await _openTypedBox<Goal>(AppConstants.hiveBoxGoals);
      print('✅ Opened goals box');

      await _openTypedBox<Category>(AppConstants.hiveBoxCategories);
      print('✅ Opened categories box');

      await _openTypedBox<RecurringTransaction>(
          AppConstants.hiveBoxRecurringTransactions);
      print('✅ Opened recurring transactions box');

      await _openTypedBox<SplitExpense>(AppConstants.hiveBoxSplitExpenses);
      print('✅ Opened split expenses box');

      await _openTypedBox<Badge>(AppConstants.hiveBoxBadges);
      print('✅ Opened badges box');

      // Open dynamic boxes for settings and other data
      await _openDynamicBox(AppConstants.hiveBoxCurrencyRates);
      print('✅ Opened currency rates box');

      await _openDynamicBox(AppConstants.hiveBoxCurrencies);
      print('✅ Opened currencies box');

      await _openDynamicBox(AppConstants.hiveBoxSettings);
      print('✅ Opened settings box');

      await _openDynamicBox(AppConstants.hiveBoxUserData);
      print('✅ Opened user data box');

      print('✅ HiveService: All boxes opened successfully');
    } catch (e) {
      print('❌ HiveService: Failed to open boxes: $e');
      throw DatabaseException(message: 'Failed to open boxes: $e');
    }
  }

  // Helper method to open typed boxes
  static Future<void> _openTypedBox<T>(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      final box = await Hive.openBox<T>(boxName);
      _openBoxes[boxName] = box;
    } else {
      _openBoxes[boxName] = Hive.box<T>(boxName);
    }
  }

  // Helper method to open dynamic boxes
  static Future<void> _openDynamicBox(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      final box = await Hive.openBox(boxName);
      _openBoxes[boxName] = box;
    } else {
      _openBoxes[boxName] = Hive.box(boxName);
    }
  }

  // Get a specific typed box
  Future<Box<T>> getBox<T>(String boxName) async {
    try {
      print('📦 HiveService: Getting box $boxName of type ${T.toString()}');

      // Check if box is already open and cached
      if (_openBoxes.containsKey(boxName)) {
        final box = _openBoxes[boxName]!;
        print('✅ HiveService: Found cached box $boxName');
        if (box is Box<T>) {
          print(
              '✅ HiveService: Box type matches, returning box with ${box.length} items');
          return box;
        } else {
          print('❌ HiveService: Box type mismatch for $boxName');
          throw DatabaseException(
              message: 'Box $boxName is not of type Box<${T.toString()}>. '
                  'Actual type: ${box.runtimeType}');
        }
      }

      // If box isn't cached, try to open it
      if (Hive.isBoxOpen(boxName)) {
        print(
            '📦 HiveService: Box $boxName is open but not cached, getting it');
        final box = Hive.box<T>(boxName);
        _openBoxes[boxName] = box;
        print(
            '✅ HiveService: Retrieved and cached box $boxName with ${box.length} items');
        return box;
      }

      // Open new typed box
      final box = await Hive.openBox<T>(boxName);
      _openBoxes[boxName] = box;
      return box;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get box $boxName: $e');
    }
  }

  // Get a dynamic box (for settings, etc.)
  Future<Box> getDynamicBox(String boxName) async {
    try {
      if (_openBoxes.containsKey(boxName)) {
        return _openBoxes[boxName]!;
      }

      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        _openBoxes[boxName] = box;
        return box;
      }

      final box = await Hive.openBox(boxName);
      _openBoxes[boxName] = box;
      return box;
    } catch (e) {
      throw DatabaseException(
          message: 'Failed to get dynamic box $boxName: $e');
    }
  }

  // Close a specific box
  Future<void> closeBox(String boxName) async {
    try {
      if (_openBoxes.containsKey(boxName)) {
        await _openBoxes[boxName]!.close();
        _openBoxes.remove(boxName);
      }
    } catch (e) {
      throw DatabaseException(message: 'Failed to close box $boxName: $e');
    }
  }

  // Close all boxes
  Future<void> closeAllBoxes() async {
    try {
      for (final entry in _openBoxes.entries) {
        await entry.value.close();
      }
      _openBoxes.clear();
    } catch (e) {
      throw DatabaseException(message: 'Failed to close all boxes: $e');
    }
  }

  // Clear a specific box
  Future<void> clearBox(String boxName) async {
    try {
      final box = await getDynamicBox(boxName);
      await box.clear();
    } catch (e) {
      throw DatabaseException(message: 'Failed to clear box $boxName: $e');
    }
  }

  // Delete a box completely
  Future<void> deleteBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).deleteFromDisk();
      } else {
        await Hive.deleteBoxFromDisk(boxName);
      }
      _openBoxes.remove(boxName);
    } catch (e) {
      throw DatabaseException(message: 'Failed to delete box $boxName: $e');
    }
  }

  // Check if box exists
  bool isBoxOpen(String boxName) {
    return Hive.isBoxOpen(boxName);
  }

  // Get box data for backup
  Future<Map<String, dynamic>> getBoxData(String boxName) async {
    try {
      final box = await getDynamicBox(boxName);
      final data = <String, dynamic>{};

      for (final key in box.keys) {
        data[key.toString()] = box.get(key);
      }

      return data;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get box data $boxName: $e');
    }
  }

  // Restore box data from backup
  Future<void> restoreBoxData(String boxName, Map<String, dynamic> data) async {
    try {
      final box = await getDynamicBox(boxName);
      await box.clear();

      for (final entry in data.entries) {
        await box.put(entry.key, entry.value);
      }
    } catch (e) {
      throw DatabaseException(
          message: 'Failed to restore box data $boxName: $e');
    }
  }

  // Compact a box (optimize storage)
  Future<void> compactBox(String boxName) async {
    try {
      final box = await getDynamicBox(boxName);
      await box.compact();
    } catch (e) {
      throw DatabaseException(message: 'Failed to compact box $boxName: $e');
    }
  }

  // Get box size information
  Future<BoxInfo> getBoxInfo(String boxName) async {
    try {
      final box = await getDynamicBox(boxName);

      return BoxInfo(
        name: boxName,
        length: box.length,
        isEmpty: box.isEmpty,
        isOpen: box.isOpen,
        keys: box.keys.map((k) => k.toString()).toList(),
      );
    } catch (e) {
      throw DatabaseException(message: 'Failed to get box info $boxName: $e');
    }
  }

  // Get all boxes info
  Future<List<BoxInfo>> getAllBoxesInfo() async {
    final boxNames = [
      AppConstants.hiveBoxTransactions,
      AppConstants.hiveBoxBudgets,
      AppConstants.hiveBoxAccounts,
      AppConstants.hiveBoxGoals,
      AppConstants.hiveBoxCategories,
      AppConstants.hiveBoxRecurringTransactions,
      AppConstants.hiveBoxSplitExpenses,
      AppConstants.hiveBoxBadges,
      AppConstants.hiveBoxCurrencyRates,
      AppConstants.hiveBoxCurrencies,
      AppConstants.hiveBoxSettings,
      AppConstants.hiveBoxUserData,
    ];

    final infos = <BoxInfo>[];

    for (final boxName in boxNames) {
      try {
        final info = await getBoxInfo(boxName);
        infos.add(info);
      } catch (e) {
        // Continue with other boxes if one fails
        continue;
      }
    }

    return infos;
  }

  // Dispose service
  Future<void> dispose() async {
    await closeAllBoxes();
  }
}

// Box information model
class BoxInfo {
  final String name;
  final int length;
  final bool isEmpty;
  final bool isOpen;
  final List<String> keys;

  const BoxInfo({
    required this.name,
    required this.length,
    required this.isEmpty,
    required this.isOpen,
    required this.keys,
  });

  @override
  String toString() {
    return 'BoxInfo(name: $name, length: $length, isEmpty: $isEmpty, isOpen: $isOpen)';
  }
}
