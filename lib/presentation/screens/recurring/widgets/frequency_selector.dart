import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../data/models/recurring_transaction.dart';

class FrequencySelector extends StatefulWidget {
  final RecurrenceFrequency selectedFrequency;
  final int intervalValue;
  final List<int>? weekdays;
  final int? dayOfMonth;
  final List<int>? monthsOfYear;
  final ValueChanged<FrequencySelectorData> onFrequencyChanged;
  final bool enabled;
  final String? labelText;
  final bool required;

  const FrequencySelector({
    super.key,
    required this.selectedFrequency,
    required this.intervalValue,
    this.weekdays,
    this.dayOfMonth,
    this.monthsOfYear,
    required this.onFrequencyChanged,
    this.enabled = true,
    this.labelText,
    this.required = false,
  });

  @override
  State<FrequencySelector> createState() => _FrequencySelectorState();
}

class _FrequencySelectorState extends State<FrequencySelector> {
  late RecurrenceFrequency _selectedFrequency;
  late int _intervalValue;
  late List<int> _selectedWeekdays;
  late int _selectedDayOfMonth;
  late List<int> _selectedMonthsOfYear;

  // Frequency options
  static const List<FrequencyOption> _frequencyOptions = [
    FrequencyOption(
      frequency: RecurrenceFrequency.daily,
      title: 'Daily',
      description: 'Repeat every day(s)',
      icon: Icons.today,
    ),
    FrequencyOption(
      frequency: RecurrenceFrequency.weekly,
      title: 'Weekly',
      description: 'Repeat every week(s)',
      icon: Icons.date_range,
    ),
    FrequencyOption(
      frequency: RecurrenceFrequency.monthly,
      title: 'Monthly',
      description: 'Repeat every month(s)',
      icon: Icons.calendar_month,
    ),
    FrequencyOption(
      frequency: RecurrenceFrequency.quarterly,
      title: 'Quarterly',
      description: 'Repeat every quarter(s)',
      icon: Icons.calendar_view_month,
    ),
    FrequencyOption(
      frequency: RecurrenceFrequency.yearly,
      title: 'Yearly',
      description: 'Repeat every year(s)',
      icon: Icons.event_repeat,
    ),
    FrequencyOption(
      frequency: RecurrenceFrequency.custom,
      title: 'Custom',
      description: 'Custom schedule',
      icon: Icons.tune,
    ),
  ];

  // Weekday names
  static const List<String> _weekdayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  // Month names
  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _selectedFrequency = widget.selectedFrequency;
    _intervalValue = widget.intervalValue;
    _selectedWeekdays = widget.weekdays ?? [1, 2, 3, 4, 5]; // Mon-Fri default
    _selectedDayOfMonth = widget.dayOfMonth ?? DateTime.now().day;
    _selectedMonthsOfYear = widget.monthsOfYear ?? [DateTime.now().month];
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

        // Frequency type selection
        _buildFrequencyTypeSelector(theme),
        const SizedBox(height: AppDimensions.spacingM),

        // Interval selector
        _buildIntervalSelector(theme),

        // Additional options based on frequency
        if (_selectedFrequency == RecurrenceFrequency.weekly) ...[
          const SizedBox(height: AppDimensions.spacingM),
          _buildWeekdaySelector(theme),
        ],

        if (_selectedFrequency == RecurrenceFrequency.monthly ||
            _selectedFrequency == RecurrenceFrequency.quarterly) ...[
          const SizedBox(height: AppDimensions.spacingM),
          _buildDayOfMonthSelector(theme),
        ],

        if (_selectedFrequency == RecurrenceFrequency.yearly) ...[
          const SizedBox(height: AppDimensions.spacingM),
          _buildMonthSelector(theme),
          const SizedBox(height: AppDimensions.spacingM),
          _buildDayOfMonthSelector(theme),
        ],

        if (_selectedFrequency == RecurrenceFrequency.custom) ...[
          const SizedBox(height: AppDimensions.spacingM),
          _buildCustomScheduleInfo(theme),
        ],
      ],
    );
  }

  Widget _buildFrequencyTypeSelector(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recurring.frequency'.tr(),
          style: theme.textTheme.p.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: AppDimensions.spacingS,
            mainAxisSpacing: AppDimensions.spacingS,
          ),
          itemCount: _frequencyOptions.length,
          itemBuilder: (context, index) {
            final option = _frequencyOptions[index];
            final isSelected = _selectedFrequency == option.frequency;

            return ShadCard(
              child: InkWell(
                onTap: widget.enabled ? () => _selectFrequency(option.frequency) : null,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : theme.colorScheme.muted.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        ),
                        child: Icon(
                          option.icon,
                          size: 16,
                          color: isSelected ? AppColors.primary : null,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'recurring.frequencies.${option.frequency.name}'.tr(),
                              style: theme.textTheme.p.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.primary : null,
                              ),
                            ),
                            Text(
                              'recurring.frequencies.${option.frequency.name}Description'.tr(),
                              style: theme.textTheme.small.copyWith(
                                color: theme.colorScheme.mutedForeground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIntervalSelector(ShadThemeData theme) {
    if (_selectedFrequency == RecurrenceFrequency.custom) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Text(
          'recurring.repeatEvery'.tr(),
          style: theme.textTheme.p,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        
        SizedBox(
          width: 80,
          child: ShadInput(
            initialValue: _intervalValue.toString(),
            keyboardType: TextInputType.number,
            enabled: widget.enabled,
            onChanged: (value) {
              final interval = int.tryParse(value);
              if (interval != null && interval > 0) {
                setState(() {
                  _intervalValue = interval;
                });
                _notifyChange();
              }
            },
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        
        Text(
          _getIntervalUnit(),
          style: theme.textTheme.p,
        ),
      ],
    );
  }

  Widget _buildWeekdaySelector(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recurring.selectWeekdays'.tr(),
          style: theme.textTheme.p.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        
        Wrap(
          spacing: AppDimensions.spacingS,
          children: List.generate(7, (index) {
            final weekday = index + 1; // 1-7 (Mon-Sun)
            final isSelected = _selectedWeekdays.contains(weekday);
            
            return FilterChip(
              label: Text(_weekdayNames[index]),
              selected: isSelected,
              onSelected: widget.enabled
                  ? (selected) {
                      setState(() {
                        if (selected) {
                          _selectedWeekdays.add(weekday);
                        } else {
                          _selectedWeekdays.remove(weekday);
                        }
                        _selectedWeekdays.sort();
                      });
                      _notifyChange();
                    }
                  : null,
              backgroundColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
              selectedColor: AppColors.primary.withOpacity(0.2),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDayOfMonthSelector(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recurring.dayOfMonth'.tr(),
          style: theme.textTheme.p.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        
        Row(
          children: [
            Text(
              'recurring.onThe'.tr(),
              style: theme.textTheme.p,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            
            SizedBox(
              width: 80,
              child: ShadInput(
                initialValue: _selectedDayOfMonth.toString(),
                keyboardType: TextInputType.number,
                enabled: widget.enabled,
                onChanged: (value) {
                  final day = int.tryParse(value);
                  if (day != null && day >= 1 && day <= 31) {
                    setState(() {
                      _selectedDayOfMonth = day;
                    });
                    _notifyChange();
                  }
                },
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            
            Text(
              'recurring.dayOfEachMonth'.tr(),
              style: theme.textTheme.p,
            ),
          ],
        ),
        
        const SizedBox(height: AppDimensions.spacingS),
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingS),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.info,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  'recurring.dayOfMonthNote'.tr(),
                  style: theme.textTheme.small.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'recurring.selectMonths'.tr(),
          style: theme.textTheme.p.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: List.generate(12, (index) {
            final month = index + 1; // 1-12 (Jan-Dec)
            final isSelected = _selectedMonthsOfYear.contains(month);
            
            return FilterChip(
              label: Text(_monthNames[index]),
              selected: isSelected,
              onSelected: widget.enabled
                  ? (selected) {
                      setState(() {
                        if (selected) {
                          _selectedMonthsOfYear.add(month);
                        } else {
                          _selectedMonthsOfYear.remove(month);
                        }
                        _selectedMonthsOfYear.sort();
                      });
                      _notifyChange();
                    }
                  : null,
              backgroundColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
              selectedColor: AppColors.primary.withOpacity(0.2),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCustomScheduleInfo(ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.construction,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'recurring.customSchedule'.tr(),
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'recurring.customScheduleDescription'.tr(),
                  style: theme.textTheme.small.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getIntervalUnit() {
    switch (_selectedFrequency) {
      case RecurrenceFrequency.daily:
        return _intervalValue == 1 ? 'day' : 'days';
      case RecurrenceFrequency.weekly:
        return _intervalValue == 1 ? 'week' : 'weeks';
      case RecurrenceFrequency.monthly:
        return _intervalValue == 1 ? 'month' : 'months';
      case RecurrenceFrequency.quarterly:
        return _intervalValue == 1 ? 'quarter' : 'quarters';
      case RecurrenceFrequency.yearly:
        return _intervalValue == 1 ? 'year' : 'years';
      case RecurrenceFrequency.custom:
        return 'custom';
    }
  }

  void _selectFrequency(RecurrenceFrequency frequency) {
    setState(() {
      _selectedFrequency = frequency;
      
      // Reset relevant values when switching frequency
      if (frequency != RecurrenceFrequency.weekly) {
        _selectedWeekdays = [1, 2, 3, 4, 5]; // Reset to weekdays
      }
      
      if (frequency != RecurrenceFrequency.monthly &&
          frequency != RecurrenceFrequency.quarterly &&
          frequency != RecurrenceFrequency.yearly) {
        _selectedDayOfMonth = DateTime.now().day;
      }
      
      if (frequency != RecurrenceFrequency.yearly) {
        _selectedMonthsOfYear = [DateTime.now().month];
      }
    });
    
    _notifyChange();
  }

  void _notifyChange() {
    widget.onFrequencyChanged(FrequencySelectorData(
      frequency: _selectedFrequency,
      intervalValue: _intervalValue,
      weekdays: _selectedFrequency == RecurrenceFrequency.weekly ? _selectedWeekdays : null,
      dayOfMonth: (_selectedFrequency == RecurrenceFrequency.monthly ||
                  _selectedFrequency == RecurrenceFrequency.quarterly ||
                  _selectedFrequency == RecurrenceFrequency.yearly)
          ? _selectedDayOfMonth
          : null,
      monthsOfYear: _selectedFrequency == RecurrenceFrequency.yearly ? _selectedMonthsOfYear : null,
    ));
  }
}

// Data classes
class FrequencyOption {
  final RecurrenceFrequency frequency;
  final String title;
  final String description;
  final IconData icon;

  const FrequencyOption({
    required this.frequency,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class FrequencySelectorData {
  final RecurrenceFrequency frequency;
  final int intervalValue;
  final List<int>? weekdays;
  final int? dayOfMonth;
  final List<int>? monthsOfYear;

  const FrequencySelectorData({
    required this.frequency,
    required this.intervalValue,
    this.weekdays,
    this.dayOfMonth,
    this.monthsOfYear,
  });
}