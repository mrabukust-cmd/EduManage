import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assignment_model.dart';
import '../models/class_model.dart';
import '../models/fee_model.dart';
import '../models/notice_model.dart';
import '../models/result_model.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../services/api/api_services.dart';
import 'repository_providers.dart';

// ── API Service Instance Providers ──────────────────────────────
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(client: ref.watch(apiClientProvider));
});

final classesApiServiceProvider = Provider<ClassesApiService>((ref) {
  return ClassesApiService(client: ref.watch(apiClientProvider));
});

final studentsApiServiceProvider = Provider<StudentsApiService>((ref) {
  return StudentsApiService(client: ref.watch(apiClientProvider));
});

final teachersApiServiceProvider = Provider<TeachersApiService>((ref) {
  return TeachersApiService(client: ref.watch(apiClientProvider));
});

final attendanceApiServiceProvider = Provider<AttendanceApiService>((ref) {
  return AttendanceApiService(client: ref.watch(apiClientProvider));
});

final assignmentsApiServiceProvider = Provider<AssignmentsApiService>((ref) {
  return AssignmentsApiService(client: ref.watch(apiClientProvider));
});

final feesApiServiceProvider = Provider<FeesApiService>((ref) {
  return FeesApiService(client: ref.watch(apiClientProvider));
});

final noticesApiServiceProvider = Provider<NoticesApiService>((ref) {
  return NoticesApiService(client: ref.watch(apiClientProvider));
});

final timetableApiServiceProvider = Provider<TimetableApiService>((ref) {
  return TimetableApiService(client: ref.watch(apiClientProvider));
});

final resultsApiServiceProvider = Provider<ResultsApiService>((ref) {
  return ResultsApiService(client: ref.watch(apiClientProvider));
});

final dashboardApiServiceProvider = Provider<DashboardApiService>((ref) {
  return DashboardApiService(client: ref.watch(apiClientProvider));
});

// ── Async Data Providers for Screens & Widgets ──────────────────

/// Fetches list of all classes from the REST API
final apiClassesProvider = FutureProvider.autoDispose<List<ClassModel>>((ref) async {
  final service = ref.watch(classesApiServiceProvider);
  final res = await service.getAll();
  return res.data ?? [];
});

/// Fetches list of students with optional class filter
final apiStudentsProvider =
    FutureProvider.autoDispose.family<List<StudentModel>, String?>((ref, className) async {
  final service = ref.watch(studentsApiServiceProvider);
  final res = await service.getAll(className: className);
  return res.data ?? [];
});

/// Fetches list of all teachers
final apiTeachersProvider = FutureProvider.autoDispose<List<TeacherModel>>((ref) async {
  final service = ref.watch(teachersApiServiceProvider);
  final res = await service.getAll();
  return res.data ?? [];
});

/// Fetches notices list
final apiNoticesProvider = FutureProvider.autoDispose<List<NoticeModel>>((ref) async {
  final service = ref.watch(noticesApiServiceProvider);
  final res = await service.getAll();
  return res.data ?? [];
});

/// Fetches assignments by class
final apiAssignmentsProvider =
    FutureProvider.autoDispose.family<List<AssignmentModel>, String?>((ref, className) async {
  final service = ref.watch(assignmentsApiServiceProvider);
  final res = await service.getAll(className: className);
  return res.data ?? [];
});

/// Fetches fee records by student ID
final apiFeesProvider =
    FutureProvider.autoDispose.family<List<FeeModel>, String?>((ref, studentId) async {
  final service = ref.watch(feesApiServiceProvider);
  final res = await service.getAll(studentId: studentId);
  return res.data ?? [];
});

/// Fetches fee collection analytics
final apiFeeStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final service = ref.watch(feesApiServiceProvider);
  final res = await service.getStatistics();
  return res.data ?? {};
});

/// Fetches exam results by student ID
final apiResultsProvider =
    FutureProvider.autoDispose.family<List<ResultModel>, String?>((ref, studentId) async {
  final service = ref.watch(resultsApiServiceProvider);
  final res = await service.getAll(studentId: studentId);
  return res.data ?? [];
});

/// Fetches aggregated admin dashboard statistics
final apiAdminDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final service = ref.watch(dashboardApiServiceProvider);
  final res = await service.getAdminDashboard();
  return res.data ?? {};
});

/// Fetches student dashboard overview
final apiStudentDashboardProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String?>((ref, studentId) async {
  final service = ref.watch(dashboardApiServiceProvider);
  final res = await service.getStudentDashboard(studentId);
  return res.data ?? {};
});

/// Fetches teacher dashboard overview
final apiTeacherDashboardProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String?>((ref, teacherId) async {
  final service = ref.watch(dashboardApiServiceProvider);
  final res = await service.getTeacherDashboard(teacherId);
  return res.data ?? {};
});
