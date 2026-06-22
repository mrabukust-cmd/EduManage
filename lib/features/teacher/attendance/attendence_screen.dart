import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

// ── Attendance Status Enum ────────────────────────────────────────────────────
enum AttendanceStatus { present, absent, late, leave }

// ── Student Attendance Model ──────────────────────────────────────────────────
class StudentAttendance {
  final String id;
  final String name;
  final String rollNo;
  final String className;
  const StudentAttendance({required this.id, required this.name, required this.rollNo, required this.className});
}

// ── Providers ──────────────────────────────────────────────────────────────────

/// Real classes assigned to the logged-in teacher (from their `teachers` doc's
/// `classes` field, falling back to matching `classTeacher` in `classes`).
final teacherAssignedClassesProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final uid = ref.watch(authProvider).user?.uid;
  final teacherName = ref.watch(authProvider).user?.displayName?.trim() ?? '';
  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instance.collection('teachers').doc(uid).snapshots().asyncMap((snapshot) async {
    final data = snapshot.data() as Map<String, dynamic>?;
    final classesFromTeacher = (data?['classes'] as List<dynamic>?)
            ?.map((e) => e.toString().trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList() ??
        <String>[];
    if (classesFromTeacher.isNotEmpty) {
      classesFromTeacher.sort();
      return classesFromTeacher;
    }

    if (teacherName.isEmpty) {
      return <String>[];
    }

    final classSnapshot = await FirebaseFirestore.instance
        .collection('classes')
        .where('classTeacher', isEqualTo: teacherName)
        .get();

    final classesFromClasses = classSnapshot.docs
        .map((doc) => (doc.data()['name'] as String? ?? '').trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return classesFromClasses;
  });
});

/// Live count of registered students for a given class name.
final classStudentCountProvider = StreamProvider.family.autoDispose<int, String>((ref, className) {
  return FirebaseFirestore.instance
      .collection('students')
      .where('class', isEqualTo: className)
      .snapshots()
      .map((snap) => snap.docs.length);
});

/// Registered students for a given class name.
final studentAttendanceStreamProvider = StreamProvider.family.autoDispose<List<StudentAttendance>, String>((ref, selectedClass) {
  return FirebaseFirestore.instance
      .collection('students')
      .where('class', isEqualTo: selectedClass)
      .snapshots()
      .map((snapshot) {
    final students = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return StudentAttendance(
        id: doc.id,
        name: data['name'] as String? ?? 'Unknown',
        rollNo: data['rollNo'] as String? ?? '-',
        className: data['class'] as String? ?? '',
      );
    }).toList();
    students.sort((a, b) => a.name.compareTo(b.name));
    return students;
  });
});

/// Per-class attendance marking state (kept separate per className so
/// switching classes never leaks one class's marks into another).
final attendanceStatusesProvider =
    StateNotifierProvider.autoDispose.family<AttendanceStatusNotifier, Map<String, AttendanceStatus>, String>(
  (ref, className) => AttendanceStatusNotifier(),
);

class AttendanceStatusNotifier extends StateNotifier<Map<String, AttendanceStatus>> {
  AttendanceStatusNotifier() : super({});

  void setStatus(String id, AttendanceStatus status) {
    state = {...state, id: status};
  }

  void markAll(List<String> ids, AttendanceStatus status) {
    state = {for (final id in ids) id: status};
  }
}

// ── Attendance Screen (class picker) ──────────────────────────────────────────
class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(teacherAssignedClassesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.teacherColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Mark Attendance', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.class_outlined, size: 64, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    Text(
                      'No classes assigned yet.\nAsk admin to assign you to a class.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: classes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ClassSelectCard(className: classes[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'Unable to load your assigned classes',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ── Class Select Card ─────────────────────────────────────────────────────────
class _ClassSelectCard extends ConsumerWidget {
  final String className;
  const _ClassSelectCard({required this.className});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(classStudentCountProvider(className));

    return GestureDetector(
      onTap: () => context.push('/teacher/home/attendance/class_attendence', extra: className),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.teacherColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.class_rounded, color: AppColors.teacherColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(className, style: AppTextStyles.bodyMediumBold),
                  const SizedBox(height: 4),
                  countAsync.when(
                    data: (count) => Text('$count registered students', style: AppTextStyles.labelSmall),
                    loading: () => Text('Loading students...', style: AppTextStyles.labelSmall),
                    error: (_, __) => Text('Unable to load count', style: AppTextStyles.labelSmall),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}