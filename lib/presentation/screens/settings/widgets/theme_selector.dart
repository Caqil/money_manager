import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/theme_provider.dart';

class ThemeOption {
  final ThemeMode mode;
  final String name;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color backgroundColor;
  final bool isRecommended;

  const ThemeOption({
    required this.mode,
    required this.name,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.backgroundColor,
    this.isRecommended = false,
  });
}

class ThemeSelector extends ConsumerStatefulWidget {
  final ThemeMode? selectedTheme;
  final Function(ThemeMode)? onThemeChanged;
  final bool showPreview;
  final bool enabled;

  const ThemeSelector({
    super.key,
    this.selectedTheme,
    this.onThemeChanged,
    this.showPreview = true,
    this.enabled = true,
  });

  @override
  ConsumerState<ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends ConsumerState<ThemeSelector>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  static const List<ThemeOption> _themeOptions = [
    ThemeOption(
      mode: ThemeMode.system,
      name: 'System',
      description: 'Follow device settings',
      icon: Icons.settings_brightness,
      primaryColor: AppColors.primary,
      backgroundColor: Colors.grey,
      isRecommended: true,
    ),
    ThemeOption(
      mode: ThemeMode.light,
      name: 'Light',
      description: 'Bright and clean interface',
      icon: Icons.light_mode,
      primaryColor: AppColors.primary,
      backgroundColor: Colors.white,
    ),
    ThemeOption(
      mode: ThemeMode.dark,
      name: 'Dark',
      description: 'Easy on the eyes',
      icon: Icons.dark_mode,
      primaryColor: AppColors.primary,
      backgroundColor: Color(0xFF1F2937),
    ),
  ];

  ThemeMode get _currentTheme =>
      widget.selectedTheme ?? ref.watch(themeModeProvider);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current theme display
        _buildCurrentThemeCard(),
        const SizedBox(height: AppDimensions.spacingL),

        // Theme options
        Text(
          'settings.availableThemes'.tr(),
          style: theme.textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingM),

        _buildThemeOptions(),

        if (widget.showPreview) ...[
          const SizedBox(height: AppDimensions.spacingL),
          _buildThemePreview(),
        ],
      ],
    );
  }

  Widget _buildCurrentThemeCard() {
    final theme = ShadTheme.of(context);
    final currentOption = _getCurrentThemeOption();

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Row(
          children: [
            // Theme preview
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: currentOption.backgroundColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                  color: theme.colorScheme.border,
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusM),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            currentOption.primaryColor.withOpacity(0.1),
                            currentOption.primaryColor.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Icon
                  Center(
                    child: Icon(
                      currentOption.icon,
                      color: currentOption.primaryColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),

            // Theme info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'settings.currentTheme'.tr(),
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    'settings.${currentOption.name.toLowerCase()}'.tr(),
                    style: theme.textTheme.h4,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'settings.${currentOption.name.toLowerCase()}Description'
                        .tr(),
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),

            // Status indicator
            if (currentOption.isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingS,
                  vertical: AppDimensions.paddingXs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                ),
                child: Text(
                  'settings.recommended'.tr(),
                  style: theme.textTheme.small.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOptions() {
    return Column(
      children: _themeOptions.map((option) {
        final isSelected = option.mode == _currentTheme;
        final isLoading = _isLoading && isSelected;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
          child: _buildThemeOptionCard(option, isSelected, isLoading),
        );
      }).toList(),
    );
  }

  Widget _buildThemeOptionCard(
      ThemeOption option, bool isSelected, bool isLoading) {
    final theme = ShadTheme.of(context);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isSelected && _animationController.isAnimating
              ? _scaleAnimation.value
              : 1.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.enabled && !_isLoading && !isSelected
                  ? () => _selectTheme(option)
                  : null,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: isSelected
                      ? option.primaryColor.withOpacity(0.05)
                      : theme.colorScheme.muted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: isSelected
                        ? option.primaryColor
                        : theme.colorScheme.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Theme preview
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: option.backgroundColor,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusS),
                        border: Border.all(
                          color: theme.colorScheme.border.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Background gradient
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusS),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    option.primaryColor.withOpacity(0.1),
                                    option.primaryColor.withOpacity(0.05),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Icon
                          Center(
                            child: Icon(
                              option.icon,
                              color: option.primaryColor,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingM),

                    // Theme info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'settings.${option.name.toLowerCase()}'.tr(),
                                style: theme.textTheme.p.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isSelected ? option.primaryColor : null,
                                ),
                              ),
                              if (option.isRecommended) ...[
                                const SizedBox(width: AppDimensions.spacingS),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusXs),
                                  ),
                                  child: Text(
                                    'settings.recommended'.tr(),
                                    style: theme.textTheme.small.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'settings.${option.name.toLowerCase()}Description'
                                .tr(),
                            style: theme.textTheme.small.copyWith(
                              color: isSelected
                                  ? option.primaryColor.withOpacity(0.8)
                                  : theme.colorScheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status indicator
                    if (isLoading) ...[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ] else if (isSelected) ...[
                      Icon(
                        Icons.check_circle,
                        color: option.primaryColor,
                        size: 24,
                      ),
                    ] else ...[
                      Icon(
                        Icons.circle_outlined,
                        color: theme.colorScheme.mutedForeground,
                        size: 24,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemePreview() {
    final theme = ShadTheme.of(context);
    final currentOption = _getCurrentThemeOption();

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings.themePreview'.tr(),
              style: theme.textTheme.h4,
            ),
            const SizedBox(height: AppDimensions.spacingM),

            // Preview container
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: currentOption.backgroundColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(
                  color: theme.colorScheme.border,
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Background gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusS),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            currentOption.primaryColor.withOpacity(0.1),
                            currentOption.primaryColor.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Preview content
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mock app bar
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: currentOption.primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacingS),
                            Container(
                              width: 60,
                              height: 12,
                              decoration: BoxDecoration(
                                color: currentOption.mode == ThemeMode.dark
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: currentOption.mode == ThemeMode.dark
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingM),

                        // Mock card
                        Container(
                          width: double.infinity,
                          height: 40,
                          decoration: BoxDecoration(
                            color: currentOption.mode == ThemeMode.dark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusS),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(AppDimensions.paddingS),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: currentOption.primaryColor
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.spacingS),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: currentOption.mode ==
                                                  ThemeMode.dark
                                              ? Colors.white.withOpacity(0.8)
                                              : Colors.black.withOpacity(0.8),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: 60,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: currentOption.mode ==
                                                  ThemeMode.dark
                                              ? Colors.white.withOpacity(0.5)
                                              : Colors.black.withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTheme(ThemeOption option) async {
    if (!widget.enabled || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Animate selection
    await _animationController.forward();
    await _animationController.reverse();

    try {
      // Update theme
      await ref.read(themeNotifierProvider.notifier).setTheme(option.mode);

      // Call callback
      widget.onThemeChanged?.call(option.mode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings.themeChanged'.tr()),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings.themeChangeError'.tr()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  ThemeOption _getCurrentThemeOption() {
    return _themeOptions.firstWhere(
      (option) => option.mode == _currentTheme,
      orElse: () => _themeOptions.first,
    );
  }
}

// Compact theme selector for use in dropdowns
class CompactThemeSelector extends ConsumerWidget {
  final ThemeMode? selectedTheme;
  final Function(ThemeMode)? onThemeChanged;
  final bool enabled;

  const CompactThemeSelector({
    super.key,
    this.selectedTheme,
    this.onThemeChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = selectedTheme ?? ref.watch(themeModeProvider);
    const options = _ThemeSelectorState._themeOptions;

    return ShadSelectFormField<ThemeMode>(
      enabled: enabled,
      placeholder: Text('settings.selectTheme'.tr()),
      options: options
          .map((option) => ShadOption(
                value: option.mode,
                child: Row(
                  children: [
                    Icon(option.icon, size: 16),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text('settings.${option.name.toLowerCase()}'.tr()),
                  ],
                ),
              ))
          .toList(),
      selectedOptionBuilder: (context, value) {
        if (value == null) return Text('settings.selectTheme'.tr());
        final option = options.firstWhere((opt) => opt.mode == value);
        return Row(
          children: [
            Icon(option.icon, size: 16),
            const SizedBox(width: AppDimensions.spacingS),
            Text('settings.${option.name.toLowerCase()}'.tr()),
          ],
        );
      },
      onChanged: onThemeChanged as ValueChanged<ThemeMode?>?,
      initialValue: currentTheme,
    );
  }
}
