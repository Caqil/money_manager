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

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialOption;
    _initializeRange();
  }

  void _initializeRange() {
    final range =
        widget.selectedRange ?? _getDateRangeFromOption(_selectedOption);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRangeChanged(range);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
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
            ),

            const SizedBox(height: AppDimensions.spacingM),

            // Quick options
            Wrap(
              spacing: AppDimensions.spacingS,
              runSpacing: AppDimensions.spacingS,
              children: [
                ..._buildQuickOptions(),
                if (widget.showCustomOption) _buildCustomOption(),
              ],
            ),

            // Selected range display
            const SizedBox(height: AppDimensions.spacingM),
            _buildSelectedRangeDisplay(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuickOptions() {
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

    return options.map((option) => _buildOptionChip(option)).toList();
  }

  Widget _buildOptionChip(DateRangeOption option) {
    final isSelected =
        _selectedOption == option && option != DateRangeOption.custom;

    return ShadButton.ghost(
      onPressed: () => _selectOption(option),
      size: ShadButtonSize.sm,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1)
              : null,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingS,
          vertical: AppDimensions.paddingXs,
        ),
        child: Text(
          _getOptionLabel(option),
          style: TextStyle(
            color: isSelected ? AppColors.primary : null,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomOption() {
    final isSelected = _selectedOption == DateRangeOption.custom;

    return ShadButton.outline(
      onPressed: _showCustomDatePicker,
      size: ShadButtonSize.sm,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingS,
          vertical: AppDimensions.paddingXs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range,
              size: AppDimensions.iconS,
              color: isSelected ? AppColors.primary : null,
            ),
            const SizedBox(width: AppDimensions.spacingXs),
            Text(
              'analytics.customRange'.tr(),
              style: TextStyle(
                color: isSelected ? AppColors.primary : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedRangeDisplay() {
    final theme = ShadTheme.of(context);
    final range =
        widget.selectedRange ?? _getDateRangeFromOption(_selectedOption);

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
              _formatDateRange(range),
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            _getDaysDifference(range),
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
    setState(() {
      _selectedOption = option;
    });

    final range = _getDateRangeFromOption(option);
    widget.onRangeChanged(range);
  }

  Future<void> _showCustomDatePicker() async {
    final theme = ShadTheme.of(context);
    final now = DateTime.now();

    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _customRange != null
          ? DateTimeRange(start: _customRange!.start, end: _customRange!.end)
          : DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: now,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (dateRange != null) {
      final customRange = DateRange(
        start: dateRange.start,
        end: dateRange.end,
      );

      setState(() {
        _selectedOption = DateRangeOption.custom;
        _customRange = customRange;
      });

      widget.onRangeChanged(customRange);
    }
  }

  String _getOptionLabel(DateRangeOption option) {
    switch (option) {
      case DateRangeOption.today:
        return 'analytics.today'.tr();
      case DateRangeOption.thisWeek:
        return 'analytics.thisWeek'.tr();
      case DateRangeOption.thisMonth:
        return 'analytics.thisMonth'.tr();
      case DateRangeOption.last30Days:
        return 'analytics.last30Days'.tr();
      case DateRangeOption.last3Months:
        return 'analytics.last3Months'.tr();
      case DateRangeOption.last6Months:
        return 'analytics.last6Months'.tr();
      case DateRangeOption.thisYear:
        return 'analytics.thisYear'.tr();
      case DateRangeOption.lastYear:
        return 'analytics.lastYear'.tr();
      case DateRangeOption.custom:
        return 'analytics.custom'.tr();
    }
  }

  DateRange _getDateRangeFromOption(DateRangeOption option) {
    if (option == DateRangeOption.custom && _customRange != null) {
      return _customRange!;
    }

    final now = DateTime.now();

    switch (option) {
      case DateRangeOption.today:
        return DateRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );

      case DateRangeOption.thisWeek:
        final startOfWeek = AppDateUtils.startOfWeek(now);
        return DateRange(
          start: startOfWeek,
          end: startOfWeek.add(
              const Duration(days: 6, hours: 23, minutes: 59, seconds: 59)),
        );

      case DateRangeOption.thisMonth:
        return DateRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );

      case DateRangeOption.last30Days:
        return DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

      case DateRangeOption.last3Months:
        return DateRange(
          start: DateTime(now.year, now.month - 3, now.day),
          end: now,
        );

      case DateRangeOption.last6Months:
        return DateRange(
          start: DateTime(now.year, now.month - 6, now.day),
          end: now,
        );

      case DateRangeOption.thisYear:
        return DateRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );

      case DateRangeOption.lastYear:
        return DateRange(
          start: DateTime(now.year - 1, 1, 1),
          end: DateTime(now.year - 1, 12, 31, 23, 59, 59),
        );

      case DateRangeOption.custom:
        return DateRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
    }
  }

  String _formatDateRange(DateRange range) {
    final start = DateFormat.yMMMd().format(range.start);
    final end = DateFormat.yMMMd().format(range.end);

    if (range.start.year == range.end.year &&
        range.start.month == range.end.month &&
        range.start.day == range.end.day) {
      return start;
    }

    return '$start - $end';
  }

  String _getDaysDifference(DateRange range) {
    final difference = range.end.difference(range.start).inDays + 1;
    return '$difference ${'analytics.days'.tr()}';
  }
}

// Data model for date range
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });

  Duration get duration => end.difference(start);
  int get days => duration.inDays + 1;

  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
        date.isBefore(end.add(const Duration(seconds: 1)));
  }

  @override
  String toString() => 'DateRange(start: $start, end: $end)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}
