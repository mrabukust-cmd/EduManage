import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../models/class_model.dart';

import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/notice_model.dart';
import '../repositories/assignment_repo.dart';
import '../repositories/attendence_repo.dart';
import '../repositories/auth_repository.dart';
import '../repositories/class_repo.dart';
import '../repositories/fee_repo.dart';
import '../repositories/notice_repo.dart';
import '../repositories/result_repo.dart';
import '../repositories/student_repository.dart';
import '../repositories/teacher_repo.dart';
import '../repositories/timetable_repo.dart';
import '../services/api_client.dart';

// ── API Client Provider ───────────────────────────────────────
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(() => client.dispose());
  return client;
});

// ── Repository Providers ──────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository.instance;
});

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepository.instance;
});

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository.instance;
});

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepository.instance;
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository.instance;
});


final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository.instance;
});

final feeRepositoryProvider = Provider<FeeRepository>((ref) {
  return FeeRepository.instance;
});

final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  return NoticeRepository.instance;
});

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository.instance;
});

final resultRepositoryProvider = Provider<ResultRepository>((ref) {
  return ResultRepository.instance;
});

// ── Common Stream / Query Providers ───────────────────────────
/// Streams all registered classes
final classesStreamProvider = StreamProvider<List<ClassModel>>((ref) {
  return ref.watch(classRepositoryProvider).watchAll();
});

/// Streams sorted unique class names
final classNamesStreamProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(classRepositoryProvider).watchClassNames();
});

/// Streams total registered classes count
final classesCountProvider = StreamProvider<int>((ref) {
  return ref.watch(classRepositoryProvider).watchTotalCount();
});

/// Streams all students
final studentsStreamProvider = StreamProvider<List<StudentModel>>((ref) {
  return ref.watch(studentRepositoryProvider).watchAll();
});

/// Streams students belonging to a specific class
final studentsByClassProvider =
    StreamProvider.family<List<StudentModel>, String>((ref, className) {
  return ref.watch(studentRepositoryProvider).watchByClass(className);
});

/// Streams student count by class
final studentCountByClassProvider =
    StreamProvider.family<int, String>((ref, className) {
  return ref.watch(studentRepositoryProvider).watchCountByClass(className);
});

/// Streams total students count
final studentsTotalCountProvider = StreamProvider<int>((ref) {
  return ref.watch(studentRepositoryProvider).watchTotalCount();
});

/// Streams all teachers
final teachersStreamProvider = StreamProvider<List<TeacherModel>>((ref) {
  return ref.watch(teacherRepositoryProvider).watchAll();
});

/// Streams only approved teachers
final approvedTeachersProvider = StreamProvider<List<TeacherModel>>((ref) {
  return ref.watch(teacherRepositoryProvider).watchAll().map(
        (list) => list.where((t) => t.approved).toList(),
      );
});

/// Streams total teachers count
final teachersTotalCountProvider = StreamProvider<int>((ref) {
  return ref.watch(teacherRepositoryProvider).watchTotalCount();
});

/// Streams all active notices
final noticesStreamProvider = StreamProvider<List<NoticeModel>>((ref) {
  return ref.watch(noticeRepositoryProvider).watchAll();
});

/// Streams total notices count
final noticesTotalCountProvider = StreamProvider<int>((ref) {
  return ref.watch(noticeRepositoryProvider).watchAll().map((list) => list.length);
});

// ── Admin Activity Event ──────────────────────────────────────
class AdminActivityEvent {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime? time;
  final String? route;

  const AdminActivityEvent({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.time,
    this.route,
  });
}

/// Provides activity stream from notices for admin feeds
final adminRecentActivityProvider =
    StreamProvider<List<AdminActivityEvent>>((ref) {
  return ref.watch(noticeRepositoryProvider).watchAll().map((notices) {
    return notices.map((n) {
      return AdminActivityEvent(
        title: 'Notice: ${n.title}',
        subtitle: n.category,
        icon: Icons.campaign_rounded,
        color: AppColors.accent,
        time: n.createdAt,
        route: '/admin/home/notices',
      );
    }).toList();
  });
});



