import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'attendence_screen.dart';

/// Shows registered students of ONE class and lets the teacher mark
/// and submit attendance. Written records are immediately visible in
/// StudentAttendanceScreen and ParentAttendanceScreen because they both
/// query: attendance WHERE studentId == uid AND date == today.
class ClassAttendanceScreen extends ConsumerStatefulWidget {
  final String className;
  const ClassAttendanceScreen({super.key, required this.className});

  @override
  ConsumerState<ClassAttendanceScreen> createState() =>
      _ClassAttendanceScreenState();
}

class _ClassAttendanceScreenState extends ConsumerState<ClassAttendanceScreen> {
  bool _submitting = false;
  bool _submitted = false;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submitAttendance(
    List<StudentAttendance> students,
    Map<String, AttendanceStatus> statuses,
  ) async {
    setState(() => _submitting = true);
    try {
      final teacherId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final db = FirebaseFirestore.instance;

      // Use a batch write for atomicity.
      // Each document: attendance/{studentId}_{date}
      // This allows upsert (teacher can re-submit to correct mistakes).
      // Student and parent screens query: studentId == uid, date == dateStr
      final batch = db.batch();

      for (final student in students) {
        final status = statuses[student.id] ?? AttendanceStatus.absent;
        // Deterministic doc ID = easy upsert + no duplicate records per day
        final docRef = db
            .collection('attendance')
            .doc('${student.id}_$_todayKey');
        batch.set(docRef, {
          'studentId': student.id,
          'studentName': student.name,
          'className': widget.className,
          'date': _todayKey,
          'status': status.name, // 'present' | 'absent' | 'late'
          'markedBy': teacherId,
          'timestamp': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Attendance for ${widget.className} submitted successfully!'),
          backgroundColor: AppColors.teacherColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit attendance: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync =
        ref.watch(studentAttendanceStreamProvider(widget.className));
    final attendanceStatuses =
        ref.watch(attendanceStatusesProvider(widget.className));
    final notifier =
        ref.read(attendanceStatusesProvider(widget.className).notifier);

    final totalCount = studentsAsync.when(
      data: (s) => s.length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final presentCount = studentsAsync.when(
      data: (s) => s
          .where((st) => attendanceStatuses[st.id] == AttendanceStatus.present)
          .length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final absentCount = studentsAsync.when(
      data: (s) => s
          .where((st) => attendanceStatuses[st.id] == AttendanceStatus.absent)
          .length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final lateCount = studentsAsync.when(
      data: (s) => s
          .where((st) => attendanceStatuses[st.id] == AttendanceStatus.late)
          .length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.teacherColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.className,
          style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // ── Summary Bar ──────────────────────────────────────
          Container(
            color: AppColors.teacherColor,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                _SummaryChip(
                    label: 'Present', count: presentCount, color: Colors.greenAccent),
                const SizedBox(width: 8),
                _SummaryChip(
                    label: 'Absent', count: absentCount, color: Colors.redAccent),
                const SizedBox(width: 8),
                _SummaryChip(
                    label: 'Late', count: lateCount, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                _SummaryChip(
                    label: 'Total', count: totalCount, color: Colors.white),
              ],
            ),
          ),

          // ── Mark All Row ─────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Text('Mark All:', style: AppTextStyles.bodyMediumBold),
                const SizedBox(width: 12),
                _MarkAllBtn(
                  label: 'Present',
                  color: Colors.green,
                  onTap: () => studentsAsync.whenData((students) {
                    notifier.markAll(
                        students.map((s) => s.id).toList(),
                        AttendanceStatus.present);
                  }),
                ),
                const SizedBox(width: 8),
                _MarkAllBtn(
                  label: 'Absent',
                  color: Colors.red,
                  onTap: () => studentsAsync.whenData((students) {
                    notifier.markAll(
                        students.map((s) => s.id).toList(),
                        AttendanceStatus.absent);
                  }),
                ),
              ],
            ),
          ),

          // ── Student List ─────────────────────────────────────
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline_rounded,
                              size: 64, color: AppColors.textHint),
                          const SizedBox(height: 16),
                          Text(
                            'No students enrolled in ${widget.className}.\n'
                            'Add students with this class assigned to see them here.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
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
                      onStatus: (status) =>
                          notifier.setStatus(student.id, status),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text('Unable to load students',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ),
          ),

          // ── Submit Button ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting || totalCount == 0 || _submitted
                    ? null
                    : () async {
                        final statuses = ref
                            .read(attendanceStatusesProvider(widget.className));
                        final students =
                            studentsAsync.asData?.value ?? [];
                        await _submitAttendance(students, statuses);
                      },
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(_submitted
                        ? Icons.check_circle_rounded
                        : Icons.save_rounded),
                label: Text(_submitting
                    ? 'Submitting...'
                    : _submitted
                        ? 'Submitted ✓'
                        : 'Submit Attendance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _submitted
                      ? AppColors.success
                      : AppColors.teacherColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
  const _SummaryChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color,
                )),
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
  const _MarkAllBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Student Attendance Row ────────────────────────────────────────────────────
class _StudentAttRow extends StatelessWidget {
  final StudentAttendance student;
  final AttendanceStatus? currentStatus;
  final ValueChanged<AttendanceStatus> onStatus;
  const _StudentAttRow(
      {required this.student,
      required this.currentStatus,
      required this.onStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.teacherColor.withOpacity(0.12),
            child: Text(
              student.rollNo,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.teacherColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(student.name, style: AppTextStyles.bodyMediumBold),
          ),
          _StatusBtn(
            label: 'P',
            status: AttendanceStatus.present,
            current: currentStatus,
            color: Colors.green,
            onTap: () => onStatus(AttendanceStatus.present),
          ),
          const SizedBox(width: 6),
          _StatusBtn(
            label: 'A',
            status: AttendanceStatus.absent,
            current: currentStatus,
            color: Colors.red,
            onTap: () => onStatus(AttendanceStatus.absent),
          ),
          const SizedBox(width: 6),
          _StatusBtn(
            label: 'L',
            status: AttendanceStatus.late,
            current: currentStatus,
            color: Colors.orange,
            onTap: () => onStatus(AttendanceStatus.late),
          ),
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
  const _StatusBtn({
    required this.label,
    required this.status,
    required this.current,
    required this.color,
    required this.onTap,
  });

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
          border: Border.all(
              color: color.withOpacity(isSelected ? 1 : 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}