import 'dart:convert';
import 'dart:io';
import '../services/hive_service.dart';
import '../services/file_service.dart';
import '../services/encryption_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/file_helper.dart';

class BackupRepository {
  late final HiveService _hiveService;
  late final FileService _fileService;
  late final EncryptionService _encryptionService;

  BackupRepository({
    HiveService? hiveService,
    FileService? fileService,
    EncryptionService? encryptionService,
  }) {
    _hiveService = hiveService ?? HiveService();
    _fileService = fileService ?? FileService();
    _encryptionService = encryptionService ?? EncryptionService();
  }

  // Create backup
  Future<String> createBackup({
    bool includeImages = true,
    bool encrypt = true,
  }) async {
    try {
      final backupData = await _collectBackupData();
      
      // Add metadata
      final backup = {
        'version': AppConstants.appVersion,
        'created_at': DateTime.now().toIso8601String(),
        'includes_images': includeImages,
        'is_encrypted': encrypt,
        'data': backupData,
      };
      
      String jsonData = jsonEncode(backup);
      
      // Encrypt if requested
      if (encrypt && _encryptionService.isEncryptionEnabled) {
        jsonData = await _encryptionService.encryptString(jsonData);
      }
      
      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${AppConstants.backupFileName}_$timestamp.json';
      
      // Save to file
      final filePath = await _fileService.saveToBackupsDirectory(
        filename,
        jsonData.codeUnits,
      );
      
      return filePath;
    } catch (e) {
      throw FileException(message: 'Failed to create backup: $e');
    }
  }

  // Restore from backup
  Future<void> restoreFromBackup(
    String filePath, {
    bool clearExistingData = true,
  }) async {
    try {
      // Read backup file
      final fileContent = await _fileService.readFile(filePath);
      final jsonString = String.fromCharCodes(fileContent);
      
      // Parse JSON
      Map<String, dynamic> backup;
      try {
        backup = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        // Try to decrypt if it's encrypted
        final decryptedString = await _encryptionService.decryptString(jsonString);
        backup = jsonDecode(decryptedString) as Map<String, dynamic>;
      }
      
      // Validate backup structure
      if (!backup.containsKey('data') || !backup.containsKey('version')) {
        throw ValidationException(message: 'Invalid backup file format');
      }
      
      // Clear existing data if requested
      if (clearExistingData) {
        await _clearAllData();
      }
      
      // Restore data
      final data = backup['data'] as Map<String, dynamic>;
      await _restoreBackupData(data);
      
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw FileException(message: 'Failed to restore backup: $e');
    }
  }

  // List available backups
  Future<List<BackupInfo>> listBackups() async {
    try {
      final backupsDir = await FileHelper.getBackupsDirectory();
      final files = await FileHelper.listFiles(backupsDir.path, extension: '.json');
      
      final backups = <BackupInfo>[];
      
      for (final file in files) {
        try {
          final info = await _getBackupInfo(file.path);
          backups.add(info);
        } catch (e) {
          // Skip invalid backup files
          continue;
        }
      }
      
      // Sort by creation date (newest first)
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return backups;
    } catch (e) {
      throw FileException(message: 'Failed to list backups: $e');
    }
  }

  // Delete backup
  Future<void> deleteBackup(String filePath) async {
    try {
      await FileHelper.deleteFile(filePath);
    } catch (e) {
      throw FileException(message: 'Failed to delete backup: $e');
    }
  }

  // Get backup info
  Future<BackupInfo> getBackupInfo(String filePath) async {
    try {
      return await _getBackupInfo(filePath);
    } catch (e) {
      throw FileException(message: 'Failed to get backup info: $e');
    }
  }

  // Auto backup
  Future<String?> autoBackup() async {
    try {
      // Check if auto backup is enabled
      // This would be checked from settings
      // For now, always create backup
      
      return await createBackup(
        includeImages: false, // Keep auto backups smaller
        encrypt: true,
      );
    } catch (e) {
      // Log error but don't throw for auto backup
      return null;
    }
  }

  // Clean old backups
  Future<void> cleanOldBackups({int keepCount = 10}) async {
    try {
      final backups = await listBackups();
      
      if (backups.length <= keepCount) return;
      
      // Delete oldest backups
      final backupsToDelete = backups.skip(keepCount);
      
      for (final backup in backupsToDelete) {
        await deleteBackup(backup.filePath);
      }
    } catch (e) {
      // Log error but don't throw
    }
  }

  // Private helper methods
  Future<Map<String, dynamic>> _collectBackupData() async {
    final data = <String, dynamic>{};
    
    // Get all box data
    final transactions = await _hiveService.getBoxData(AppConstants.hiveBoxTransactions);
    final budgets = await _hiveService.getBoxData(AppConstants.hiveBoxBudgets);
    final accounts = await _hiveService.getBoxData(AppConstants.hiveBoxAccounts);
    final goals = await _hiveService.getBoxData(AppConstants.hiveBoxGoals);
    final categories = await _hiveService.getBoxData(AppConstants.hiveBoxCategories);
    final recurringTransactions = await _hiveService.getBoxData(AppConstants.hiveBoxRecurringTransactions);
    final splitExpenses = await _hiveService.getBoxData(AppConstants.hiveBoxSplitExpenses);
    final badges = await _hiveService.getBoxData(AppConstants.hiveBoxBadges);
    final currencyRates = await _hiveService.getBoxData(AppConstants.hiveBoxCurrencyRates);
    final settings = await _hiveService.getBoxData(AppConstants.hiveBoxSettings);
    
    data['transactions'] = transactions;
    data['budgets'] = budgets;
    data['accounts'] = accounts;
    data['goals'] = goals;
    data['categories'] = categories;
    data['recurring_transactions'] = recurringTransactions;
    data['split_expenses'] = splitExpenses;
    data['badges'] = badges;
    data['currency_rates'] = currencyRates;
    data['settings'] = settings;
    
    return data;
  }

  Future<void> _restoreBackupData(Map<String, dynamic> data) async {
    // Restore each box
    if (data.containsKey('transactions')) {
      await _hiveService.restoreBoxData(AppConstants.hiveBoxTransactions, data['transactions']);
    }
    if (data.containsKey('budgets')) {
      await _hiveService.restoreBoxData(AppConstants.hiveBoxBudgets, data['budgets']);
    }
    if (data.containsKey('accounts')) {
      await _hiveService.restoreBoxData(AppConstants.hiveBoxAccounts, data['accounts']);
    }
    if (data.containsKey('goals')) {
      await _hiveService.restoreBoxData(AppConstants.hiveBoxGoals, data['goals']);
    }
    if (data.containsKey('categories')) {
      await _hiveService.restoreBoxData(AppConstants.hiveBoxCategories, data['categories']);
    }
    if (data.containsKey('recurring_transactions')) {
      await _hiveService.restoreBoxData(AppConstants.hiveBoxRecurringTransactions, data['recurring_transactions']);
    }
    if (data.containsKey('split_expenses')) {
      await _hiveService.restoreBoxData(AppConstants.hiveBoxSplitExpenses, data['split_expenses']);
    }
    if (data.containsKey('badges')) {
      await _hiveService.restoreBoxData(AppConstants.hiveBoxBadges, data['badges']);
    }
    if (data.containsKey('currency_rates')) {
      await _hiveService.restoreBoxData(AppConstants.hiveBoxCurrencyRates, data['currency_rates']);
    }
    if (data.containsKey('settings')) {
      await _hiveService.restoreBoxData(AppConstants.hiveBoxSettings, data['settings']);
    }
  }

  Future<void> _clearAllData() async {
    await _hiveService.clearBox(AppConstants.hiveBoxTransactions);
    await _hiveService.clearBox(AppConstants.hiveBoxBudgets);
    await _hiveService.clearBox(AppConstants.hiveBoxAccounts);
    await _hiveService.clearBox(AppConstants.hiveBoxGoals);
    await _hiveService.clearBox(AppConstants.hiveBoxCategories);
    await _hiveService.clearBox(AppConstants.hiveBoxRecurringTransactions);
    await _hiveService.clearBox(AppConstants.hiveBoxSplitExpenses);
    await _hiveService.clearBox(AppConstants.hiveBoxBadges);
    await _hiveService.clearBox(AppConstants.hiveBoxCurrencyRates);
    // Don't clear settings
  }

  Future<BackupInfo> _getBackupInfo(String filePath) async {
    final fileContent = await _fileService.readFile(filePath);
    final jsonString = String.fromCharCodes(fileContent);
    
    Map<String, dynamic> backup;
    try {
      backup = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Try to decrypt if it's encrypted
      final decryptedString = await _encryptionService.decryptString(jsonString);
      backup = jsonDecode(decryptedString) as Map<String, dynamic>;
    }
    
    final file = File(filePath);
    final stats = await file.stat();
    
    return BackupInfo(
      filePath: filePath,
      fileName: file.path.split('/').last,
      createdAt: DateTime.parse(backup['created_at'] as String),
      version: backup['version'] as String? ?? 'Unknown',
      isEncrypted: backup['is_encrypted'] as bool? ?? false,
      includesImages: backup['includes_images'] as bool? ?? false,
      fileSize: stats.size,
    );
  }
}

// Backup info model
class BackupInfo {
  final String filePath;
  final String fileName;
  final DateTime createdAt;
  final String version;
  final bool isEncrypted;
  final bool includesImages;
  final int fileSize;

  const BackupInfo({
    required this.filePath,
    required this.fileName,
    required this.createdAt,
    required this.version,
    required this.isEncrypted,
    required this.includesImages,
    required this.fileSize,
  });
}


