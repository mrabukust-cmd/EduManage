import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_system/core/widgets/app_toast.dart';
import 'package:school_management_system/core/utils/responsive_sizer.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: ResponsiveSizer(
        builder: (context, orientation, screenType) {
          return Scaffold(body: child);
        },
      ),
    );
  }

  group('AppToast & AppBanner Widget Suite', () {
    testWidgets('AppBanner displays title, message, and icon properly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppBanner(
            title: 'Attendance Alert',
            message: 'Class 10-A attendance submitted successfully',
            type: ToastType.success,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Attendance Alert'), findsOneWidget);
      expect(find.text('Class 10-A attendance submitted successfully'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('AppBanner responds to tap and dismiss actions', (tester) async {
      bool tapped = false;
      bool dismissed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          AppBanner(
            message: 'Fee payment pending',
            type: ToastType.warning,
            onTap: () => tapped = true,
            onDismiss: () => dismissed = true,
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Fee payment pending'));
      expect(tapped, isTrue);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(dismissed, isTrue);
    });

    testWidgets('AppToast shows floating snackbar on trigger', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppToast.success(context, 'Data saved', title: 'Success');
                },
                child: const Text('Show Toast'),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Toast'));
      await tester.pump(); // Start animation

      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Data saved'), findsOneWidget);
    });
  });
}
