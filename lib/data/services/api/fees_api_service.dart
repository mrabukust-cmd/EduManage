import '../../../core/constants/api_endpoints.dart';
import '../../models/api_response.dart';
import '../../models/fee_model.dart';
import '../api_client.dart';

class FeesApiService {
  final ApiClient _client;

  FeesApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetches fee records with optional filters.
  Future<ApiResponse<List<FeeModel>>> getAll({
    String? studentId,
    String? className,
    String? status,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (studentId != null && studentId.isNotEmpty) query['studentId'] = studentId;
      if (className != null && className.isNotEmpty) query['class'] = className;
      if (status != null && status.isNotEmpty) query['status'] = status;

      final response = await _client.get(
        ApiEndpoints.fees,
        queryParameters: query,
      );

      if (response is List) {
        final list = response.map((item) {
          final map = item as Map<String, dynamic>;
          final id = (map['id'] ?? map['_id'] ?? '').toString();
          return FeeModel.fromMap(id, map);
        }).toList();

        return ApiResponse<List<FeeModel>>(
          success: true,
          data: list,
        );
      }

      return ApiResponse<List<FeeModel>>(
        success: true,
        data: const [],
      );
    } on ApiException catch (e) {
      return ApiResponse<List<FeeModel>>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<List<FeeModel>>.error(e.toString());
    }
  }

  /// Fetches aggregated fee collection statistics.
  Future<ApiResponse<Map<String, dynamic>>> getStatistics() async {
    try {
      final response = await _client.get(ApiEndpoints.feeStatistics);
      if (response is Map<String, dynamic>) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response,
        );
      }
      return ApiResponse<Map<String, dynamic>>.error('Invalid statistics format');
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

  /// Creates a fee invoice.
  Future<ApiResponse<FeeModel>> create(FeeModel fee) async {
    try {
      final payload = {
        'studentId': fee.studentId,
        'studentName': fee.studentName,
        'className': fee.className,
        'feeType': fee.feeType,
        'amount': fee.amount,
        if (fee.dueDate != null) 'dueDate': fee.dueDate!.toIso8601String(),
        if (fee.month != null) 'month': fee.month,
        if (fee.year != null) 'year': fee.year,
      };

      final response = await _client.post(
        ApiEndpoints.fees,
        body: payload,
      );

      if (response is Map<String, dynamic>) {
        final id = (response['id'] ?? response['_id'] ?? fee.id).toString();
        return ApiResponse<FeeModel>(
          success: true,
          data: FeeModel.fromMap(id, response),
          message: 'Fee record created successfully',
          statusCode: 201,
        );
      }

      return ApiResponse<FeeModel>.error('Failed to create fee record');
    } on ApiException catch (e) {
      return ApiResponse<FeeModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<FeeModel>.error(e.toString());
    }
  }

  /// Submits fee payment proof (student/parent).
  Future<ApiResponse<FeeModel>> submitPayment({
    required String feeId,
    required String receiptUrl,
    required String paymentMethod,
    String? transactionId,
  }) async {
    try {
      final body = <String, dynamic>{
        'receiptUrl': receiptUrl,
        'paymentMethod': paymentMethod,
      };
      if (transactionId != null) body['transactionId'] = transactionId;

      final response = await _client.post(
        ApiEndpoints.feePay(feeId),
        body: body,
      );

      if (response is Map<String, dynamic>) {
        final id = (response['id'] ?? response['_id'] ?? feeId).toString();
        return ApiResponse<FeeModel>(
          success: true,
          data: FeeModel.fromMap(id, response),
          message: 'Payment proof submitted successfully',
        );
      }

      return ApiResponse<FeeModel>.error('Failed to submit payment');
    } on ApiException catch (e) {
      return ApiResponse<FeeModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<FeeModel>.error(e.toString());
    }
  }

  /// Verifies or rejects payment proof (admin action).
  Future<ApiResponse<FeeModel>> verifyPayment({
    required String feeId,
    required bool approved,
    String? remarks,
  }) async {
    try {
      final body = <String, dynamic>{
        'status': approved ? 'paid' : 'rejected',
      };
      if (remarks != null) body['remarks'] = remarks;

      final response = await _client.put(
        ApiEndpoints.feeVerify(feeId),
        body: body,
      );

      if (response is Map<String, dynamic>) {
        final id = (response['id'] ?? response['_id'] ?? feeId).toString();
        return ApiResponse<FeeModel>(
          success: true,
          data: FeeModel.fromMap(id, response),
          message: 'Payment verification status updated',
        );
      }

      return ApiResponse<FeeModel>.error('Failed to verify payment');
    } on ApiException catch (e) {
      return ApiResponse<FeeModel>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<FeeModel>.error(e.toString());
    }
  }
}
