import 'package:flutter/material.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_typography.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle headingLarge = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontFamilyFallback: AppTypography.fontFamilyFallback,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontFamilyFallback: AppTypography.fontFamilyFallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontFamilyFallback: AppTypography.fontFamilyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontFamilyFallback: AppTypography.fontFamilyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMediumBold = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontFamilyFallback: AppTypography.fontFamilyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontFamilyFallback: AppTypography.fontFamilyFallback,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontFamilyFallback: AppTypography.fontFamilyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelTiny = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontFamilyFallback: AppTypography.fontFamilyFallback,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle statValue = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontFamilyFallback: AppTypography.fontFamilyFallback,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle navLabel = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontFamilyFallback: AppTypography.fontFamilyFallback,
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
}
