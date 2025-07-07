import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/dimensions.dart';

class CustomTimePicker extends StatefulWidget {
  final String? labelText;
  final String? placeholder;
  final String? description;
  final TimeOfDay? selectedTime;
  final ValueChanged<TimeOfDay?>? onTimeSelected;
  final bool enabled;
  final bool required;
  final bool use24HourFormat;
  final String? Function(TimeOfDay?)? validator;
  final AutovalidateMode? autovalidateMode;
  final EdgeInsetsGeometry? padding;
  final double? minWidth;
  final double? maxWidth;

  const CustomTimePicker({
    super.key,
    this.labelText,
    this.placeholder,
    this.description,
    this.selectedTime,
    this.onTimeSelected,
    this.enabled = true,
    this.required = false,
    this.use24HourFormat = false,
    this.validator,
    this.autovalidateMode,
    this.padding,
    this.minWidth,
    this.maxWidth,
  });

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

    if (widget.selectedTime != null) {
      _controller.text = _formatTime(widget.selectedTime!);
    }
  }

  @override
  void didUpdateWidget(CustomTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTime != oldWidget.selectedTime) {
      if (widget.selectedTime != null) {
        _controller.text = _formatTime(widget.selectedTime!);
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

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (widget.use24HourFormat) {
      return DateFormat.Hm().format(dateTime);
    } else {
      return DateFormat.jm().format(dateTime);
    }
  }

  String? _getValidator(String? value) {
    if (widget.validator != null) {
      return widget.validator!(widget.selectedTime);
    }

    if (widget.required && (value == null || value.trim().isEmpty)) {
      return 'validation.required'.tr();
    }

    return null;
  }

  Future<void> _selectTime() async {
    if (!widget.enabled) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: widget.selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        final theme = ShadTheme.of(context);
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: theme.colorScheme.background,
              dialBackgroundColor: theme.colorScheme.card,
              dialHandColor: theme.colorScheme.primary,
              dialTextColor: theme.colorScheme.foreground,
              entryModeIconColor: theme.colorScheme.primary,
              hourMinuteColor: theme.colorScheme.muted,
              hourMinuteTextColor: theme.colorScheme.foreground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      _controller.text = _formatTime(selectedTime);
      widget.onTimeSelected?.call(selectedTime);
    }
  }

  void _clearTime() {
    _controller.clear();
    widget.onTimeSelected?.call(null);
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
        placeholder: Text(widget.placeholder ?? 'forms.selectTime'.tr()),
        description:
            widget.description != null ? Text(widget.description!) : null,
        readOnly: true,
        enabled: widget.enabled,
        leading: const Padding(
          padding: EdgeInsets.all(AppDimensions.paddingS),
          child: Icon(
            Icons.access_time,
            size: AppDimensions.iconS,
          ),
        ),
        trailing: widget.selectedTime != null
            ? ShadButton(
                width: 24,
                height: 24,
                padding: EdgeInsets.zero,
                child: const Icon(
                  Icons.clear,
                  size: AppDimensions.iconS,
                ),
                onPressed: widget.enabled ? _clearTime : null,
              )
            : null,
        onPressed: _selectTime,
        validator: _getValidator,
      );
    }

    // Basic time picker without form field
    return Container(
      padding: widget.padding,
      constraints: BoxConstraints(
        minWidth: widget.minWidth ?? 0,
        maxWidth: widget.maxWidth ?? double.infinity,
      ),
      child: ShadInput(
        controller: _controller,
        placeholder: Text(widget.placeholder ?? 'forms.selectTime'.tr()),
        readOnly: true,
        enabled: widget.enabled,
        leading: const Padding(
          padding: EdgeInsets.all(AppDimensions.paddingS),
          child: Icon(
            Icons.access_time,
            size: AppDimensions.iconS,
          ),
        ),
        trailing: widget.selectedTime != null
            ? ShadButton(
                width: 24,
                height: 24,
                padding: EdgeInsets.zero,
                child: const Icon(
                  Icons.clear,
                  size: AppDimensions.iconS,
                ),
                onPressed: widget.enabled ? _clearTime : null,
              )
            : null,
        onPressed: _selectTime,
      ),
    );
  }
}

// DateTime picker (combines date and time)
class CustomDateTimePicker extends StatefulWidget {
  final String? labelText;
  final String? placeholder;
  final String? description;
  final DateTime? selectedDateTime;
  final ValueChanged<DateTime?>? onDateTimeSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final bool required;
  final bool use24HourFormat;
  final String? Function(DateTime?)? validator;
  final AutovalidateMode? autovalidateMode;
  final EdgeInsetsGeometry? padding;
  final double? minWidth;
  final double? maxWidth;
  final DateFormat? dateTimeFormat;

  const CustomDateTimePicker({
    super.key,
    this.labelText,
    this.placeholder,
    this.description,
    this.selectedDateTime,
    this.onDateTimeSelected,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.required = false,
    this.use24HourFormat = false,
    this.validator,
    this.autovalidateMode,
    this.padding,
    this.minWidth,
    this.maxWidth,
    this.dateTimeFormat,
  });

  @override
  State<CustomDateTimePicker> createState() => _CustomDateTimePickerState();
}

class _CustomDateTimePickerState extends State<CustomDateTimePicker> {
  late TextEditingController _controller;
  late DateFormat _dateTimeFormatter;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _dateTimeFormatter = widget.dateTimeFormat ??
        DateFormat(widget.use24HourFormat
            ? 'MMM dd, yyyy HH:mm'
            : 'MMM dd, yyyy hh:mm a');

    if (widget.selectedDateTime != null) {
      _controller.text = _dateTimeFormatter.format(widget.selectedDateTime!);
    }
  }

  @override
  void didUpdateWidget(CustomDateTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDateTime != oldWidget.selectedDateTime) {
      if (widget.selectedDateTime != null) {
        _controller.text = _dateTimeFormatter.format(widget.selectedDateTime!);
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

  String? _getValidator(String? value) {
    if (widget.validator != null) {
      return widget.validator!(widget.selectedDateTime);
    }

    if (widget.required && (value == null || value.trim().isEmpty)) {
      return 'validation.required'.tr();
    }

    return null;
  }

  Future<void> _selectDateTime() async {
    if (!widget.enabled) return;

    final now = DateTime.now();
    final firstDate = widget.firstDate ?? DateTime(1900);
    final lastDate = widget.lastDate ?? DateTime(now.year + 100);

    // First select date
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: widget.selectedDateTime ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        final theme = ShadTheme.of(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.primaryForeground,
              surface: theme.colorScheme.background,
              onSurface: theme.colorScheme.foreground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;

    // Then select time
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: widget.selectedDateTime != null
          ? TimeOfDay.fromDateTime(widget.selectedDateTime!)
          : TimeOfDay.now(),
      builder: (context, child) {
        final theme = ShadTheme.of(context);
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: theme.colorScheme.background,
              dialBackgroundColor: theme.colorScheme.card,
              dialHandColor: theme.colorScheme.primary,
              dialTextColor: theme.colorScheme.foreground,
              entryModeIconColor: theme.colorScheme.primary,
              hourMinuteColor: theme.colorScheme.muted,
              hourMinuteTextColor: theme.colorScheme.foreground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) return;

    final selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    _controller.text = _dateTimeFormatter.format(selectedDateTime);
    widget.onDateTimeSelected?.call(selectedDateTime);
  }

  void _clearDateTime() {
    _controller.clear();
    widget.onDateTimeSelected?.call(null);
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
        placeholder: Text(widget.placeholder ?? 'forms.selectDateTime'.tr()),
        description:
            widget.description != null ? Text(widget.description!) : null,
        readOnly: true,
        enabled: widget.enabled,
        leading: const Padding(
          padding: EdgeInsets.all(AppDimensions.paddingS),
          child: Icon(
            Icons.event,
            size: AppDimensions.iconS,
          ),
        ),
        trailing: widget.selectedDateTime != null
            ? ShadButton(
                width: 24,
                height: 24,
                padding: EdgeInsets.zero,
                child: const Icon(
                  Icons.clear,
                  size: AppDimensions.iconS,
                ),
                onPressed: widget.enabled ? _clearDateTime : null,
              )
            : null,
        onPressed: _selectDateTime,
        validator: _getValidator,
      );
    }

    // Basic datetime picker without form field
    return Container(
      padding: widget.padding,
      constraints: BoxConstraints(
        minWidth: widget.minWidth ?? 0,
        maxWidth: widget.maxWidth ?? double.infinity,
      ),
      child: ShadInput(
        controller: _controller,
        placeholder: Text(widget.placeholder ?? 'forms.selectDateTime'.tr()),
        readOnly: true,
        enabled: widget.enabled,
        leading: const Padding(
          padding: EdgeInsets.all(AppDimensions.paddingS),
          child: Icon(
            Icons.event,
            size: AppDimensions.iconS,
          ),
        ),
        trailing: widget.selectedDateTime != null
            ? ShadButton(
                width: 24,
                height: 24,
                padding: EdgeInsets.zero,
                child: const Icon(
                  Icons.clear,
                  size: AppDimensions.iconS,
                ),
                onPressed: widget.enabled ? _clearDateTime : null,
              )
            : null,
        onPressed: _selectDateTime,
      ),
    );
  }
}

// Quick time picker with preset options
class QuickTimePicker extends StatelessWidget {
  final String? labelText;
  final TimeOfDay? selectedTime;
  final ValueChanged<TimeOfDay?>? onTimeSelected;
  final List<QuickTimeOption> quickOptions;
  final bool showCustomOption;
  final bool enabled;
  final bool use24HourFormat;

  const QuickTimePicker({
    super.key,
    this.labelText,
    this.selectedTime,
    this.onTimeSelected,
    this.quickOptions = const [],
    this.showCustomOption = true,
    this.enabled = true,
    this.use24HourFormat = false,
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
                      enabled ? () => onTimeSelected?.call(option.time) : null,
                  variant: _isSelected(option.time)
                      ? ShadButtonVariant.primary
                      : ShadButtonVariant.outline,
                  child: Text(option.label),
                )),
            if (showCustomOption)
              ShadButton.outline(
                onPressed:
                    enabled ? () => _showCustomTimePicker(context) : null,
                leading: const Icon(
                  Icons.access_time,
                  size: AppDimensions.iconXs,
                ),
                child: Text('common.custom'.tr()),
              ),
          ],
        ),
      ],
    );
  }

  bool _isSelected(TimeOfDay time) {
    if (selectedTime == null) return false;
    return selectedTime!.hour == time.hour &&
        selectedTime!.minute == time.minute;
  }

  List<QuickTimeOption> _getDefaultQuickOptions() {
    return [
      QuickTimeOption(
        label: use24HourFormat ? '09:00' : '9:00 AM',
        time: const TimeOfDay(hour: 9, minute: 0),
      ),
      QuickTimeOption(
        label: use24HourFormat ? '12:00' : '12:00 PM',
        time: const TimeOfDay(hour: 12, minute: 0),
      ),
      QuickTimeOption(
        label: use24HourFormat ? '15:00' : '3:00 PM',
        time: const TimeOfDay(hour: 15, minute: 0),
      ),
      QuickTimeOption(
        label: use24HourFormat ? '18:00' : '6:00 PM',
        time: const TimeOfDay(hour: 18, minute: 0),
      ),
    ];
  }

  Future<void> _showCustomTimePicker(BuildContext context) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: this.selectedTime ?? TimeOfDay.now(),
    );

    if (selectedTime != null) {
      onTimeSelected?.call(selectedTime);
    }
  }
}

// Quick time option data class
class QuickTimeOption {
  final String label;
  final TimeOfDay time;

  const QuickTimeOption({
    required this.label,
    required this.time,
  });
}

// Time range picker
class TimeRangePicker extends StatefulWidget {
  final String? labelText;
  final String? description;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final ValueChanged<TimeRange?>? onChanged;
  final bool enabled;
  final bool required;
  final bool use24HourFormat;
  final String? Function(TimeRange?)? validator;

  const TimeRangePicker({
    super.key,
    this.labelText,
    this.description,
    this.startTime,
    this.endTime,
    this.onChanged,
    this.enabled = true,
    this.required = false,
    this.use24HourFormat = false,
    this.validator,
  });

  @override
  State<TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<TimeRangePicker> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = widget.startTime;
    _endTime = widget.endTime;
  }

  void _onStartTimeChanged(TimeOfDay? time) {
    setState(() {
      _startTime = time;
    });

    _notifyChange();
  }

  void _onEndTimeChanged(TimeOfDay? time) {
    setState(() {
      _endTime = time;
    });

    _notifyChange();
  }

  void _notifyChange() {
    if (_startTime != null && _endTime != null) {
      widget.onChanged?.call(TimeRange(start: _startTime!, end: _endTime!));
    } else {
      widget.onChanged?.call(null);
    }
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
        Row(
          children: [
            Expanded(
              child: CustomTimePicker(
                labelText: 'Start Time',
                selectedTime: _startTime,
                onTimeSelected: _onStartTimeChanged,
                enabled: widget.enabled,
                use24HourFormat: widget.use24HourFormat,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: CustomTimePicker(
                labelText: 'End Time',
                selectedTime: _endTime,
                onTimeSelected: _onEndTimeChanged,
                enabled: widget.enabled,
                use24HourFormat: widget.use24HourFormat,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Time range data class
class TimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  const TimeRange({
    required this.start,
    required this.end,
  });

  Duration get duration {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return Duration(minutes: endMinutes - startMinutes);
  }

  @override
  String toString() {
    return 'TimeRange(start: $start, end: $end)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}
