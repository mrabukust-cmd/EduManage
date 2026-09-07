import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_theme.dart';
import 'package:school_management_system/core/theme/theme_provider.dart';

void main() {
  group('Theme & Dark Mode Test Suite', () {
    test('AppTheme lightTheme and darkTheme have appropriate brightness and color schemes', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);

      expect(light.scaffoldBackgroundColor, AppColors.background);
      expect(dark.scaffoldBackgroundColor, AppColors.darkBackground);

      expect(light.colorScheme.surface, AppColors.surface);
      expect(dark.colorScheme.surface, AppColors.darkSurface);

      expect(light.cardTheme.color, AppColors.cardBg);
      expect(dark.cardTheme.color, AppColors.darkCardBg);
    });

    test('ThemeModeNotifier toggles and updates mode correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Default is system
      expect(container.read(themeModeProvider), ThemeMode.system);

      // Set explicit dark
      container.read(themeModeProvider.notifier).setDark();
      expect(container.read(themeModeProvider), ThemeMode.dark);

      // Toggle dark -> light
      container.read(themeModeProvider.notifier).toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.light);

      // Toggle light -> dark
      container.read(themeModeProvider.notifier).toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.dark);

      // Set system
      container.read(themeModeProvider.notifier).setSystem();
      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });
}
