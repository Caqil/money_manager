import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../errors/exceptions.dart';

class FileHelper {
  FileHelper._();

  // Get application documents directory
  static Future<Directory> getAppDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  // Get application cache directory
  static Future<Directory> getAppCacheDirectory() async {
    return await getTemporaryDirectory();
  }

  // Create directory if it doesn't exist
  static Future<Directory> createDirectory(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  // Get receipts directory
  static Future<Directory> getReceiptsDirectory() async {
    final appDir = await getAppDocumentsDirectory();
    final receiptsPath = path.join(appDir.path, 'receipts');
    return await createDirectory(receiptsPath);
  }

  // Get backups directory
  static Future<Directory> getBackupsDirectory() async {
    final appDir = await getAppDocumentsDirectory();
    final backupsPath = path.join(appDir.path, 'backups');
    return await createDirectory(backupsPath);
  }

  // Get exports directory
  static Future<Directory> getExportsDirectory() async {
    final appDir = await getAppDocumentsDirectory();
    final exportsPath = path.join(appDir.path, 'exports');
    return await createDirectory(exportsPath);
  }

  // Save file
  static Future<File> saveFile(String fileName, Uint8List data,
      {String? subDirectory}) async {
    final appDir = await getAppDocumentsDirectory();
    final dirPath = subDirectory != null
        ? path.join(appDir.path, subDirectory)
        : appDir.path;

    await createDirectory(dirPath);
    final filePath = path.join(dirPath, fileName);
    final file = File(filePath);

    return await file.writeAsBytes(data);
  }

  // Read file
  static Future<Uint8List> readFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileNotFoundAppException(filePath: filePath);
    }
    return await file.readAsBytes();
  }

  // Delete file
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check if file exists
  static Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  // Get file size
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileNotFoundAppException(filePath: filePath);
    }
    return await file.length();
  }

  // Get file extension
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  // Get file name without extension
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  // Generate unique file name
  static String generateUniqueFileName(String baseName, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return '${baseName}_${timestamp}_$random.$extension';
  }

  // Validate file size
  static bool isValidFileSize(int fileSize, int maxSizeBytes) {
    return fileSize <= maxSizeBytes;
  }

  // Validate file extension
  static bool isValidFileExtension(
      String filePath, List<String> allowedExtensions) {
    final extension = getFileExtension(filePath).replaceFirst('.', '');
    return allowedExtensions.contains(extension.toLowerCase());
  }

  // Copy file
  static Future<File> copyFile(
      String sourcePath, String destinationPath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileNotFoundAppException(filePath: sourcePath);
    }

    // Create destination directory if it doesn't exist
    final destinationDir = Directory(path.dirname(destinationPath));
    if (!await destinationDir.exists()) {
      await destinationDir.create(recursive: true);
    }

    return await sourceFile.copy(destinationPath);
  }

  // Move file
  static Future<File> moveFile(
      String sourcePath, String destinationPath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileNotFoundAppException(filePath: sourcePath);
    }

    // Create destination directory if it doesn't exist
    final destinationDir = Directory(path.dirname(destinationPath));
    if (!await destinationDir.exists()) {
      await destinationDir.create(recursive: true);
    }

    return await sourceFile.rename(destinationPath);
  }

  // List files in directory
  static Future<List<File>> listFiles(String directoryPath,
      {String? extension}) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return [];
    }

    final entities = await directory.list().toList();
    final files = entities.whereType<File>().toList();

    if (extension != null) {
      return files
          .where(
              (file) => getFileExtension(file.path) == extension.toLowerCase())
          .toList();
    }

    return files;
  }

  // Clean cache directory
  static Future<void> cleanCacheDirectory() async {
    try {
      final cacheDir = await getAppCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
    } catch (e) {
      // Ignore errors during cache cleanup
    }
  }

  // Get directory size
  static Future<int> getDirectorySize(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return 0;
    }

    int size = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
    return size;
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
