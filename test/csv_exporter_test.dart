import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_system/core/utils/csv_exporter.dart';
import 'package:school_management_system/data/models/student_model.dart';
import 'package:school_management_system/data/models/fee_model.dart';
import 'package:school_management_system/data/models/result_model.dart';

void main() {
  group('CsvExporter Engine Test Suite', () {
    test('escapeCell handles basic values, quotes, commas, and null', () {
      expect(CsvExporter.escapeCell(null), '""');
      expect(CsvExporter.escapeCell('simple'), '"simple"');
      expect(CsvExporter.escapeCell('hello, world'), '"hello, world"');
      expect(CsvExporter.escapeCell('say "hi"'), '"say ""hi"""');
      expect(CsvExporter.escapeCell(1234), '"1234"');
    });

    test('escapeCell prevents CSV formula injection attacks', () {
      expect(CsvExporter.escapeCell('=1+1'), '"\'=1+1"');
      expect(CsvExporter.escapeCell('+cmd'), '"\'+cmd"');
      expect(CsvExporter.escapeCell('-calc'), '"\'-calc"');
      expect(CsvExporter.escapeCell('@sum(A1:A10)'), '"\'@sum(A1:A10)"');
    });

    test('exportStudentRoster formats students correctly', () {
      final students = [
        const StudentModel(
          id: 's1',
          name: 'Alex Johnson',
          rollNo: 'STD-101',
          className: 'Grade 10 - A',
          section: 'A',
          email: 'alex@example.com',
          contact: '1234567890',
        ),
      ];

      final csv = CsvExporter.exportStudentRoster(students);
      expect(csv, contains('"Roll Number","Full Name","Class"'));
      expect(csv, contains('"STD-101","Alex Johnson","Grade 10 - A","A","alex@example.com","1234567890"'));
    });

    test('exportFeeReport formats fee models with date and status', () {
      final fees = [
        FeeModel(
          id: 'fee_01',
          studentId: 's1',
          studentName: 'Alex Johnson',
          className: 'Grade 10 - A',
          amount: 500.0,
          dueDate: DateTime(2026, 9, 30),
          status: FeeStatus.paid,
          paidAt: DateTime(2026, 9, 5),
        ),
      ];

      final csv = CsvExporter.exportFeeReport(fees);
      expect(csv, contains('"Fee ID","Student Name","Class","Amount"'));
      expect(csv, contains('"fee_01","Alex Johnson","Grade 10 - A","500.00","2026-09-30","PAID","2026-09-05"'));
    });

    test('exportAttendanceReport and exportResultsReport produce valid output', () {
      final attendance = [
        {'rollNo': '101', 'studentName': 'Alex Johnson', 'status': 'PRESENT', 'remarks': 'On time'},
      ];

      final attCsv = CsvExporter.exportAttendanceReport(
        className: 'Grade 10 - A',
        date: '2026-09-07',
        records: attendance,
      );
      expect(attCsv, contains('"2026-09-07","Grade 10 - A","101","Alex Johnson","PRESENT","On time"'));

      final results = [
        const ResultModel(
          id: 'r1',
          studentId: 's1',
          studentName: 'Alex Johnson',
          className: 'Grade 10 - A',
          subject: 'Mathematics',
          examTitle: 'Midterm 2026',
          marksObtained: 95.0,
          totalMarks: 100.0,
          percentage: 95.0,
        ),
      ];

      final resCsv = CsvExporter.exportResultsReport(
        className: 'Grade 10 - A',
        examTitle: 'Midterm 2026',
        results: results,
      );
      expect(resCsv, contains('"Midterm 2026","Grade 10 - A","Alex Johnson","Mathematics","95.0","100.0","95.0%","A+"'));
    });
  });
}
