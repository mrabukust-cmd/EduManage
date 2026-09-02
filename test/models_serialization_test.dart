import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/data/models/assignment_model.dart';
import 'package:school_management_system/data/models/attendence_model.dart';
import 'package:school_management_system/data/models/class_model.dart';
import 'package:school_management_system/data/models/fee_model.dart';
import 'package:school_management_system/data/models/result_model.dart';
import 'package:school_management_system/data/models/timetable_model.dart';

void main() {
  group('AssignmentModel Tests', () {
    test('serializes and deserializes map correctly', () {
      final dueDate = DateTime(2026, 10, 15);
      final assignment = AssignmentModel(
        id: 'assign_123',
        title: 'Math Homework 1',
        description: 'Complete chapter 4 exercises 1-10',
        subject: 'Mathematics',
        className: 'Grade 10 - A',
        dueDate: dueDate,
        teacherId: 'teacher_99',
        teacherName: 'Prof. Smith',
        totalMarks: 50.0,
      );

      final map = assignment.toMap();
      expect(map['title'], 'Math Homework 1');
      expect(map['subject'], 'Mathematics');
      expect(map['className'], 'Grade 10 - A');
      expect(map['teacherId'], 'teacher_99');
      expect(map['teacherName'], 'Prof. Smith');
      expect(map['totalMarks'], 50.0);

      final parsed = AssignmentModel.fromMap('assign_123', {
        'title': 'Math Homework 1',
        'description': 'Complete chapter 4 exercises 1-10',
        'subject': 'Mathematics',
        'className': 'Grade 10 - A',
        'dueDate': Timestamp.fromDate(dueDate),
        'teacherId': 'teacher_99',
        'teacherName': 'Prof. Smith',
        'totalMarks': 50.0,
      });

      expect(parsed.id, 'assign_123');
      expect(parsed.title, 'Math Homework 1');
      expect(parsed.dueDate, dueDate);
      expect(parsed.formattedDueDate, 'Oct 15, 2026');
    });

    test('overdue calculation is accurate', () {
      final pastDue = AssignmentModel(
        id: '1',
        title: 'Past Assignment',
        subject: 'Physics',
        className: 'Grade 9 - A',
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        teacherId: 't1',
      );
      expect(pastDue.isOverdue, isTrue);

      final futureDue = AssignmentModel(
        id: '2',
        title: 'Future Assignment',
        subject: 'Physics',
        className: 'Grade 9 - A',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        teacherId: 't1',
      );
      expect(futureDue.isOverdue, isFalse);
    });
  });

  group('ClassModel Tests', () {
    test('serializes and deserializes class data correctly', () {
      final classModel = ClassModel(
        id: 'cls_001',
        name: 'Grade 9 - B',
        classTeacher: 'Mr. Anderson',
        classTeacherId: 'teacher_42',
        room: 'Room 204',
        capacity: 35,
      );

      final map = classModel.toMap();
      expect(map['name'], 'Grade 9 - B');
      expect(map['classTeacher'], 'Mr. Anderson');
      expect(map['classTeacherId'], 'teacher_42');
      expect(map['room'], 'Room 204');
      expect(map['capacity'], 35);

      final parsed = ClassModel.fromMap('cls_001', map);
      expect(parsed.id, 'cls_001');
      expect(parsed.name, 'Grade 9 - B');
      expect(parsed.classTeacher, 'Mr. Anderson');
      expect(parsed.room, 'Room 204');
      expect(parsed.capacity, 35);
    });
  });

  group('FeeModel Tests', () {
    test('handles fee statuses and overdue tracking', () {
      final fee = FeeModel(
        id: 'fee_01',
        studentId: 'std_55',
        studentName: 'Alice Johnson',
        className: 'Grade 10 - A',
        amount: 4500,
        status: FeeStatus.pending,
        dueDate: DateTime(2025, 1, 1),
      );

      expect(fee.isOverdue, isTrue);
      expect(fee.formattedAmount, 'Rs. 4500');

      final paidFee = fee.copyWith(status: FeeStatus.paid);
      expect(paidFee.isOverdue, isFalse);
      expect(paidFee.status, FeeStatus.paid);
    });

    test('fee status parser maps string variants correctly', () {
      expect(feeStatusFromString('paid'), FeeStatus.paid);
      expect(feeStatusFromString('pending'), FeeStatus.pending);
      expect(feeStatusFromString('overdue'), FeeStatus.overdue);
      expect(feeStatusFromString('pending_verification'), FeeStatus.pendingVerification);
      expect(feeStatusFromString('pendingVerification'), FeeStatus.pendingVerification);
      expect(feeStatusFromString('invalid'), FeeStatus.unknown);
    });
  });

  group('TimetableModel Tests', () {
    test('formats time ranges and serializes properties', () {
      final slot = TimetableModel(
        id: 'slot_1',
        className: 'Grade 8 - A',
        day: 'Monday',
        subject: 'English',
        teacher: 'Ms. Davis',
        startTime: '08:30 AM',
        endTime: '09:15 AM',
        room: 'Lab 1',
      );

      expect(slot.timeRange, '08:30 AM - 09:15 AM');

      final map = slot.toMap();
      expect(map['className'], 'Grade 8 - A');
      expect(map['day'], 'Monday');
      expect(map['subject'], 'English');
      expect(map['startTime'], '08:30 AM');
      expect(map['endTime'], '09:15 AM');
    });
  });

  group('ResultModel Tests', () {
    test('computes letter grades accurately', () {
      final aPlus = ResultModel(
        id: '1',
        studentId: 's1',
        studentName: 'Bob',
        className: 'Grade 9 - A',
        subject: 'Biology',
        examTitle: 'Midterm',
        marksObtained: 95,
        totalMarks: 100,
        percentage: 95,
      );
      expect(aPlus.letterGrade, 'A+');

      final bGrade = aPlus.copyWith(percentage: 65, marksObtained: 65);
      expect(bGrade.letterGrade, 'B');

      final fGrade = aPlus.copyWith(percentage: 35, marksObtained: 35);
      expect(fGrade.letterGrade, 'F');
    });
  });

  group('AttendanceModel Tests', () {
    test('maps attendance status correctly', () {
      expect(attendanceStatusFromString('present'), AttendanceStatusValue.present);
      expect(attendanceStatusFromString('absent'), AttendanceStatusValue.absent);
      expect(attendanceStatusFromString('late'), AttendanceStatusValue.late);
      expect(attendanceStatusFromString('leave'), AttendanceStatusValue.leave);
      expect(attendanceStatusFromString('unknown'), AttendanceStatusValue.unmarked);
    });
  });
}
