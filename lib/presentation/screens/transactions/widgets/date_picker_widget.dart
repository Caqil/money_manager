import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';

class DatePickerWidget extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime?) onDateChanged;
  final String? label;
  final String? placeholder;
  final bool enabled;
  final bool required;
  final DateTime? minDate;
  final DateTime? maxDate;
  final String? errorText;
  final bool showQuickOptions;
  final DateFormat? dateFormat;

  const DatePickerWidget({
    super.key,
    this.selectedDate,
    required this.onDateChanged,
    this.label,
    this.placeholder,
    this.enabled = true,
    this.required = false,
    this.minDate,
    this.maxDate,
    this.errorText,
    this.showQuickOptions = true,
    this.dateFormat,
  });

  @override
  State<DatePickerWidget> createState() => _DatePickerWidgetState();
}

class _DatePickerWidgetState extends State<DatePickerWidget> {
  DateTime? _selectedDate;
  late DateFormat _formatter;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _formatter = widget.dateFormat ?? DateFormat.yMMMd();
  }

  @override
  void didUpdateWidget(DatePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      setState(() {
        _selectedDate = widget.selectedDate;
      });
    }
    if (widget.dateFormat != oldWidget.dateFormat) {
      _formatter = widget.dateFormat ?? DateFormat.yMMMd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

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

        // Date selector with quick options
        Row(
          children: [
            Expanded(
              child: _buildDateSelector(theme),
            ),
            if (widget.showQuickOptions) ...[
              const SizedBox(width: AppDimensions.spacingS),
              _buildQuickOptionsButton(theme),
            ],
          ],
        ),

        // Error message
        if (widget.errorText != null) ...[
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            widget.errorText!,
            style: theme.textTheme.small.copyWith(
              color: AppColors.error,
            ),
          ),
        ],

        // Quick date options (if enabled)
        if (widget.showQuickOptions) ...[
          const SizedBox(height: AppDimensions.spacingS),
          _buildQuickDateOptions(),
        ],
      ],
    );
  }

  Widget _buildDateSelector(ShadThemeData theme) {
    return GestureDetector(
      onTap: widget.enabled ? _showDatePicker : null,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.errorText != null 
                ? AppColors.error 
                : theme.colorScheme.border,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          color: widget.enabled 
              ? Colors.transparent 
              : theme.colorScheme.muted,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: widget.enabled 
                  ? theme.colorScheme.foreground 
                  : theme.colorScheme.mutedForeground,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Text(
                _selectedDate != null 
                    ? _formatter.format(_selectedDate!)
                    : widget.placeholder ?? 'transactions.selectDate'.tr(),
                style: theme.textTheme.p.copyWith(
                  color: _selectedDate != null 
                      ? theme.colorScheme.foreground
                      : theme.colorScheme.mutedForeground,
                ),
              ),
            ),
            if (_selectedDate != null && widget.enabled)
              GestureDetector(
                onTap: _clearDate,
                child: Icon(
                  Icons.clear,
                  size: 18,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOptionsButton(ShadThemeData theme) {
    return ShadPopover(
      popover: (context) => _buildQuickOptionsPopover(),
      child: ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: widget.enabled ? () {} : null,
        child: const Icon(Icons.access_time, size: 16),
      ),
    );
  }

  Widget _buildQuickOptionsPopover() {
    final quickOptions = _getQuickDateOptions();
    
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'transactions.quickDateOptions'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          ...quickOptions.map((option) => ListTile(
            dense: true,
            title: Text(option.label),
            subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
            onTap: () {
              _selectDate(option.date);
              Navigator.of(context).pop();
            },
          )),
        ],
      ),
    );
  }

  Widget _buildQuickDateOptions() {
    final quickOptions = _getQuickDateOptions().take(4).toList();
    
    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingXs,
      children: quickOptions.map((option) => ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: widget.enabled 
            ? () => _selectDate(option.date)
            : null,
        child: Text(
          option.label,
          style: const TextStyle(fontSize: 12),
        ),
      )).toList(),
    );
  }

  List<QuickDateOption> _getQuickDateOptions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    return [
      QuickDateOption(
        label: 'transactions.today'.tr(),
        date: today,
        subtitle: _formatter.format(today),
      ),
      QuickDateOption(
        label: 'transactions.yesterday'.tr(),
        date: yesterday,
        subtitle: _formatter.format(yesterday),
      ),
      QuickDateOption(
        label: 'transactions.thisWeek'.tr(),
        date: thisWeekStart,
        subtitle: '${_formatter.format(thisWeekStart)} - ${_formatter.format(today)}',
      ),
      QuickDateOption(
        label: 'transactions.lastWeek'.tr(),
        date: lastWeekStart,
        subtitle: '${_formatter.format(lastWeekStart)} - ${_formatter.format(lastWeekStart.add(const Duration(days: 6)))}',
      ),
      QuickDateOption(
        label: 'transactions.thisMonth'.tr(),
        date: thisMonthStart,
        subtitle: DateFormat.yMMM().format(thisMonthStart),
      ),
      QuickDateOption(
        label: 'transactions.lastMonth'.tr(),
        date: lastMonthStart,
        subtitle: DateFormat.yMMM().format(lastMonthStart),
      ),
    ];
  }

  Future<void> _showDatePicker() async {
    final now = DateTime.now();
    final firstDate = widget.minDate ?? DateTime(now.year - 10);
    final lastDate = widget.maxDate ?? DateTime(now.year + 1);
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      _selectDate(selectedDate);
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onDateChanged(date);
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
    });
    widget.onDateChanged(null);
  }
}

class QuickDateOption {
  final String label;
  final DateTime date;
  final String? subtitle;

  const QuickDateOption({
    required this.label,
    required this.date,
    this.subtitle,
  });
}

// Extension for date utilities
extension DatePickerExtensions on DateTime {
  /// Gets the start of the week (Monday)
  DateTime get startOfWeek {
    final daysFromMonday = weekday - 1;
    return subtract(Duration(days: daysFromMonday));
  }

  /// Gets the end of the week (Sunday)
  DateTime get endOfWeek {
    final daysToSunday = 7 - weekday;
    return add(Duration(days: daysToSunday));
  }

  /// Gets the start of the month
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }

  /// Gets the end of the month
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0);
  }

  /// Gets the start of the year
  DateTime get startOfYear {
    return DateTime(year, 1, 1);
  }

  /// Gets the end of the year
  DateTime get endOfYear {
    return DateTime(year, 12, 31);
  }

  /// Checks if this date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Checks if this date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && 
           month == yesterday.month && 
           day == yesterday.day;
  }

  /// Checks if this date is in this week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = DatePickerExtensions(now).startOfWeek;
    final endOfWeek = DatePickerExtensions(now).endOfWeek;
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Checks if this date is in this month
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Gets a human-readable relative description
  String get relativeDescription {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    
    final now = DateTime.now();
    final difference = now.difference(this).inDays;
    
    if (difference == -1) return 'Tomorrow';
    if (difference < 7 && difference > 0) return '$difference days ago';
    if (difference < 0 && difference > -7) return 'In ${-difference} days';
    if (isThisWeek) return 'This week';
    if (isThisMonth) return 'This month';
    
    return DateFormat.yMMMd().format(this);
  }
}