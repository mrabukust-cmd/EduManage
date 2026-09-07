import 'package:flutter/material.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_dimensions.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/utils/responsive_sizer.dart';

/// Semantic types of toasts and banners
enum ToastType {
  success,
  error,
  warning,
  info,
}

/// Helper methods and standardized snackbar presentation for EduManage.
class AppToast {
  AppToast._();

  static Color _bgColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return AppColors.success;
      case ToastType.error:
        return AppColors.danger;
      case ToastType.warning:
        return AppColors.warning;
      case ToastType.info:
        return AppColors.primary;
    }
  }

  static IconData _icon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  /// Displays a standardized floating snackbar.
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        backgroundColor: _bgColor(type),
        margin: EdgeInsets.symmetric(
          horizontal: 4.w.clamp(16.0, 24.0),
          vertical: 2.h.clamp(12.0, 18.0),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        content: Row(
          children: [
            Icon(_icon(type), color: AppColors.white, size: 5.w.clamp(20.0, 24.0)),
            SizedBox(width: 3.w.clamp(10.0, 14.0)),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null && title.isNotEmpty)
                    Text(
                      title,
                      style: AppTextStyles.bodyMediumBold.copyWith(
                        color: AppColors.white,
                        fontSize: 3.5.w.clamp(13.0, 15.0),
                      ),
                    ),
                  Text(
                    message,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.white,
                      fontSize: 3.w.clamp(11.0, 13.0),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        action: action,
      ),
    );
  }

  static void success(BuildContext context, String message, {String? title}) =>
      show(context, message: message, title: title, type: ToastType.success);

  static void error(BuildContext context, String message, {String? title}) =>
      show(context, message: message, title: title, type: ToastType.error);

  static void warning(BuildContext context, String message, {String? title}) =>
      show(context, message: message, title: title, type: ToastType.warning);

  static void info(BuildContext context, String message, {String? title}) =>
      show(context, message: message, title: title, type: ToastType.info);
}

/// An inline announcement / feedback banner widget.
class AppBanner extends StatelessWidget {
  final String message;
  final String? title;
  final ToastType type;
  final VoidCallback? onDismiss;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AppBanner({
    super.key,
    required this.message,
    this.title,
    this.type = ToastType.info,
    this.onDismiss,
    this.trailing,
    this.onTap,
  });

  Color get _backgroundColor {
    switch (type) {
      case ToastType.success:
        return AppColors.successLight;
      case ToastType.error:
        return AppColors.dangerLight;
      case ToastType.warning:
        return AppColors.warningLight;
      case ToastType.info:
        return AppColors.primarySubtle;
    }
  }

  Color get _borderColor {
    switch (type) {
      case ToastType.success:
        return AppColors.success.withValues(alpha: 0.3);
      case ToastType.error:
        return AppColors.danger.withValues(alpha: 0.3);
      case ToastType.warning:
        return AppColors.warning.withValues(alpha: 0.3);
      case ToastType.info:
        return AppColors.primary.withValues(alpha: 0.3);
    }
  }

  Color get _accentColor {
    switch (type) {
      case ToastType.success:
        return AppColors.success;
      case ToastType.error:
        return AppColors.danger;
      case ToastType.warning:
        return AppColors.warning;
      case ToastType.info:
        return AppColors.primary;
    }
  }

  IconData get _iconData {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_outline_rounded;
      case ToastType.error:
        return Icons.error_outline_rounded;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 3.5.w.clamp(12.0, 16.0),
            vertical: 1.5.h.clamp(10.0, 14.0),
          ),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(_iconData, color: _accentColor, size: 5.w.clamp(20.0, 24.0)),
              SizedBox(width: 3.w.clamp(10.0, 12.0)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null && title!.isNotEmpty)
                      Text(
                        title!,
                        style: AppTextStyles.bodyMediumBold.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 3.5.w.clamp(13.0, 14.0),
                        ),
                      ),
                    Text(
                      message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 3.w.clamp(11.0, 12.0),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDismiss,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
