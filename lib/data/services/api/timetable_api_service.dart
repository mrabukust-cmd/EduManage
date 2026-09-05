import '../../../core/constants/api_endpoints.dart';
import '../../models/api_response.dart';
import '../../models/timetable_model.dart';
import '../api_client.dart';

class TimetableApiService {
  final ApiClient _client;

  TimetableApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches timetable periods for a specific class or day.
  Future<ApiResponse<List<TimetableModel>>> getByClass(
    String className, {
    String? day,
  }) async {
    try {
      final query = <String, dynamic>{
        'class': className,
      };
      if (day != null && day.isNotEmpty) query['day'] = day;

      final response = await _client.get(
        ApiEndpoints.timetable,
        queryParameters: query,
      );

      if (response is List) {
        final list = response.map((item) {
          final map = item as Map<String, dynamic>;
          final id = (map['id'] ?? map['_id'] ?? '').toString();
          return TimetableModel.fromMap(id, map);
        }).toList();

        return ApiResponse<List<TimetableModel>>(
          success: true,
          data: list,
        );
      }

      return ApiResponse<List<TimetableModel>>(
        success: true,
        data: const [],
      );
    } on ApiException catch (e) {
      return ApiResponse<List<TimetableModel>>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<List<TimetableModel>>.error(e.toString());
    }
  }

  /// Creates a new timetable slot.
  Future<ApiResponse<TimetableModel>> create(TimetableModel slot) async {
    try {
      final payload = {
        'className': slot.className,
        'day': slot.day,
        'subject': slot.subject,
        'teacher': slot.teacher,
        if (slot.teacherId != null) 'teacherId': slot.teacherId,
        'startTime': slot.startTime,
        'endTime': slot.endTime,
        if (slot.room != null) 'room': slot.room,
      };

      final response = await _client.post(
        ApiEndpoints.timetable,
        body: payload,
      );

      if (response is Map<String, dynamic>) {
        final id = (response['id'] ?? response['_id'] ?? slot.id).toString();
        return ApiResponse<TimetableModel>(
          success: true,
          data: TimetableModel.fromMap(id, response),
          message: 'Timetable slot created successfully',
          statusCode: 201,
        );
      }

      return ApiResponse<TimetableModel>.error('Failed to create timetable slot');
    } on ApiException catch (e) {
      return ApiResponse<TimetableModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<TimetableModel>.error(e.toString());
    }
  }

  /// Deletes a timetable slot.
  Future<ApiResponse<bool>> delete(String id) async {
    try {
      await _client.delete(ApiEndpoints.timetableById(id));
      return const ApiResponse<bool>(
        success: true,
        data: true,
        message: 'Slot removed successfully',
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
