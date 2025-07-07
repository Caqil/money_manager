import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/utils/validation_helper.dart';

class CustomTextField extends StatefulWidget {
  final String? labelText;
  final String? placeholder;
  final String? description;
  final String? initialValue;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? maxLines;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool required;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final EdgeInsetsGeometry? padding;
  final double? minWidth;
  final double? maxWidth;

  const CustomTextField({
    super.key,
    this.labelText,
    this.placeholder,
    this.description,
    this.initialValue,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.leading,
    this.trailing,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.validator,
    this.autovalidateMode,
    this.padding,
    this.minWidth,
    this.maxWidth,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }

    _focusNode.addListener(_onFocusChange);
    if (widget.autovalidateMode == AutovalidateMode.onUserInteraction) {
      _controller.addListener(_onTextChange);
    }
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      if (widget.initialValue != null) {
        _controller.text = widget.initialValue!;
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _onTextChange() {
    if (mounted) {
      _validateInput();
    }
  }

  void _validateInput() {
    final error = _getValidator(_controller.text);
    if (_errorText != error) {
      setState(() {
        _errorText = error;
      });
    }
  }

  String? _getValidator(String? value) {
    if (widget.validator != null) {
      return widget.validator!(value);
    }

    if (widget.required && (value == null || value.trim().isEmpty)) {
      return 'validation.required'.tr();
    }

    // Auto-validation based on keyboard type
    if (value != null && value.trim().isNotEmpty) {
      switch (widget.keyboardType) {
        case TextInputType.emailAddress:
          return ValidationHelper.getEmailErrorMessage(value);
        case TextInputType.phone:
          return ValidationHelper.getPhoneErrorMessage(value);
        case TextInputType.number:
        // Handle numberWithOptions by comparing runtimeType or using ==
        default:
          if (widget.keyboardType == const TextInputType.numberWithOptions(decimal: true) ||
              widget.keyboardType == const TextInputType.numberWithOptions(decimal: false)) {
            if (widget.labelText?.toLowerCase().contains('amount') == true) {
              return ValidationHelper.getAmountErrorMessage(value);
            }
          }
          break;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    Widget textField = ShadInput(
      controller: _controller,
      focusNode: _focusNode,
      placeholder:
          widget.placeholder != null ? Text(widget.placeholder!) : null,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      textCapitalization: widget.textCapitalization,
      leading: widget.leading,
      trailing: widget.trailing,
      onPressed: widget.onTap,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      padding: widget.padding is EdgeInsets ? widget.padding as EdgeInsets? : null,
    );

    // If using form field mode
    if (widget.labelText != null ||
        widget.description != null ||
        widget.required) {
      return ShadInputFormField(
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
                        color: ShadTheme.of(context).colorScheme.destructive,
                      ),
                    ),
                ],
              )
            : null,
        placeholder:
            widget.placeholder != null ? Text(widget.placeholder!) : null,
        description:
            widget.description != null ? Text(widget.description!) : null,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.inputFormatters,
        maxLength: widget.maxLength,
        maxLines: widget.maxLines,
        obscureText: widget.obscureText,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        textCapitalization: widget.textCapitalization,
        leading: widget.leading,
        trailing: widget.trailing,
        onPressed: widget.onTap,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onEditingComplete: widget.onEditingComplete,
        validator: (value) {
          if (widget.autovalidateMode == AutovalidateMode.disabled) {
            return _getValidator(value);
          }
          return _errorText;
        },
        padding: widget.padding is EdgeInsets ? widget.padding as EdgeInsets? : null,
      );
    }

    return textField;
  }
}

// Specialized text field for amounts
class AmountTextField extends StatelessWidget {
  final String? labelText;
  final String? placeholder;
  final String? description;
  final String? initialValue;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool required;
  final bool allowNegative;
  final int decimalPlaces;
  final String? currencySymbol;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final double? minWidth;
  final double? maxWidth;

  const AmountTextField({
    super.key,
    this.labelText,
    this.placeholder,
    this.description,
    this.initialValue,
    this.controller,
    this.focusNode,
    this.required = false,
    this.allowNegative = false,
    this.decimalPlaces = 2,
    this.currencySymbol,
    this.onChanged,
    this.validator,
    this.minWidth,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      labelText: labelText ?? 'common.amount'.tr(),
      placeholder: placeholder ?? 'forms.enterAmount'.tr(),
      description: description,
      initialValue: initialValue,
      controller: controller,
      focusNode: focusNode,
      required: required,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowNegative ? RegExp(r'^-?\d*\.?\d*') : RegExp(r'^\d*\.?\d*'),
        ),
        if (decimalPlaces >= 0)
          TextInputFormatter.withFunction((oldValue, newValue) {
            if (newValue.text.isEmpty) return newValue;

            final parts = newValue.text.split('.');
            if (parts.length > 2) return oldValue;

            if (parts.length == 2 && parts[1].length > decimalPlaces) {
              return oldValue;
            }

            return newValue;
          }),
      ],
      leading: currencySymbol != null
          ? Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              child: Text(currencySymbol!),
            )
          : null,
      onChanged: onChanged,
      validator: validator ??
          (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return 'validation.required'.tr();
            }
            if (value != null && value.trim().isNotEmpty) {
              if (allowNegative) {
                return ValidationHelper.getAmountErrorMessage(
                    value.replaceAll('-', ''));
              } else {
                return ValidationHelper.getPositiveAmountErrorMessage(value);
              }
            }
            return null;
          },
      minWidth: minWidth,
      maxWidth: maxWidth,
    );
  }
}

// Search text field
class SearchTextField extends StatefulWidget {
  final String? placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;
  final double? minWidth;
  final double? maxWidth;

  const SearchTextField({
    super.key,
    this.placeholder,
    this.controller,
    this.onChanged,
    this.onClear,
    this.autofocus = false,
    this.minWidth,
    this.maxWidth,
  });

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
    widget.onChanged?.call(_controller.text);
  }

  void _clearText() {
    _controller.clear();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ShadInput(
      controller: _controller,
      placeholder: Text(widget.placeholder ?? 'common.search'.tr()),
      autofocus: widget.autofocus,
      leading: const Padding(
        padding: EdgeInsets.all(AppDimensions.paddingS),
        child: Icon(
          Icons.search,
          size: AppDimensions.iconS,
        ),
      ),
      trailing: _controller.text.isNotEmpty
          ? ShadButton(
              width: 24,
              height: 24,
              padding: EdgeInsets.zero,
              onPressed: _clearText,
              child: const Icon(
                Icons.clear,
                size: AppDimensions.iconS,
              ),
            )
          : null,
    );
  }
}

// Password text field
class PasswordTextField extends StatefulWidget {
  final String? labelText;
  final String? placeholder;
  final String? description;
  final TextEditingController? controller;
  final bool required;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final double? minWidth;
  final double? maxWidth;

  const PasswordTextField({
    super.key,
    this.labelText,
    this.placeholder,
    this.description,
    this.controller,
    this.required = false,
    this.onChanged,
    this.validator,
    this.minWidth,
    this.maxWidth,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      labelText: widget.labelText ?? 'common.password'.tr(),
      placeholder: widget.placeholder ?? 'forms.enterPassword'.tr(),
      description: widget.description,
      controller: widget.controller,
      required: widget.required,
      obscureText: _obscureText,
      trailing: ShadButton(
        width: 24,
        height: 24,
        padding: EdgeInsets.zero,
        child: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          size: AppDimensions.iconS,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      ),
      onChanged: widget.onChanged,
      validator: widget.validator,
      minWidth: widget.minWidth,
      maxWidth: widget.maxWidth,
    );
  }
}
