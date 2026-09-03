import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_system/core/widgets/app_empty_state.dart';
import 'package:school_management_system/core/widgets/app_error_state.dart';
import 'package:school_management_system/core/widgets/app_shimmer_loading.dart';

void main() {
  group('Unified State Widgets Tests', () {
    testWidgets('AppEmptyState renders title, subtitle, and responds to action tap',
        (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              title: 'No Classes Found',
              subtitle: 'Create your first class to get started',
              actionLabel: 'Add Class',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Classes Found'), findsOneWidget);
      expect(find.text('Create your first class to get started'), findsOneWidget);
      expect(find.text('Add Class'), findsOneWidget);

      await tester.tap(find.text('Add Class'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('AppErrorState renders title, error details, and retry button',
        (tester) async {
      bool retryTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorState(
              title: 'Failed to connect',
              message: 'Connection timed out',
              onRetry: () => retryTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Failed to connect'), findsOneWidget);
      expect(find.text('Connection timed out'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retryTriggered, isTrue);
    });

    testWidgets('ShimmerPlaceholder renders and animates smoothly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerPlaceholder(
              width: 200,
              height: 40,
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerPlaceholder), findsOneWidget);

      // Advance animation
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ShimmerPlaceholder), findsOneWidget);
    });
  });
}
