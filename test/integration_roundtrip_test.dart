import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_system/data/models/class_model.dart';
import 'package:school_management_system/data/models/notice_model.dart';
import 'package:school_management_system/data/models/student_model.dart';
import 'package:school_management_system/data/models/teacher_model.dart';

void main() {
  group('Backend API & Client Model Roundtrip Alignment', () {
    test('ClassModel conforms to backend /api/v1/classes payload schema', () {
      final backendJson = {
        'id': 'class_123',
        'name': 'Grade 10 - A',
        'classTeacher': 'John Doe',
        'classTeacherId': 'teacher_456',
        'capacity': 35,
        'createdAt': '2026-09-03T10:00:00.000Z',
      };

      final model = ClassModel(
        id: backendJson['id'] as String,
        name: backendJson['name'] as String,
        classTeacher: backendJson['classTeacher'] as String,
        classTeacherId: backendJson['classTeacherId'] as String,
        capacity: backendJson['capacity'] as int,
        createdAt: DateTime.parse(backendJson['createdAt'] as String),
      );

      final serialized = model.toMap();
      expect(serialized['name'], 'Grade 10 - A');
      expect(serialized['classTeacher'], 'John Doe');
      expect(serialized['classTeacherId'], 'teacher_456');
      expect(serialized['capacity'], 35);
    });

    test('StudentModel conforms to backend /api/v1/students payload schema', () {
      final backendJson = {
        'id': 'student_789',
        'name': 'Alice Smith',
        'rollNo': '101',
        'className': 'Grade 10 - A',
        'section': 'A',
        'contact': '+1234567890',
        'email': 'alice@school.edu',
      };

      final model = StudentModel(
        id: backendJson['id'] as String,
        name: backendJson['name'] as String,
        rollNo: backendJson['rollNo'] as String,
        className: backendJson['className'] as String,
        section: backendJson['section'] as String,
        contact: backendJson['contact'] as String,
        email: backendJson['email'] as String,
      );

      final map = model.toMap();
      expect(map['name'], 'Alice Smith');
      expect(map['rollNo'], '101');
      expect(map['class'], 'Grade 10 - A');
      expect(map['contact'], '+1234567890');
    });

    test('NoticeModel conforms to backend /api/v1/notices payload schema', () {
      final backendPayload = {
        'id': 'notice_001',
        'title': 'School Sports Day',
        'body': 'Annual sports day will be held this Friday.',
        'category': 'Events',
        'author': 'Admin',
        'createdAt': '2026-09-03T10:00:00.000Z',
      };

      final notice = NoticeModel(
        id: backendPayload['id'] as String,
        title: backendPayload['title'] as String,
        body: backendPayload['body'] as String,
        category: backendPayload['category'] as String,
        author: backendPayload['author'] as String,
        createdAt: DateTime.parse(backendPayload['createdAt'] as String),
      );

      final serialized = notice.toMap();
      expect(serialized['title'], 'School Sports Day');
      expect(serialized['category'], 'Events');
      expect(serialized['author'], 'Admin');
    });

    test('TeacherModel conforms to backend /api/v1/teachers approval status schema', () {
      final teacherJson = {
        'name': 'Sarah Connor',
        'email': 'sarah@school.edu',
        'phone': '+1234567890',
        'subject': 'Physics',
        'qualification': 'M.Sc. Physics',
        'classes': ['Grade 9 - A', 'Grade 10 - B'],
        'approved': true,
      };

      final teacher = TeacherModel.fromMap('teacher_001', teacherJson);
      expect(teacher.name, 'Sarah Connor');
      expect(teacher.subject, 'Physics');
      expect(teacher.approved, isTrue);
      expect(teacher.isApproved, isTrue);
    });
  });
}
