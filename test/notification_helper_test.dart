import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_system/core/utils/notification_helper.dart';

void main() {
  group('NotificationHelper Tests', () {
    test('classifyCategory identifies category keywords accurately', () {
      expect(
        NotificationHelper.classifyCategory('School Lockdown Notice', 'Immediate evacuation procedure'),
        NotificationCategory.emergency,
      );
      expect(
        NotificationHelper.classifyCategory('Monthly Fee Challan Issued', 'Please pay your dues on time'),
        NotificationCategory.fee,
      );
      expect(
        NotificationHelper.classifyCategory('Final Exam Datesheet Released', 'Midterm examination schedule'),
        NotificationCategory.exam,
      );
      expect(
        NotificationHelper.classifyCategory('Attendance Warning', 'Student was marked absent today'),
        NotificationCategory.attendance,
      );
      expect(
        NotificationHelper.classifyCategory('Summer Vacation Announcement', 'School will remain closed'),
        NotificationCategory.holiday,
      );
      expect(
        NotificationHelper.classifyCategory('Homework Submission', 'Physics assignment chapter 4'),
        NotificationCategory.academic,
      );
      expect(
        NotificationHelper.classifyCategory('Principal Address', 'Welcome to the new school term'),
        NotificationCategory.general,
      );
    });

    test('inferPriority assigns correct priority levels', () {
      expect(
        NotificationHelper.inferPriority('Urgent Notice', 'Last day to verify documents', NotificationCategory.emergency),
        NotificationPriority.urgent,
      );
      expect(
        NotificationHelper.inferPriority('Tuition Overdue', 'Fee is due today', NotificationCategory.fee),
        NotificationPriority.high,
      );
      expect(
        NotificationHelper.inferPriority('Exam Schedule', 'Upcoming papers', NotificationCategory.exam),
        NotificationPriority.high,
      );
      expect(
        NotificationHelper.inferPriority('Winter Break', 'School closed next week', NotificationCategory.holiday),
        NotificationPriority.low,
      );
      expect(
        NotificationHelper.inferPriority('Routine Memo', 'Book collection', NotificationCategory.general),
        NotificationPriority.normal,
      );
    });

    test('countUnread and formatBadgeCount calculate badge values', () {
      final items = [
        NotificationItem(
          id: '1',
          title: 'A',
          body: 'B',
          category: NotificationCategory.fee,
          priority: NotificationPriority.high,
          isRead: false,
          timestamp: DateTime.now(),
        ),
        NotificationItem(
          id: '2',
          title: 'C',
          body: 'D',
          category: NotificationCategory.exam,
          priority: NotificationPriority.normal,
          isRead: true,
          timestamp: DateTime.now(),
        ),
        NotificationItem(
          id: '3',
          title: 'E',
          body: 'F',
          category: NotificationCategory.general,
          priority: NotificationPriority.low,
          isRead: false,
          timestamp: DateTime.now(),
        ),
      ];

      expect(NotificationHelper.countUnread(items), 2);
      expect(NotificationHelper.formatBadgeCount(0), '');
      expect(NotificationHelper.formatBadgeCount(5), '5');
      expect(NotificationHelper.formatBadgeCount(120), '99+');
    });

    test('groupByCategory partitions list cleanly', () {
      final items = [
        NotificationItem(
          id: '1',
          title: 'Fee 1',
          body: '',
          category: NotificationCategory.fee,
          priority: NotificationPriority.high,
          timestamp: DateTime.now(),
        ),
        NotificationItem(
          id: '2',
          title: 'Fee 2',
          body: '',
          category: NotificationCategory.fee,
          priority: NotificationPriority.normal,
          timestamp: DateTime.now(),
        ),
        NotificationItem(
          id: '3',
          title: 'Exam 1',
          body: '',
          category: NotificationCategory.exam,
          priority: NotificationPriority.high,
          timestamp: DateTime.now(),
        ),
      ];

      final grouped = NotificationHelper.groupByCategory(items);
      expect(grouped[NotificationCategory.fee]?.length, 2);
      expect(grouped[NotificationCategory.exam]?.length, 1);
      expect(grouped[NotificationCategory.holiday], isNull);
    });
  });
}
