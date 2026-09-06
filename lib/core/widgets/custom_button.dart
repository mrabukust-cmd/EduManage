import 'package:flutter/material.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_dimensions.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/utils/responsive_sizer.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final double? width;
  final double borderRadius;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.gradient,
    this.backgroundColor,
    this.textColor,
    this.height,
    this.width,
    this.borderRadius = AppDimensions.radiusMedium,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 6.2.h.clamp(48.0, 56.0);
    final iconSize = 5.w.clamp(18.0, 22.0);
    final loaderSize = 5.w.clamp(20.0, 24.0);

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: effectiveHeight,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          gradient: gradient ?? AppColors.primaryGradient,
          color: gradient == null ? backgroundColor : null,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: loaderSize,
                  height: loaderSize,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.onPrimary,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: textColor ?? AppColors.onPrimary, size: iconSize),
                      SizedBox(width: 2.w.clamp(6.0, 10.0)),
                    ],
                    Text(
                      label,
                      style: textColor != null
                          ? AppTextStyles.button.copyWith(color: textColor)
                          : AppTextStyles.button,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class CustomOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final Color? textColor;
  final double? height;
  final IconData? icon;

  const CustomOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.borderColor,
    this.textColor,
    this.height,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 6.2.h.clamp(48.0, 56.0);
    final iconSize = 5.w.clamp(18.0, 22.0);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: effectiveHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: borderColor ?? AppColors.primary,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor ?? AppColors.primary, size: iconSize),
                SizedBox(width: 2.w.clamp(6.0, 10.0)),
              ],
              Text(
                label,
                style: textColor != null
                    ? AppTextStyles.button.copyWith(color: textColor)
                    : AppTextStyles.button.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
