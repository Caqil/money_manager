
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/account.dart';
import '../../../data/models/category.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/custom_app_bar.dart';

// Voice recognition states
enum VoiceState {
  idle,
  listening,
  processing,
  completed,
  error,
}

// Parsed voice command result
class VoiceTransactionData {
  final double? amount;
  final TransactionType? type;
  final String? categoryName;
  final String? accountName;
  final String? description;
  final DateTime? date;

  const VoiceTransactionData({
    this.amount,
    this.type,
    this.categoryName,
    this.accountName,
    this.description,
    this.date,
  });

  VoiceTransactionData copyWith({
    double? amount,
    TransactionType? type,
    String? categoryName,
    String? accountName,
    String? description,
    DateTime? date,
  }) {
    return VoiceTransactionData(
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryName: categoryName ?? this.categoryName,
      accountName: accountName ?? this.accountName,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }
}

class VoiceInputScreen extends ConsumerStatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen>
    with TickerProviderStateMixin {
  final _uuid = const Uuid();

  VoiceState _voiceState = VoiceState.idle;
  VoiceTransactionData? _parsedData;
  String _recognizedText = '';
  String? _errorMessage;
  bool _isCreatingTransaction = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  // Example voice commands for help
  List<String> get _exampleCommands => [
        "transactions.voiceExample1".tr(),
        "transactions.voiceExample2".tr(),
        "transactions.voiceExample3".tr(),
        "transactions.voiceExample4".tr(),
        "transactions.voiceExample5".tr(),
      ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'transactions.voiceInput'.tr(),
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: _showHelpDialog,
            icon: const Icon(Icons.help_outline),
            tooltip: 'transactions.voiceCommandsHelp'.tr(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          children: [
            // Voice Input Section
            _buildVoiceInputSection(),

            const SizedBox(height: AppDimensions.spacingXl),

            // Recognized Text Display
            if (_recognizedText.isNotEmpty) _buildRecognizedTextSection(),

            // Parsed Data Preview
            if (_parsedData != null) ...[
              const SizedBox(height: AppDimensions.spacingL),
              _buildParsedDataSection(),
            ],

            // Error Display
            if (_errorMessage != null) ...[
              const SizedBox(height: AppDimensions.spacingL),
              _buildErrorSection(),
            ],

            // Action Buttons
            if (_parsedData != null || _errorMessage != null) ...[
              const SizedBox(height: AppDimensions.spacingXl),
              _buildActionButtons(),
            ],

            // Example Commands
            const SizedBox(height: AppDimensions.spacingXl),
            _buildExampleCommands(),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceInputSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingXl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      child: Column(
        children: [
          // Voice Animation
          _buildVoiceAnimation(),

          const SizedBox(height: AppDimensions.spacingL),

          // Status Text
          Text(
            _getStatusText(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppDimensions.spacingS),

          // Subtitle
          Text(
            _getSubtitleText(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // Voice Button
          _buildVoiceButton(),
        ],
      ),
    );
  }

  Widget _buildVoiceAnimation() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer wave animation (when listening)
          if (_voiceState == VoiceState.listening)
            AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return Container(
                  width: 120 * (1 + _waveAnimation.value * 0.3),
                  height: 120 * (1 + _waveAnimation.value * 0.3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white
                          .withOpacity(0.3 * (1 - _waveAnimation.value)),
                      width: 2,
                    ),
                  ),
                );
              },
            ),

          // Pulse animation (when processing)
          if (_voiceState == VoiceState.processing)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                );
              },
            ),

          // Main microphone icon
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              _getMicrophoneIcon(),
              size: 40,
              color: _getMicrophoneColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton() {
    return SizedBox(
      width: 200,
      height: 50,
      child: ShadButton.raw(
        onPressed: _canInteract() ? _toggleVoiceInput : null,
        variant: ShadButtonVariant.outline,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getButtonIcon(),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Text(
              _getButtonText(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecognizedTextSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: ShadTheme.of(context).colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'transactions.voiceWhatIHeard'.tr(),
                style: ShadTheme.of(context).textTheme.h4,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            '"$_recognizedText"',
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedDataSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'transactions.transactionDetails'.tr(),
                style: ShadTheme.of(context).textTheme.h4.copyWith(
                      color: AppColors.success,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Parsed fields
          if (_parsedData!.type != null)
            _buildDetailRow('transactions.type'.tr(),
                _parsedData!.type!.name.toUpperCase()),
          if (_parsedData!.amount != null)
            _buildDetailRow('transactions.amount'.tr(),
                CurrencyFormatter.format(_parsedData!.amount!)),
          if (_parsedData!.categoryName != null)
            _buildDetailRow(
                'categories.category'.tr(), _parsedData!.categoryName!),
          if (_parsedData!.accountName != null)
            _buildDetailRow('accounts.account'.tr(), _parsedData!.accountName!),
          if (_parsedData!.description != null)
            _buildDetailRow(
                'transactions.description'.tr(), _parsedData!.description!),
          if (_parsedData!.date != null)
            _buildDetailRow('transactions.date'.tr(),
                DateFormat.yMMMd().format(_parsedData!.date!)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'transactions.voiceRecognitionError'.tr(),
                style: ShadTheme.of(context).textTheme.h4.copyWith(
                      color: AppColors.error,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_parsedData != null) {
      return Row(
        children: [
          Expanded(
            child: ShadButton.outline(
              onPressed: _tryAgain,
              child: Text('common.tryAgain'.tr()),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            flex: 2,
            child: ShadButton(
              onPressed: _isCreatingTransaction ? null : _createTransaction,
              child: _isCreatingTransaction
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text('common.creating'.tr()),
                      ],
                    )
                  : Text('transactions.createTransaction'.tr()),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ShadButton.outline(
          onPressed: _tryAgain,
          child: Text('Try Again'),
        ),
      );
    }
  }

  Widget _buildExampleCommands() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'transactions.voiceExampleCommands'.tr(),
          style: ShadTheme.of(context).textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        ..._exampleCommands.map((command) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border:
                    Border.all(color: ShadTheme.of(context).colorScheme.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.volume_up,
                    color: AppColors.secondary,
                    size: 16,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Text(
                      '"$command"',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // Voice state management methods
  String _getStatusText() {
    switch (_voiceState) {
      case VoiceState.idle:
        return 'transactions.voiceReady'.tr();
      case VoiceState.listening:
        return 'transactions.voiceListening'.tr();
      case VoiceState.processing:
        return 'transactions.voiceProcessing'.tr();
      case VoiceState.completed:
        return 'transactions.voiceCompleted'.tr();
      case VoiceState.error:
        return 'transactions.voiceFailed'.tr();
    }
  }

  String _getSubtitleText() {
    switch (_voiceState) {
      case VoiceState.idle:
        return 'transactions.voiceIdleSubtitle'.tr();
      case VoiceState.listening:
        return 'transactions.voiceListeningSubtitle'.tr();
      case VoiceState.processing:
        return 'transactions.voiceProcessingSubtitle'.tr();
      case VoiceState.completed:
        return 'transactions.voiceCompletedSubtitle'.tr();
      case VoiceState.error:
        return 'transactions.voiceErrorSubtitle'.tr();
    }
  }

  IconData _getMicrophoneIcon() {
    switch (_voiceState) {
      case VoiceState.idle:
        return Icons.mic;
      case VoiceState.listening:
        return Icons.mic;
      case VoiceState.processing:
        return Icons.graphic_eq;
      case VoiceState.completed:
        return Icons.check;
      case VoiceState.error:
        return Icons.mic_off;
    }
  }

  Color _getMicrophoneColor() {
    switch (_voiceState) {
      case VoiceState.idle:
        return AppColors.primary;
      case VoiceState.listening:
        return AppColors.error;
      case VoiceState.processing:
        return AppColors.warning;
      case VoiceState.completed:
        return AppColors.success;
      case VoiceState.error:
        return AppColors.error;
    }
  }

  IconData _getButtonIcon() {
    switch (_voiceState) {
      case VoiceState.idle:
        return Icons.mic;
      case VoiceState.listening:
        return Icons.stop;
      case VoiceState.processing:
        return Icons.hourglass_empty;
      case VoiceState.completed:
        return Icons.refresh;
      case VoiceState.error:
        return Icons.refresh;
    }
  }

  String _getButtonText() {
    switch (_voiceState) {
      case VoiceState.idle:
        return 'transactions.voiceStartSpeaking'.tr();
      case VoiceState.listening:
        return 'transactions.voiceStopListening'.tr();
      case VoiceState.processing:
        return 'transactions.voiceProcessing'.tr();
      case VoiceState.completed:
        return 'transactions.voiceSpeakAgain'.tr();
      case VoiceState.error:
        return 'common.tryAgain'.tr();
    }
  }

  bool _canInteract() {
    return _voiceState != VoiceState.processing && !_isCreatingTransaction;
  }

  // Voice input methods (placeholder implementations)
  void _toggleVoiceInput() {
    if (_voiceState == VoiceState.listening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() {
    setState(() {
      _voiceState = VoiceState.listening;
      _recognizedText = '';
      _parsedData = null;
      _errorMessage = null;
    });

    // Start wave animation
    _waveController.repeat();

    // Simulate voice recognition (replace with actual implementation)
    _simulateVoiceRecognition();
  }

  void _stopListening() {
    setState(() {
      _voiceState = VoiceState.processing;
    });

    _waveController.stop();
    _pulseController.repeat();

    // Process the recognized text
    _processVoiceInput();
  }

  void _simulateVoiceRecognition() {
    // Simulate listening delay
    Future.delayed(const Duration(seconds: 3), () {
      if (_voiceState == VoiceState.listening) {
        setState(() {
          _recognizedText = 'transactions.voiceExample1'.tr();
        });
        _stopListening();
      }
    });
  }

  void _processVoiceInput() {
    // Simulate processing delay
    Future.delayed(const Duration(seconds: 2), () {
      _pulseController.stop();

      // Parse the voice input (placeholder implementation)
      final parsed = _parseVoiceCommand(_recognizedText);

      if (parsed != null) {
        setState(() {
          _voiceState = VoiceState.completed;
          _parsedData = parsed;
        });
      } else {
        setState(() {
          _voiceState = VoiceState.error;
          _errorMessage = 'transactions.voiceCouldNotUnderstand'.tr();
        });
      }
    });
  }

  VoiceTransactionData? _parseVoiceCommand(String text) {
    // Simple parsing logic (replace with more sophisticated NLP)
    final lowerText = text.toLowerCase();

    // Extract amount
    final amountRegex = RegExp(r'(\d+(?:\.\d{2})?)\s*(?:dollars?|bucks?|\$)');
    final amountMatch = amountRegex.firstMatch(lowerText);
    final amount =
        amountMatch != null ? double.tryParse(amountMatch.group(1)!) : null;

    // Determine transaction type
    TransactionType? type;
    if (lowerText.contains('spent') ||
        lowerText.contains('paid') ||
        lowerText.contains('bought')) {
      type = TransactionType.expense;
    } else if (lowerText.contains('received') ||
        lowerText.contains('got') ||
        lowerText.contains('earned')) {
      type = TransactionType.income;
    } else if (lowerText.contains('transfer')) {
      type = TransactionType.transfer;
    }

    // Extract category hints
    String? categoryName;
    if (lowerText.contains('lunch') ||
        lowerText.contains('dinner') ||
        lowerText.contains('food') ||
        lowerText.contains('restaurant')) {
      categoryName = 'Food & Dining';
    } else if (lowerText.contains('gas') || lowerText.contains('fuel')) {
      categoryName = 'Transportation';
    } else if (lowerText.contains('salary') || lowerText.contains('paycheck')) {
      categoryName = 'Salary';
    }

    // Extract account hints
    String? accountName;
    if (lowerText.contains('checking')) {
      accountName = 'Checking';
    } else if (lowerText.contains('savings')) {
      accountName = 'Savings';
    }

    if (amount == null || type == null) {
      return null; // Could not parse essential information
    }

    return VoiceTransactionData(
      amount: amount,
      type: type,
      categoryName: categoryName,
      accountName: accountName,
      description: text, // Use original text as description
      date: DateTime.now(),
    );
  }

  void _tryAgain() {
    setState(() {
      _voiceState = VoiceState.idle;
      _recognizedText = '';
      _parsedData = null;
      _errorMessage = null;
    });
  }

  Future<void> _createTransaction() async {
    if (_parsedData == null) return;

    setState(() {
      _isCreatingTransaction = true;
    });

    try {
      // Get accounts and categories to find IDs
      final accountsAsync = ref.read(accountListProvider);
      final categoriesAsync = ref.read(categoryListProvider);

      // Wait until both AsyncValues are loaded
      if (accountsAsync is! AsyncData<List<Account>> || categoriesAsync is! AsyncData<List<Category>>) {
        // Optionally, show a loading indicator or handle this case
        setState(() {
          _isCreatingTransaction = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.loadingData'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final accounts = accountsAsync.value;
      final categories = categoriesAsync.value;

      // Find matching account
      Account? account;
      if (_parsedData!.accountName != null) {
        account = accounts.firstWhere(
          (acc) => acc.name
              .toLowerCase()
              .contains(_parsedData!.accountName!.toLowerCase()),
          orElse: () => accounts.first,
        );
      } else {
        account = accounts.first;
      }

      // Find matching category
      Category? category;
      if (_parsedData!.categoryName != null &&
          _parsedData!.type != TransactionType.transfer) {
        category = categories.firstWhere(
          (cat) => cat.name
              .toLowerCase()
              .contains(_parsedData!.categoryName!.toLowerCase()),
          orElse: () => categories.first,
        );
      } else if (_parsedData!.type != TransactionType.transfer) {
        category = categories.first;
      }

      // Create transaction
      final transaction = Transaction(
        id: _uuid.v4(),
        amount: _parsedData!.amount!,
        categoryId: category?.id ?? '',
        date: _parsedData!.date ?? DateTime.now(),
        notes: _parsedData!.description,
        type: _parsedData!.type!,
        accountId: account.id,
        currency: account.currency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final transactionId = await ref
          .read(transactionListProvider.notifier)
          .addTransaction(transaction);

      if (transactionId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'transactions.voiceTransactionCreated'.tr(),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        throw Exception('Failed to save transaction');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${'transactions.createTransactionError'.tr()}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingTransaction = false;
        });
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('transactions.voiceCommandsHelp'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'transactions.voiceHelpIntro'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              _buildHelpItem('transactions.amount'.tr(),
                  'transactions.voiceHelpAmount'.tr()),
              _buildHelpItem('transactions.voiceHelpAction'.tr(),
                  'transactions.voiceHelpActionDesc'.tr()),
              _buildHelpItem('categories.category'.tr(),
                  'transactions.voiceHelpCategory'.tr()),
              _buildHelpItem('accounts.account'.tr(),
                  'transactions.voiceHelpAccount'.tr()),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                'common.examples'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              ..._exampleCommands.take(3).map((cmd) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppDimensions.spacingXs),
                    child: Text(
                      '• "$cmd"',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.gotIt'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          Text(description),
        ],
      ),
    );
  }
}
