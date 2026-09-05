import '../../../core/constants/api_endpoints.dart';
import '../../models/api_response.dart';
import '../../models/teacher_model.dart';
import '../api_client.dart';

class TeachersApiService {
  final ApiClient _client;

  TeachersApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches teachers list with optional approval filter and search.
  Future<ApiResponse<List<TeacherModel>>> getAll({
    bool? approved,
    String? search,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (approved != null) query['approved'] = approved.toString();
      if (search != null && search.isNotEmpty) query['search'] = search;

      final response = await _client.get(
        ApiEndpoints.teachers,
        queryParameters: query,
      );

      if (response is List) {
        final teachers = response.map((item) {
          final map = item as Map<String, dynamic>;
          final id = (map['id'] ?? map['uid'] ?? '').toString();
          return TeacherModel.fromMap(id, map);
        }).toList();

        return ApiResponse<List<TeacherModel>>(
          success: true,
          data: teachers,
        );
      }

      return ApiResponse<List<TeacherModel>>(
        success: true,
        data: const [],
      );
    } on ApiException catch (e) {
      return ApiResponse<List<TeacherModel>>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<List<TeacherModel>>.error(e.toString());
    }
  }

  /// Fetches a teacher by ID.
  Future<ApiResponse<TeacherModel>> getById(String id) async {
    try {
      final response = await _client.get(ApiEndpoints.teacherById(id));
      if (response is Map<String, dynamic>) {
        final teacherId = (response['id'] ?? response['uid'] ?? id).toString();
        return ApiResponse<TeacherModel>(
          success: true,
          data: TeacherModel.fromMap(teacherId, response),
        );
      }
      return ApiResponse<TeacherModel>.error('Teacher not found', statusCode: 404);
    } on ApiException catch (e) {
      return ApiResponse<TeacherModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<TeacherModel>.error(e.toString());
    }
  }

  /// Approves or rejects a teacher account (admin action).
  Future<ApiResponse<TeacherModel>> approve(String id, bool approved) async {
    try {
      final response = await _client.put(
        '${ApiEndpoints.teachers}/$id/approve',
        body: {'approved': approved},
      );

      if (response is Map<String, dynamic>) {
        final teacherId = (response['id'] ?? response['uid'] ?? id).toString();
        return ApiResponse<TeacherModel>(
          success: true,
          data: TeacherModel.fromMap(teacherId, response),
          message: 'Teacher status updated successfully',
        );
      }

      return ApiResponse<TeacherModel>.error('Failed to update teacher approval status');
    } on ApiException catch (e) {
      return ApiResponse<TeacherModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<TeacherModel>.error(e.toString());
    }
  }

  /// Updates teacher profile or assigned classes.
  Future<ApiResponse<TeacherModel>> update(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client.put(
        ApiEndpoints.teacherById(id),
        body: updates,
      );

      if (response is Map<String, dynamic>) {
        return ApiResponse<TeacherModel>(
          success: true,
          data: TeacherModel.fromMap(id, response),
          message: 'Teacher profile updated successfully',
        );
      }

      return ApiResponse<TeacherModel>.error('Failed to update teacher');
    } on ApiException catch (e) {
      return ApiResponse<TeacherModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<TeacherModel>.error(e.toString());
    }
  }

  /// Deletes a teacher by ID.
  Future<ApiResponse<bool>> delete(String id) async {
    try {
      await _client.delete(ApiEndpoints.teacherById(id));
      return const ApiResponse<bool>(
        success: true,
        data: true,
        message: 'Teacher deleted successfully',
      );
    } on ApiException catch (e) {
      return ApiResponse<bool>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<bool>.error(e.toString());
    }
  }
}
