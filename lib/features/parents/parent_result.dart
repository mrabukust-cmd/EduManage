import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

class ParentResultsScreen extends ConsumerWidget {
  const ParentResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authProvider).user?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text("Child's Results",
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('parent_children')
                  .where('parentId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snap) {
                final children = snap.data?.docs ?? [];
                if (children.isEmpty) {
                  return Center(
                    child: Text('No child linked.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  );
                }
                final data = children.first.data() as Map<String, dynamic>;
                final studentId = data['studentId'] as String? ?? '';
                return _ResultsForStudent(studentId: studentId);
              },
            ),
    );
  }
}

class _ResultsForStudent extends StatelessWidget {
  final String studentId;
  const _ResultsForStudent({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('results')
          .where('studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bar_chart_rounded, size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No results available yet.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        // Overall average
        double totalPct = 0;
        int count = 0;
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final pct = (d['percentage'] as num?)?.toDouble();
          if (pct != null) {
            totalPct += pct;
            count++;
          }
        }
        final avg = count > 0 ? totalPct / count : 0.0;

        // Group by exam
        final Map<String, List<QueryDocumentSnapshot>> grouped = {};
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final exam = d['examTitle'] as String? ?? 'General';
          grouped.putIfAbsent(exam, () => []).add(doc);
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Overall card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
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
                          value: avg / 100,
                          strokeWidth: 7,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                        Text(_letterGrade(avg),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Overall Performance',
                            style: AppTextStyles.bodyMediumBold.copyWith(color: Colors.white)),
                        const SizedBox(height: 6),
                        Text('Average: ${avg.toStringAsFixed(1)}%',
                            style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text('Total subjects: $count',
                            style: AppTextStyles.labelSmall.copyWith(color: Colors.white60)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ...grouped.entries.expand((entry) => [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(width: 4, height: 18,
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 10),
                        Text(entry.key, style: AppTextStyles.sectionTitle),
                      ],
                    ),
                  ),
                  ...entry.value.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final subject = d['subject'] as String? ?? '';
                    final marks = (d['marksObtained'] as num?)?.toDouble() ?? 0;
                    final total = (d['totalMarks'] as num?)?.toDouble() ?? 100;
                    final pct = (d['percentage'] as num?)?.toDouble() ?? 0;
                    final grade = _letterGrade(pct);
                    final gradeColor = _gradeColor(pct);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(subject, style: AppTextStyles.bodyMediumBold)),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: gradeColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(grade,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: gradeColor,
                                    )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct / 100,
                                    minHeight: 6,
                                    backgroundColor: AppColors.divider,
                                    valueColor: AlwaysStoppedAnimation(gradeColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('${marks.toInt()}/${total.toInt()}',
                                  style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ]),
          ],
        );
      },
    );
  }
}

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