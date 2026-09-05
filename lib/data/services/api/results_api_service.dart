import '../../../core/constants/api_endpoints.dart';
import '../../models/api_response.dart';
import '../../models/result_model.dart';
import '../api_client.dart';

class ResultsApiService {
  final ApiClient _client;

  ResultsApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches exam results with optional class or student filters.
  Future<ApiResponse<List<ResultModel>>> getAll({
    String? className,
    String? studentId,
    String? subject,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (className != null && className.isNotEmpty) query['class'] = className;
      if (studentId != null && studentId.isNotEmpty) query['studentId'] = studentId;
      if (subject != null && subject.isNotEmpty) query['subject'] = subject;

      final response = await _client.get(
        ApiEndpoints.results,
        queryParameters: query,
      );

      if (response is List) {
        final list = response.map((item) {
          final map = item as Map<String, dynamic>;
          final id = (map['id'] ?? map['_id'] ?? '').toString();
          return ResultModel.fromMap(id, map);
        }).toList();

        return ApiResponse<List<ResultModel>>(
          success: true,
          data: list,
        );
      }

      return ApiResponse<List<ResultModel>>(
        success: true,
        data: const [],
      );
    } on ApiException catch (e) {
      return ApiResponse<List<ResultModel>>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<List<ResultModel>>.error(e.toString());
    }
  }

  /// Fetches results for a specific student.
  Future<ApiResponse<List<ResultModel>>> getByStudent(String studentId) async {
    return getAll(studentId: studentId);
  }

  /// Records an exam result.
  Future<ApiResponse<ResultModel>> create(ResultModel result) async {
    try {
      final payload = {
        'studentId': result.studentId,
        'studentName': result.studentName,
        'className': result.className,
        'subject': result.subject,
        'examTitle': result.examTitle,
        'marksObtained': result.marksObtained,
        'totalMarks': result.totalMarks,
      };

      final response = await _client.post(
        ApiEndpoints.results,
        body: payload,
      );

      if (response is Map<String, dynamic>) {
        final id = (response['id'] ?? response['_id'] ?? result.id).toString();
        return ApiResponse<ResultModel>(
          success: true,
          data: ResultModel.fromMap(id, response),
          message: 'Exam grade recorded successfully',
          statusCode: 201,
        );
      }

      return ApiResponse<ResultModel>.error('Failed to record result');
    } on ApiException catch (e) {
      return ApiResponse<ResultModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<ResultModel>.error(e.toString());
    }
  }

  /// Deletes a result.
  Future<ApiResponse<bool>> delete(String id) async {
    try {
      await _client.delete(ApiEndpoints.resultById(id));
      return const ApiResponse<bool>(
        success: true,
        data: true,
        message: 'Result deleted successfully',
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
