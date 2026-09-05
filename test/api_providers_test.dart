import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:school_management_system/data/providers/api_providers.dart';
import 'package:school_management_system/data/providers/repository_providers.dart';
import 'package:school_management_system/data/services/api_client.dart';

void main() {
  group('Riverpod API Providers Resolution Suite', () {
    late ProviderContainer container;

    setUp(() {
      final mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path == '/api/v1/classes') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 'class_1', 'name': 'Grade 9 - A'}
              ]
            }),
            200,
          );
        }

        if (path == '/api/v1/teachers') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 'teacher_1', 'name': 'Prof. John Smith', 'approved': true}
              ]
            }),
            200,
          );
        }

        if (path == '/api/v1/fees/statistics') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'totalCollected': 50000}
            }),
            200,
          );
        }

        if (path == '/api/v1/dashboard/admin') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'totalStudents': 120}
            }),
            200,
          );
        }

        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(client: mockClient)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('All API service providers resolve without error', () {
      expect(container.read(authApiServiceProvider), isNotNull);
      expect(container.read(classesApiServiceProvider), isNotNull);
      expect(container.read(studentsApiServiceProvider), isNotNull);
      expect(container.read(teachersApiServiceProvider), isNotNull);
      expect(container.read(attendanceApiServiceProvider), isNotNull);
      expect(container.read(assignmentsApiServiceProvider), isNotNull);
      expect(container.read(feesApiServiceProvider), isNotNull);
      expect(container.read(noticesApiServiceProvider), isNotNull);
      expect(container.read(timetableApiServiceProvider), isNotNull);
      expect(container.read(resultsApiServiceProvider), isNotNull);
      expect(container.read(dashboardApiServiceProvider), isNotNull);
    });

    test('apiClassesProvider loads classes from mock backend', () async {
      final classes = await container.read(apiClassesProvider.future);
      expect(classes.length, 1);
      expect(classes.first.name, 'Grade 9 - A');
    });

    test('apiTeachersProvider loads teachers correctly', () async {
      final teachers = await container.read(apiTeachersProvider.future);
      expect(teachers.length, 1);
      expect(teachers.first.name, 'Prof. John Smith');
    });

    test('apiFeeStatsProvider loads stats data', () async {
      final stats = await container.read(apiFeeStatsProvider.future);
      expect(stats['totalCollected'], 50000);
    });

    test('apiAdminDashboardProvider loads dashboard data', () async {
      final data = await container.read(apiAdminDashboardProvider.future);
      expect(data['totalStudents'], 120);
    });
  });
}
