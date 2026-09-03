import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_theme.dart';
import 'package:school_management_system/core/widgets/app_section_card.dart';
import 'package:school_management_system/core/widgets/custom_button.dart';
import 'package:school_management_system/core/widgets/loading_widget.dart';

void main() {
  group('EduManage Core Widgets & Theme Tests', () {
    testWidgets('LoadingWidget renders spinner and custom message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(
              message: 'Fetching student records...',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Fetching student records...'), findsOneWidget);
    });

    testWidgets('LoadingScreen renders full page loading scaffold',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingScreen(message: 'Initializing system...'),
        ),
      );

      expect(find.byType(LoadingWidget), findsOneWidget);
      expect(find.text('Initializing system...'), findsOneWidget);
    });

    testWidgets('CustomButton renders label and responds to user tap',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CustomButton(
              label: 'Save Class',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Save Class'), findsOneWidget);
      await tester.tap(find.text('Save Class'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('CustomButton shows progress indicator when loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CustomButton(
              label: 'Submit Form',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit Form'), findsNothing);
    });

    testWidgets('AppSectionCard displays child content and decorative styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppSectionCard(
              child: Text('Section Content'),
            ),
          ),
        ),
      );

      expect(find.text('Section Content'), findsOneWidget);
      expect(find.byType(AppSectionCard), findsOneWidget);
    });

    test('AppTheme defines consistent primary colors and surfaces', () {
      final theme = AppTheme.lightTheme;
      expect(theme.primaryColor, AppColors.primary);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
    });
  });
}