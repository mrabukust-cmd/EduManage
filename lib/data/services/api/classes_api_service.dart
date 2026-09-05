import '../../../core/constants/api_endpoints.dart';
import '../../models/api_response.dart';
import '../../models/class_model.dart';
import '../api_client.dart';

class ClassesApiService {
  final ApiClient _client;

  ClassesApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches all classes with optional search filter.
  Future<ApiResponse<List<ClassModel>>> getAll({String? search}) async {
    try {
      final response = await _client.get(
        ApiEndpoints.classes,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      if (response is List) {
        final classes = response.map((item) {
          final map = item as Map<String, dynamic>;
          final id = (map['id'] ?? map['_id'] ?? '').toString();
          return ClassModel.fromMap(id, map);
        }).toList();

        return ApiResponse<List<ClassModel>>(
          success: true,
          data: classes,
        );
      }

      return ApiResponse<List<ClassModel>>(
        success: true,
        data: const [],
      );
    } on ApiException catch (e) {
      return ApiResponse<List<ClassModel>>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<List<ClassModel>>.error(e.toString());
    }
  }

  /// Fetches single class by ID.
  Future<ApiResponse<ClassModel>> getById(String id) async {
    try {
      final response = await _client.get(ApiEndpoints.classById(id));
      if (response is Map<String, dynamic>) {
        final classId = (response['id'] ?? response['_id'] ?? id).toString();
        return ApiResponse<ClassModel>(
          success: true,
          data: ClassModel.fromMap(classId, response),
        );
      }
      return ApiResponse<ClassModel>.error('Class not found', statusCode: 404);
    } on ApiException catch (e) {
      return ApiResponse<ClassModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<ClassModel>.error(e.toString());
    }
  }

  /// Creates a new class.
  Future<ApiResponse<ClassModel>> create(ClassModel classModel) async {
    try {
      final payload = {
        'name': classModel.name,
        'classTeacher': classModel.classTeacher,
        if (classModel.classTeacherId != null)
          'classTeacherId': classModel.classTeacherId,
        if (classModel.room != null) 'room': classModel.room,
        if (classModel.capacity != null) 'capacity': classModel.capacity,
      };

      final response = await _client.post(
        ApiEndpoints.classes,
        body: payload,
      );

      if (response is Map<String, dynamic>) {
        final id = (response['id'] ?? response['_id'] ?? classModel.id).toString();
        return ApiResponse<ClassModel>(
          success: true,
          data: ClassModel.fromMap(id, response),
          message: 'Class created successfully',
          statusCode: 201,
        );
      }

      return ApiResponse<ClassModel>.error('Failed to create class');
    } on ApiException catch (e) {
      return ApiResponse<ClassModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<ClassModel>.error(e.toString());
    }
  }

  /// Updates an existing class.
  Future<ApiResponse<ClassModel>> update(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client.put(
        ApiEndpoints.classById(id),
        body: updates,
      );

      if (response is Map<String, dynamic>) {
        return ApiResponse<ClassModel>(
          success: true,
          data: ClassModel.fromMap(id, response),
          message: 'Class updated successfully',
        );
      }

      return ApiResponse<ClassModel>.error('Failed to update class');
    } on ApiException catch (e) {
      return ApiResponse<ClassModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<ClassModel>.error(e.toString());
    }
  }

  /// Deletes a class by ID.
  Future<ApiResponse<bool>> delete(String id) async {
    try {
      await _client.delete(ApiEndpoints.classById(id));
      return const ApiResponse<bool>(
        success: true,
        data: true,
        message: 'Class deleted successfully',
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
