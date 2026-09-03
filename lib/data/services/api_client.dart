import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

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

  final http.Client _client;
  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
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

  Future<dynamic> get(String url, {Map<String, String>? headers}) async {
    try {
      final response = await _client
          .get(Uri.parse(url), headers: _headers(headers))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Network error: Unable to connect to server');
    } on http.ClientException catch (e) {
      throw ApiException('Client error: ${e.message}');
    }
  }

  Future<dynamic> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: _headers(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Network error: Unable to connect to server');
    } on http.ClientException catch (e) {
      throw ApiException('Client error: ${e.message}');
    }
  }

  Future<dynamic> put(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .put(
            Uri.parse(url),
            headers: _headers(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Network error: Unable to connect to server');
    } on http.ClientException catch (e) {
      throw ApiException('Client error: ${e.message}');
    }
  }

  Future<dynamic> delete(String url, {Map<String, String>? headers}) async {
    try {
      final response = await _client
          .delete(Uri.parse(url), headers: _headers(headers))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Network error: Unable to connect to server');
    } on http.ClientException catch (e) {
      throw ApiException('Client error: ${e.message}');
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
