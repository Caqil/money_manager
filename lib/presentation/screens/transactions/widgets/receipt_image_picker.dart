import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';

class ReceiptImagePicker extends StatefulWidget {
  final String? imagePath;
  final Function(String?) onImageChanged;
  final String? label;
  final bool enabled;
  final bool required;
  final String? errorText;
  final double maxWidth;
  final double maxHeight;
  final int imageQuality;

  const ReceiptImagePicker({
    super.key,
    this.imagePath,
    required this.onImageChanged,
    this.label,
    this.enabled = true,
    this.required = false,
    this.errorText,
    this.maxWidth = 1024,
    this.maxHeight = 1024,
    this.imageQuality = 85,
  });

  @override
  State<ReceiptImagePicker> createState() => _ReceiptImagePickerState();
}

class _ReceiptImagePickerState extends State<ReceiptImagePicker> {
  final ImagePicker _imagePicker = ImagePicker();
  String? _currentImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
  }

  @override
  void didUpdateWidget(ReceiptImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imagePath != oldWidget.imagePath) {
      setState(() {
        _currentImagePath = widget.imagePath;
      });
    }
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

        // Image picker area
        _buildImagePickerArea(theme),

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

        // Helper text
        if (_currentImagePath == null) ...[
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            'transactions.receiptImageHelper'.tr(),
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePickerArea(ShadThemeData theme) {
    if (_currentImagePath != null) {
      return _buildImagePreview(theme);
    } else {
      return _buildImagePickerButton(theme);
    }
  }

  Widget _buildImagePickerButton(ShadThemeData theme) {
    return GestureDetector(
      onTap: widget.enabled && !_isLoading ? _showImageSourceOptions : null,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.errorText != null
                ? AppColors.error
                : theme.colorScheme.border,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          color: widget.enabled
              ? theme.colorScheme.muted.withOpacity(0.3)
              : theme.colorScheme.muted,
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 48,
                    color: widget.enabled
                        ? theme.colorScheme.foreground.withOpacity(0.6)
                        : theme.colorScheme.mutedForeground,
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    'transactions.addReceiptImage'.tr(),
                    style: theme.textTheme.p.copyWith(
                      color: widget.enabled
                          ? theme.colorScheme.foreground.withOpacity(0.8)
                          : theme.colorScheme.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    'transactions.tapToAddImage'.tr(),
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildImagePreview(ShadThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        children: [
          // Image preview
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusM),
              topRight: Radius.circular(AppDimensions.radiusM),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.file(
                File(_currentImagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: theme.colorScheme.muted,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: theme.colorScheme.mutedForeground,
                        ),
                        const SizedBox(height: AppDimensions.spacingS),
                        Text(
                          'transactions.imageLoadError'.tr(),
                          style: theme.textTheme.small.copyWith(
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            child: Row(
              children: [
                Expanded(
                  child: ShadButton.outline(
                    size: ShadButtonSize.sm,
                    onPressed: widget.enabled ? _viewFullImage : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.zoom_in, size: 16),
                        const SizedBox(width: AppDimensions.spacingXs),
                        Text('common.view'.tr()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: ShadButton.outline(
                    size: ShadButtonSize.sm,
                    onPressed: widget.enabled ? _showImageSourceOptions : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit, size: 16),
                        const SizedBox(width: AppDimensions.spacingXs),
                        Text('common.change'.tr()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: widget.enabled ? _removeImage : null,
                  child: const Icon(Icons.delete_outline, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceOptions() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('transactions.selectImageSource'.tr()),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text('transactions.takePhoto'.tr()),
              subtitle: Text('transactions.takePhotoDescription'.tr()),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('transactions.chooseFromGallery'.tr()),
              subtitle: Text('transactions.chooseFromGalleryDescription'.tr()),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    if (!await _requestCameraPermission()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
        imageQuality: widget.imageQuality,
      );

      if (image != null) {
        setState(() {
          _currentImagePath = image.path;
        });
        widget.onImageChanged(image.path);
      }
    } catch (e) {
      _showError('transactions.errorTakingPhoto'.tr());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (!await _requestStoragePermission()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
        imageQuality: widget.imageQuality,
      );

      if (image != null) {
        setState(() {
          _currentImagePath = image.path;
        });
        widget.onImageChanged(image.path);
      }
    } catch (e) {
      _showError('transactions.errorPickingImage'.tr());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      _showPermissionDialog('camera');
      return false;
    }
    return status.isGranted;
  }

  Future<bool> _requestStoragePermission() async {
    final status = await Permission.photos.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      _showPermissionDialog('storage');
      return false;
    }
    return status.isGranted;
  }

  void _showPermissionDialog(String permissionType) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('transactions.permissionRequired'.tr()),
        description: Text(
          'transactions.permissionDescription'.tr(
            namedArgs: {'permission': permissionType},
          ),
        ),
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

  void _viewFullImage() {
    if (_currentImagePath == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullImageViewer(imagePath: _currentImagePath!),
      ),
    );
  }

  void _removeImage() {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('transactions.removeImage'.tr()),
        description: Text('transactions.removeImageConfirmation'.tr()),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ShadButton.destructive(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentImagePath = null;
              });
              widget.onImageChanged(null);
            },
            child: Text('common.remove'.tr()),
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

class _FullImageViewer extends StatelessWidget {
  final String imagePath;

  const _FullImageViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'transactions.receiptImage'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => _shareImage(context),
            icon: const Icon(Icons.share, color: Colors.white),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'transactions.imageLoadError'.tr(),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _shareImage(BuildContext context) {
    // Implement image sharing functionality
    // This could use the share_plus package
  }
}
