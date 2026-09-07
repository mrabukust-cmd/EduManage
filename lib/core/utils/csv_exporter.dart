import 'package:school_management_system/data/models/student_model.dart';
import 'package:school_management_system/data/models/fee_model.dart';
import 'package:school_management_system/data/models/result_model.dart';

/// Standardized CSV export engine adhering to RFC 4180 specifications
/// with protection against CSV injection attacks.
class CsvExporter {
  CsvExporter._();

  /// Escapes a single cell according to RFC 4180 rules.
  /// Also protects against CSV injection vulnerabilities by prefixing
  /// formula characters (`=`, `+`, `-`, `@`, `\t`, `\r`) with a single quote.
  static String escapeCell(dynamic value) {
    if (value == null) return '""';
    String str = value.toString();

    // Prevent CSV formula injection
    if (str.isNotEmpty && (str.startsWith('=') ||
        str.startsWith('+') ||
        str.startsWith('-') ||
        str.startsWith('@') ||
        str.startsWith('\t') ||
        str.startsWith('\r'))) {
      str = "'$str";
    }

    // Always quote cells that contain commas, double quotes, or newlines
    if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }

    return '"$str"';
  }

  /// Builds a CSV document from headers and rows.
  static String toCsv(List<String> headers, List<List<dynamic>> rows) {
    final buffer = StringBuffer();

    // Write header line
    buffer.writeln(headers.map(escapeCell).join(','));

    // Write data rows
    for (final row in rows) {
      buffer.writeln(row.map(escapeCell).join(','));
    }

    return buffer.toString();
  }

  /// Exports enrolled student roster into CSV format.
  static String exportStudentRoster(List<StudentModel> students) {
    final headers = [
      'Roll Number',
      'Full Name',
      'Class',
      'Section',
      'Email',
      'Contact',
    ];

    final rows = students.map((s) {
      return [
        s.rollNo,
        s.name,
        s.className,
        s.section,
        s.email,
        s.contact,
      ];
    }).toList();

    return toCsv(headers, rows);
  }

  /// Exports fee invoice tracking records into CSV format.
  static String exportFeeReport(List<FeeModel> fees) {
    final headers = [
      'Fee ID',
      'Student Name',
      'Class',
      'Amount',
      'Due Date',
      'Status',
      'Paid At',
    ];

    final rows = fees.map((f) {
      return [
        f.id,
        f.studentName,
        f.className,
        f.amount.toStringAsFixed(2),
        f.dueDate != null ? f.dueDate!.toIso8601String().split('T').first : 'N/A',
        f.status.name.toUpperCase(),
        f.paidAt != null ? f.paidAt!.toIso8601String().split('T').first : 'N/A',
      ];
    }).toList();

    return toCsv(headers, rows);
  }

  /// Exports class attendance records.
  static String exportAttendanceReport({
    required String className,
    required String date,
    required List<Map<String, dynamic>> records,
  }) {
    final headers = [
      'Date',
      'Class',
      'Roll Number',
      'Student Name',
      'Status',
      'Remarks',
    ];

    final rows = records.map((r) {
      return [
        date,
        className,
        r['rollNo'] ?? '',
        r['studentName'] ?? '',
        r['status'] ?? 'PRESENT',
        r['remarks'] ?? '',
      ];
    }).toList();

    return toCsv(headers, rows);
  }

  /// Exports student academic examination results.
  static String exportResultsReport({
    required String className,
    required String examTitle,
    required List<ResultModel> results,
  }) {
    final headers = [
      'Exam',
      'Class',
      'Student Name',
      'Subject',
      'Marks Obtained',
      'Total Marks',
      'Percentage',
      'Grade',
    ];

    final rows = results.map((r) {
      return [
        examTitle,
        className,
        r.studentName,
        r.subject,
        r.marksObtained.toStringAsFixed(1),
        r.totalMarks.toStringAsFixed(1),
        '${r.percentage.toStringAsFixed(1)}%',
        r.letterGrade,
      ];
    }).toList();

    return toCsv(headers, rows);
  }
}
