import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:school_management_system/core/constants/api_endpoints.dart';
import 'package:school_management_system/data/providers/repository_providers.dart';
import 'package:school_management_system/data/services/api_client.dart';

void main() {
  group('ApiClient Tests', () {
    test('ApiClient successfully parses data from JSON response', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/classes') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {'id': '1', 'name': 'Grade 9 - A'}
              ]
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final result = await apiClient.get('http://localhost:5000/api/v1/classes');

      expect(result, isA<List>());
      expect((result as List).first['name'], 'Grade 9 - A');
    });

    test('ApiClient attaches Bearer token to Authorization header', () async {
      String? sentAuthHeader;

      final mockClient = MockClient((request) async {
        sentAuthHeader = request.headers['Authorization'];
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      });

      final apiClient = ApiClient(client: mockClient);
      apiClient.setAuthToken('sample_jwt_token_123');

      await apiClient.get('http://localhost:5000/api/v1/auth/me');

      expect(sentAuthHeader, 'Bearer sample_jwt_token_123');
    });

    test('ApiClient throws ApiException on error response code', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Invalid credentials',
          }),
          401,
        );
      });

      final apiClient = ApiClient(client: mockClient);

      expect(
        () => apiClient.post(
          'http://localhost:5000/api/v1/auth/login',
          body: {'email': 'test@test.com', 'password': 'wrong'},
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Invalid credentials',
          ),
        ),
      );
    });

    test('ApiEndpoints formats URLs appropriately', () {
      expect(ApiEndpoints.login.contains('/auth/login'), isTrue);
      expect(ApiEndpoints.classes.contains('/classes'), isTrue);
      expect(ApiEndpoints.attendance.contains('/attendance'), isTrue);
    });

    test('Repository Providers resolve via ProviderContainer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final client = container.read(apiClientProvider);
      expect(client, isA<ApiClient>());

      final classRepo = container.read(classRepositoryProvider);
      expect(classRepo, isNotNull);

      final studentRepo = container.read(studentRepositoryProvider);
      expect(studentRepo, isNotNull);

      final teacherRepo = container.read(teacherRepositoryProvider);
      expect(teacherRepo, isNotNull);
    });
  });
}
