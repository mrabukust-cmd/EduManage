import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:school_management_system/data/models/api_response.dart';
import 'package:school_management_system/data/models/assignment_model.dart';
import 'package:school_management_system/data/models/class_model.dart';
import 'package:school_management_system/data/models/fee_model.dart';
import 'package:school_management_system/data/models/notice_model.dart';
import 'package:school_management_system/data/models/result_model.dart';
import 'package:school_management_system/data/models/student_model.dart';
import 'package:school_management_system/data/models/teacher_model.dart';
import 'package:school_management_system/data/models/timetable_model.dart';
import 'package:school_management_system/data/services/api/api_services.dart';
import 'package:school_management_system/data/services/api_client.dart';

void main() {
  group('EduManage API Services Comprehensive Test Suite', () {
    late http.Client mockClient;
    late ApiClient apiClient;

    setUp(() {
      mockClient = MockClient((request) async {
        final path = request.url.path;
        final method = request.method;

        // 1. Auth endpoints
        if (path == '/api/v1/auth/login' && method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body['email'] == 'admin@edumanage.edu') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'token': 'jwt_mock_token_123',
                  'user': {'id': 'admin_001', 'name': 'Admin', 'role': 'admin'}
                }
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({'success': false, 'message': 'Invalid credentials'}),
            401,
          );
        }

        if (path == '/api/v1/auth/me' && method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'id': 'admin_001', 'name': 'Admin', 'role': 'admin'}
            }),
            200,
          );
        }

        // 2. Classes endpoints
        if (path == '/api/v1/classes' && method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 'class_1', 'name': 'Grade 9 - A', 'classTeacher': 'John Doe', 'capacity': 30},
                {'id': 'class_2', 'name': 'Grade 10 - B', 'classTeacher': 'Sarah Connor', 'capacity': 25},
              ]
            }),
            200,
          );
        }

        if (path == '/api/v1/classes' && method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'id': 'class_new', ...body}
            }),
            201,
          );
        }

        // 3. Students endpoints
        if (path == '/api/v1/students' && method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'student_1',
                  'name': 'Alex Johnson',
                  'email': 'alex@school.edu',
                  'rollNo': '101',
                  'class': 'Grade 9 - A',
                  'section': 'A',
                  'contact': '+1234567890',
                  'approved': true,
                }
              ]
            }),
            200,
          );
        }

        // 4. Teachers endpoints
        if (path == '/api/v1/teachers' && method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'teacher_1',
                  'name': 'Prof. John Smith',
                  'email': 'john@school.edu',
                  'phone': '+1234567890',
                  'subject': 'Math',
                  'qualification': 'M.Sc',
                  'classes': ['Grade 9 - A'],
                  'approved': true,
                }
              ]
            }),
            200,
          );
        }

        if (path == '/api/v1/teachers/teacher_1/approve' && method == 'PUT') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 'teacher_1',
                'name': 'Prof. John Smith',
                'approved': true,
              }
            }),
            200,
          );
        }

        // 5. Attendance endpoints
        if (path == '/api/v1/attendance' && method == 'POST') {
          return http.Response(
            jsonEncode({'success': true, 'message': 'Attendance saved'}),
            200,
          );
        }

        if (path == '/api/v1/attendance/student/student_1' && method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'percentage': 95.0, 'total': 20, 'present': 19}
            }),
            200,
          );
        }

        // 6. Assignments endpoints
        if (path == '/api/v1/assignments' && method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'assign_1',
                  'title': 'Math Algebra HW',
                  'subject': 'Mathematics',
                  'className': 'Grade 9 - A',
                  'teacherId': 'teacher_1',
                }
              ]
            }),
            200,
          );
        }

        // 7. Fees endpoints
        if (path == '/api/v1/fees/statistics' && method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'totalCollected': 50000, 'pendingAmount': 12000}
            }),
            200,
          );
        }

        // 8. Notices endpoints
        if (path == '/api/v1/notices' && method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'notice_1',
                  'title': 'School Holiday Announcement',
                  'body': 'School remains closed on Monday.',
                  'category': 'General',
                  'author': 'Admin',
                }
              ]
            }),
            200,
          );
        }

        // 9. Timetable endpoints
        if (path == '/api/v1/timetable' && method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'slot_1',
                  'className': 'Grade 9 - A',
                  'day': 'Monday',
                  'subject': 'Mathematics',
                  'teacher': 'Prof. John Smith',
                  'startTime': '09:00 AM',
                  'endTime': '10:00 AM',
                }
              ]
            }),
            200,
          );
        }

        // 10. Results endpoints
        if (path == '/api/v1/results' && method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'res_1',
                  'studentId': 'student_1',
                  'studentName': 'Alex Johnson',
                  'className': 'Grade 9 - A',
                  'subject': 'Mathematics',
                  'marksObtained': 95,
                  'totalMarks': 100,
                  'examTitle': 'Midterm Exam',
                }
              ]
            }),
            200,
          );
        }

        // 11. Dashboard endpoints
        if (path == '/api/v1/dashboard/admin' && method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'totalStudents': 120, 'totalTeachers': 15, 'totalClasses': 6}
            }),
            200,
          );
        }

        return http.Response(jsonEncode({'success': false, 'message': 'Not Found'}), 404);
      });

      apiClient = ApiClient(client: mockClient);
    });

    tearDown(() {
      apiClient.dispose();
    });

    test('AuthApiService: handles successful login and saves token', () async {
      final authService = AuthApiService(client: apiClient);
      final res = await authService.login(
        email: 'admin@edumanage.edu',
        password: 'Password@123',
      );

      expect(res.isSuccess, isTrue);
      expect(apiClient.authToken, 'jwt_mock_token_123');
    });

    test('AuthApiService: handles login failure with error response', () async {
      final authService = AuthApiService(client: apiClient);
      final res = await authService.login(
        email: 'wrong@school.edu',
        password: 'badpassword',
      );

      expect(res.isSuccess, isFalse);
      expect(res.message, contains('Invalid credentials'));
    });

    test('ClassesApiService: parses list of ClassModel correctly', () async {
      final service = ClassesApiService(client: apiClient);
      final res = await service.getAll();

      expect(res.isSuccess, isTrue);
      expect(res.data, isA<List<ClassModel>>());
      expect(res.data!.length, 2);
      expect(res.data!.first.name, 'Grade 9 - A');
    });

    test('StudentsApiService: fetches and parses students list', () async {
      final service = StudentsApiService(client: apiClient);
      final res = await service.getAll(className: 'Grade 9 - A');

      expect(res.isSuccess, isTrue);
      expect(res.data, isA<List<StudentModel>>());
      expect(res.data!.first.name, 'Alex Johnson');
      expect(res.data!.first.className, 'Grade 9 - A');
    });

    test('TeachersApiService: approves teacher successfully', () async {
      final service = TeachersApiService(client: apiClient);
      final res = await service.approve('teacher_1', true);

      expect(res.isSuccess, isTrue);
      expect(res.data!.approved, isTrue);
    });

    test('AttendanceApiService: gets student attendance stats', () async {
      final service = AttendanceApiService(client: apiClient);
      final res = await service.getStudentAttendance('student_1');

      expect(res.isSuccess, isTrue);
      expect(res.data!['percentage'], 95.0);
    });

    test('FeesApiService: fetches fee collection statistics', () async {
      final service = FeesApiService(client: apiClient);
      final res = await service.getStatistics();

      expect(res.isSuccess, isTrue);
      expect(res.data!['totalCollected'], 50000);
    });

    test('NoticesApiService: parses notice list correctly', () async {
      final service = NoticesApiService(client: apiClient);
      final res = await service.getAll();

      expect(res.isSuccess, isTrue);
      expect(res.data!.first.title, 'School Holiday Announcement');
      expect(res.data!.first.category, 'General');
    });

    test('TimetableApiService: parses timetable slot correctly', () async {
      final service = TimetableApiService(client: apiClient);
      final res = await service.getByClass('Grade 9 - A');

      expect(res.isSuccess, isTrue);
      expect(res.data!.first.day, 'Monday');
      expect(res.data!.first.subject, 'Mathematics');
    });

    test('ResultsApiService: parses exam results correctly', () async {
      final service = ResultsApiService(client: apiClient);
      final res = await service.getAll();

      expect(res.isSuccess, isTrue);
      expect(res.data!.first.marksObtained, 95);
      expect(res.data!.first.letterGrade, 'A+');
    });

    test('DashboardApiService: fetches admin dashboard statistics', () async {
      final service = DashboardApiService(client: apiClient);
      final res = await service.getAdminDashboard();

      expect(res.isSuccess, isTrue);
      expect(res.data!['totalStudents'], 120);
      expect(res.data!['totalTeachers'], 15);
    });
  });
}
