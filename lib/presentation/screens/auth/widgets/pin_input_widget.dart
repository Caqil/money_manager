import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/constants/text_styles.dart';

class PinInputWidget extends StatefulWidget {
  final int pinLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final VoidCallback? onDelete;
  final bool obscureText;
  final bool enabled;
  final String? errorText;
  final bool autoFocus;
  final bool showCursor;
  final Color? fillColor;
  final Color? activeFillColor;
  final Color? errorFillColor;
  final Color? borderColor;
  final Color? activeBorderColor;
  final Color? errorBorderColor;
  final double? borderWidth;
  final double? borderRadius;
  final double spacing;
  final double fieldWidth;
  final double fieldHeight;
  final TextStyle? textStyle;
  final bool hapticFeedback;
  final bool readOnly;
  final String? currentPin;

  const PinInputWidget({
    super.key,
    this.pinLength = 4,
    this.onChanged,
    this.onCompleted,
    this.onDelete,
    this.obscureText = true,
    this.enabled = true,
    this.errorText,
    this.autoFocus = false,
    this.showCursor = true,
    this.fillColor,
    this.activeFillColor,
    this.errorFillColor,
    this.borderColor,
    this.activeBorderColor,
    this.errorBorderColor,
    this.borderWidth,
    this.borderRadius,
    this.spacing = AppDimensions.spacingM,
    this.fieldWidth = 56.0,
    this.fieldHeight = 56.0,
    this.textStyle,
    this.hapticFeedback = true,
    this.readOnly = false,
    this.currentPin,
  });

  @override
  State<PinInputWidget> createState() => PinInputWidgetState();
}

class PinInputWidgetState extends State<PinInputWidget>
    with TickerProviderStateMixin {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  int _currentIndex = 0;
  String _pin = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    
    if (widget.currentPin != null) {
      _setPin(widget.currentPin!);
    }
  }

  void _initializeControllers() {
    _controllers = List.generate(
      widget.pinLength,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.pinLength,
      (index) => FocusNode(),
    );

    // Add listeners
    for (int i = 0; i < widget.pinLength; i++) {
      _controllers[i].addListener(() => _onTextChanged(i));
      _focusNodes[i].addListener(() => _onFocusChanged(i));
    }
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  void _setPin(String pin) {
    for (int i = 0; i < widget.pinLength; i++) {
      if (i < pin.length) {
        _controllers[i].text = pin[i];
      } else {
        _controllers[i].clear();
      }
    }
    _currentIndex = pin.length;
    _pin = pin;
  }

  void _onTextChanged(int index) {
    final text = _controllers[index].text;
    
    if (text.isNotEmpty) {
      // Only allow digits
      if (!RegExp(r'^\d$').hasMatch(text)) {
        _controllers[index].clear();
        return;
      }

      // Move to next field
      if (index < widget.pinLength - 1) {
        _focusNodes[index + 1].requestFocus();
        _currentIndex = index + 1;
      } else {
        _focusNodes[index].unfocus();
        _currentIndex = widget.pinLength;
      }

      if (widget.hapticFeedback) {
        HapticFeedback.lightImpact();
      }

      // Scale animation for feedback
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
    }

    _updatePin();
  }

  void _onFocusChanged(int index) {
    if (_focusNodes[index].hasFocus) {
      _currentIndex = index;
      setState(() {});
    }
  }

  void _updatePin() {
    final newPin = _controllers.map((c) => c.text).join();
    if (_pin != newPin) {
      _pin = newPin;
      _hasError = false;
      widget.onChanged?.call(_pin);

      if (_pin.length == widget.pinLength) {
        widget.onCompleted?.call(_pin);
      }

      setState(() {});
    }
  }

  void _onKeyPressed(int index, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].clear();
          _currentIndex = index - 1;
          widget.onDelete?.call();
        } else if (_controllers[index].text.isNotEmpty) {
          _controllers[index].clear();
          widget.onDelete?.call();
        }
        
        if (widget.hapticFeedback) {
          HapticFeedback.selectionClick();
        }
      }
    }
  }

  // Public methods for external control
  void showError() {
    setState(() {
      _hasError = true;
    });
    
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });

    if (widget.hapticFeedback) {
      HapticFeedback.heavyImpact();
    }
  }

  void clearPin() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _currentIndex = 0;
    _pin = '';
    _hasError = false;
    
    if (widget.pinLength > 0) {
      _focusNodes[0].requestFocus();
    }
    
    setState(() {});
  }

  void setPin(String pin) {
    _setPin(pin);
    setState(() {});
  }

  String get currentPin => _pin;

  @override
  void didUpdateWidget(PinInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.errorText != oldWidget.errorText && widget.errorText != null) {
      showError();
    }
    
    if (widget.currentPin != oldWidget.currentPin && widget.currentPin != null) {
      _setPin(widget.currentPin!);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _shakeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Color _getFieldColor(int index) {
    final theme = Theme.of(context);
    final hasError = _hasError || widget.errorText != null;
    final isActive = _currentIndex == index;
    final isFilled = _controllers[index].text.isNotEmpty;

    if (hasError) {
      return widget.errorFillColor ?? AppColors.error.withOpacity(0.1);
    }
    
    if (isActive || isFilled) {
      return widget.activeFillColor ?? theme.colorScheme.primary.withOpacity(0.1);
    }
    
    return widget.fillColor ?? theme.colorScheme.surface;
  }

  Color _getBorderColor(int index) {
    final theme = Theme.of(context);
    final hasError = _hasError || widget.errorText != null;
    final isActive = _currentIndex == index;
    final isFilled = _controllers[index].text.isNotEmpty;

    if (hasError) {
      return widget.errorBorderColor ?? AppColors.error;
    }
    
    if (isActive) {
      return widget.activeBorderColor ?? theme.colorScheme.primary;
    }
    
    if (isFilled) {
      return widget.activeBorderColor ?? theme.colorScheme.primary.withOpacity(0.5);
    }
    
    return widget.borderColor ?? theme.colorScheme.outline.withOpacity(0.3);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(widget.pinLength, (index) {
                  return AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      final isCurrentIndex = _currentIndex == index;
                      final scale = isCurrentIndex ? _scaleAnimation.value : 1.0;
                      
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: widget.fieldWidth,
                          height: widget.fieldHeight,
                          margin: EdgeInsets.symmetric(
                            horizontal: widget.spacing / 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getFieldColor(index),
                            borderRadius: BorderRadius.circular(
                              widget.borderRadius ?? AppDimensions.radiusM,
                            ),
                            border: Border.all(
                              color: _getBorderColor(index),
                              width: widget.borderWidth ?? 2.0,
                            ),
                          ),
                          child: KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: (event) => _onKeyPressed(index, event),
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              enabled: widget.enabled,
                              readOnly: widget.readOnly,
                              autofocus: widget.autoFocus && index == 0,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              obscureText: widget.obscureText,
                              maxLength: 1,
                              style: widget.textStyle ?? AppTextStyles.headlineMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
                              ],
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                                hintText: widget.showCursor && _currentIndex == index ? '' : null,
                              ),
                              onTap: () {
                                _currentIndex = index;
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            );
          },
        ),
        
        // Error message
        if (widget.errorText != null) ...[
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            widget.errorText!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}