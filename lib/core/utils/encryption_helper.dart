import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionHelper {
  EncryptionHelper._();

  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits

  // Generate a random key
  static String generateKey() {
    final random = Random.secure();
    final keyBytes = Uint8List(_keyLength);
    for (int i = 0; i < _keyLength; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    return base64.encode(keyBytes);
  }

  // Generate a random IV
  static String generateIV() {
    final random = Random.secure();
    final ivBytes = Uint8List(_ivLength);
    for (int i = 0; i < _ivLength; i++) {
      ivBytes[i] = random.nextInt(256);
    }
    return base64.encode(ivBytes);
  }

  // Encrypt data
  static String encrypt(String data, String keyString, {String? ivString}) {
    try {
      final key = Key(base64.decode(keyString));
      final iv = ivString != null
          ? IV(base64.decode(ivString))
          : IV.fromSecureRandom(_ivLength);
      final encrypter = Encrypter(AES(key));

      final encrypted = encrypter.encrypt(data, iv: iv);

      // Combine IV and encrypted data
      final combined = iv.bytes + encrypted.bytes;
      return base64.encode(combined);
    } catch (e) {
      throw EncryptionException(message: 'Failed to encrypt data: $e');
    }
  }

  // Decrypt data
  static String decrypt(String encryptedData, String keyString) {
    try {
      final key = Key(base64.decode(keyString));
      final combined = base64.decode(encryptedData);

      // Extract IV and encrypted data
      final iv = IV(combined.sublist(0, _ivLength));
      final encrypted = Encrypted(combined.sublist(_ivLength));

      final encrypter = Encrypter(AES(key));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw DecryptionException(message: 'Failed to decrypt data: $e');
    }
  }

  // Hash password using PBKDF2
  static String hashPassword(String password, String salt) {
    final saltBytes = utf8.encode(salt);
    final passwordBytes = utf8.encode(password);

    const iterations = 10000;
    const keyLength = 32;

    final digest = sha256;
    final hmac = Hmac(digest, saltBytes);

    // Simple PBKDF2 implementation
    var derivedKey = Uint8List(keyLength);
    var blockIndex = 1;
    var offset = 0;

    while (offset < keyLength) {
      final block = _pbkdf2Block(hmac, passwordBytes, blockIndex, iterations);
      final copyLength = math.min(block.length, keyLength - offset);
      derivedKey.setRange(offset, offset + copyLength, block);
      offset += copyLength;
      blockIndex++;
    }

    return base64.encode(derivedKey);
  }

  static Uint8List _pbkdf2Block(
      Hmac hmac, List<int> password, int blockIndex, int iterations) {
    final blockIndexBytes = Uint8List(4);
    blockIndexBytes.buffer.asByteData().setUint32(0, blockIndex, Endian.big);

    var u = hmac.convert(password + blockIndexBytes).bytes;
    final result = Uint8List.fromList(u);

    for (int i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (int j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result;
  }

  // Generate salt for password hashing
  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      saltBytes[i] = random.nextInt(256);
    }
    return base64.encode(saltBytes);
  }

  // Verify password
  static bool verifyPassword(
      String password, String hashedPassword, String salt) {
    final inputHash = hashPassword(password, salt);
    return inputHash == hashedPassword;
  }

  // Generate PIN hash
  static String hashPin(String pin, String salt) {
    return hashPassword(pin, salt);
  }

  // Verify PIN
  static bool verifyPin(String pin, String hashedPin, String salt) {
    return verifyPassword(pin, hashedPin, salt);
  }

  // Encrypt sensitive double values (amounts)
  static String encryptAmount(double amount, String keyString) {
    return encrypt(amount.toString(), keyString);
  }

  // Decrypt sensitive double values (amounts)
  static double decryptAmount(String encryptedAmount, String keyString) {
    final decryptedString = decrypt(encryptedAmount, keyString);
    return double.parse(decryptedString);
  }

  // Encrypt JSON data
  static String encryptJson(Map<String, dynamic> data, String keyString) {
    final jsonString = jsonEncode(data);
    return encrypt(jsonString, keyString);
  }

  // Decrypt JSON data
  static Map<String, dynamic> decryptJson(
      String encryptedData, String keyString) {
    final decryptedString = decrypt(encryptedData, keyString);
    return jsonDecode(decryptedString) as Map<String, dynamic>;
  }
}

// Custom Exceptions for Encryption
class EncryptionException implements Exception {
  final String message;
  const EncryptionException({required this.message});

  @override
  String toString() => 'EncryptionException: $message';
}

class DecryptionException implements Exception {
  final String message;
  const DecryptionException({required this.message});

  @override
  String toString() => 'DecryptionException: $message';
}
