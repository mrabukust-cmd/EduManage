import 'package:flutter/material.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_dimensions.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/utils/responsive_sizer.dart';
import 'custom_button.dart';

class AppErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool isCompact;

  const AppErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final circleSize = isCompact ? 14.w.clamp(48.0, 58.0) : 20.w.clamp(68.0, 80.0);
    final iconSize = isCompact ? 7.w.clamp(24.0, 30.0) : 10.w.clamp(34.0, 40.0);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? AppDimensions.space16 : AppDimensions.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: isCompact
                  ? AppTextStyles.titleMedium.copyWith(fontSize: 14.sp)
                  : AppTextStyles.headingMedium.copyWith(fontSize: 16.sp),
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.space20),
              CustomOutlineButton(
                label: 'Try Again',
                onPressed: onRetry,
                borderColor: AppColors.danger,
                textColor: AppColors.danger,
                icon: Icons.refresh_rounded,
                height: 5.5.h.clamp(42.0, 48.0),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
