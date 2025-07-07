import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/file_helper.dart';

class FileService {
  static FileService? _instance;
  late final ImagePicker _imagePicker;

  FileService._internal();

  factory FileService() {
    _instance ??= FileService._internal();
    return _instance!;
  }

  // Initialize file service
  static Future<FileService> init() async {
    final instance = FileService();
    await instance._initialize();
    return instance;
  }

  Future<void> _initialize() async {
    _imagePicker = ImagePicker();
  }

  // Save file to receipts directory
  Future<String> saveToReceiptsDirectory(
      String filename, List<int> data) async {
    try {
      final receiptsDir = await FileHelper.getReceiptsDirectory();
      final filePath = path.join(receiptsDir.path, filename);

      final file = File(filePath);
      await file.writeAsBytes(data);

      return filePath;
    } catch (e) {
      throw FileException(message: 'Failed to save receipt: $e');
    }
  }

  // Save file to backups directory
  Future<String> saveToBackupsDirectory(String filename, List<int> data) async {
    try {
      final backupsDir = await FileHelper.getBackupsDirectory();
      final filePath = path.join(backupsDir.path, filename);

      final file = File(filePath);
      await file.writeAsBytes(data);

      return filePath;
    } catch (e) {
      throw FileException(message: 'Failed to save backup: $e');
    }
  }

  // Save file to exports directory
  Future<String> saveToExportsDirectory(String filename, List<int> data) async {
    try {
      final exportsDir = await FileHelper.getExportsDirectory();
      final filePath = path.join(exportsDir.path, filename);

      final file = File(filePath);
      await file.writeAsBytes(data);

      return filePath;
    } catch (e) {
      throw FileException(message: 'Failed to save export: $e');
    }
  }

  // Pick image from camera
  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Validate file size
      final fileSize = await image.length();
      if (!FileHelper.isValidFileSize(fileSize, AppConstants.maxImageSize)) {
        throw FileSizeExceededException(
          maxSize: AppConstants.maxImageSize,
          actualSize: fileSize,
        );
      }

      // Generate unique filename
      final extension =
          FileHelper.getFileExtension(image.path).replaceFirst('.', '');
      final filename = FileHelper.generateUniqueFileName('receipt', extension);

      // Read image data
      final imageData = await image.readAsBytes();

      // Save to receipts directory
      final savedPath = await saveToReceiptsDirectory(filename, imageData);

      return savedPath;
    } catch (e) {
      if (e is FileSizeExceededException) rethrow;
      throw FileException(message: 'Failed to pick image from camera: $e');
    }
  }

  // Pick image from gallery
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Validate file extension
      if (!FileHelper.isValidFileExtension(
          image.path, AppConstants.supportedImageFormats)) {
        throw ValidationException(message: 'Unsupported image format');
      }

      // Validate file size
      final fileSize = await image.length();
      if (!FileHelper.isValidFileSize(fileSize, AppConstants.maxImageSize)) {
        throw FileSizeExceededException(
          maxSize: AppConstants.maxImageSize,
          actualSize: fileSize,
        );
      }

      // Generate unique filename
      final extension =
          FileHelper.getFileExtension(image.path).replaceFirst('.', '');
      final filename = FileHelper.generateUniqueFileName('receipt', extension);

      // Read image data
      final imageData = await image.readAsBytes();

      // Save to receipts directory
      final savedPath = await saveToReceiptsDirectory(filename, imageData);

      return savedPath;
    } catch (e) {
      if (e is FileSizeExceededException || e is ValidationException) rethrow;
      throw FileException(message: 'Failed to pick image from gallery: $e');
    }
  }

  // Read file
  Future<Uint8List> readFile(String filePath) async {
    try {
      return await FileHelper.readFile(filePath);
    } catch (e) {
      throw FileException(message: 'Failed to read file: $e');
    }
  }

  // Delete file
  Future<bool> deleteFile(String filePath) async {
    try {
      return await FileHelper.deleteFile(filePath);
    } catch (e) {
      throw FileException(message: 'Failed to delete file: $e');
    }
  }

  // Check if file exists
  Future<bool> fileExists(String filePath) async {
    try {
      return await FileHelper.fileExists(filePath);
    } catch (e) {
      return false;
    }
  }

  // Get file size
  Future<int> getFileSize(String filePath) async {
    try {
      return await FileHelper.getFileSize(filePath);
    } catch (e) {
      throw FileException(message: 'Failed to get file size: $e');
    }
  }

  // List receipt files
  Future<List<File>> listReceiptFiles() async {
    try {
      final receiptsDir = await FileHelper.getReceiptsDirectory();
      return await FileHelper.listFiles(receiptsDir.path);
    } catch (e) {
      throw FileException(message: 'Failed to list receipt files: $e');
    }
  }

  // List backup files
  Future<List<File>> listBackupFiles() async {
    try {
      final backupsDir = await FileHelper.getBackupsDirectory();
      return await FileHelper.listFiles(backupsDir.path);
    } catch (e) {
      throw FileException(message: 'Failed to list backup files: $e');
    }
  }

  // List export files
  Future<List<File>> listExportFiles() async {
    try {
      final exportsDir = await FileHelper.getExportsDirectory();
      return await FileHelper.listFiles(exportsDir.path);
    } catch (e) {
      throw FileException(message: 'Failed to list export files: $e');
    }
  }

  // Copy file
  Future<String> copyFile(String sourcePath, String destinationDir,
      {String? newName}) async {
    try {
      final fileName = newName ?? path.basename(sourcePath);
      final destinationPath = path.join(destinationDir, fileName);

      await FileHelper.copyFile(sourcePath, destinationPath);
      return destinationPath;
    } catch (e) {
      throw FileException(message: 'Failed to copy file: $e');
    }
  }

  // Move file
  Future<String> moveFile(String sourcePath, String destinationDir,
      {String? newName}) async {
    try {
      final fileName = newName ?? path.basename(sourcePath);
      final destinationPath = path.join(destinationDir, fileName);

      await FileHelper.moveFile(sourcePath, destinationPath);
      return destinationPath;
    } catch (e) {
      throw FileException(message: 'Failed to move file: $e');
    }
  }

  // Get directory size
  Future<int> getDirectorySize(String directoryPath) async {
    try {
      return await FileHelper.getDirectorySize(directoryPath);
    } catch (e) {
      throw FileException(message: 'Failed to get directory size: $e');
    }
  }

  // Clean cache
  Future<void> cleanCache() async {
    try {
      await FileHelper.cleanCacheDirectory();
    } catch (e) {
      // Don't throw error for cache cleanup
    }
  }

  // Get storage info
  Future<StorageInfo> getStorageInfo() async {
    try {
      final receiptsDir = await FileHelper.getReceiptsDirectory();
      final backupsDir = await FileHelper.getBackupsDirectory();
      final exportsDir = await FileHelper.getExportsDirectory();

      final receiptsSize = await getDirectorySize(receiptsDir.path);
      final backupsSize = await getDirectorySize(backupsDir.path);
      final exportsSize = await getDirectorySize(exportsDir.path);

      final totalSize = receiptsSize + backupsSize + exportsSize;

      return StorageInfo(
        receiptsSize: receiptsSize,
        backupsSize: backupsSize,
        exportsSize: exportsSize,
        totalSize: totalSize,
      );
    } catch (e) {
      throw FileException(message: 'Failed to get storage info: $e');
    }
  }

  // Clear old files
  Future<void> clearOldFiles({
    int keepReceiptDays = 365,
    int keepBackupCount = 10,
    int keepExportDays = 30,
  }) async {
    try {
      final now = DateTime.now();

      // Clear old receipts
      final receipts = await listReceiptFiles();
      for (final receipt in receipts) {
        final stats = await receipt.stat();
        final age = now.difference(stats.modified).inDays;
        if (age > keepReceiptDays) {
          await receipt.delete();
        }
      }

      // Clear old exports
      final exports = await listExportFiles();
      for (final export in exports) {
        final stats = await export.stat();
        final age = now.difference(stats.modified).inDays;
        if (age > keepExportDays) {
          await export.delete();
        }
      }

      // Keep only latest backups
      final backups = await listBackupFiles();
      backups.sort((a, b) {
        final aStats = a.statSync();
        final bStats = b.statSync();
        return bStats.modified.compareTo(aStats.modified);
      });

      if (backups.length > keepBackupCount) {
        final backupsToDelete = backups.skip(keepBackupCount);
        for (final backup in backupsToDelete) {
          await backup.delete();
        }
      }
    } catch (e) {
      // Don't throw error for cleanup operations
    }
  }
}

// Storage info model
class StorageInfo {
  final int receiptsSize;
  final int backupsSize;
  final int exportsSize;
  final int totalSize;

  const StorageInfo({
    required this.receiptsSize,
    required this.backupsSize,
    required this.exportsSize,
    required this.totalSize,
  });

  String get formattedReceiptsSize => FileHelper.formatFileSize(receiptsSize);
  String get formattedBackupsSize => FileHelper.formatFileSize(backupsSize);
  String get formattedExportsSize => FileHelper.formatFileSize(exportsSize);
  String get formattedTotalSize => FileHelper.formatFileSize(totalSize);
}
