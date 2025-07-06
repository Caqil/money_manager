import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/dimensions.dart';
import '../../core/enums/transaction_type.dart';
import '../../core/errors/exceptions.dart';

class VoiceService {
  static VoiceService? _instance;
  late final SpeechToText _speechToText;
  bool _isInitialized = false;
  bool _isListening = false;

  VoiceService._internal();

  factory VoiceService() {
    _instance ??= VoiceService._internal();
    return _instance!;
  }

  // Initialize voice service
  static Future<VoiceService> init() async {
    final instance = VoiceService();
    await instance._initialize();
    return instance;
  }

  Future<void> _initialize() async {
    try {
      _speechToText = SpeechToText();
      _isInitialized = await _speechToText.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );

      if (!_isInitialized) {
        throw Exception('Failed to initialize speech recognition');
      }
    } catch (e) {
      throw Exception('Failed to initialize voice service: $e');
    }
  }

  // Check if speech recognition is available
  Future<bool> isAvailable() async {
    try {
      if (!_isInitialized) {
        await _initialize();
      }
      return _speechToText.isAvailable;
    } catch (e) {
      return false;
    }
  }

  // Request microphone permission
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.microphone.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  // Check microphone permission
  Future<bool> hasPermission() async {
    try {
      final status = await Permission.microphone.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  // Start listening for voice input
  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'en_US',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      if (!await isAvailable()) {
        throw Exception('Speech recognition not available');
      }

      if (!await hasPermission()) {
        final granted = await requestPermission();
        if (!granted) {
          throw PermissionException(message: 'Microphone permission denied');
        }
      }

      if (_isListening) {
        await stopListening();
      }

      _isListening = true;

      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: localeId,
        listenFor: timeout,
        pauseFor: AppConstants.voiceInputPause,
        partialResults: true,
        cancelOnError: true,
      );
    } catch (e) {
      _isListening = false;
      if (e is AppException || e is PermissionException) rethrow;
      throw Exception('Failed to start voice recognition: $e');
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speechToText.stop();
        _isListening = false;
      }
    } catch (e) {
      _isListening = false;
      throw Exception('Failed to stop voice recognition: $e');
    }
  }

  // Cancel listening
  Future<void> cancelListening() async {
    try {
      if (_isListening) {
        await _speechToText.cancel();
        _isListening = false;
      }
    } catch (e) {
      _isListening = false;
      throw Exception('Failed to cancel voice recognition: $e');
    }
  }

  // Get available locales
  Future<List<LocaleName>> getAvailableLocales() async {
    try {
      if (!await isAvailable()) {
        return [];
      }
      return await _speechToText.locales();
    } catch (e) {
      return [];
    }
  }

  // Parse voice input for transaction data
  VoiceTransactionData? parseTransactionFromText(String text) {
    try {
      final words = text.toLowerCase().split(' ');

      // Extract amount
      double? amount;
      final amountRegex = RegExp(r'\b(\d+(?:\.\d{2})?)\b');
      final amountMatch = amountRegex.firstMatch(text);
      if (amountMatch != null) {
        amount = double.tryParse(amountMatch.group(1)!);
      }

      // Extract transaction type
      TransactionType? type;
      if (text.contains('spent') ||
          text.contains('paid') ||
          text.contains('bought')) {
        type = TransactionType.expense;
      } else if (text.contains('earned') ||
          text.contains('received') ||
          text.contains('got')) {
        type = TransactionType.income;
      }

      // Extract category hints
      String? categoryHint;
      final categoryKeywords = {
        'food': [
          'food',
          'restaurant',
          'lunch',
          'dinner',
          'breakfast',
          'coffee',
          'eat'
        ],
        'transport': [
          'gas',
          'fuel',
          'uber',
          'taxi',
          'bus',
          'train',
          'transport'
        ],
        'shopping': ['shopping', 'store', 'bought', 'purchase', 'amazon'],
        'entertainment': ['movie', 'game', 'entertainment', 'fun', 'concert'],
        'utilities': ['electric', 'water', 'gas', 'internet', 'phone', 'bill'],
      };

      for (final entry in categoryKeywords.entries) {
        if (entry.value
            .any((keyword) => text.toLowerCase().contains(keyword))) {
          categoryHint = entry.key;
          break;
        }
      }

      // Extract notes (simplified)
      String notes = text;
      if (amount != null) {
        notes = text.replaceAll(amountMatch!.group(0)!, '').trim();
      }

      return VoiceTransactionData(
        amount: amount,
        type: type,
        categoryHint: categoryHint,
        notes: notes.isNotEmpty ? notes : null,
      );
    } catch (e) {
      return null;
    }
  }

  // Check if currently listening
  bool get isListening => _isListening;

  // Check if initialized
  bool get isInitialized => _isInitialized;

  // Private methods
  void _onError(dynamic error) {
    _isListening = false;
    // Handle error - could notify listeners
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  // Dispose
  void dispose() {
    if (_isListening) {
      stopListening();
    }
  }
}

// Voice transaction data model
class VoiceTransactionData {
  final double? amount;
  final TransactionType? type;
  final String? categoryHint;
  final String? notes;

  const VoiceTransactionData({
    this.amount,
    this.type,
    this.categoryHint,
    this.notes,
  });

  bool get isValid => amount != null && amount! > 0;
}
