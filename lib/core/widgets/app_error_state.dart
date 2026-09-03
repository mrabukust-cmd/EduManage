import 'package:flutter/material.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_dimensions.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
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
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? AppDimensions.space16 : AppDimensions.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isCompact ? 56 : 76,
              height: isCompact ? 56 : 76,
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Icon(
                icon,
                size: isCompact ? 28 : 38,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: isCompact ? AppTextStyles.titleMedium : AppTextStyles.headingMedium,
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
