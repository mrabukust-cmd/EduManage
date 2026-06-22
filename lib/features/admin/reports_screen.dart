import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Reports', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _AttendanceReportCard()),
                const SizedBox(width: 12),
                Expanded(child: _LatestExamGradeCard()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _NewStudentsCard()),
                const SizedBox(width: 12),
                Expanded(child: _TeacherLoadCard()),
              ],
            ),
            const SizedBox(height: 24),
            Text('Highlights', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            const _ComputedHighlights(),
          ],
        ),
      ),
    );
  }
}

// ── Shared card shell ──────────────────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final String title;
  final Widget valueWidget;
  final Color color;
  const _ReportCard({required this.title, required this.valueWidget, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          valueWidget,
        ],
      ),
    );
  }
}

Widget _loadingValue() => const SizedBox(
      height: 28,
      width: 28,
      child: CircularProgressIndicator(strokeWidth: 2.5),
    );

Widget _errorValue() => Text(
      '—',
      style: AppTextStyles.headingLarge.copyWith(color: AppColors.textHint),
    );

// ── Attendance: present / total over last 30 days ─────────────────────────────
class _AttendanceReportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final since = DateTime.now().subtract(const Duration(days: 30));
    final sinceKey =
        '${since.year.toString().padLeft(4, '0')}-${since.month.toString().padLeft(2, '0')}-${since.day.toString().padLeft(2, '0')}';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: sinceKey)
          .snapshots(),
      builder: (context, snap) {
        Widget value;
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          value = _loadingValue();
        } else if (snap.hasError) {
          value = _errorValue();
        } else {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            value = Text('No data', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint));
          } else {
            int present = 0;
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              if ((data['status'] as String?) == 'present') present++;
            }
            final pct = (present / docs.length) * 100;
            value = Text('${pct.toStringAsFixed(0)}%',
                style: AppTextStyles.headingLarge.copyWith(color: AppColors.success));
          }
        }
        return _ReportCard(title: 'Attendance (30 days)', valueWidget: value, color: AppColors.success);
      },
    );
  }
}

// ── Average grade for the most recent examTitle ────────────────────────────────
class _LatestExamGradeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('results')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, latestSnap) {
        if (latestSnap.connectionState == ConnectionState.waiting && !latestSnap.hasData) {
          return _ReportCard(title: 'Latest Exam Avg', valueWidget: _loadingValue(), color: AppColors.primary);
        }
        if (latestSnap.hasError) {
          return _ReportCard(title: 'Latest Exam Avg', valueWidget: _errorValue(), color: AppColors.primary);
        }
        final latestDocs = latestSnap.data?.docs ?? [];
        if (latestDocs.isEmpty) {
          return _ReportCard(
            title: 'Latest Exam Avg',
            valueWidget: Text('No data', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
            color: AppColors.primary,
          );
        }

        final latestData = latestDocs.first.data() as Map<String, dynamic>;
        final examTitle = latestData['examTitle'] as String? ?? 'General';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('results')
              .where('examTitle', isEqualTo: examTitle)
              .snapshots(),
          builder: (context, examSnap) {
            Widget value;
            String subtitle = examTitle;
            if (examSnap.connectionState == ConnectionState.waiting && !examSnap.hasData) {
              value = _loadingValue();
            } else if (examSnap.hasError) {
              value = _errorValue();
            } else {
              final docs = examSnap.data?.docs ?? [];
              if (docs.isEmpty) {
                value = Text('No data', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint));
              } else {
                double total = 0;
                int count = 0;
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final pct = (data['percentage'] as num?)?.toDouble();
                  if (pct != null) {
                    total += pct;
                    count++;
                  }
                }
                final avg = count > 0 ? total / count : 0.0;
                value = Text(_letterGrade(avg),
                    style: AppTextStyles.headingLarge.copyWith(color: _gradeColor(avg)));
              }
            }
            return _ReportCard(
              title: 'Latest Exam Avg — $subtitle',
              valueWidget: value,
              color: AppColors.primary,
            );
          },
        );
      },
    );
  }
}

// ── New students enrolled in the last 30 days ──────────────────────────────────
class _NewStudentsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final since = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30)));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('createdAt', isGreaterThanOrEqualTo: since)
          .snapshots(),
      builder: (context, snap) {
        Widget value;
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          value = _loadingValue();
        } else if (snap.hasError) {
          value = _errorValue();
        } else {
          final count = snap.data?.docs.length ?? 0;
          value = Text('$count', style: AppTextStyles.headingLarge.copyWith(color: AppColors.studentColor));
        }
        return _ReportCard(title: 'New Students (30 days)', valueWidget: value, color: AppColors.studentColor);
      },
    );
  }
}

// ── Teacher load: total class-assignments across all teachers ────────────────
class _TeacherLoadCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('teachers').snapshots(),
      builder: (context, snap) {
        Widget value;
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          value = _loadingValue();
        } else if (snap.hasError) {
          value = _errorValue();
        } else {
          final docs = snap.data?.docs ?? [];
          int totalAssignments = 0;
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final classes = data['classes'] as List<dynamic>?;
            totalAssignments += classes?.length ?? 0;
          }
          value = Text('$totalAssignments classes',
              style: AppTextStyles.headingLarge.copyWith(color: AppColors.teacherColor));
        }
        return _ReportCard(title: 'Teacher Load', valueWidget: value, color: AppColors.teacherColor);
      },
    );
  }
}

// ── Computed highlights (factual, derived from current data) ─────────────────
class _ComputedHighlights extends StatelessWidget {
  const _ComputedHighlights();

  @override
  Widget build(BuildContext context) {
    final since30 = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30)));
    final sinceDate = DateTime.now().subtract(const Duration(days: 30));
    final sinceKey =
        '${sinceDate.year.toString().padLeft(4, '0')}-${sinceDate.month.toString().padLeft(2, '0')}-${sinceDate.day.toString().padLeft(2, '0')}';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: sinceKey)
          .snapshots(),
      builder: (context, attSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('students')
              .where('createdAt', isGreaterThanOrEqualTo: since30)
              .snapshots(),
          builder: (context, newStudentSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('classes').snapshots(),
              builder: (context, classSnap) {
                final attDocs = attSnap.data?.docs ?? [];
                int present = 0;
                for (final doc in attDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if ((data['status'] as String?) == 'present') present++;
                }
                final attPct = attDocs.isNotEmpty ? (present / attDocs.length) * 100 : null;

                final newStudentCount = newStudentSnap.data?.docs.length;
                final classCount = classSnap.data?.docs.length;

                final items = <Widget>[];

                if (attPct != null) {
                  items.add(_ReportListItem(
                    title: 'Attendance over the last 30 days: ${attPct.toStringAsFixed(0)}%',
                    subtitle: 'Based on ${attDocs.length} recorded attendance entries',
                  ));
                }

                if (newStudentCount != null) {
                  items.add(_ReportListItem(
                    title: newStudentCount == 0
                        ? 'No new students enrolled in the last 30 days'
                        : '$newStudentCount new student${newStudentCount == 1 ? '' : 's'} enrolled in the last 30 days',
                    subtitle: 'Counted from student creation date',
                  ));
                }

                if (classCount != null) {
                  items.add(_ReportListItem(
                    title: '$classCount class${classCount == 1 ? '' : 'es'} currently set up',
                    subtitle: 'Total entries in the classes collection',
                  ));
                }

                if (items.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }

                return Column(children: items);
              },
            );
          },
        );
      },
    );
  }
}

class _ReportListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ReportListItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyMediumBold),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────
String _letterGrade(double pct) {
  if (pct >= 90) return 'A+';
  if (pct >= 80) return 'A';
  if (pct >= 70) return 'B+';
  if (pct >= 60) return 'B';
  if (pct >= 50) return 'C';
  if (pct >= 40) return 'D';
  return 'F';
}

Color _gradeColor(double pct) {
  if (pct >= 80) return AppColors.success;
  if (pct >= 60) return AppColors.primary;
  if (pct >= 40) return AppColors.warning;
  return AppColors.danger;
}