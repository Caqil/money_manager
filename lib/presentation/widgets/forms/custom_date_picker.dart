import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/utils/validation_helper.dart';

class CustomDatePicker extends StatefulWidget {
  final String? labelText;
  final String? description;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?>? onChanged;
  final DateTime? fromMonth;
  final DateTime? toMonth;
  final bool enabled;
  final bool required;
  final String? Function(DateTime?)? validator;
  final AutovalidateMode? autovalidateMode;
  final EdgeInsetsGeometry? padding;
  final double? minWidth;
  final double? maxWidth;
  final List<QuickDateOption>? presets;

  const CustomDatePicker({
    super.key,
    this.labelText,
    this.description,
    this.selectedDate,
    this.onChanged,
    this.fromMonth,
    this.toMonth,
    this.enabled = true,
    this.required = false,
    this.validator,
    this.autovalidateMode,
    this.padding,
    this.minWidth,
    this.maxWidth,
    this.presets,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  String? _getValidator(DateTime? value) {
    if (widget.validator != null) {
      return widget.validator!(value);
    }

    if (widget.required && value == null) {
      return 'validation.required'.tr();
    }

    if (value != null && !ValidationHelper.isValidDate(value)) {
      return 'validation.invalidDate'.tr();
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    // If using form field mode
    if (widget.labelText != null ||
        widget.description != null ||
        widget.required) {
      return ShadDatePickerFormField(
        label: widget.labelText != null
            ? Row(
                children: [
                  Text(widget.labelText!),
                  if (widget.required)
                    Text(
                      ' *',
                      style: TextStyle(
                        color: theme.colorScheme.destructive,
                      ),
                    ),
                ],
              )
            : null,
        description:
            widget.description != null ? Text(widget.description!) : null,
        initialValue: widget.selectedDate,
        onChanged: widget.enabled
            ? (date) => widget.onChanged?.call(date)
            : null,
        validator: _getValidator,
        fromMonth: widget.fromMonth,
        toMonth: widget.toMonth,
      );
    }

    // Basic date picker without form field
    return Container(
      padding: widget.padding,
      constraints: BoxConstraints(
        minWidth: widget.minWidth ?? 0,
        maxWidth: widget.maxWidth ?? double.infinity,
      ),
      child: ShadDatePicker(
        selected: widget.selectedDate,
        onChanged: widget.enabled
            ? (date) => widget.onChanged?.call(date)
            : null,
        fromMonth: widget.fromMonth,
        toMonth: widget.toMonth,
      ),
    );
  }
}

// Date range picker
class CustomDateRangePicker extends StatefulWidget {
  final String? labelText;
  final String? description;
  final ShadDateTimeRange? selectedRange;
  final ValueChanged<ShadDateTimeRange?>? onChanged;
  final DateTime? fromMonth;
  final DateTime? toMonth;
  final bool enabled;
  final bool required;
  final String? Function(ShadDateTimeRange?)? validator;
  final AutovalidateMode? autovalidateMode;
  final EdgeInsetsGeometry? padding;
  final double? minWidth;
  final double? maxWidth;

  const CustomDateRangePicker({
    super.key,
    this.labelText,
    this.description,
    this.selectedRange,
    this.onChanged,
    this.fromMonth,
    this.toMonth,
    this.enabled = true,
    this.required = false,
    this.validator,
    this.autovalidateMode,
    this.padding,
    this.minWidth,
    this.maxWidth,
  });

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  String? _getValidator(ShadDateTimeRange? value) {
    if (widget.validator != null) {
      return widget.validator!(value);
    }

    if (widget.required && value == null) {
      return 'validation.required'.tr();
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    // If using form field mode
    if (widget.labelText != null ||
        widget.description != null ||
        widget.required) {
      return ShadDateRangePickerFormField(
        label: widget.labelText != null
            ? Row(
                children: [
                  Text(widget.labelText!),
                  if (widget.required)
                    Text(
                      ' *',
                      style: TextStyle(
                        color: theme.colorScheme.destructive,
                      ),
                    ),
                ],
              )
            : null,
        description:
            widget.description != null ? Text(widget.description!) : null,
        initialValue: widget.selectedRange,
        onChanged: widget.enabled
            ? (date) => widget.onChanged?.call(date)
            : null,
        validator: _getValidator,
        fromMonth: widget.fromMonth,
        toMonth: widget.toMonth,
      );
    }

    // Basic date range picker without form field
    return Container(
      padding: widget.padding,
      constraints: BoxConstraints(
        minWidth: widget.minWidth ?? 0,
        maxWidth: widget.maxWidth ?? double.infinity,
      ),
      child: ShadDatePicker.range(
        selected: widget.selectedRange,
        onChanged: widget.enabled
            ? (value) => widget.onChanged
            : null,
        fromMonth: widget.fromMonth,
        toMonth: widget.toMonth,
      ),
    );
  }
}

// Date picker with presets
class PresetDatePicker extends StatefulWidget {
  final String? labelText;
  final String? description;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?>? onChanged;
  final Map<int, String> presets;
  final DateTime? fromMonth;
  final DateTime? toMonth;
  final bool enabled;
  final bool required;
  final String? Function(DateTime?)? validator;
  final double? minWidth;
  final double? maxWidth;

  const PresetDatePicker({
    super.key,
    this.labelText,
    this.description,
    this.selectedDate,
    this.onChanged,
    this.presets = const {},
    this.fromMonth,
    this.toMonth,
    this.enabled = true,
    this.required = false,
    this.validator,
    this.minWidth,
    this.maxWidth,
  });

  @override
  State<PresetDatePicker> createState() => _PresetDatePickerState();
}

class _PresetDatePickerState extends State<PresetDatePicker> {
  final groupId = UniqueKey();
  final today = DateTimeExtension(DateTime.now()).startOfDay;

  void _onPresetChanged(int? days) {
    if (days == null || !widget.enabled) return;

    final selectedDate = today.add(Duration(days: days));
    widget.onChanged?.call(selectedDate);
  }

  String? _getValidator(DateTime? value) {
    if (widget.validator != null) {
      return widget.validator!(value);
    }

    if (widget.required && value == null) {
      return 'validation.required'.tr();
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Row(
            children: [
              Text(
                widget.labelText!,
                style: theme.textTheme.h4,
              ),
              if (widget.required)
                Text(
                  ' *',
                  style: theme.textTheme.h4.copyWith(
                    color: theme.colorScheme.destructive,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
        ],
        if (widget.description != null) ...[
          Text(
            widget.description!,
            style: theme.textTheme.muted,
          ),
          const SizedBox(height: AppDimensions.spacingM),
        ],
        Container(
          constraints: BoxConstraints(
            minWidth: widget.minWidth ?? 0,
            maxWidth: widget.maxWidth ?? double.infinity,
          ),
          child: ShadDatePicker(
            groupId: groupId,
            selected: widget.selectedDate,
            onChanged: widget.enabled ? widget.onChanged : null,
            fromMonth: widget.fromMonth,
            toMonth: widget.toMonth,
            header: widget.presets.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ShadSelect<int>(
                      groupId: groupId,
                      minWidth: 276,
                      placeholder: const Text('Select preset'),
                      options: widget.presets.entries
                          .map((e) => ShadOption(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      selectedOptionBuilder: (context, value) {
                        return Text(widget.presets[value]!);
                      },
                      onChanged: _onPresetChanged,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

// Quick date picker with preset buttons
class QuickDatePicker extends StatelessWidget {
  final String? labelText;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?>? onDateSelected;
  final List<QuickDateOption> quickOptions;
  final bool showCustomOption;
  final bool enabled;

  const QuickDatePicker({
    super.key,
    this.labelText,
    this.selectedDate,
    this.onDateSelected,
    this.quickOptions = const [],
    this.showCustomOption = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final defaultQuickOptions = _getDefaultQuickOptions();
    final allOptions = [...quickOptions, ...defaultQuickOptions];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: theme.textTheme.h4,
          ),
          const SizedBox(height: AppDimensions.spacingS),
        ],
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: [
            ...allOptions.map((option) => ShadButton.raw(
                  onPressed:
                      enabled ? () => onDateSelected?.call(option.date) : null,
                  variant: _isSelected(option.date)
                      ? ShadButtonVariant.primary
                      : ShadButtonVariant.outline,
                  child: Text(option.label),
                )),
            if (showCustomOption)
              ShadButton.outline(
                onPressed:
                    enabled ? () => _showCustomDatePicker(context) : null,
                leading: const Icon(
                  Icons.calendar_today,
                  size: AppDimensions.iconXs,
                ),
                child: Text('common.custom'.tr()),
              ),
          ],
        ),
      ],
    );
  }

  bool _isSelected(DateTime? date) {
    if (selectedDate == null || date == null) return false;
    return DateUtils.isSameDay(selectedDate, date);
  }

  List<QuickDateOption> _getDefaultQuickOptions() {
    final now = DateTime.now();
    return [
      QuickDateOption(
        label: 'common.today'.tr(),
        date: now,
      ),
      QuickDateOption(
        label: 'common.yesterday'.tr(),
        date: now.subtract(const Duration(days: 1)),
      ),
      QuickDateOption(
        label: 'common.thisWeek'.tr(),
        date: now.subtract(Duration(days: now.weekday - 1)),
      ),
      QuickDateOption(
        label: 'common.lastWeek'.tr(),
        date: now.subtract(Duration(days: now.weekday + 6)),
      ),
      QuickDateOption(
        label: 'common.thisMonth'.tr(),
        date: DateTime(now.year, now.month, 1),
      ),
      QuickDateOption(
        label: 'common.lastMonth'.tr(),
        date: DateTime(now.year, now.month - 1, 1),
      ),
    ];
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: this.selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      onDateSelected?.call(selectedDate);
    }
  }
}

// Quick date option data class
class QuickDateOption {
  final String label;
  final DateTime date;

  const QuickDateOption({
    required this.label,
    required this.date,
  });
}

// Date input field that opens date picker
class DateInputField extends StatefulWidget {
  final String? labelText;
  final String? placeholder;
  final String? description;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?>? onChanged;
  final bool enabled;
  final bool required;
  final String? Function(DateTime?)? validator;
  final DateFormat? dateFormat;
  final double? minWidth;
  final double? maxWidth;

  const DateInputField({
    super.key,
    this.labelText,
    this.placeholder,
    this.description,
    this.selectedDate,
    this.onChanged,
    this.enabled = true,
    this.required = false,
    this.validator,
    this.dateFormat,
    this.minWidth,
    this.maxWidth,
  });

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  late TextEditingController _controller;
  late DateFormat _dateFormatter;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _dateFormatter = widget.dateFormat ?? DateFormat('MMM dd, yyyy');

    if (widget.selectedDate != null) {
      _controller.text = _dateFormatter.format(widget.selectedDate!);
    }
  }

  @override
  void didUpdateWidget(DateInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      if (widget.selectedDate != null) {
        _controller.text = _dateFormatter.format(widget.selectedDate!);
      } else {
        _controller.clear();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    if (!widget.enabled) return;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      _controller.text = _dateFormatter.format(selectedDate);
      widget.onChanged?.call(selectedDate);
    }
  }

  void _clearDate() {
    _controller.clear();
    widget.onChanged?.call(null);
  }

  String? _getValidator(String? value) {
    if (widget.validator != null) {
      return widget.validator!(widget.selectedDate);
    }

    if (widget.required && (value == null || value.trim().isEmpty)) {
      return 'validation.required'.tr();
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    // If using form field mode
    if (widget.labelText != null ||
        widget.description != null ||
        widget.required) {
      return ShadInputFormField(
        controller: _controller,
        label: widget.labelText != null
            ? Row(
                children: [
                  Text(widget.labelText!),
                  if (widget.required)
                    Text(
                      ' *',
                      style: TextStyle(
                        color: theme.colorScheme.destructive,
                      ),
                    ),
                ],
              )
            : null,
        placeholder: Text(widget.placeholder ?? 'forms.selectDate'.tr()),
        description:
            widget.description != null ? Text(widget.description!) : null,
        readOnly: true,
        enabled: widget.enabled,
        leading: const Padding(
          padding: EdgeInsets.all(AppDimensions.paddingS),
          child: Icon(
            Icons.calendar_today,
            size: AppDimensions.iconS,
          ),
        ),
        trailing: widget.selectedDate != null
            ? ShadButton(
                width: 24,
                height: 24,
                padding: EdgeInsets.zero,
                child: const Icon(
                  Icons.clear,
                  size: AppDimensions.iconS,
                ),
                onPressed: widget.enabled ? _clearDate : null,
              )
            : null,
        onPressed: _selectDate,
        validator: _getValidator,
      );
    }

    // Basic input field
    return ShadInput(
      controller: _controller,
      placeholder: Text(widget.placeholder ?? 'forms.selectDate'.tr()),
      readOnly: true,
      enabled: widget.enabled,
      leading: const Padding(
        padding: EdgeInsets.all(AppDimensions.paddingS),
        child: Icon(
          Icons.calendar_today,
          size: AppDimensions.iconS,
        ),
      ),
      trailing: widget.selectedDate != null
          ? ShadButton(
              width: 24,
              height: 24,
              padding: EdgeInsets.zero,
              child: const Icon(
                Icons.clear,
                size: AppDimensions.iconS,
              ),
              onPressed: widget.enabled ? _clearDate : null,
            )
          : null,
      onPressed: _selectDate,
    );
  }
}

// Extension to get start of day
extension DateTimeExtension on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
}
