import '../../../core/constants/api_endpoints.dart';
import '../../models/api_response.dart';
import '../../models/attendence_model.dart';
import '../api_client.dart';

class AttendanceApiService {
  final ApiClient _client;

  AttendanceApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Records attendance for a batch of students or single entry.
  Future<ApiResponse<dynamic>> markAttendance({
    required String className,
    required String date,
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.attendance,
        body: {
          'className': className,
          'date': date,
          'records': records,
        },
      );

      return ApiResponse<dynamic>(
        success: true,
        data: response,
        message: 'Attendance saved successfully',
      );
    } on ApiException catch (e) {
      return ApiResponse<dynamic>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<dynamic>.error(e.toString());
    }
  }

  /// Fetches attendance history and stats for a specific student.
  Future<ApiResponse<Map<String, dynamic>>> getStudentAttendance(String studentId) async {
    try {
      final url = ApiEndpoints.studentAttendance(studentId);
      final response = await _client.get(url);

      if (response is Map<String, dynamic>) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response,
        );
      }

      return ApiResponse<Map<String, dynamic>>.error('Invalid attendance data');
    } on ApiException catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>.error(e.toString());
    }
  }

  /// Fetches attendance records for a specific class and date.
  Future<ApiResponse<List<AttendanceModel>>> getClassAttendance({
    required String className,
    required String date,
  }) async {
    try {
      final response = await _client.get(
        ApiEndpoints.attendance,
        queryParameters: {
          'class': className,
          'date': date,
        },
      );

      if (response is List) {
        final list = response.map((item) {
          final map = item as Map<String, dynamic>;
          final id = (map['id'] ?? map['_id'] ?? '').toString();
          return AttendanceModel.fromMap(id, map);
        }).toList();

        return ApiResponse<List<AttendanceModel>>(
          success: true,
          data: list,
        );
      }

      return ApiResponse<List<AttendanceModel>>(
        success: true,
        data: const [],
      );
    } on ApiException catch (e) {
      return ApiResponse<List<AttendanceModel>>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<List<AttendanceModel>>.error(e.toString());
    }
  }
}
