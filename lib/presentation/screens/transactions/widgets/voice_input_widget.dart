import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';

class VoiceInputWidget extends StatefulWidget {
  final Function(String) onTextReceived;
  final bool enabled;
  final String? locale;
  final Duration? timeout;
  final String? hintText;

  const VoiceInputWidget({
    super.key,
    required this.onTextReceived,
    this.enabled = true,
    this.locale,
    this.timeout,
    this.hintText,
  });

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _isListening = false;
  bool _isAvailable = false;
  bool _isInitializing = false;
  String _currentWords = '';
  double _confidence = 0.0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _initializeSpeech();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: false,
      );

      setState(() {
        _isAvailable = available;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isAvailable = false;
        _isInitializing = false;
      });
    }
  }

  void _onSpeechStatus(String status) {
    setState(() {
      _isListening = status == 'listening';
    });

    if (_isListening) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
      _animationController.reset();
    }
  }

  void _onSpeechError(dynamic error) {
    setState(() {
      _isListening = false;
      _currentWords = '';
    });
    _animationController.stop();
    _animationController.reset();

    _showError('voice.speechError'.tr());
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    if (_isInitializing) {
      return ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: null,
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (!_isAvailable) {
      return ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: widget.enabled ? _showPermissionDialog : null,
        child: Icon(
          Icons.mic_off,
          size: 16,
          color: AppColors.lightDisabled,
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 48, // Constrain width to prevent overflow
        maxHeight: 48,
      ),
      child: ShadPopover(
        visible: _isListening,
        popover: (context) =>
            _isListening ? _buildListeningPopover() : const SizedBox.shrink(),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening ? _scaleAnimation.value : 1.0,
              child: Opacity(
                opacity: _isListening ? _opacityAnimation.value : 1.0,
                child: ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: widget.enabled ? _toggleListening : null,
                  backgroundColor:
                      _isListening ? AppColors.primary.withOpacity(0.1) : null,
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 16,
                    color: _isListening
                        ? AppColors.primary
                        : theme.colorScheme.foreground,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListeningPopover() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.mic,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'voice.listening'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _stopListening,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.lightOnSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Waveform visualization
          _buildWaveform(),
          const SizedBox(height: AppDimensions.spacingM),

          // Current words
          Container(
            width: double.infinity,
            height: 60,
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Text(
              _currentWords.isNotEmpty
                  ? _currentWords
                  : widget.hintText ?? 'voice.speakNow'.tr(),
              style: TextStyle(
                color: _currentWords.isNotEmpty
                    ? AppColors.lightOnSurface
                    : AppColors.lightOnSurfaceVariant,
                fontStyle: _currentWords.isEmpty ? FontStyle.italic : null,
              ),
            ),
          ),

          // Confidence indicator
          if (_confidence > 0) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Row(
              children: [
                Text(
                  'voice.confidence'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: LinearProgressIndicator(
                    value: _confidence,
                    backgroundColor: AppColors.lightBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _confidence > 0.7
                          ? AppColors.success
                          : _confidence > 0.4
                              ? AppColors.warning
                              : AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  '${(_confidence * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppDimensions.spacingM),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: _stopListening,
                  child: Text('common.cancel'.tr()),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: ShadButton(
                  size: ShadButtonSize.sm,
                  onPressed: _currentWords.isNotEmpty ? _acceptText : null,
                  child: Text('voice.use'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return Container(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(20, (index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 100 + (index * 50)),
            width: 3,
            height: _isListening ? (20 + (index % 3) * 10).toDouble() : 5,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _isListening
                  ? AppColors.primary.withOpacity(0.7 + (index % 2) * 0.3)
                  : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!await _requestMicrophonePermission()) return;

    setState(() {
      _currentWords = '';
      _confidence = 0.0;
    });

    try {
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _currentWords = result.recognizedWords;
            _confidence = result.confidence;
          });
        },
        listenFor: widget.timeout ?? const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: widget.locale,
        onSoundLevelChange: null,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      _showError('voice.startListeningError'.tr());
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _acceptText() {
    if (_currentWords.isNotEmpty) {
      widget.onTextReceived(_currentWords);
      _stopListening();
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      _showPermissionDialog();
      return false;
    }
    return status.isGranted;
  }

  void _showPermissionDialog() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('voice.permissionRequired'.tr()),
        description: Text('voice.microphonePermissionDescription'.tr()),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ShadButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text('common.settings'.tr()),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ShadSonner.of(context).show(
      ShadToast.raw(
        variant: ShadToastVariant.primary,
        description: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
