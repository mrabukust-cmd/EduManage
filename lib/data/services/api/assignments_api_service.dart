import '../../../core/constants/api_endpoints.dart';
import '../../models/api_response.dart';
import '../../models/assignment_model.dart';
import '../api_client.dart';

class AssignmentsApiService {
  final ApiClient _client;

  AssignmentsApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches assignments, optionally filtered by class or teacher.
  Future<ApiResponse<List<AssignmentModel>>> getAll({
    String? className,
    String? teacherId,
    String? search,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (className != null && className.isNotEmpty) query['class'] = className;
      if (teacherId != null && teacherId.isNotEmpty) query['teacherId'] = teacherId;
      if (search != null && search.isNotEmpty) query['search'] = search;

      final response = await _client.get(
        ApiEndpoints.assignments,
        queryParameters: query,
      );

      if (response is List) {
        final list = response.map((item) {
          final map = item as Map<String, dynamic>;
          final id = (map['id'] ?? map['_id'] ?? '').toString();
          return AssignmentModel.fromMap(id, map);
        }).toList();

        return ApiResponse<List<AssignmentModel>>(
          success: true,
          data: list,
        );
      }

      return ApiResponse<List<AssignmentModel>>(
        success: true,
        data: const [],
      );
    } on ApiException catch (e) {
      return ApiResponse<List<AssignmentModel>>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<List<AssignmentModel>>.error(e.toString());
    }
  }

  /// Fetches single assignment by ID.
  Future<ApiResponse<AssignmentModel>> getById(String id) async {
    try {
      final response = await _client.get(ApiEndpoints.assignmentById(id));
      if (response is Map<String, dynamic>) {
        final assignId = (response['id'] ?? response['_id'] ?? id).toString();
        return ApiResponse<AssignmentModel>(
          success: true,
          data: AssignmentModel.fromMap(assignId, response),
        );
      }
      return ApiResponse<AssignmentModel>.error('Assignment not found', statusCode: 404);
    } on ApiException catch (e) {
      return ApiResponse<AssignmentModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<AssignmentModel>.error(e.toString());
    }
  }

  /// Creates a new assignment.
  Future<ApiResponse<AssignmentModel>> create(AssignmentModel assignment) async {
    try {
      final payload = {
        'title': assignment.title,
        'description': assignment.description,
        'subject': assignment.subject,
        'className': assignment.className,
        if (assignment.dueDate != null)
          'dueDate': assignment.dueDate!.toIso8601String(),
        'teacherId': assignment.teacherId,
        'teacherName': assignment.teacherName,
        if (assignment.fileUrl != null) 'fileUrl': assignment.fileUrl,
        if (assignment.totalMarks != null) 'totalMarks': assignment.totalMarks,
      };

      final response = await _client.post(
        ApiEndpoints.assignments,
        body: payload,
      );

      if (response is Map<String, dynamic>) {
        final id = (response['id'] ?? response['_id'] ?? assignment.id).toString();
        return ApiResponse<AssignmentModel>(
          success: true,
          data: AssignmentModel.fromMap(id, response),
          message: 'Assignment created successfully',
          statusCode: 201,
        );
      }

      return ApiResponse<AssignmentModel>.error('Failed to create assignment');
    } on ApiException catch (e) {
      return ApiResponse<AssignmentModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<AssignmentModel>.error(e.toString());
    }
  }

  /// Submits student work for an assignment.
  Future<ApiResponse<dynamic>> submit({
    required String assignmentId,
    required String studentId,
    required String fileUrl,
    String? comment,
  }) async {
    try {
      final body = <String, dynamic>{
        'studentId': studentId,
        'fileUrl': fileUrl,
      };
      if (comment != null) body['comment'] = comment;

      final response = await _client.post(
        '${ApiEndpoints.assignments}/$assignmentId/submissions',
        body: body,
      );

      return ApiResponse<dynamic>(
        success: true,
        data: response,
        message: 'Submission uploaded successfully',
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

  /// Deletes an assignment.
  Future<ApiResponse<bool>> delete(String id) async {
    try {
      await _client.delete(ApiEndpoints.assignmentById(id));
      return const ApiResponse<bool>(
        success: true,
        data: true,
        message: 'Assignment deleted successfully',
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
