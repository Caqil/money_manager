import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/encryption_helper.dart' show EncryptionHelper;

class EncryptionService {
  static EncryptionService? _instance;
  late final SharedPreferences _prefs;
  String? _encryptionKey;
  bool _isInitialized = false;

  EncryptionService._internal();

  factory EncryptionService() {
    _instance ??= EncryptionService._internal();
    return _instance!;
  }

  // Initialize encryption service
  static Future<EncryptionService> init() async {
    final instance = EncryptionService();
    await instance._initialize();
    return instance;
  }

  Future<void> _initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Load or generate encryption key
      _encryptionKey = _prefs.getString('encryption_key');
      if (_encryptionKey == null) {
        _encryptionKey = EncryptionHelper.generateKey();
        await _prefs.setString('encryption_key', _encryptionKey!);
      }
      
      _isInitialized = true;
    } catch (e) {
      throw EncryptionException(message: 'Failed to initialize encryption service: $e');
    }
  }

  // Check if encryption is enabled
  bool get isEncryptionEnabled {
    return _prefs.getBool('encryption_enabled') ?? false;
  }

  // Enable encryption
  Future<void> enableEncryption() async {
    try {
      if (!_isInitialized) {
        await _initialize();
      }
      await _prefs.setBool('encryption_enabled', true);
    } catch (e) {
      throw EncryptionException(message: 'Failed to enable encryption: $e');
    }
  }

  // Disable encryption
  Future<void> disableEncryption() async {
    try {
      await _prefs.setBool('encryption_enabled', false);
    } catch (e) {
      throw EncryptionException(message: 'Failed to disable encryption: $e');
    }
  }

  // Encrypt string
  Future<String> encryptString(String data) async {
    try {
      if (!_isInitialized || _encryptionKey == null) {
        throw EncryptionException(message: 'Encryption service not initialized');
      }
      
      return EncryptionHelper.encrypt(data, _encryptionKey!);
    } catch (e) {
      throw EncryptionException(message: 'Failed to encrypt string: $e');
    }
  }

  // Decrypt string
  Future<String> decryptString(String encryptedData) async {
    try {
      if (!_isInitialized || _encryptionKey == null) {
        throw DecryptionException(message: 'Encryption service not initialized');
      }
      
      return EncryptionHelper.decrypt(encryptedData, _encryptionKey!);
    } catch (e) {
      throw DecryptionException(message: 'Failed to decrypt string: $e');
    }
  }

  // Encrypt double value
  Future<String> encryptDouble(double value) async {
    try {
      return await encryptString(value.toString());
    } catch (e) {
      throw EncryptionException(message: 'Failed to encrypt double: $e');
    }
  }

  // Decrypt double value
  Future<double> decryptDouble(String encryptedValue) async {
    try {
      final decryptedString = await decryptString(encryptedValue);
      return double.parse(decryptedString);
    } catch (e) {
      throw DecryptionException(message: 'Failed to decrypt double: $e');
    }
  }

  // Encrypt JSON data
  Future<String> encryptJson(Map<String, dynamic> data) async {
    try {
      if (!_isInitialized || _encryptionKey == null) {
        throw EncryptionException(message: 'Encryption service not initialized');
      }
      
      return EncryptionHelper.encryptJson(data, _encryptionKey!);
    } catch (e) {
      throw EncryptionException(message: 'Failed to encrypt JSON: $e');
    }
  }

  // Decrypt JSON data
  Future<Map<String, dynamic>> decryptJson(String encryptedData) async {
    try {
      if (!_isInitialized || _encryptionKey == null) {
        throw DecryptionException(message: 'Encryption service not initialized');
      }
      
      return EncryptionHelper.decryptJson(encryptedData, _encryptionKey!);
    } catch (e) {
      throw DecryptionException(message: 'Failed to decrypt JSON: $e');
    }
  }

  // Change encryption key
  Future<void> changeEncryptionKey() async {
    try {
      // Generate new key
      final newKey = EncryptionHelper.generateKey();
      
      // Store new key
      await _prefs.setString('encryption_key', newKey);
      _encryptionKey = newKey;
      
      // Note: This would require re-encrypting all existing data
      // which should be handled by the calling code
    } catch (e) {
      throw EncryptionException(message: 'Failed to change encryption key: $e');
    }
  }

  // Get encryption status
  EncryptionStatus getEncryptionStatus() {
    if (!_isInitialized) {
      return EncryptionStatus.notInitialized;
    } else if (isEncryptionEnabled) {
      return EncryptionStatus.enabled;
    } else {
      return EncryptionStatus.disabled;
    }
  }

  // Reset encryption
  Future<void> resetEncryption() async {
    try {
      await _prefs.remove('encryption_key');
      await _prefs.remove('encryption_enabled');
      _encryptionKey = null;
      _isInitialized = false;
      
      // Re-initialize with new key
      await _initialize();
    } catch (e) {
      throw EncryptionException(message: 'Failed to reset encryption: $e');
    }
  }

  // Test encryption/decryption
  Future<bool> testEncryption() async {
    try {
      const testData = 'test_encryption_data_123';
      final encrypted = await encryptString(testData);
      final decrypted = await decryptString(encrypted);
      return decrypted == testData;
    } catch (e) {
      return false;
    }
  }
}

// Encryption status enum
enum EncryptionStatus {
  notInitialized,
  disabled,
  enabled,
}