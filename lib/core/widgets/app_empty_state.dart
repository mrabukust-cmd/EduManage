import 'package:flutter/material.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_dimensions.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/utils/responsive_sizer.dart';
import 'custom_button.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isCompact;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final circleSize = isCompact ? 14.w.clamp(48.0, 58.0) : 20.w.clamp(68.0, 84.0);
    final iconSize = isCompact ? 7.w.clamp(24.0, 30.0) : 10.w.clamp(34.0, 42.0);

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
                color: AppColors.primarySubtle,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: AppColors.primary,
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
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.space20),
              CustomButton(
                label: actionLabel!,
                onPressed: onAction,
                width: 44.w.clamp(140.0, 180.0),
                height: 5.5.h.clamp(42.0, 48.0),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
