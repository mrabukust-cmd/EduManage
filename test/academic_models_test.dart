import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_system/data/models/class_model.dart';
import 'package:school_management_system/data/models/timetable_model.dart';
import 'package:school_management_system/data/models/notice_model.dart';

void main() {
  group('Academic Models Deep Validation Suite', () {
    test('ClassModel handles full and partial attributes correctly', () {
      final now = DateTime(2026, 9, 10, 10, 0);
      final model = ClassModel(
        id: 'cls_001',
        name: 'Grade 10 - Science',
        classTeacher: 'Prof. Anderson',
        classTeacherId: 'tch_99',
        room: 'Lab B-2',
        capacity: 35,
        createdAt: now,
      );

      expect(model.id, 'cls_001');
      expect(model.name, 'Grade 10 - Science');
      expect(model.classTeacher, 'Prof. Anderson');
      expect(model.classTeacherId, 'tch_99');
      expect(model.room, 'Lab B-2');
      expect(model.capacity, 35);
      expect(model.createdAt, now);

      final cloned = model.copyWith(name: 'Grade 10 - Advanced Physics', capacity: 40);
      expect(cloned.id, 'cls_001');
      expect(cloned.name, 'Grade 10 - Advanced Physics');
      expect(cloned.capacity, 40);
      expect(cloned.room, 'Lab B-2');
    });

    test('ClassModel fromMap parses string ISO date safely', () {
      final map = {
        'name': ' Grade 8 - Arts ',
        'classTeacher': ' Mrs. Davis ',
        'room': 'Studio 3',
        'capacity': 28,
        'createdAt': '2026-09-01T08:00:00.000Z',
      };

      final parsed = ClassModel.fromMap('cls_002', map);
      expect(parsed.name, 'Grade 8 - Arts');
      expect(parsed.classTeacher, 'Mrs. Davis');
      expect(parsed.room, 'Studio 3');
      expect(parsed.capacity, 28);
      expect(parsed.createdAt, isNotNull);
      expect(parsed.createdAt?.year, 2026);
    });

    test('TimetableModel validates time slot string representations', () {
      final slot = TimetableModel(
        id: 'slot_1',
        className: 'Grade 10',
        day: 'Monday',
        subject: 'Mathematics',
        teacher: 'Dr. Euler',
        startTime: '08:30 AM',
        endTime: '09:30 AM',
        room: 'Room 101',
      );

      expect(slot.timeRange, '08:30 AM - 09:30 AM');
      expect(slot.subject, 'Mathematics');
      expect(slot.day, 'Monday');

      final map = slot.toMap();
      expect(map['className'], 'Grade 10');
      expect(map['subject'], 'Mathematics');
      expect(map['startTime'], '08:30 AM');
    });

    test('NoticeModel parses body, category, author, and dateLabel correctly', () {
      final notice = NoticeModel.fromMap('ntc_101', {
        'title': 'Midterm Exam Schedule Released',
        'body': 'Please review the exam dates in your student portal.',
        'category': 'Exam',
        'author': 'Principal Office',
        'createdAt': '2026-09-10T09:00:00.000Z',
      });

      expect(notice.id, 'ntc_101');
      expect(notice.title, 'Midterm Exam Schedule Released');
      expect(notice.body, contains('Please review'));
      expect(notice.category, 'Exam');
      expect(notice.author, 'Principal Office');
      expect(notice.dateLabel, isNotEmpty);
    });
  });
}
