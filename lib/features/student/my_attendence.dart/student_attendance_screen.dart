import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

// ── Place this file at:
// lib/features/student/attendance/student_attendance_screen.dart
//
// Firestore: teachers write to 'attendance' collection when they submit.
// Update attendence_screen.dart submit button to also write records:
//
//   Future<void> _submitAttendance(Map<String,AttendanceStatus> statuses,
//       List<StudentAttendance> students, String className) async {
//     final batch = FirebaseFirestore.instance.batch();
//     final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     for (final s in students) {
//       final status = statuses[s.id] ?? AttendanceStatus.absent;
//       final ref = FirebaseFirestore.instance
//           .collection('attendance')
//           .doc('${s.id}_$dateStr');
//       batch.set(ref, {
//         'studentId': s.id,
//         'studentName': s.name,
//         'className': className,
//         'date': dateStr,
//         'status': status.name,   // 'present', 'absent', 'late'
//         'createdAt': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//     }
//     await batch.commit();
//   }
//
// Add route under /student/home:
//   GoRoute(path: 'attendance',
//       builder: (_, __) => const StudentAttendanceScreen()),
//
// Required Firestore index:
//   collection: attendance, fields: studentId (ASC), date (DESC)

class StudentAttendanceScreen extends ConsumerWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authProvider).user?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.studentColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('My Attendance',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('studentId', isEqualTo: uid)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _EmptyAttendance();
                }

                // Compute stats
                int present = 0, absent = 0, late = 0;
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] as String? ?? 'absent';
                  if (status == 'present') present++;
                  else if (status == 'absent') absent++;
                  else if (status == 'late') late++;
                }
                final total = docs.length;
                final pct =
                    total > 0 ? (present + late * 0.5) / total : 0.0;

                // Group by month
                final Map<String, List<QueryDocumentSnapshot>> grouped = {};
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final dateStr = data['date'] as String? ?? '';
                  try {
                    final dt = DateTime.parse(dateStr);
                    final key = DateFormat('MMMM yyyy').format(dt);
                    grouped.putIfAbsent(key, () => []).add(doc);
                  } catch (_) {
                    grouped.putIfAbsent('Other', () => []).add(doc);
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // ── Summary card ─────────────────────────────
                    _SummaryCard(
                      pct: pct,
                      present: present,
                      absent: absent,
                      late: late,
                      total: total,
                    ),
                    const SizedBox(height: 24),

                    // ── Monthly breakdown ─────────────────────────
                    ...grouped.entries.expand((entry) => [
                          _MonthHeader(label: entry.key),
                          ...entry.value.map((doc) {
                            final data =
                                doc.data() as Map<String, dynamic>;
                            return _AttendanceRow(data: data);
                          }),
                          const SizedBox(height: 8),
                        ]),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final double pct;
  final int present, absent, late, total;
  const _SummaryCard({
    required this.pct,
    required this.present,
    required this.absent,
    required this.late,
    required this.total,
  });

  Color get _pctColor {
    if (pct >= 0.85) return AppColors.success;
    if (pct >= 0.70) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(children: [
        Row(children: [
          // Circular progress
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: pct,
                strokeWidth: 8,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(_pctColor),
              ),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _pctColor)),
              ]),
            ]),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attendance Overview',
                      style: AppTextStyles.bodyMediumBold),
                  const SizedBox(height: 10),
                  _StatRow(label: 'Present', value: '$present days',
                      color: AppColors.success),
                  _StatRow(label: 'Absent', value: '$absent days',
                      color: AppColors.danger),
                  _StatRow(label: 'Late', value: '$late days',
                      color: AppColors.warning),
                  _StatRow(label: 'Total', value: '$total days',
                      color: AppColors.textSecondary),
                ]),
          ),
        ]),
        if (pct < 0.75) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.danger.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.danger, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your attendance is below 75%. '
                  'Please attend classes regularly.',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.danger),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: ',
            style: AppTextStyles.labelSmall),
        Text(value,
            style: AppTextStyles.labelSmall
                .copyWith(fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
      ]),
    );
  }
}

// ── Month header ──────────────────────────────────────────────────────────────
class _MonthHeader extends StatelessWidget {
  final String label;
  const _MonthHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(width: 4, height: 16,
            decoration: BoxDecoration(color: AppColors.studentColor,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.sectionTitle),
      ]),
    );
  }
}

// ── Attendance row ────────────────────────────────────────────────────────────
class _AttendanceRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AttendanceRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'absent';
    final dateStr = data['date'] as String? ?? '';
    final color = _statusColor(status);
    final icon = _statusIcon(status);

    DateTime? dt;
    String dayLabel = dateStr;
    String weekday = '';
    try {
      dt = DateTime.parse(dateStr);
      dayLabel = DateFormat('d MMM').format(dt);
      weekday = DateFormat('EEEE').format(dt);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(weekday,
                style: AppTextStyles.bodyMediumBold),
            Text(data['className'] as String? ?? '',
                style: AppTextStyles.labelSmall),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(dayLabel,
              style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(status[0].toUpperCase() + status.substring(1),
                style: AppTextStyles.labelTiny.copyWith(
                    color: color, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }
}

class _EmptyAttendance extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.event_note_rounded,
            size: 72, color: AppColors.textHint),
        const SizedBox(height: 20),
        Text('No attendance records yet',
            style: AppTextStyles.bodyMediumBold
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Text('Your teacher hasn\'t marked attendance yet.',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textHint)),
      ]),
    );
  }
}

Color _statusColor(String s) {
  switch (s) {
    case 'present':
      return AppColors.success;
    case 'late':
      return AppColors.warning;
    default:
      return AppColors.danger;
  }
}

IconData _statusIcon(String s) {
  switch (s) {
    case 'present':
      return Icons.check_circle_outline_rounded;
    case 'late':
      return Icons.access_time_rounded;
    default:
      return Icons.cancel_outlined;
  }
}