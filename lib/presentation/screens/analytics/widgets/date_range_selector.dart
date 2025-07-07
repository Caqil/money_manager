import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/utils/date_utils.dart';

enum DateRangeOption {
  today,
  thisWeek,
  thisMonth,
  last30Days,
  last3Months,
  last6Months,
  thisYear,
  lastYear,
  custom,
}

class DateRangeSelector extends StatefulWidget {
  final DateRange? selectedRange;
  final Function(DateRange) onRangeChanged;
  final DateRangeOption initialOption;
  final bool showCustomOption;

  const DateRangeSelector({
    super.key,
    required this.onRangeChanged,
    this.selectedRange,
    this.initialOption = DateRangeOption.thisMonth,
    this.showCustomOption = true,
  });

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  late DateRangeOption _selectedOption;
  DateRange? _customRange;
  late DateRange _currentRange;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialOption;
    _currentRange =
        widget.selectedRange ?? _getDateRangeFromOption(_selectedOption);

    // Notify parent of initial range without post-frame callback
    Future.microtask(() => widget.onRangeChanged(_currentRange));
  }

  @override
  void didUpdateWidget(DateRangeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRange != oldWidget.selectedRange &&
        widget.selectedRange != null) {
      _currentRange = widget.selectedRange!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppDimensions.spacingM),
            _buildQuickOptions(),
            if (widget.showCustomOption) ...[
              const SizedBox(height: AppDimensions.spacingS),
              _buildCustomOption(),
            ],
            const SizedBox(height: AppDimensions.spacingM),
            _buildSelectedRangeDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = ShadTheme.of(context);

    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: AppDimensions.iconS,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Text(
          'analytics.dateRange'.tr(),
          style: theme.textTheme.p.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickOptions() {
    final options = [
      DateRangeOption.today,
      DateRangeOption.thisWeek,
      DateRangeOption.thisMonth,
      DateRangeOption.last30Days,
      DateRangeOption.last3Months,
      DateRangeOption.last6Months,
      DateRangeOption.thisYear,
      DateRangeOption.lastYear,
    ];

    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingS,
      children: options.map(_buildOptionChip).toList(),
    );
  }

  Widget _buildOptionChip(DateRangeOption option) {
    final isSelected =
        _selectedOption == option && option != DateRangeOption.custom;

    return ShadButton.raw(
      onPressed: () => _selectOption(option),
      size: ShadButtonSize.sm,
      variant:
          isSelected ? ShadButtonVariant.primary : ShadButtonVariant.outline,
      child: Text(_getOptionLabel(option)),
    );
  }

  Widget _buildCustomOption() {
    final isSelected = _selectedOption == DateRangeOption.custom;

    return ShadButton.raw(
      onPressed: _showCustomDatePicker,
      size: ShadButtonSize.sm,
      variant:
          isSelected ? ShadButtonVariant.primary : ShadButtonVariant.outline,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.date_range,
            size: AppDimensions.iconS,
          ),
          const SizedBox(width: AppDimensions.spacingXs),
          Text('analytics.customRange'.tr()),
        ],
      ),
    );
  }

  Widget _buildSelectedRangeDisplay() {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month,
            size: AppDimensions.iconS,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              _formatDateRange(_currentRange),
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            _getDaysDifference(_currentRange),
            style: theme.textTheme.small.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _selectOption(DateRangeOption option) {
    final range = _getDateRangeFromOption(option);

    setState(() {
      _selectedOption = option;
      _currentRange = range;
    });

    widget.onRangeChanged(range);
  }

  Future<void> _showCustomDatePicker() async {
    final now = DateTime.now();
    final initialRange = _customRange ??
        DateRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );

    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: initialRange.start,
        end: initialRange.end,
      ),
      helpText: 'analytics.selectDateRange'.tr(),
      cancelText: 'common.cancel'.tr(),
      confirmText: 'common.confirm'.tr(),
    );

    if (dateRange != null && mounted) {
      // Validate date range
      if (dateRange.end.isBefore(dateRange.start)) {
        _showErrorSnackBar('analytics.invalidDateRange'.tr());
        return;
      }

      final customRange = DateRange(
        start: _normalizeDate(dateRange.start, isStart: true),
        end: _normalizeDate(dateRange.end, isStart: false),
      );

      setState(() {
        _selectedOption = DateRangeOption.custom;
        _customRange = customRange;
        _currentRange = customRange;
      });

      widget.onRangeChanged(customRange);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Normalize dates to start/end of day
  DateTime _normalizeDate(DateTime date, {required bool isStart}) {
    if (isStart) {
      return DateTime(date.year, date.month, date.day);
    } else {
      return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    }
  }

  String _getOptionLabel(DateRangeOption option) {
    return switch (option) {
      DateRangeOption.today => 'analytics.today'.tr(),
      DateRangeOption.thisWeek => 'analytics.thisWeek'.tr(),
      DateRangeOption.thisMonth => 'analytics.thisMonth'.tr(),
      DateRangeOption.last30Days => 'analytics.last30Days'.tr(),
      DateRangeOption.last3Months => 'analytics.last3Months'.tr(),
      DateRangeOption.last6Months => 'analytics.last6Months'.tr(),
      DateRangeOption.thisYear => 'analytics.thisYear'.tr(),
      DateRangeOption.lastYear => 'analytics.lastYear'.tr(),
      DateRangeOption.custom => 'analytics.custom'.tr(),
    };
  }

  DateRange _getDateRangeFromOption(DateRangeOption option) {
    if (option == DateRangeOption.custom && _customRange != null) {
      return _customRange!;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return switch (option) {
      DateRangeOption.today => DateRange(
          start: today,
          end: endOfToday,
        ),
      DateRangeOption.thisWeek => () {
          final startOfWeek = AppDateUtils.startOfWeek(now);
          return DateRange(
            start: startOfWeek,
            end: startOfWeek.add(const Duration(
                days: 6,
                hours: 23,
                minutes: 59,
                seconds: 59,
                milliseconds: 999)),
          );
        }(),
      DateRangeOption.thisMonth => DateRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
        ),
      DateRangeOption.last30Days => DateRange(
          start: today.subtract(const Duration(days: 29)),
          end: endOfToday,
        ),
      DateRangeOption.last3Months => () {
          // Safer month subtraction
          var targetMonth = now.month - 3;
          var targetYear = now.year;

          if (targetMonth <= 0) {
            targetYear -= 1;
            targetMonth += 12;
          }

          return DateRange(
            start: DateTime(targetYear, targetMonth, now.day),
            end: endOfToday,
          );
        }(),
      DateRangeOption.last6Months => () {
          // Safer month subtraction
          var targetMonth = now.month - 6;
          var targetYear = now.year;

          if (targetMonth <= 0) {
            targetYear -= (targetMonth.abs() ~/ 12) + 1;
            targetMonth = 12 - (targetMonth.abs() % 12);
          }

          return DateRange(
            start: DateTime(targetYear, targetMonth, now.day),
            end: endOfToday,
          );
        }(),
      DateRangeOption.thisYear => DateRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59, 999),
        ),
      DateRangeOption.lastYear => DateRange(
          start: DateTime(now.year - 1, 1, 1),
          end: DateTime(now.year - 1, 12, 31, 23, 59, 59, 999),
        ),
      DateRangeOption.custom => DateRange(
          start: DateTime(now.year, now.month, 1),
          end: endOfToday,
        ),
    };
  }

  String _formatDateRange(DateRange range) {
    final formatter = DateFormat.yMMMd();
    final start = formatter.format(range.start);
    final end = formatter.format(range.end);

    // Same day
    if (DateUtils.isSameDay(range.start, range.end)) {
      return start;
    }

    return '$start - $end';
  }

  String _getDaysDifference(DateRange range) {
    final difference = range.end.difference(range.start).inDays + 1;
    return '$difference ${'analytics.days'.tr()}';
  }
}

// Improved DateRange class
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  }) : assert(
            start != null && end != null, 'Start and end dates cannot be null');

  Duration get duration => end.difference(start);
  int get days => duration.inDays + 1;

  bool contains(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    return (normalizedDate.isAtSameMomentAs(normalizedStart) ||
            normalizedDate.isAfter(normalizedStart)) &&
        (normalizedDate.isAtSameMomentAs(normalizedEnd) ||
            normalizedDate.isBefore(normalizedEnd));
  }

  bool isValid() => !end.isBefore(start);

  DateRange copyWith({DateTime? start, DateTime? end}) {
    return DateRange(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  @override
  String toString() => 'DateRange(start: $start, end: $end)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRange &&
        other.start.isAtSameMomentAs(start) &&
        other.end.isAtSameMomentAs(end);
  }

  @override
  int get hashCode => Object.hash(start, end);
}
