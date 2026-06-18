import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';


// ── Attendance Status Enum ────────────────────────────────────────────────────
enum AttendanceStatus { present, absent, late, leave }

// ── Student Attendance Model ──────────────────────────────────────────────────
class StudentAttendance {
  final String id, name, rollNo;
  AttendanceStatus status;
  StudentAttendance({required this.id, required this.name, required this.rollNo, this.status = AttendanceStatus.present});
}

// ── Provider ──────────────────────────────────────────────────────────────────
final attendanceProvider = StateNotifierProvider.autoDispose<AttendanceNotifier, List<StudentAttendance>>((ref) {
  return AttendanceNotifier();
});

class AttendanceNotifier extends StateNotifier<List<StudentAttendance>> {
  AttendanceNotifier() : super(_mockStudents());

  void setStatus(String id, AttendanceStatus status) {
    state = [for (final s in state) if (s.id == id) (s..status = status) else s];
  }

  void markAll(AttendanceStatus status) {
    state = [for (final s in state) (s..status = status)];
  }

  static List<StudentAttendance> _mockStudents() => [
    StudentAttendance(id: '1', name: 'Ali Khan', rollNo: '01'),
    StudentAttendance(id: '2', name: 'Sara Noor', rollNo: '02'),
    StudentAttendance(id: '3', name: 'Usman Tariq', rollNo: '03'),
    StudentAttendance(id: '4', name: 'Ayesha Malik', rollNo: '04'),
    StudentAttendance(id: '5', name: 'Bilal Ahmed', rollNo: '05'),
    StudentAttendance(id: '6', name: 'Fatima Rizvi', rollNo: '06'),
    StudentAttendance(id: '7', name: 'Zain ul Abideen', rollNo: '07'),
    StudentAttendance(id: '8', name: 'Hira Baig', rollNo: '08'),
  ];
}

// ── Attendance Screen ─────────────────────────────────────────────────────────
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String _selectedClass = 'Grade 9A';
  final _classes = ['Grade 8B', 'Grade 9A', 'Grade 10B'];
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(attendanceProvider);
    final notifier = ref.read(attendanceProvider.notifier);

    final presentCount = students.where((s) => s.status == AttendanceStatus.present).length;
    final absentCount  = students.where((s) => s.status == AttendanceStatus.absent).length;

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
                value: _selectedClass,
                dropdownColor: AppColors.teacherColor,
                style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                iconEnabledColor: Colors.white,
                items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedClass = v!),
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
                _SummaryChip(label: 'Total', count: students.length, color: Colors.white),
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
                _MarkAllBtn(label: 'Present', color: Colors.green, onTap: () => notifier.markAll(AttendanceStatus.present)),
                const SizedBox(width: 8),
                _MarkAllBtn(label: 'Absent', color: Colors.red, onTap: () => notifier.markAll(AttendanceStatus.absent)),
              ],
            ),
          ),

          // ── Student List ──────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final s = students[i];
                return _StudentAttRow(
                  student: s,
                  onStatus: (status) => notifier.setStatus(s.id, status),
                );
              },
            ),
          ),

          // ── Submit Button ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitted ? null : () {
                  setState(() => _submitted = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attendance submitted successfully!'), backgroundColor: AppColors.teacherColor),
                  );
                },
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
  final ValueChanged<AttendanceStatus> onStatus;
  const _StudentAttRow({required this.student, required this.onStatus});

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
          _StatusBtn(label: 'P', status: AttendanceStatus.present, current: student.status, color: Colors.green, onTap: () => onStatus(AttendanceStatus.present)),
          const SizedBox(width: 6),
          _StatusBtn(label: 'A', status: AttendanceStatus.absent, current: student.status, color: Colors.red, onTap: () => onStatus(AttendanceStatus.absent)),
          const SizedBox(width: 6),
          _StatusBtn(label: 'L', status: AttendanceStatus.late, current: student.status, color: Colors.orange, onTap: () => onStatus(AttendanceStatus.late)),
        ],
      ),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final AttendanceStatus status, current;
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