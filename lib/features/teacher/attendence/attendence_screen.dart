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

final studentAttendanceStreamProvider = StreamProvider.family.autoDispose<List<StudentAttendance>, String>((ref, selectedClass) {
  return FirebaseFirestore.instance
      .collection('students')
      .where('class', isEqualTo: selectedClass)
      .orderBy('name')
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

final attendanceStatusesProvider = StateNotifierProvider.autoDispose<AttendanceStatusNotifier, Map<String, AttendanceStatus>>((ref) {
  return AttendanceStatusNotifier();
});

class AttendanceStatusNotifier extends StateNotifier<Map<String, AttendanceStatus>> {
  AttendanceStatusNotifier() : super({});

  void setStatus(String id, AttendanceStatus status) {
    state = {...state, id: status};
  }

  void markAll(List<String> ids, AttendanceStatus status) {
    state = {for (final id in ids) id: status};
  }
}

// ── Attendance Screen ─────────────────────────────────────────────────────────
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String _selectedClass = '';
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final classNamesAsync = ref.watch(teacherAssignedClassesProvider);
    final attendanceStatuses = ref.watch(attendanceStatusesProvider);
    final notifier = ref.read(attendanceStatusesProvider.notifier);

    final classOptions = classNamesAsync.when(
      data: (classes) => classes.isEmpty ? const ['No classes assigned'] : classes,
      loading: () => const ['Loading classes...'],
      error: (_, __) => const ['Unable to load classes'],
    );

    final selectedClassValue = classOptions.contains(_selectedClass) ? _selectedClass : classOptions.first;
    final isClassSelectable = classOptions.isNotEmpty && classOptions.first != 'No classes assigned' && classOptions.first != 'Loading classes...' && classOptions.first != 'Unable to load classes';
    final studentsAsync = isClassSelectable ? ref.watch(studentAttendanceStreamProvider(selectedClassValue)) : const AsyncValue.data(<StudentAttendance>[]);

    final totalCount = studentsAsync.when(data: (students) => students.length, loading: () => 0, error: (_, __) => 0);
    final presentCount = studentsAsync.when(data: (students) => students.where((student) => attendanceStatuses[student.id] == AttendanceStatus.present).length, loading: () => 0, error: (_, __) => 0);
    final absentCount = studentsAsync.when(data: (students) => students.where((student) => attendanceStatuses[student.id] == AttendanceStatus.absent).length, loading: () => 0, error: (_, __) => 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.teacherColor,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white), onPressed: () => context.pop()),
        title: Text('Mark Attendance', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedClassValue,
                dropdownColor: AppColors.teacherColor,
                style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                iconEnabledColor: Colors.white,
                items: classOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: isClassSelectable
                    ? (v) {
                        if (v == null) return;
                        setState(() {
                          _selectedClass = v;
                          _submitted = false;
                        });
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Summary Bar ────────────────────────────────────────
          Container(
            color: AppColors.teacherColor,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                _SummaryChip(label: 'Present', count: presentCount, color: Colors.greenAccent),
                const SizedBox(width: 10),
                _SummaryChip(label: 'Absent', count: absentCount, color: Colors.redAccent),
                const SizedBox(width: 10),
                _SummaryChip(label: 'Total', count: totalCount, color: Colors.white),
              ],
            ),
          ),

          // ── Mark All Row ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Text('Mark All:', style: AppTextStyles.bodyMediumBold),
                const SizedBox(width: 12),
                _MarkAllBtn(
                  label: 'Present',
                  color: Colors.green,
                  onTap: () => studentsAsync.whenData((students) {
                    notifier.markAll(students.map((s) => s.id).toList(), AttendanceStatus.present);
                  }),
                ),
                const SizedBox(width: 8),
                _MarkAllBtn(
                  label: 'Absent',
                  color: Colors.red,
                  onTap: () => studentsAsync.whenData((students) {
                    notifier.markAll(students.map((s) => s.id).toList(), AttendanceStatus.absent);
                  }),
                ),
              ],
            ),
          ),

          // ── Student List ──────────────────────────────────────
          Expanded(
            child: classNamesAsync.when(
              data: (classes) {
                if (!isClassSelectable) {
                  final message = classOptions.first == 'Loading classes...'
                      ? 'Loading your assigned classes...'
                      : classOptions.first == 'Unable to load classes'
                          ? 'Unable to load classes. Please try again.'
                          : 'No classes assigned. Ask admin to assign you to a class.';
                  return Center(
                    child: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                  );
                }

                return studentsAsync.when(
                  data: (students) {
                    if (students.isEmpty) {
                      return Center(
                        child: Text('No students found for $selectedClassValue.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final student = students[index];
                        final currentStatus = attendanceStatuses[student.id];
                        return _StudentAttRow(
                          student: student,
                          currentStatus: currentStatus,
                          onStatus: (status) => notifier.setStatus(student.id, status),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Unable to load students', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Unable to load your assigned classes', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))),
            ),
          ),

          // ── Submit Button ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: !_submitted && isClassSelectable && totalCount > 0
                    ? () {
                        setState(() => _submitted = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Attendance submitted successfully!'), backgroundColor: AppColors.teacherColor),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teacherColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_submitted ? 'Submitted ✓' : 'Submit Attendance', style: AppTextStyles.bodyMediumBold.copyWith(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Chip ──────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text('$count', style: AppTextStyles.statValue.copyWith(color: color, fontSize: 18)),
            Text(label, style: AppTextStyles.labelTiny.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Mark All Button ───────────────────────────────────────────────────────────
class _MarkAllBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MarkAllBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
        child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Student Attendance Row ────────────────────────────────────────────────────
class _StudentAttRow extends StatelessWidget {
  final StudentAttendance student;
  final AttendanceStatus? currentStatus;
  final ValueChanged<AttendanceStatus> onStatus;
  const _StudentAttRow({required this.student, required this.currentStatus, required this.onStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.teacherColor.withOpacity(0.12),
            child: Text(student.rollNo, style: AppTextStyles.labelSmall.copyWith(color: AppColors.teacherColor, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(student.name, style: AppTextStyles.bodyMediumBold)),
          // Status Buttons
          _StatusBtn(label: 'P', status: AttendanceStatus.present, current: currentStatus, color: Colors.green, onTap: () => onStatus(AttendanceStatus.present)),
          const SizedBox(width: 6),
          _StatusBtn(label: 'A', status: AttendanceStatus.absent, current: currentStatus, color: Colors.red, onTap: () => onStatus(AttendanceStatus.absent)),
          const SizedBox(width: 6),
          _StatusBtn(label: 'L', status: AttendanceStatus.late, current: currentStatus, color: Colors.orange, onTap: () => onStatus(AttendanceStatus.late)),
        ],
      ),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final AttendanceStatus status;
  final AttendanceStatus? current;
  final Color color;
  final VoidCallback onTap;
  const _StatusBtn({required this.label, required this.status, required this.current, required this.color, required this.onTap});

  bool get isSelected => status == current;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(isSelected ? 1 : 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: isSelected ? Colors.white : color, fontWeight: FontWeight.w700)),
      ),
    );
  }
}