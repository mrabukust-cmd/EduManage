import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

class ParentAttendanceScreen extends ConsumerWidget {
  const ParentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authProvider).user?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.success,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text("Child's Attendance",
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : _ParentAttendanceBody(parentUid: uid),
    );
  }
}

class _ParentAttendanceBody extends StatefulWidget {
  final String parentUid;
  const _ParentAttendanceBody({required this.parentUid});

  @override
  State<_ParentAttendanceBody> createState() => _ParentAttendanceBodyState();
}

class _ParentAttendanceBodyState extends State<_ParentAttendanceBody> {
  String? _studentId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentId();
  }

  Future<void> _loadStudentId() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('parent_children')
          .where('parentId', isEqualTo: widget.parentUid)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _studentId = snap.docs.isNotEmpty
              ? (snap.docs.first.data()['studentId'] as String? ?? '')
              : null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_studentId == null || _studentId!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom_rounded,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('No child linked to your account.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return _AttendanceForStudent(studentId: _studentId!);
  }
}

// FIX: Student name is now fetched once via FutureBuilder instead of
// being wrapped in a StreamBuilder. The old pattern caused the inner
// attendance StreamBuilder to reset to ConnectionState.waiting every
// time the outer student-doc stream re-emitted (e.g. on reconnect),
// producing the "flash then disappear" effect. A FutureBuilder reads
// the doc once and never re-triggers the attendance stream.
class _AttendanceForStudent extends StatefulWidget {
  final String studentId;
  const _AttendanceForStudent({required this.studentId});

  @override
  State<_AttendanceForStudent> createState() => _AttendanceForStudentState();
}

class _AttendanceForStudentState extends State<_AttendanceForStudent> {
  late Future<String> _studentNameFuture;

  @override
  void initState() {
    super.initState();
    _studentNameFuture = _fetchStudentName();
  }

  Future<String> _fetchStudentName() async {
    final doc = await FirebaseFirestore.instance
        .collection('students')
        .doc(widget.studentId)
        .get();
    return (doc.data()?['name'] as String?) ?? 'Child';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _studentNameFuture,
      builder: (context, nameSnap) {
        final studentName = nameSnap.data ?? 'Child';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('attendance')
              .where('studentId', isEqualTo: widget.studentId)
              .snapshots(),
          builder: (context, snap) {
            // Show spinner only on first load, not on subsequent emissions
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Sort in Dart — avoids the composite index requirement on
            // (studentId + date) that causes Firestore to silently return
            // empty results, then retry, producing the flash-disappear bug.
            final docs = List.of(snap.data?.docs ?? [])
              ..sort((a, b) {
                final aDate = (a.data() as Map<String, dynamic>)['date'] as String? ?? '';
                final bDate = (b.data() as Map<String, dynamic>)['date'] as String? ?? '';
                return bDate.compareTo(aDate); // descending
              });

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_note_rounded,
                        size: 64, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    Text('No attendance records yet.',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }

            int present = 0, absent = 0, late = 0;
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? 'absent';
              if (status == 'present') present++;
              else if (status == 'absent') absent++;
              else if (status == 'late') late++;
            }
            final total = docs.length;
            final pct = total > 0 ? (present / total) : 0.0;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Student name card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_rounded,
                          color: AppColors.success),
                      const SizedBox(width: 10),
                      Text(studentName,
                          style: AppTextStyles.bodyMediumBold
                              .copyWith(color: AppColors.success)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Summary card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: pct,
                              strokeWidth: 8,
                              backgroundColor: AppColors.divider,
                              valueColor: AlwaysStoppedAnimation(
                                pct >= 0.85
                                    ? AppColors.success
                                    : pct >= 0.70
                                        ? AppColors.warning
                                        : AppColors.danger,
                              ),
                            ),
                            Text('${(pct * 100).round()}%',
                                style: AppTextStyles.statValue
                                    .copyWith(fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatRow(
                                label: 'Present',
                                value: '$present days',
                                color: AppColors.success),
                            _StatRow(
                                label: 'Absent',
                                value: '$absent days',
                                color: AppColors.danger),
                            _StatRow(
                                label: 'Late',
                                value: '$late days',
                                color: AppColors.warning),
                            _StatRow(
                                label: 'Total',
                                value: '$total days',
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (pct < 0.75)
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.danger),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Your child's attendance is below 75%. "
                            "Please ensure regular attendance.",
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                  ),

                Text('Attendance History',
                    style: AppTextStyles.sectionTitle),
                const SizedBox(height: 12),

                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] as String? ?? 'absent';
                  final dateStr = data['date'] as String? ?? '';
                  final Color color;
                  final IconData icon;
                  switch (status) {
                    case 'present':
                      color = AppColors.success;
                      icon = Icons.check_circle_outline_rounded;
                      break;
                    case 'late':
                      color = AppColors.warning;
                      icon = Icons.access_time_rounded;
                      break;
                    default:
                      color = AppColors.danger;
                      icon = Icons.cancel_outlined;
                  }

                  String dayLabel = dateStr;
                  String weekday = '';
                  try {
                    final dt = DateTime.parse(dateStr);
                    dayLabel = DateFormat('d MMM yyyy').format(dt);
                    weekday = DateFormat('EEEE').format(dt);
                  } catch (_) {}

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(weekday,
                                  style: AppTextStyles.bodyMediumBold),
                              Text(dayLabel,
                                  style: AppTextStyles.labelSmall),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status[0].toUpperCase() + status.substring(1),
                            style: AppTextStyles.labelTiny.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label: ', style: AppTextStyles.labelSmall),
          Text(value,
              style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}