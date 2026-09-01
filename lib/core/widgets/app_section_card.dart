import 'package:flutter/material.dart';
import 'package:school_management_system/core/theme/app_dimensions.dart';

/// A consistently spaced, themed container for grouped screen content.
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.child,
    this.padding = AppDimensions.cardPadding,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      child: Padding(padding: padding, child: child),
    );
  }
}
