import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/utils/data_helpers.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

// ── Place this file at:
// lib/features/student/results/student_results_screen.dart
//
// Add route in app_router.dart under /student/home routes:
//   GoRoute(path: 'results', builder: (_, __) => const StudentResultsScreen()),

class StudentResultsScreen extends ConsumerWidget {
  const StudentResultsScreen({super.key});

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
        title: Text('My Results',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('results')
                  .where('studentId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return _EmptyResults();
                }

                final docs = snap.data!.docs;

                // Group by examTitle
                final Map<String, List<QueryDocumentSnapshot>> grouped = {};
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final exam = data['examTitle'] as String? ?? 'General';
                  grouped.putIfAbsent(exam, () => []).add(doc);
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // ── Overall GPA card ────────────────────────
                    _OverallCard(docs: docs),
                    const SizedBox(height: 24),

                    // ── Per-exam sections ────────────────────────
                    ...grouped.entries.map((entry) => _ExamSection(
                          examTitle: entry.key,
                          docs: entry.value,
                        )),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
    );
  }
}

// ── Overall summary card ──────────────────────────────────────────────────────
class _OverallCard extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  const _OverallCard({required this.docs});

  @override
  Widget build(BuildContext context) {
    double totalPct = 0;
    int count = 0;
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final pct = (data['percentage'] as num?)?.toDouble();
      if (pct != null) {
        totalPct += pct;
        count++;
      }
    }
    final avg = count > 0 ? totalPct / count : 0.0;
    final grade = DataHelpers.letterGrade(avg);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.studentGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          // Circle
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(grade,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Performance',
                    style: AppTextStyles.bodyMediumBold
                        .copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text('Average: ${avg.toStringAsFixed(1)}%',
                    style:
                        AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('Total subjects: $count',
                    style:
                        AppTextStyles.labelSmall.copyWith(color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Exam section ──────────────────────────────────────────────────────────────
class _ExamSection extends StatelessWidget {
  final String examTitle;
  final List<QueryDocumentSnapshot> docs;
  const _ExamSection({required this.examTitle, required this.docs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.studentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(examTitle, style: AppTextStyles.sectionTitle),
            ],
          ),
        ),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _ResultRow(data: data);
        }),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Result row ────────────────────────────────────────────────────────────────
class _ResultRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ResultRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final subject = data['subject'] as String? ?? 'Subject';
    final marks = (data['marksObtained'] as num?)?.toDouble() ?? 0;
    final total = (data['totalMarks'] as num?)?.toDouble() ?? 100;
    final pct = (data['percentage'] as num?)?.toDouble() ?? 0;
    final grade = DataHelpers.letterGrade(pct);
    final gradeColor = DataHelpers.gradeColor(pct);

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
              Text(
                '${marks.toInt()}/${total.toInt()}',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyResults extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart_rounded,
              size: 72, color: AppColors.textHint),
          const SizedBox(height: 20),
          Text('No results available yet.',
              style: AppTextStyles.bodyMediumBold
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Your teacher hasn\'t entered grades yet.',
              style:
                  AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
        ],
      ),
    );
  }
}