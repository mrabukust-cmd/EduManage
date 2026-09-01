import 'package:flutter/material.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_dimensions.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';

/// Centered loading spinner with consistent app theming.
/// Use in place of bare `CircularProgressIndicator()` calls.
class LoadingWidget extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;

  const LoadingWidget({
    super.key,
    this.size = 36,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(color ?? AppColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.space12),
            Text(
              message!,
              style: AppTextStyles.labelMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-page loading state for screens whose entire body depends on one
/// async call (as opposed to inline spinners inside StreamBuilders).
class LoadingScreen extends StatelessWidget {
  final String? message;
  const LoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingWidget(message: message),
    );
  }
}
