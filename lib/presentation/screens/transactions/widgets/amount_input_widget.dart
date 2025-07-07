import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/transaction.dart';
import '../../../providers/settings_provider.dart';

class AmountInputWidget extends ConsumerStatefulWidget {
  final double? initialAmount;
  final Function(double?) onAmountChanged;
  final String? label;
  final String? placeholder;
  final bool enabled;
  final bool required;
  final TransactionType? transactionType;
  final String? currency;
  final String? errorText;
  final bool autofocus;
  final bool showCalculator;
  final bool showCurrencySymbol;
  final double? maxAmount;
  final double? minAmount;

  const AmountInputWidget({
    super.key,
    this.initialAmount,
    required this.onAmountChanged,
    this.label,
    this.placeholder,
    this.enabled = true,
    this.required = false,
    this.transactionType,
    this.currency,
    this.errorText,
    this.autofocus = false,
    this.showCalculator = true,
    this.showCurrencySymbol = true,
    this.maxAmount,
    this.minAmount,
  });

  @override
  ConsumerState<AmountInputWidget> createState() => _AmountInputWidgetState();
}

class _AmountInputWidgetState extends ConsumerState<AmountInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _validationError;
  bool _isCalculatorVisible = false;
  double? _currentAmount;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      _currentAmount = widget.initialAmount;
      _controller.text = _formatAmountForDisplay(widget.initialAmount!);
    }
    _controller.addListener(_onTextChanged);

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(AmountInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAmount != oldWidget.initialAmount) {
      if (widget.initialAmount != null) {
        _currentAmount = widget.initialAmount;
        _controller.text = _formatAmountForDisplay(widget.initialAmount!);
      } else {
        _currentAmount = null;
        _controller.clear();
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    if (text.isEmpty) {
      setState(() {
        _currentAmount = null;
        _validationError = null;
      });
      widget.onAmountChanged(null);
      return;
    }

    // Parse the amount
    final amount = _parseAmount(text);
    if (amount != null) {
      setState(() {
        _currentAmount = amount;
        _validationError = _validateAmount(amount);
      });
      widget.onAmountChanged(amount);
    } else {
      setState(() {
        _currentAmount = null;
        _validationError = 'transactions.invalidAmount'.tr();
      });
      widget.onAmountChanged(null);
    }
  }

  String? _validateAmount(double amount) {
    if (widget.required && amount <= 0) {
      return 'transactions.amountRequired'.tr();
    }

    if (widget.minAmount != null && amount < widget.minAmount!) {
      return 'transactions.amountTooSmall'.tr(
        namedArgs: {'min': _formatAmountForDisplay(widget.minAmount!)},
      );
    }

    if (widget.maxAmount != null && amount > widget.maxAmount!) {
      return 'transactions.amountTooLarge'.tr(
        namedArgs: {'max': _formatAmountForDisplay(widget.maxAmount!)},
      );
    }

    return null;
  }

  double? _parseAmount(String text) {
    // Remove currency symbols and formatting
    final effectiveCurrency = widget.currency ?? _getDefaultCurrency();
    return CurrencyFormatter.parse(text, currency: effectiveCurrency);
  }

  String _formatAmountForDisplay(double amount) {
    // For input display, we use a simplified format
    return amount.toStringAsFixed(2);
  }

  String _getDefaultCurrency() {
    final settings = ref.read(settingsStateProvider);
    return settings.baseCurrency;
  }

  Color _getAmountColor() {
    if (widget.transactionType == null || _currentAmount == null) {
      return AppColors.lightOnSurface;
    }

    switch (widget.transactionType!) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.transfer:
        return AppColors.transfer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final effectiveCurrency = widget.currency ?? _getDefaultCurrency();
    final currencySymbol = CurrencyFormatter.getSymbol(effectiveCurrency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: theme.textTheme.h4,
              ),
              if (widget.required)
                Text(
                  ' *',
                  style: theme.textTheme.h4.copyWith(
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
        ],

        // Amount Input Field
        Row(
          children: [
            // Currency Symbol
            if (widget.showCurrencySymbol) ...[
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted,
                  border: Border.all(color: theme.colorScheme.border),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusS),
                    bottomLeft: Radius.circular(AppDimensions.radiusS),
                  ),
                ),
                child: Center(
                  child: Text(
                    currencySymbol,
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getAmountColor(),
                    ),
                  ),
                ),
              ),
            ],

            // Amount Input
            Expanded(
              child: ShadInputFormField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                placeholder:
                    Text(widget.placeholder ?? 'forms.enterAmount'.tr()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  _AmountInputFormatter(),
                ],
                textAlign: TextAlign.end,
                style: theme.textTheme.h3.copyWith(
                  color: _getAmountColor(),
                  fontWeight: FontWeight.w600,
                ),
                decoration: ShadDecoration(
                  border: ShadBorder(
                    radius: BorderRadius.only(
                      topLeft: widget.showCurrencySymbol
                          ? Radius.zero
                          : const Radius.circular(AppDimensions.radiusS),
                      bottomLeft: widget.showCurrencySymbol
                          ? Radius.zero
                          : const Radius.circular(AppDimensions.radiusS),
                      topRight: const Radius.circular(AppDimensions.radiusS),
                      bottomRight: const Radius.circular(AppDimensions.radiusS),
                    ),
                  ),
                ),
                validator: (value) {
                  if (_validationError != null) return _validationError;
                  if (widget.errorText != null) return widget.errorText;
                  return null;
                },
              ),
            ),
          ],
        ),

        // Error message
        if (_validationError != null || widget.errorText != null) ...[
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            _validationError ?? widget.errorText!,
            style: theme.textTheme.small.copyWith(
              color: AppColors.error,
            ),
          ),
        ],

        // Amount display in words (for large amounts)
        if (_currentAmount != null && _currentAmount! >= 1000) ...[
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            _formatAmountInWords(_currentAmount!),
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  void _showCalculator() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('transactions.calculator'.tr()),
        child: SizedBox(
          width: 300,
          child: _CalculatorWidget(
            initialValue: _currentAmount,
            onCalculated: (result) {
              setState(() {
                _currentAmount = result;
                _controller.text = _formatAmountForDisplay(result);
                _validationError = _validateAmount(result);
              });
              widget.onAmountChanged(result);
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  String _formatAmountInWords(double amount) {
    final effectiveCurrency = widget.currency ?? _getDefaultCurrency();
    return CurrencyFormatter.formatCompact(
      amount,
      currency: effectiveCurrency,
    );
  }
}

class _AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow empty input
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Validate decimal places
    final parts = newValue.text.split('.');
    if (parts.length > 2) {
      return oldValue;
    }

    if (parts.length == 2 && parts[1].length > 2) {
      return oldValue;
    }

    return newValue;
  }
}

class _CalculatorWidget extends StatefulWidget {
  final double? initialValue;
  final Function(double) onCalculated;

  const _CalculatorWidget({
    this.initialValue,
    required this.onCalculated,
  });

  @override
  State<_CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<_CalculatorWidget> {
  String _display = '0';
  String _operation = '';
  double _previousValue = 0;
  bool _waitingForOperand = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _display = widget.initialValue!.toStringAsFixed(2);
    }
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_waitingForOperand) {
        _display = number;
        _waitingForOperand = false;
      } else {
        _display = _display == '0' ? number : _display + number;
      }
    });
  }

  void _onOperationPressed(String operation) {
    final currentValue = double.tryParse(_display) ?? 0;

    if (_previousValue == 0) {
      _previousValue = currentValue;
    } else if (_operation.isNotEmpty) {
      final result = _calculate(_previousValue, currentValue, _operation);
      setState(() {
        _display = result.toStringAsFixed(2);
        _previousValue = result;
      });
    }

    setState(() {
      _operation = operation;
      _waitingForOperand = true;
    });
  }

  void _onEqualsPressed() {
    final currentValue = double.tryParse(_display) ?? 0;
    if (_operation.isNotEmpty) {
      final result = _calculate(_previousValue, currentValue, _operation);
      setState(() {
        _display = result.toStringAsFixed(2);
        _operation = '';
        _previousValue = 0;
        _waitingForOperand = true;
      });
    }
  }

  void _onClearPressed() {
    setState(() {
      _display = '0';
      _operation = '';
      _previousValue = 0;
      _waitingForOperand = false;
    });
  }

  void _onDecimalPressed() {
    if (!_display.contains('.')) {
      setState(() {
        _display = _display + '.';
      });
    }
  }

  double _calculate(double a, double b, String operation) {
    switch (operation) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b != 0 ? a / b : 0;
      default:
        return b;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: AppColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Text(
            _display,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Buttons
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 4,
          crossAxisSpacing: AppDimensions.spacingS,
          mainAxisSpacing: AppDimensions.spacingS,
          children: [
            _buildButton('C', _onClearPressed, color: AppColors.warning),
            _buildButton('⌫', () {
              setState(() {
                _display = _display.length > 1
                    ? _display.substring(0, _display.length - 1)
                    : '0';
              });
            }),
            _buildButton('÷', () => _onOperationPressed('÷'),
                color: AppColors.primary),
            _buildButton('×', () => _onOperationPressed('×'),
                color: AppColors.primary),
            _buildButton('7', () => _onNumberPressed('7')),
            _buildButton('8', () => _onNumberPressed('8')),
            _buildButton('9', () => _onNumberPressed('9')),
            _buildButton('-', () => _onOperationPressed('-'),
                color: AppColors.primary),
            _buildButton('4', () => _onNumberPressed('4')),
            _buildButton('5', () => _onNumberPressed('5')),
            _buildButton('6', () => _onNumberPressed('6')),
            _buildButton('+', () => _onOperationPressed('+'),
                color: AppColors.primary),
            _buildButton('1', () => _onNumberPressed('1')),
            _buildButton('2', () => _onNumberPressed('2')),
            _buildButton('3', () => _onNumberPressed('3')),
            _buildButton('=', _onEqualsPressed, color: AppColors.success),
            _buildButton('0', () => _onNumberPressed('0')),
            _buildButton('.', _onDecimalPressed),
            _buildButton('OK', () {
              final result = double.tryParse(_display);
              if (result != null) {
                widget.onCalculated(result);
              }
            }, color: AppColors.primary),
          ],
        ),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, {Color? color}) {
    return ShadButton(
      onPressed: onPressed,
      backgroundColor: color,
      child: Text(
        text,
        style: TextStyle(
          color: color != null ? Colors.white : null,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
