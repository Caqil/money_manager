import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

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
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final DateRangePickerController _datePickerController = DateRangePickerController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _formatter = widget.dateFormat ?? DateFormat.yMMMd();
    _datePickerController.selectedDate = widget.selectedDate;
  }

  @override
  void didUpdateWidget(DatePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      setState(() {
        _selectedDate = widget.selectedDate;
      });
      _datePickerController.selectedDate = widget.selectedDate;
    }
    if (widget.dateFormat != oldWidget.dateFormat) {
      _formatter = widget.dateFormat ?? DateFormat.yMMMd();
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _datePickerController.dispose();
    super.dispose();
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
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
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
                ? theme.colorScheme.background
                : theme.colorScheme.muted,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: AppDimensions.iconS,
                color: widget.enabled 
                    ? theme.colorScheme.foreground
                    : theme.colorScheme.mutedForeground,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  _selectedDate != null
                      ? _formatter.format(_selectedDate!)
                      : (widget.placeholder ?? 'transactions.selectDate'.tr()),
                  style: theme.textTheme.p.copyWith(
                    color: _selectedDate != null
                        ? (widget.enabled 
                            ? theme.colorScheme.foreground
                            : theme.colorScheme.mutedForeground)
                        : theme.colorScheme.mutedForeground,
                  ),
                ),
              ),
              if (_selectedDate != null && widget.enabled)
                GestureDetector(
                  onTap: _clearDate,
                  child: Icon(
                    Icons.clear,
                    size: AppDimensions.iconXs,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickOptionsButton(ShadThemeData theme) {
    return ShadButton.outline(
      onPressed: widget.enabled ? _showQuickOptionsModal : null,
      child: const Icon(
        Icons.access_time,
        size: AppDimensions.iconS,
      ),
    );
  }

  Widget _buildQuickDateOptions() {
    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingXs,
      children: _getQuickDateOptions().take(4).toList().map((option) => 
        ShadButton.outline(
          size: ShadButtonSize.sm,
          onPressed: widget.enabled 
              ? () => _selectDate(option.date)
              : null,
          child: Text(
            option.label,
            style: const TextStyle(fontSize: 12),
          ),
        )
      ).toList(),
    );
  }

  void _showDatePicker() {
    if (!widget.enabled) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDatePicker() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 5,
        width: size.width.clamp(300.0, 400.0),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ShadTheme.of(context).colorScheme.border,
                ),
                color: ShadTheme.of(context).colorScheme.background,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick date options header
                  _buildQuickDateOptionsHeader(),
                  
                  // Syncfusion Date Picker
                  SfDateRangePicker(
                    controller: _datePickerController,
                    view: DateRangePickerView.month,
                    selectionMode: DateRangePickerSelectionMode.single,
                    showNavigationArrow: true,
                    allowViewNavigation: true,
                    enablePastDates: true,
                    minDate: widget.minDate,
                    maxDate: widget.maxDate,
                    initialSelectedDate: _selectedDate,
                    onSelectionChanged: _onSelectionChanged,
                    monthViewSettings: const DateRangePickerMonthViewSettings(
                      enableSwipeSelection: false,
                    ),
                    monthCellStyle: DateRangePickerMonthCellStyle(
                      textStyle: TextStyle(
                        color: ShadTheme.of(context).colorScheme.foreground,
                      ),
                      todayTextStyle: TextStyle(
                        color: ShadTheme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selectionTextStyle: TextStyle(
                      color: ShadTheme.of(context).colorScheme.primaryForeground,
                    ),
                    selectionColor: ShadTheme.of(context).colorScheme.primary,
                    todayHighlightColor: ShadTheme.of(context).colorScheme.primary,
                    headerStyle: DateRangePickerHeaderStyle(
                      textStyle: TextStyle(
                        color: ShadTheme.of(context).colorScheme.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    yearCellStyle: DateRangePickerYearCellStyle(
                      textStyle: TextStyle(
                        color: ShadTheme.of(context).colorScheme.foreground,
                      ),
                      todayTextStyle: TextStyle(
                        color: ShadTheme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ShadButton.outline(
                          onPressed: () {
                            _hideDatePicker();
                          },
                          child: Text('common.cancel'.tr()),
                        ),
                        const SizedBox(width: 8),
                        ShadButton(
                          onPressed: () {
                            _hideDatePicker();
                          },
                          child: Text('common.done'.tr()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDateOptionsHeader() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ShadTheme.of(context).colorScheme.border,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'transactions.quickSelect'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: ShadTheme.of(context).colorScheme.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _getQuickDateOptions().map((option) => ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: () {
                _selectDate(option.date);
                _hideDatePicker();
              },
              child: Text(option.label),
            )).toList(),
          ),
        ],
      ),
    );
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    if (args.value is DateTime) {
      final selectedDate = args.value as DateTime;
      _selectDate(selectedDate);
    }
  }

  void _showQuickOptionsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'transactions.quickSelect'.tr(),
              style: ShadTheme.of(context).textTheme.h3,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            ...(_getQuickDateOptions().map((option) => ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(option.label),
              subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
              onTap: () {
                _selectDate(option.date);
                Navigator.of(context).pop();
              },
            )).toList()),
          ],
        ),
      ),
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

  void _selectDate(DateTime date) {
    // Validate against min/max dates
    if (widget.minDate != null && date.isBefore(widget.minDate!)) {
      return;
    }
    if (widget.maxDate != null && date.isAfter(widget.maxDate!)) {
      return;
    }

    setState(() {
      _selectedDate = date;
    });
    _datePickerController.selectedDate = date;
    widget.onDateChanged(date);
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
    });
    _datePickerController.selectedDate = null;
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