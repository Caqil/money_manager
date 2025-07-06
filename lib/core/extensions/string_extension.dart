import 'dart:convert';
import 'dart:ui';
import 'package:crypto/crypto.dart';

import '../utils/currency_formatter.dart';
import '../utils/file_helper.dart';
import '../utils/validation_helper.dart';

extension StringExtension on String {
  // Null/Empty checks
  bool get isNullOrEmpty => trim().isEmpty;
  bool get isNotNullOrEmpty => trim().isNotEmpty;

  // Capitalization
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String get capitalizeWords {
    return split(' ')
        .map((word) => word.isEmpty ? word : word.capitalize)
        .join(' ');
  }

  String get toTitleCase => capitalizeWords;

  // Truncation
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  String truncateWords(int maxWords, {String suffix = '...'}) {
    final words = split(' ');
    if (words.length <= maxWords) return this;
    return '${words.take(maxWords).join(' ')}$suffix';
  }

  // Validation helpers
  bool get isValidEmail => ValidationHelper.isValidEmail(this);
  bool get isValidPhone => ValidationHelper.isValidPhoneNumber(this);
  bool get isValidAmount => ValidationHelper.isValidAmount(this);
  bool get isValidPositiveAmount =>
      ValidationHelper.isValidPositiveAmount(this);
  bool get isValidPin => ValidationHelper.isValidPin(this);
  bool get isValidName => ValidationHelper.isValidName(this);

  // Parsing
  double? get toDouble => double.tryParse(trim());
  int? get toInt => int.tryParse(trim());
  DateTime? get toDateTime => DateTime.tryParse(this);

  // Currency parsing
  double? toCurrencyAmount({String currency = 'USD'}) {
    return CurrencyFormatter.parse(this, currency: currency);
  }

  // Remove formatting
  String get digitsOnly => replaceAll(RegExp(r'[^\d]'), '');
  String get lettersOnly => replaceAll(RegExp(r'[^a-zA-Z]'), '');
  String get alphanumericOnly => replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  // File operations
  String get fileExtension => FileHelper.getFileExtension(this);
  String get fileNameWithoutExtension =>
      FileHelper.getFileNameWithoutExtension(this);
  bool hasValidExtension(List<String> extensions) =>
      FileHelper.isValidFileExtension(this, extensions);

  // URL operations
  bool get isValidUrl {
    try {
      final uri = Uri.parse(this);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Text processing
  String removeExtraSpaces() {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String removeSpecialCharacters() {
    return replaceAll(RegExp(r'[^\w\s]'), '');
  }

  String toSlug() {
    return toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  // Search/Filter helpers
  bool containsIgnoreCase(String other) {
    return toLowerCase().contains(other.toLowerCase());
  }

  bool startsWithIgnoreCase(String other) {
    return toLowerCase().startsWith(other.toLowerCase());
  }

  bool endsWithIgnoreCase(String other) {
    return toLowerCase().endsWith(other.toLowerCase());
  }

  // Phone formatting
  String formatAsPhone() {
    final cleaned = digitsOnly;
    if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length == 11 && cleaned.startsWith('1')) {
      return '+1 (${cleaned.substring(1, 4)}) ${cleaned.substring(4, 7)}-${cleaned.substring(7)}';
    }
    return this;
  }

  // Credit card formatting
  String formatAsCreditCard() {
    final cleaned = digitsOnly;
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  // Mask sensitive data
  String maskCreditCard() {
    if (length < 4) return this;
    return '${'*' * (length - 4)}${substring(length - 4)}';
  }

  String maskEmail() {
    if (!contains('@')) return this;
    final parts = split('@');
    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) return this;

    final maskedUsername =
        '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}';
    return '$maskedUsername@$domain';
  }

  // Color conversion
  Color? toColor() {
    try {
      var hexString = this;
      if (hexString.startsWith('#')) {
        hexString = hexString.substring(1);
      }
      if (hexString.length == 6) {
        hexString = 'FF$hexString';
      }
      return Color(int.parse(hexString, radix: 16));
    } catch (e) {
      return null;
    }
  }

  // Base64 operations
  String toBase64() {
    return base64Encode(utf8.encode(this));
  }

  String? fromBase64() {
    try {
      return utf8.decode(base64Decode(this));
    } catch (e) {
      return null;
    }
  }

  // Hash operations
  String toMD5() {
    return md5.convert(utf8.encode(this)).toString();
  }

  String toSHA256() {
    return sha256.convert(utf8.encode(this)).toString();
  }

  // Word count
  int get wordCount => trim().isEmpty ? 0 : trim().split(RegExp(r'\s+')).length;

  // Character count (excluding spaces)
  int get characterCount => replaceAll(' ', '').length;

  // Reverse string
  String get reversed => split('').reversed.join('');

  // Check if palindrome
  bool get isPalindrome {
    final cleaned = toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return cleaned == cleaned.reversed;
  }

  // Generate initials
  String get initials {
    return split(' ')
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join('');
  }

  // Wrap text
  String wrapText(int lineLength) {
    if (length <= lineLength) return this;

    final words = split(' ');
    final lines = <String>[];
    var currentLine = '';

    for (final word in words) {
      if ((currentLine + word).length <= lineLength) {
        currentLine += currentLine.isEmpty ? word : ' $word';
      } else {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
          currentLine = word;
        } else {
          lines.add(word);
        }
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines.join('\n');
  }
}
