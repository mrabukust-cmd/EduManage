/// Standardized API response wrapper for EduManage client communication.
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;
  final dynamic errors;
  final Map<String, dynamic>? meta;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
    this.errors,
    this.meta,
  });

  bool get isSuccess => success && (statusCode == null || (statusCode! >= 200 && statusCode! < 300));
  bool get hasError => !success || (statusCode != null && statusCode! >= 400);

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, [
    T Function(dynamic data)? fromData,
  ]) {
    final rawData = json['data'];
    T? parsedData;

    if (rawData != null && fromData != null) {
      parsedData = fromData(rawData);
    } else if (rawData != null && rawData is T) {
      parsedData = rawData;
    }

    return ApiResponse<T>(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
      data: parsedData,
      statusCode: json['statusCode'] as int?,
      errors: json['errors'],
      meta: json['meta'] as Map<String, dynamic>? ??
          (json['pagination'] as Map<String, dynamic>?),
    );
  }

  factory ApiResponse.error(String message, {int? statusCode, dynamic errors}) {
    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (data != null) 'data': data,
      if (statusCode != null) 'statusCode': statusCode,
      if (errors != null) 'errors': errors,
      if (meta != null) 'meta': meta,
    };
  }

  @override
  String toString() =>
      'ApiResponse(success: $success, message: $message, statusCode: $statusCode, data: $data)';
}
