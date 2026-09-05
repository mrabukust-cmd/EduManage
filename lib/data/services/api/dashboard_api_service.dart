import '../../../core/constants/api_endpoints.dart';
import '../../models/api_response.dart';
import '../api_client.dart';

class DashboardApiService {
  final ApiClient _client;

  DashboardApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches admin dashboard statistics and summary metrics.
  Future<ApiResponse<Map<String, dynamic>>> getAdminDashboard() async {
    try {
      final response = await _client.get(ApiEndpoints.adminDashboard);
      if (response is Map<String, dynamic>) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response,
        );
      }
      return ApiResponse<Map<String, dynamic>>.error('Invalid dashboard data');
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

  /// Fetches teacher dashboard metrics.
  Future<ApiResponse<Map<String, dynamic>>> getTeacherDashboard([String? teacherId]) async {
    try {
      final url = ApiEndpoints.teacherDashboard(teacherId);
      final response = await _client.get(url);
      if (response is Map<String, dynamic>) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response,
        );
      }
      return ApiResponse<Map<String, dynamic>>.error('Invalid teacher dashboard data');
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

  /// Fetches student dashboard metrics.
  Future<ApiResponse<Map<String, dynamic>>> getStudentDashboard([String? studentId]) async {
    try {
      final url = ApiEndpoints.studentDashboard(studentId);
      final response = await _client.get(url);
      if (response is Map<String, dynamic>) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response,
        );
      }
      return ApiResponse<Map<String, dynamic>>.error('Invalid student dashboard data');
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
}
