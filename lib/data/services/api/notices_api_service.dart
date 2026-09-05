import '../../../core/constants/api_endpoints.dart';
import '../../models/api_response.dart';
import '../../models/notice_model.dart';
import '../api_client.dart';

class NoticesApiService {
  final ApiClient _client;

  NoticesApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches notices with optional category filter and search query.
  Future<ApiResponse<List<NoticeModel>>> getAll({
    String? category,
    String? search,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (category != null && category.isNotEmpty) query['category'] = category;
      if (search != null && search.isNotEmpty) query['search'] = search;

      final response = await _client.get(
        ApiEndpoints.notices,
        queryParameters: query,
      );

      if (response is List) {
        final list = response.map((item) {
          final map = item as Map<String, dynamic>;
          final id = (map['id'] ?? map['_id'] ?? '').toString();
          return NoticeModel.fromMap(id, map);
        }).toList();

        return ApiResponse<List<NoticeModel>>(
          success: true,
          data: list,
        );
      }

      return ApiResponse<List<NoticeModel>>(
        success: true,
        data: const [],
      );
    } on ApiException catch (e) {
      return ApiResponse<List<NoticeModel>>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<List<NoticeModel>>.error(e.toString());
    }
  }

  /// Fetches notice by ID.
  Future<ApiResponse<NoticeModel>> getById(String id) async {
    try {
      final response = await _client.get(ApiEndpoints.noticeById(id));
      if (response is Map<String, dynamic>) {
        final noticeId = (response['id'] ?? response['_id'] ?? id).toString();
        return ApiResponse<NoticeModel>(
          success: true,
          data: NoticeModel.fromMap(noticeId, response),
        );
      }
      return ApiResponse<NoticeModel>.error('Notice not found', statusCode: 404);
    } on ApiException catch (e) {
      return ApiResponse<NoticeModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<NoticeModel>.error(e.toString());
    }
  }

  /// Creates a notice.
  Future<ApiResponse<NoticeModel>> create(NoticeModel notice) async {
    try {
      final payload = {
        'title': notice.title,
        'body': notice.body,
        'category': notice.category,
        'author': notice.author,
      };

      final response = await _client.post(
        ApiEndpoints.notices,
        body: payload,
      );

      if (response is Map<String, dynamic>) {
        final id = (response['id'] ?? response['_id'] ?? notice.id).toString();
        return ApiResponse<NoticeModel>(
          success: true,
          data: NoticeModel.fromMap(id, response),
          message: 'Notice created successfully',
          statusCode: 201,
        );
      }

      return ApiResponse<NoticeModel>.error('Failed to create notice');
    } on ApiException catch (e) {
      return ApiResponse<NoticeModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<NoticeModel>.error(e.toString());
    }
  }

  /// Deletes a notice.
  Future<ApiResponse<bool>> delete(String id) async {
    try {
      await _client.delete(ApiEndpoints.noticeById(id));
      return const ApiResponse<bool>(
        success: true,
        data: true,
        message: 'Notice deleted successfully',
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
