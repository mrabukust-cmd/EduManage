import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const String tokenStorageKey = 'edumanage_jwt_auth_token';

  final http.Client _client;
  String? _authToken;

  String? get authToken => _authToken;

  /// Loads token stored in SharedPreferences if available.
  Future<void> initAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(tokenStorageKey);
    } catch (_) {
      // Ignored if storage is unavailable (e.g. unit tests)
    }
  }

  /// Sets the bearer auth token, optionally persisting to SharedPreferences.
  void setAuthToken(String? token, {bool persist = true}) {
    _authToken = token;
    if (persist) {
      SharedPreferences.getInstance().then((prefs) {
        if (token != null && token.isNotEmpty) {
          prefs.setString(tokenStorageKey, token);
        } else {
          prefs.remove(tokenStorageKey);
        }
      }).catchError((_) {});
    }
  }

  /// Clears active auth token from memory and persistent storage.
  void clearAuthToken() {
    setAuthToken(null, persist: true);
  }

  Uri _buildUri(String url, [Map<String, dynamic>? queryParams]) {
    final uri = Uri.parse(url);
    if (queryParams == null || queryParams.isEmpty) {
      return uri;
    }

    final mergedParams = Map<String, dynamic>.from(uri.queryParameters);
    queryParams.forEach((key, value) {
      if (value != null) {
        mergedParams[key] = value.toString();
      }
    });

    return uri.replace(queryParameters: mergedParams);
  }

  Map<String, String> _headers([Map<String, String>? extra]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  Future<dynamic> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final uri = _buildUri(url, queryParameters);
      final response = await _client
          .get(uri, headers: _headers(headers))
          .timeout(timeout);
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Network error: Unable to connect to server');
    } on http.ClientException catch (e) {
      throw ApiException('Client error: ${e.message}');
    }
  }

  Future<dynamic> post(
    String url, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final uri = _buildUri(url, queryParameters);
      final response = await _client
          .post(
            uri,
            headers: _headers(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Network error: Unable to connect to server');
    } on http.ClientException catch (e) {
      throw ApiException('Client error: ${e.message}');
    }
  }

  Future<dynamic> put(
    String url, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final uri = _buildUri(url, queryParameters);
      final response = await _client
          .put(
            uri,
            headers: _headers(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Network error: Unable to connect to server');
    } on http.ClientException catch (e) {
      throw ApiException('Client error: ${e.message}');
    }
  }

  Future<dynamic> patch(
    String url, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final uri = _buildUri(url, queryParameters);
      final response = await _client
          .patch(
            uri,
            headers: _headers(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Network error: Unable to connect to server');
    } on http.ClientException catch (e) {
      throw ApiException('Client error: ${e.message}');
    }
  }

  Future<dynamic> delete(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final uri = _buildUri(url, queryParameters);
      final response = await _client
          .delete(uri, headers: _headers(headers))
          .timeout(timeout);
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Network error: Unable to connect to server');
    } on http.ClientException catch (e) {
      throw ApiException('Client error: ${e.message}');
    }
  }

  /// Sends a request and wraps the result in a strongly typed ApiResponse<T>.
  Future<ApiResponse<T>> request<T>(
    Future<dynamic> Function() caller, {
    T Function(dynamic json)? mapper,
  }) async {
    try {
      final raw = await caller();
      if (raw is Map<String, dynamic> && raw.containsKey('success')) {
        return ApiResponse<T>.fromJson(raw, mapper);
      }
      final parsed = mapper != null ? mapper(raw) : raw as T;
      return ApiResponse<T>(
        success: true,
        data: parsed,
        statusCode: 200,
      );
    } on ApiException catch (e) {
      return ApiResponse<T>.error(
        e.message,
        statusCode: e.statusCode,
        errors: e.data,
      );
    } catch (e) {
      return ApiResponse<T>.error(
        e.toString(),
        statusCode: 500,
      );
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(response.body);
    } catch (_) {
      jsonBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (jsonBody is Map<String, dynamic> && jsonBody.containsKey('data')) {
        return jsonBody['data'];
      }
      return jsonBody;
    }

    final message = jsonBody is Map<String, dynamic> && jsonBody.containsKey('message')
        ? jsonBody['message'] as String
        : 'Request failed with status ${response.statusCode}';

    throw ApiException(
      message,
      statusCode: response.statusCode,
      data: jsonBody,
    );
  }

  void dispose() {
    _client.close();
  }
}
