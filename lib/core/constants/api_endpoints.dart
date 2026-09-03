import 'package:flutter/foundation.dart';

/// Centralized API endpoint configurations for EduManage backend.
class ApiEndpoints {
  ApiEndpoints._();

  // Configurable base URL:
  // - Android emulator: http://10.0.2.2:5000/api/v1
  // - Web / Windows / macOS / iOS Simulator: http://localhost:5000/api/v1
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api/v1';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000/api/v1';
      default:
        return 'http://localhost:5000/api/v1';
    }
  }

  // Health
  static String get health => '$baseUrl/health';

  // Auth
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get me => '$baseUrl/auth/me';

  // Classes
  static String get classes => '$baseUrl/classes';
  static String classById(String id) => '$baseUrl/classes/$id';

  // Students
  static String get students => '$baseUrl/students';
  static String studentById(String id) => '$baseUrl/students/$id';
  static String parentChildren([String? parentId]) =>
      parentId != null ? '$baseUrl/students/parent/$parentId' : '$baseUrl/students/parent';

  // Teachers
  static String get teachers => '$baseUrl/teachers';
  static String teacherById(String id) => '$baseUrl/teachers/$id';

  // Attendance
  static String get attendance => '$baseUrl/attendance';
  static String get attendanceByClass => '$baseUrl/attendance/class';
  static String studentAttendance([String? studentId]) =>
      studentId != null ? '$baseUrl/attendance/student/$studentId' : '$baseUrl/attendance/student';

  // Assignments
  static String get assignments => '$baseUrl/assignments';
  static String assignmentById(String id) => '$baseUrl/assignments/$id';

  // Fees
  static String get fees => '$baseUrl/fees';
  static String get feeStatistics => '$baseUrl/fees/statistics';
  static String feeById(String id) => '$baseUrl/fees/$id';
  static String feePay(String id) => '$baseUrl/fees/$id/pay';
  static String feeVerify(String id) => '$baseUrl/fees/$id/verify';

  // Notices
  static String get notices => '$baseUrl/notices';
  static String noticeById(String id) => '$baseUrl/notices/$id';

  // Timetable
  static String get timetable => '$baseUrl/timetable';
  static String timetableById(String id) => '$baseUrl/timetable/$id';

  // Results
  static String get results => '$baseUrl/results';
  static String resultById(String id) => '$baseUrl/results/$id';

  // Dashboard
  static String get adminDashboard => '$baseUrl/dashboard/admin';
  static String teacherDashboard([String? teacherId]) =>
      teacherId != null ? '$baseUrl/dashboard/teacher/$teacherId' : '$baseUrl/dashboard/teacher';
  static String studentDashboard([String? studentId]) =>
      studentId != null ? '$baseUrl/dashboard/student/$studentId' : '$baseUrl/dashboard/student';
}
