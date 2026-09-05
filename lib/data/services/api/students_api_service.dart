import '../../../core/constants/api_endpoints.dart';
import '../../models/api_response.dart';
import '../../models/student_model.dart';
import '../api_client.dart';

class StudentsApiService {
  final ApiClient _client;

  StudentsApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches students list with optional filtering by class, approval status, and search query.
  Future<ApiResponse<List<StudentModel>>> getAll({
    String? className,
    bool? approved,
    String? search,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (className != null && className.isNotEmpty) query['class'] = className;
      if (approved != null) query['approved'] = approved.toString();
      if (search != null && search.isNotEmpty) query['search'] = search;

      final response = await _client.get(
        ApiEndpoints.students,
        queryParameters: query,
      );

      if (response is List) {
        final students = response.map((item) {
          final map = item as Map<String, dynamic>;
          final id = (map['id'] ?? map['uid'] ?? '').toString();
          return StudentModel.fromMap(id, map);
        }).toList();

        return ApiResponse<List<StudentModel>>(
          success: true,
          data: students,
        );
      }

      return ApiResponse<List<StudentModel>>(
        success: true,
        data: const [],
      );
    } on ApiException catch (e) {
      return ApiResponse<List<StudentModel>>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<List<StudentModel>>.error(e.toString());
    }
  }

  /// Fetches a student by ID.
  Future<ApiResponse<StudentModel>> getById(String id) async {
    try {
      final response = await _client.get(ApiEndpoints.studentById(id));
      if (response is Map<String, dynamic>) {
        final studentId = (response['id'] ?? response['uid'] ?? id).toString();
        return ApiResponse<StudentModel>(
          success: true,
          data: StudentModel.fromMap(studentId, response),
        );
      }
      return ApiResponse<StudentModel>.error('Student not found', statusCode: 404);
    } on ApiException catch (e) {
      return ApiResponse<StudentModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<StudentModel>.error(e.toString());
    }
  }

  /// Fetches children linked to a parent user.
  Future<ApiResponse<List<StudentModel>>> getParentChildren([String? parentId]) async {
    try {
      final url = ApiEndpoints.parentChildren(parentId);
      final response = await _client.get(url);

      if (response is List) {
        final children = response.map((item) {
          final map = item as Map<String, dynamic>;
          final id = (map['id'] ?? map['uid'] ?? '').toString();
          return StudentModel.fromMap(id, map);
        }).toList();

        return ApiResponse<List<StudentModel>>(
          success: true,
          data: children,
        );
      }

      return ApiResponse<List<StudentModel>>(
        success: true,
        data: const [],
      );
    } on ApiException catch (e) {
      return ApiResponse<List<StudentModel>>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<List<StudentModel>>.error(e.toString());
    }
  }

  /// Registers a new student.
  Future<ApiResponse<StudentModel>> create(StudentModel student) async {
    try {
      final payload = {
        'name': student.name,
        'email': student.email,
        'rollNo': student.rollNo,
        'class': student.className,
        'section': student.section,
        'contact': student.contact,
        'approved': student.approved,
      };

      final response = await _client.post(
        ApiEndpoints.students,
        body: payload,
      );

      if (response is Map<String, dynamic>) {
        final id = (response['id'] ?? response['uid'] ?? student.id).toString();
        return ApiResponse<StudentModel>(
          success: true,
          data: StudentModel.fromMap(id, response),
          message: 'Student registered successfully',
          statusCode: 201,
        );
      }

      return ApiResponse<StudentModel>.error('Failed to create student');
    } on ApiException catch (e) {
      return ApiResponse<StudentModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<StudentModel>.error(e.toString());
    }
  }

  /// Updates student profile.
  Future<ApiResponse<StudentModel>> update(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client.put(
        ApiEndpoints.studentById(id),
        body: updates,
      );

      if (response is Map<String, dynamic>) {
        return ApiResponse<StudentModel>(
          success: true,
          data: StudentModel.fromMap(id, response),
          message: 'Student updated successfully',
        );
      }

      return ApiResponse<StudentModel>.error('Failed to update student');
    } on ApiException catch (e) {
      return ApiResponse<StudentModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<StudentModel>.error(e.toString());
    }
  }

  /// Deletes a student by ID.
  Future<ApiResponse<bool>> delete(String id) async {
    try {
      await _client.delete(ApiEndpoints.studentById(id));
      return const ApiResponse<bool>(
        success: true,
        data: true,
        message: 'Student deleted successfully',
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
