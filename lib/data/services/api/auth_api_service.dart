import '../../../core/constants/api_endpoints.dart';
import '../../models/api_response.dart';
import '../api_client.dart';

class AuthApiService {
  final ApiClient _client;

  AuthApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Logs in a user with email and password, returning user data and token.
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.login,
        body: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      if (response is Map<String, dynamic>) {
        final token = response['token'] as String?;
        if (token != null && token.isNotEmpty) {
          _client.setAuthToken(token, persist: true);
        }
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response,
          message: 'Login successful',
        );
      }

      return ApiResponse<Map<String, dynamic>>.error('Invalid response format');
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

  /// Registers a new user (teacher, student, parent).
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.register,
        body: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'role': role,
          if (phone != null) 'phone': phone.trim(),
        },
      );

      if (response is Map<String, dynamic>) {
        final token = response['token'] as String?;
        if (token != null && token.isNotEmpty) {
          _client.setAuthToken(token, persist: true);
        }
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response,
          message: 'Registration successful',
        );
      }

      return ApiResponse<Map<String, dynamic>>.error('Invalid response format');
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

  /// Fetches the profile of the currently authenticated user.
  Future<ApiResponse<Map<String, dynamic>>> getMe() async {
    try {
      final response = await _client.get(ApiEndpoints.me);
      if (response is Map<String, dynamic>) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response,
        );
      }
      return ApiResponse<Map<String, dynamic>>.error('Invalid profile data');
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

  /// Logs out by clearing active JWT token.
  void logout() {
    _client.clearAuthToken();
  }
}
