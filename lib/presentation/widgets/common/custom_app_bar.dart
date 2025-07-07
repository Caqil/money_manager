import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final double? elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final PreferredSizeWidget? bottom;
  final double? leadingWidth;
  final double? titleSpacing;
  final double? toolbarHeight;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final EdgeInsetsGeometry? titlePadding;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
    this.leadingWidth,
    this.titleSpacing,
    this.toolbarHeight,
    this.showBackButton = false,
    this.onBackPressed,
    this.titlePadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      centerTitle: centerTitle,
      elevation: elevation ?? AppDimensions.appBarElevation,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      surfaceTintColor: Colors.transparent,
      leading: _buildLeading(context, canPop),
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      bottom: bottom,
      leadingWidth: leadingWidth,
      titleSpacing: titleSpacing,
      toolbarHeight: toolbarHeight ?? AppDimensions.appBarHeight,
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: foregroundColor ?? theme.appBarTheme.foregroundColor,
      ),
    );
  }

  Widget? _buildLeading(BuildContext context, bool canPop) {
    if (leading != null) return leading;

    if (showBackButton || (automaticallyImplyLeading && canPop)) {
      return IconButton(
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'common.back'.tr(),
      );
    }

    return null;
  }

  @override
  Size get preferredSize => Size.fromHeight(
        (toolbarHeight ?? AppDimensions.appBarHeight) +
            (bottom?.preferredSize.height ?? 0.0),
      );
}

/// App bar with search functionality
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchSubmitted;
  final VoidCallback? onSearchClear;
  final TextEditingController? searchController;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final bool showSearchByDefault;
  final Widget? leading;

  const SearchAppBar({
    super.key,
    this.title,
    this.searchHint,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onSearchClear,
    this.searchController,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.showSearchByDefault = false,
    this.leading,
  });

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);
}

class _SearchAppBarState extends State<SearchAppBar> {
  late TextEditingController _searchController;
  late bool _isSearching;

  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ?? TextEditingController();
    _isSearching = widget.showSearchByDefault;
  }

  @override
  void dispose() {
    if (widget.searchController == null) {
      _searchController.dispose();
    }
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        widget.onSearchClear?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isSearching) {
      return _buildSearchAppBar(context);
    }
    return _buildNormalAppBar(context);
  }

  Widget _buildNormalAppBar(BuildContext context) {
    return CustomAppBar(
      title: widget.title,
      leading: widget.leading,
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      actions: [
        IconButton(
          onPressed: _toggleSearch,
          icon: const Icon(Icons.search_rounded),
          tooltip: 'common.search'.tr(),
        ),
        ...?widget.actions,
      ],
    );
  }

  Widget _buildSearchAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return CustomAppBar(
      titleWidget: TextField(
        controller: _searchController,
        autofocus: true,
        style: theme.textTheme.titleMedium,
        decoration: InputDecoration(
          hintText: widget.searchHint ?? 'common.search'.tr(),
          border: InputBorder.none,
          hintStyle: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        onChanged: widget.onSearchChanged,
        onSubmitted: (_) => widget.onSearchSubmitted?.call(),
      ),
      leading: IconButton(
        onPressed: _toggleSearch,
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'common.back'.tr(),
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            onPressed: () {
              _searchController.clear();
              widget.onSearchClear?.call();
              setState(() {});
            },
            icon: const Icon(Icons.clear_rounded),
            tooltip: 'common.clear'.tr(),
          ),
        ...?widget.actions,
      ],
    );
  }
}

/// App bar with tab functionality
class TabAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final TabController tabController;
  final List<Widget> tabs;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? indicatorColor;
  final EdgeInsetsGeometry? tabPadding;

  const TabAppBar({
    super.key,
    this.title,
    this.titleWidget,
    required this.tabController,
    required this.tabs,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.indicatorColor,
    this.tabPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomAppBar(
      title: title,
      titleWidget: titleWidget,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      bottom: TabBar(
        controller: tabController,
        tabs: tabs,
        indicatorColor: indicatorColor ?? theme.colorScheme.primary,
        labelColor: foregroundColor ?? theme.colorScheme.onSurface,
        unselectedLabelColor:
            (foregroundColor ?? theme.colorScheme.onSurface).withOpacity(0.6),
        padding: tabPadding,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(
        AppDimensions.appBarHeight + kToolbarHeight,
      );
}

/// Minimal app bar for modal screens
class ModalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final VoidCallback? onClose;
  final bool showCloseButton;

  const ModalAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.onClose,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      title: title,
      titleWidget: titleWidget,
      leading: showCloseButton
          ? IconButton(
              onPressed: onClose ?? () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              tooltip: 'common.close'.tr(),
            )
          : null,
      automaticallyImplyLeading: false,
      actions: actions,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);
}

/// App bar with action buttons for forms
class FormAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final bool showSaveButton;
  final bool showCancelButton;
  final bool saveEnabled;
  final String? saveText;
  final String? cancelText;
  final List<Widget>? additionalActions;

  const FormAppBar({
    super.key,
    this.title,
    this.onSave,
    this.onCancel,
    this.showSaveButton = true,
    this.showCancelButton = true,
    this.saveEnabled = true,
    this.saveText,
    this.cancelText,
    this.additionalActions,
  });

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      title: title,
      leading: showCancelButton
          ? TextButton(
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
              child: Text(cancelText ?? 'common.cancel'.tr()),
            )
          : null,
      automaticallyImplyLeading: false,
      actions: [
        ...?additionalActions,
        if (showSaveButton)
          TextButton(
            onPressed: saveEnabled ? onSave : null,
            child: Text(
              saveText ?? 'common.save'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: saveEnabled ? null : Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);
}
