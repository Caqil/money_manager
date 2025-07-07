import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/dimensions.dart';

class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? labelText;
  final String? sublabelText;
  final Widget? label;
  final Widget? sublabel;
  final bool enabled;
  final bool tristate;
  final EdgeInsetsGeometry? padding;

  const CustomCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.labelText,
    this.sublabelText,
    this.label,
    this.sublabel,
    this.enabled = true,
    this.tristate = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Simple checkbox without label
    if (labelText == null &&
        sublabelText == null &&
        label == null &&
        sublabel == null) {
      return ShadCheckbox(
        value: value,
        onChanged: enabled ? onChanged : null,
      );
    }

    // Checkbox with label and sublabel
    return Container(
      padding: padding,
      child: ShadCheckbox(
        value: value,
        onChanged: enabled ? onChanged : null,
        label: label ?? (labelText != null ? Text(labelText!) : null),
        sublabel:
            sublabel ?? (sublabelText != null ? Text(sublabelText!) : null),
      ),
    );
  }
}

// Custom checkbox group for multiple selections
class CustomCheckboxGroup<T> extends StatefulWidget {
  final List<CheckboxGroupItem<T>> items;
  final List<T> selectedValues;
  final ValueChanged<List<T>>? onChanged;
  final String? title;
  final String? subtitle;
  final bool enabled;
  final int? maxSelections;
  final int? minSelections;
  final bool required;
  final String? Function(List<T>?)? validator;
  final AutovalidateMode? autovalidateMode;
  final EdgeInsetsGeometry? padding;
  final double spacing;
  final bool showSelectAll;
  final String? selectAllText;
  final String? clearAllText;
  final bool wrap;
  final WrapAlignment wrapAlignment;
  final double runSpacing;
  final Axis direction;

  const CustomCheckboxGroup({
    super.key,
    required this.items,
    required this.selectedValues,
    this.onChanged,
    this.title,
    this.subtitle,
    this.enabled = true,
    this.maxSelections,
    this.minSelections,
    this.required = false,
    this.validator,
    this.autovalidateMode,
    this.padding,
    this.spacing = AppDimensions.spacingS,
    this.showSelectAll = false,
    this.selectAllText,
    this.clearAllText,
    this.wrap = false,
    this.wrapAlignment = WrapAlignment.start,
    this.runSpacing = AppDimensions.spacingS,
    this.direction = Axis.vertical,
  });

  @override
  State<CustomCheckboxGroup<T>> createState() => _CustomCheckboxGroupState<T>();
}

class _CustomCheckboxGroupState<T> extends State<CustomCheckboxGroup<T>> {
  late List<T> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = List<T>.from(widget.selectedValues);
  }

  @override
  void didUpdateWidget(CustomCheckboxGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValues != oldWidget.selectedValues) {
      _selectedValues = List<T>.from(widget.selectedValues);
    }
  }

  void _onItemChanged(T value, bool selected) {
    if (!widget.enabled) return;

    setState(() {
      if (selected) {
        if (widget.maxSelections == null ||
            _selectedValues.length < widget.maxSelections!) {
          _selectedValues.add(value);
        }
      } else {
        _selectedValues.remove(value);
      }
    });

    widget.onChanged?.call(_selectedValues);
  }

  void _selectAll() {
    if (!widget.enabled) return;

    setState(() {
      _selectedValues = widget.items.map((item) => item.value).toList();
    });

    widget.onChanged?.call(_selectedValues);
  }

  void _clearAll() {
    if (!widget.enabled) return;

    setState(() {
      _selectedValues.clear();
    });

    widget.onChanged?.call(_selectedValues);
  }

  String? _getValidator() {
    if (widget.validator != null) {
      return widget.validator!(_selectedValues);
    }

    if (widget.required && _selectedValues.isEmpty) {
      return 'validation.required'.tr();
    }

    if (widget.minSelections != null &&
        _selectedValues.length < widget.minSelections!) {
      return 'validation.minSelection'.tr(namedArgs: {
        'count': widget.minSelections.toString(),
      });
    }

    if (widget.maxSelections != null &&
        _selectedValues.length > widget.maxSelections!) {
      return 'validation.maxSelection'.tr(namedArgs: {
        'count': widget.maxSelections.toString(),
      });
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return FormField<List<T>>(
      initialValue: _selectedValues,
      validator: (_) => _getValidator(),
      autovalidateMode:
          widget.autovalidateMode ?? AutovalidateMode.onUserInteraction,
      builder: (fieldState) {
        final errorText = fieldState.errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.title != null) ...[
              Row(
                children: [
                  Text(
                    widget.title!,
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
            if (widget.subtitle != null) ...[
              Text(
                widget.subtitle!,
                style: theme.textTheme.muted,
              ),
              const SizedBox(height: AppDimensions.spacingM),
            ],
            if (widget.showSelectAll) ...[
              Row(
                children: [
                  ShadButton.ghost(
                    onPressed: widget.enabled ? _selectAll : null,
                    child:
                        Text(widget.selectAllText ?? 'common.selectAll'.tr()),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  ShadButton.ghost(
                    onPressed: widget.enabled ? _clearAll : null,
                    child: Text(widget.clearAllText ?? 'common.clearAll'.tr()),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingS),
            ],
            Container(
              padding: widget.padding,
              child: widget.wrap
                  ? Wrap(
                      spacing: widget.spacing,
                      runSpacing: widget.runSpacing,
                      alignment: widget.wrapAlignment,
                      children: _buildCheckboxes(),
                    )
                  : widget.direction == Axis.vertical
                      ? Column(
                          children: _buildCheckboxes()
                              .expand((w) => [
                                    w,
                                    SizedBox(height: widget.spacing),
                                  ])
                              .take(_buildCheckboxes().length * 2 - 1)
                              .toList(),
                        )
                      : Row(
                          children: _buildCheckboxes()
                              .expand((w) => [
                                    w,
                                    SizedBox(width: widget.spacing),
                                  ])
                              .take(_buildCheckboxes().length * 2 - 1)
                              .toList(),
                        ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                errorText,
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.destructive,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _buildCheckboxes() {
    return widget.items.map((item) {
      final isSelected = _selectedValues.contains(item.value);
      final isDisabled = !widget.enabled ||
          !item.enabled ||
          (!isSelected &&
              widget.maxSelections != null &&
              _selectedValues.length >= widget.maxSelections!);

      return CustomCheckbox(
        value: isSelected,
        onChanged: isDisabled
            ? null
            : (value) => _onItemChanged(item.value, value),
        labelText: item.title,
        sublabelText: item.subtitle,
        enabled: !isDisabled,
        padding: EdgeInsets.zero,
      );
    }).toList();
  }
}

// Checkbox group item data class
class CheckboxGroupItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final bool enabled;

  const CheckboxGroupItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.enabled = true,
  });
}

// Simple checkbox with label (legacy support)
class LabeledCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String label;
  final bool enabled;
  final MainAxisAlignment mainAxisAlignment;
  final EdgeInsetsGeometry? padding;

  const LabeledCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    required this.label,
    this.enabled = true,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCheckbox(
      value: value,
      onChanged: onChanged,
      labelText: label,
      enabled: enabled,
      padding: padding,
    );
  }
}

// Checkbox form field
class CheckboxFormField extends StatelessWidget {
  final String id;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;
  final String? Function(bool)? validator;
  final String? labelText;
  final String? sublabelText;
  final Widget? inputLabel;
  final Widget? inputSublabel;
  final bool enabled;

  const CheckboxFormField({
    super.key,
    required this.id,
    this.initialValue = false,
    this.onChanged,
    this.validator,
    this.labelText,
    this.sublabelText,
    this.inputLabel,
    this.inputSublabel,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShadCheckboxFormField(
      id: id,
      initialValue: initialValue,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      inputLabel: inputLabel ?? (labelText != null ? Text(labelText!) : null),
      inputSublabel:
          inputSublabel ?? (sublabelText != null ? Text(sublabelText!) : null),
    );
  }
}

// Checkbox card for settings
class CheckboxCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String title;
  final String? description;
  final Widget? icon;
  final bool enabled;

  const CheckboxCard({
    super.key,
    required this.value,
    this.onChanged,
    required this.title,
    this.description,
    this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: InkWell(
        onTap: enabled ? () => onChanged?.call(!value) : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Row(
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: AppDimensions.spacingM),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      description!,
                      style: theme.textTheme.muted,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            ShadCheckbox(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}
