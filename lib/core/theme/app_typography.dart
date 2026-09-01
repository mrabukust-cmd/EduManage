import 'package:flutter/material.dart';

/// Central typography settings. The system font fallback keeps text readable
/// on every supported platform until branded font assets are added.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Poppins';
  static const List<String> fontFamilyFallback = <String>[
    'Segoe UI',
    'Roboto',
    'Arial',
    'sans-serif',
  ];

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}
