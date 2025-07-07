import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
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
  final TextEditingController _controller = TextEditingController();
  final DateRangePickerController _datePickerController =
      DateRangePickerController();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _updateController();
    _datePickerController.selectedDate = widget.selectedDate;
  }

  @override
  void didUpdateWidget(CustomDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _updateController();
      _datePickerController.selectedDate = widget.selectedDate;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _datePickerController.dispose();
    _overlayEntry?.remove();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateController() {
    if (widget.selectedDate != null) {
      _controller.text = DateFormat.yMMMd().format(widget.selectedDate!);
    } else {
      _controller.clear();
    }
  }

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

  void _showDatePicker() {
    if (!widget.enabled) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _focusNode.requestFocus();
  }

  void _hideDatePicker() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _focusNode.unfocus();
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
                  // Quick date options if provided
                  if (widget.presets != null && widget.presets!.isNotEmpty)
                    _buildQuickDateOptions(),

                  // Syncfusion Date Picker
                  SfDateRangePicker(
                    controller: _datePickerController,
                    view: DateRangePickerView.month,
                    selectionMode: DateRangePickerSelectionMode.single,
                    showNavigationArrow: true,
                    allowViewNavigation: true,
                    enablePastDates: true,
                    minDate: widget.fromMonth,
                    maxDate: widget.toMonth,
                    initialSelectedDate: widget.selectedDate,
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
                      color:
                          ShadTheme.of(context).colorScheme.primaryForeground,
                    ),
                    rangeTextStyle: TextStyle(
                      color: ShadTheme.of(context).colorScheme.foreground,
                    ),
                    selectionColor: ShadTheme.of(context).colorScheme.primary,
                    startRangeSelectionColor:
                        ShadTheme.of(context).colorScheme.primary,
                    endRangeSelectionColor:
                        ShadTheme.of(context).colorScheme.primary,
                    rangeSelectionColor: ShadTheme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.3),
                    todayHighlightColor:
                        ShadTheme.of(context).colorScheme.primary,
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

  Widget _buildQuickDateOptions() {
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
            'common.quickSelect'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: ShadTheme.of(context).colorScheme.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: widget.presets!
                .map((option) => ShadButton.outline(
                      size: ShadButtonSize.sm,
                      onPressed: () {
                        widget.onChanged?.call(option.date);
                        _hideDatePicker();
                      },
                      child: Text(option.label),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    if (args.value is DateTime) {
      final selectedDate = args.value as DateTime;
      widget.onChanged?.call(selectedDate);
    }
  }

  void _clearDate() {
    widget.onChanged?.call(null);
    _hideDatePicker();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    // If using form field mode
    if (widget.labelText != null ||
        widget.description != null ||
        widget.required) {
      return CompositedTransformTarget(
        link: _layerLink,
        child: ShadInputFormField(
          controller: _controller,
          focusNode: _focusNode,
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
          placeholder: Text('forms.selectDate'.tr()),
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
                  onPressed: widget.enabled ? _clearDate : null,
                  child: const Icon(
                    Icons.clear,
                    size: AppDimensions.iconS,
                  ),
                )
              : null,
          onPressed: _showDatePicker,
          validator: (value) => _getValidator(widget.selectedDate),
          autovalidateMode: widget.autovalidateMode,
        ),
      );
    }

    // Basic input field
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        padding: widget.padding,
        constraints: BoxConstraints(
          minWidth: widget.minWidth ?? 0,
          maxWidth: widget.maxWidth ?? double.infinity,
        ),
        child: ShadInput(
          controller: _controller,
          focusNode: _focusNode,
          placeholder: Text('forms.selectDate'.tr()),
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
                  onPressed: widget.enabled ? _clearDate : null,
                  child: Icon(
                    Icons.clear,
                    size: AppDimensions.iconS,
                  ),
                )
              : null,
          onPressed: _showDatePicker,
        ),
      ),
    );
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
