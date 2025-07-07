import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';

enum ExportFormat { json, csv, excel, pdf }

enum DataType { all, transactions, budgets, categories, accounts, goals }

class ExportImportWidget extends ConsumerStatefulWidget {
  final bool showExport;
  final bool showImport;
  final Function(String)? onExportCompleted;
  final Function(String)? onImportCompleted;

  const ExportImportWidget({
    super.key,
    this.showExport = true,
    this.showImport = true,
    this.onExportCompleted,
    this.onImportCompleted,
  });

  @override
  ConsumerState<ExportImportWidget> createState() => _ExportImportWidgetState();
}

class _ExportImportWidgetState extends ConsumerState<ExportImportWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Export settings
  ExportFormat _selectedExportFormat = ExportFormat.json;
  Set<DataType> _selectedDataTypes = {DataType.all};
  DateTimeRange? _exportDateRange;
  bool _includeMetadata = true;
  bool _includeImages = false;
  bool _isExporting = false;

  // Import settings
  String? _selectedImportFile;
  bool _isImporting = false;
  bool _backupBeforeImport = true;
  bool _mergeData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.showExport && widget.showImport ? 2 : 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    if (!widget.showExport && !widget.showImport) {
      return const SizedBox.shrink();
    }

    if (widget.showExport && !widget.showImport) {
      return _buildExportSection();
    }

    if (!widget.showExport && widget.showImport) {
      return _buildImportSection();
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.file_upload),
              text: 'settings.export'.tr(),
            ),
            Tab(
              icon: const Icon(Icons.file_download),
              text: 'settings.import'.tr(),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildExportSection(),
              _buildImportSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExportSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format selection
          _buildFormatSelection(),
          const SizedBox(height: AppDimensions.spacingM),

          // Data type selection
          _buildDataTypeSelection(),
          const SizedBox(height: AppDimensions.spacingM),

          // Date range selection
          _buildDateRangeSelection(),
          const SizedBox(height: AppDimensions.spacingM),

          // Additional options
          _buildExportOptions(),
          const SizedBox(height: AppDimensions.spacingL),

          // Export button
          _buildExportButton(),
        ],
      ),
    );
  }

  Widget _buildImportSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File selection
          _buildFileSelection(),
          const SizedBox(height: AppDimensions.spacingM),

          // Import options
          _buildImportOptions(),
          const SizedBox(height: AppDimensions.spacingM),

          // Warning
          _buildImportWarning(),
          const SizedBox(height: AppDimensions.spacingL),

          // Import button
          _buildImportButton(),
        ],
      ),
    );
  }

  Widget _buildFormatSelection() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings.exportFormat'.tr(),
          style: theme.textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Wrap(
          spacing: AppDimensions.spacingS,
          children: ExportFormat.values.map((format) {
            final isSelected = _selectedExportFormat == format;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getFormatIcon(format),
                    size: 16,
                    color: isSelected ? Colors.white : null,
                  ),
                  const SizedBox(width: AppDimensions.spacingXs),
                  Text(_getFormatName(format)),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedExportFormat = format;
                  });
                }
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDataTypeSelection() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings.dataToExport'.tr(),
          style: theme.textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        ...DataType.values.map((dataType) => CheckboxListTile(
              title: Text(_getDataTypeName(dataType)),
              subtitle: Text(_getDataTypeDescription(dataType)),
              value: _selectedDataTypes.contains(dataType),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    if (dataType == DataType.all) {
                      _selectedDataTypes = {DataType.all};
                    } else {
                      _selectedDataTypes.remove(DataType.all);
                      _selectedDataTypes.add(dataType);
                    }
                  } else {
                    _selectedDataTypes.remove(dataType);
                    if (_selectedDataTypes.isEmpty) {
                      _selectedDataTypes.add(DataType.all);
                    }
                  }
                });
              },
              dense: true,
            )),
      ],
    );
  }

  Widget _buildDateRangeSelection() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings.dateRange'.tr(),
          style: theme.textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        ShadButton.outline(
          onPressed: _selectDateRange,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.date_range, size: 16),
              const SizedBox(width: AppDimensions.spacingXs),
              Text(_exportDateRange == null
                  ? 'settings.allTime'.tr()
                  : '${DateFormat.yMd().format(_exportDateRange!.start)} - ${DateFormat.yMd().format(_exportDateRange!.end)}'),
            ],
          ),
        ),
        if (_exportDateRange != null) ...[
          const SizedBox(height: AppDimensions.spacingS),
          ShadButton.ghost(
            size: ShadButtonSize.sm,
            onPressed: () => setState(() => _exportDateRange = null),
            child: Text('settings.clearDateRange'.tr()),
          ),
        ],
      ],
    );
  }

  Widget _buildExportOptions() {
    return Column(
      children: [
        SwitchListTile(
          title: Text('settings.includeMetadata'.tr()),
          subtitle: Text('settings.includeMetadataDescription'.tr()),
          value: _includeMetadata,
          onChanged: (value) => setState(() => _includeMetadata = value),
          dense: true,
        ),
        SwitchListTile(
          title: Text('settings.includeImages'.tr()),
          subtitle: Text('settings.includeImagesDescription'.tr()),
          value: _includeImages,
          onChanged: (value) => setState(() => _includeImages = value),
          dense: true,
        ),
      ],
    );
  }

  Widget _buildFileSelection() {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings.selectFile'.tr(),
          style: theme.textTheme.h4,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.border),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Column(
            children: [
              if (_selectedImportFile == null) ...[
                Icon(
                  Icons.file_upload,
                  size: 48,
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  'settings.selectFileToImport'.tr(),
                  style: theme.textTheme.p.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                ShadButton.outline(
                  onPressed: _selectImportFile,
                  child: Text('settings.selectFile'.tr()),
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(
                      Icons.file_present,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Text(
                        _selectedImportFile!.split('/').last,
                        style: theme.textTheme.p.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      onPressed: () =>
                          setState(() => _selectedImportFile = null),
                      child: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportOptions() {
    return Column(
      children: [
        SwitchListTile(
          title: Text('settings.backupBeforeImport'.tr()),
          subtitle: Text('settings.backupBeforeImportDescription'.tr()),
          value: _backupBeforeImport,
          onChanged: (value) => setState(() => _backupBeforeImport = value),
          dense: true,
        ),
        SwitchListTile(
          title: Text('settings.mergeData'.tr()),
          subtitle: Text('settings.mergeDataDescription'.tr()),
          value: _mergeData,
          onChanged: (value) => setState(() => _mergeData = value),
          dense: true,
        ),
      ],
    );
  }

  Widget _buildImportWarning() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              'settings.importWarning'.tr(),
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ShadButton(
        onPressed: _isExporting ? null : _performExport,
        child: _isExporting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text('settings.exporting'.tr()),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.file_upload, size: 18),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text('settings.exportData'.tr()),
                ],
              ),
      ),
    );
  }

  Widget _buildImportButton() {
    return SizedBox(
      width: double.infinity,
      child: ShadButton(
        onPressed:
            _isImporting || _selectedImportFile == null ? null : _performImport,
        child: _isImporting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text('settings.importing'.tr()),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.file_download, size: 18),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text('settings.importData'.tr()),
                ],
              ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _exportDateRange,
    );

    if (picked != null) {
      setState(() {
        _exportDateRange = picked;
      });
    }
  }

  Future<void> _selectImportFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImportFile = result.files.first.path;
        });
      }
    } catch (e) {
      _showError('settings.errorSelectingFile'.tr());
    }
  }

  Future<void> _performExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Simulate export process
      await Future.delayed(const Duration(seconds: 3));

      final fileName =
          'money_manager_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.${_selectedExportFormat.name}';

      widget.onExportCompleted?.call(fileName);

      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast.raw(
            variant: ShadToastVariant.primary,
            description: Text('settings.exportCompleted'.tr()),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'settings.share'.tr(),
              onPressed: () => _shareExportedFile(fileName),
            ),
          ),
        );
      }
    } catch (e) {
      _showError('settings.exportError'.tr());
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _performImport() async {
    if (_selectedImportFile == null) return;

    setState(() {
      _isImporting = true;
    });

    try {
      // Create backup if requested
      if (_backupBeforeImport) {
        await Future.delayed(const Duration(seconds: 1));
      }

      // Perform import
      await Future.delayed(const Duration(seconds: 2));

      widget.onImportCompleted?.call(_selectedImportFile!);

      if (mounted) {
        ShadSonner.of(context).show(
          ShadToast.raw(
            variant: ShadToastVariant.primary,
            description: Text('settings.importCompleted'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError('settings.importError'.tr());
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _selectedImportFile = null;
        });
      }
    }
  }

  Future<void> _shareExportedFile(String fileName) async {
    // Implementation would share the actual file
    // await Share.shareXFiles([XFile(filePath)]);
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

  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return Icons.code;
      case ExportFormat.csv:
        return Icons.table_chart;
      case ExportFormat.excel:
        return Icons.grid_on;
      case ExportFormat.pdf:
        return Icons.picture_as_pdf;
    }
  }

  String _getFormatName(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.excel:
        return 'Excel';
      case ExportFormat.pdf:
        return 'PDF';
    }
  }

  String _getDataTypeName(DataType dataType) {
    switch (dataType) {
      case DataType.all:
        return 'settings.allData'.tr();
      case DataType.transactions:
        return 'settings.transactions'.tr();
      case DataType.budgets:
        return 'settings.budgets'.tr();
      case DataType.categories:
        return 'settings.categories'.tr();
      case DataType.accounts:
        return 'settings.accounts'.tr();
      case DataType.goals:
        return 'settings.goals'.tr();
    }
  }

  String _getDataTypeDescription(DataType dataType) {
    switch (dataType) {
      case DataType.all:
        return 'settings.allDataDescription'.tr();
      case DataType.transactions:
        return 'settings.transactionsDescription'.tr();
      case DataType.budgets:
        return 'settings.budgetsDescription'.tr();
      case DataType.categories:
        return 'settings.categoriesDescription'.tr();
      case DataType.accounts:
        return 'settings.accountsDescription'.tr();
      case DataType.goals:
        return 'settings.goalsDescription'.tr();
    }
  }
}
