import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';

class CurrencyRateEditor extends ConsumerStatefulWidget {
  final String baseCurrency;
  final String targetCurrency;
  final double? currentRate;
  final Function(double) onRateChanged;
  final bool enabled;
  final bool showLastUpdated;

  const CurrencyRateEditor({
    super.key,
    required this.baseCurrency,
    required this.targetCurrency,
    this.currentRate,
    required this.onRateChanged,
    this.enabled = true,
    this.showLastUpdated = true,
  });

  @override
  ConsumerState<CurrencyRateEditor> createState() => _CurrencyRateEditorState();
}

class _CurrencyRateEditorState extends ConsumerState<CurrencyRateEditor> {
  final TextEditingController _rateController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _validationError;
  bool _isLoading = false;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    if (widget.currentRate != null) {
      _rateController.text = widget.currentRate!.toStringAsFixed(6);
    }
    _rateController.addListener(_onRateChanged);
    _lastUpdated = DateTime.now();
  }

  @override
  void didUpdateWidget(CurrencyRateEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentRate != oldWidget.currentRate) {
      if (widget.currentRate != null) {
        _rateController.text = widget.currentRate!.toStringAsFixed(6);
        _lastUpdated = DateTime.now();
      } else {
        _rateController.clear();
      }
    }
  }

  @override
  void dispose() {
    _rateController.removeListener(_onRateChanged);
    _rateController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onRateChanged() {
    final text = _rateController.text;
    if (text.isEmpty) {
      setState(() {
        _validationError = null;
      });
      return;
    }

    final rate = double.tryParse(text);
    if (rate != null && rate > 0) {
      setState(() {
        _validationError = null;
      });
      widget.onRateChanged(rate);
    } else {
      setState(() {
        _validationError = 'settings.invalidExchangeRate'.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with currency pair
            _buildHeader(theme),
            const SizedBox(height: AppDimensions.spacingM),

            // Rate input field
            _buildRateInput(theme),

            // Conversion preview
            if (_rateController.text.isNotEmpty &&
                _validationError == null) ...[
              const SizedBox(height: AppDimensions.spacingM),
              _buildConversionPreview(theme),
            ],

            // Last updated info
            if (widget.showLastUpdated && _lastUpdated != null) ...[
              const SizedBox(height: AppDimensions.spacingS),
              _buildLastUpdatedInfo(theme),
            ],

            // Quick actions
            if (widget.enabled) ...[
              const SizedBox(height: AppDimensions.spacingM),
              _buildQuickActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ShadThemeData theme) {
    return Row(
      children: [
        // Currency flags/icons could go here
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingS,
            vertical: AppDimensions.paddingXs,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
          ),
          child: Text(
            widget.baseCurrency,
            style: theme.textTheme.small.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Icon(
          Icons.arrow_forward,
          size: 16,
          color: theme.colorScheme.mutedForeground,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingS,
            vertical: AppDimensions.paddingXs,
          ),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
          ),
          child: Text(
            widget.targetCurrency,
            style: theme.textTheme.small.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        if (_isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildRateInput(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings.exchangeRate'.tr(),
          style: theme.textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        ShadInputFormField(
          controller: _rateController,
          focusNode: _focusNode,
          enabled: widget.enabled && !_isLoading,
          placeholder: Text('settings.enterExchangeRate'.tr()),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}')),
          ],
          leading: Icon(
            Icons.currency_exchange,
            size: 18,
            color: theme.colorScheme.mutedForeground,
          ),
          trailing: widget.enabled && _rateController.text.isNotEmpty
              ? IconButton(
                  onPressed: _clearRate,
                  icon: Icon(
                    Icons.clear,
                    size: 18,
                    color: theme.colorScheme.mutedForeground,
                  ),
                )
              : null,
          validator: (value) => _validationError,
        ),
        if (_validationError != null) ...[
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            _validationError!,
            style: theme.textTheme.small.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConversionPreview(ShadThemeData theme) {
    final rate = double.tryParse(_rateController.text);
    if (rate == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: theme.colorScheme.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'settings.conversionPreview'.tr(),
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Row(
            children: [
              Expanded(
                child: _buildConversionItem(
                  '1 ${widget.baseCurrency}',
                  '${rate.toStringAsFixed(4)} ${widget.targetCurrency}',
                  theme,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Icon(
                Icons.swap_horiz,
                color: theme.colorScheme.mutedForeground,
                size: 16,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: _buildConversionItem(
                  '1 ${widget.targetCurrency}',
                  '${(1 / rate).toStringAsFixed(4)} ${widget.baseCurrency}',
                  theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversionItem(String from, String to, ShadThemeData theme) {
    return Column(
      children: [
        Text(
          from,
          style: theme.textTheme.small.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Icon(
          Icons.keyboard_arrow_down,
          size: 16,
          color: theme.colorScheme.mutedForeground,
        ),
        Text(
          to,
          style: theme.textTheme.small.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLastUpdatedInfo(ShadThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.update,
          size: 14,
          color: theme.colorScheme.mutedForeground,
        ),
        const SizedBox(width: AppDimensions.spacingXs),
        Text(
          'settings.lastUpdated'.tr(namedArgs: {
            'time': DateFormat.jm().format(_lastUpdated!),
          }),
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: _fetchLatestRate,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh, size: 16),
                const SizedBox(width: AppDimensions.spacingXs),
                Text('settings.fetchLatest'.tr()),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: _resetToDefault,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restore, size: 16),
                const SizedBox(width: AppDimensions.spacingXs),
                Text('settings.reset'.tr()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _clearRate() {
    _rateController.clear();
    setState(() {
      _validationError = null;
    });
  }

  Future<void> _fetchLatestRate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call to fetch latest exchange rate
      await Future.delayed(const Duration(seconds: 2));

      // Mock rate - in real implementation, this would fetch from an API
      final mockRate = 1.0 + (DateTime.now().millisecond / 10000);

      setState(() {
        _rateController.text = mockRate.toStringAsFixed(6);
        _lastUpdated = DateTime.now();
      });

      widget.onRateChanged(mockRate);

      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast.raw(
            variant: ShadToastVariant.primary,
            description: Text('settings.exchangeRateUpdated'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast.raw(
            variant: ShadToastVariant.primary,
            description: Text('settings.errorFetchingRate'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetToDefault() {
    setState(() {
      _rateController.text = '1.0';
      _lastUpdated = DateTime.now();
      _validationError = null;
    });
    widget.onRateChanged(1.0);
  }
}
