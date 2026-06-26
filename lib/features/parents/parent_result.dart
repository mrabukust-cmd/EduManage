import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/utils/data_helpers.dart';
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
        title: Text("Children's Results",
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : _MultiChildResultsBody(parentUid: uid),
    );
  }
}

// ── Multi-child body ──────────────────────────────────────────────────────────
class _MultiChildResultsBody extends StatefulWidget {
  final String parentUid;
  const _MultiChildResultsBody({required this.parentUid});

  @override
  State<_MultiChildResultsBody> createState() =>
      _MultiChildResultsBodyState();
}

class _MultiChildResultsBodyState extends State<_MultiChildResultsBody> {
  List<Map<String, dynamic>> _children = [];
  bool _loading = true;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('parent_children')
          .where('parentId', isEqualTo: widget.parentUid)
          .get();

      final children = <Map<String, dynamic>>[];

      for (final doc in snap.docs) {
        final studentId = doc.data()['studentId'] as String? ?? '';
        if (studentId.isEmpty) continue;

        final studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .get();

        if (studentDoc.exists) {
          children.add({
            'studentId': studentId,
            'name': studentDoc.data()?['name'] as String? ?? 'Student',
            'class': studentDoc.data()?['class'] as String? ?? '',
            'rollNo': studentDoc.data()?['rollNo'] as String? ?? '',
          });
        }
      }

      if (mounted) {
        setState(() {
          _children = children;
          _selectedIndex = children.length == 1 ? 0 : -1;
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

    if (_children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom_rounded,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('No children linked to your account.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Contact the school admin to link your child.',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textHint)),
          ],
        ),
      );
    }

    // Single child → go straight to detail
    if (_children.length == 1) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _ResultsDetail(
          studentId: _children[0]['studentId'] as String,
          studentName: _children[0]['name'] as String,
        ),
      );
    }

    // Multiple children → selector cards + detail
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Select a child to view results',
            style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),

        // ── Child selector cards ──────────────────────────────
        ..._children.asMap().entries.map((entry) {
          final i = entry.key;
          final child = entry.value;
          final isSelected = _selectedIndex == i;

          return GestureDetector(
            onTap: () => setState(
                () => _selectedIndex = isSelected ? -1 : i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.cardShadow,
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isSelected
                        ? Colors.white24
                        : AppColors.primary.withOpacity(0.12),
                    child: Text(
                      (child['name'] as String).isNotEmpty
                          ? (child['name'] as String)[0].toUpperCase()
                          : 'S',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: isSelected
                            ? Colors.white
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child['name'] as String,
                          style: AppTextStyles.bodyMediumBold.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${child['class']}  •  Roll: ${child['rollNo']}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          );
        }),

        // ── Detail for selected child ─────────────────────────
        if (_selectedIndex >= 0 &&
            _selectedIndex < _children.length) ...[
          const SizedBox(height: 8),
          _ResultsDetail(
            studentId:
                _children[_selectedIndex]['studentId'] as String,
            studentName:
                _children[_selectedIndex]['name'] as String,
          ),
        ],
      ],
    );
  }
}

// ── Results detail for one child ──────────────────────────────────────────────
class _ResultsDetail extends StatelessWidget {
  final String studentId;
  final String studentName;

  const _ResultsDetail({
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('results')
          .where('studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting &&
            !snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                const Icon(Icons.bar_chart_rounded,
                    size: 48, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text('No results available yet for $studentName.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
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
        final grade = DataHelpers.letterGrade(avg);

        // Group by exam
        final Map<String, List<QueryDocumentSnapshot>> grouped = {};
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final exam = d['examTitle'] as String? ?? 'General';
          grouped.putIfAbsent(exam, () => []).add(doc);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                        ),
                        Text(grade,
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
                            style: AppTextStyles.bodyMediumBold
                                .copyWith(color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(
                            'Average: ${avg.toStringAsFixed(1)}%',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text('Total subjects: $count',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: Colors.white60)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Per-exam sections
            ...grouped.entries.expand((entry) => [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 10),
                        Text(entry.key,
                            style: AppTextStyles.sectionTitle),
                      ],
                    ),
                  ),
                  ...entry.value.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final subject =
                        d['subject'] as String? ?? 'Subject';
                    final marks =
                        (d['marksObtained'] as num?)?.toDouble() ?? 0;
                    final total =
                        (d['totalMarks'] as num?)?.toDouble() ?? 100;
                    final pct =
                        (d['percentage'] as num?)?.toDouble() ?? 0;
                    final grd = DataHelpers.letterGrade(pct);
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
                              Expanded(
                                  child: Text(subject,
                                      style:
                                          AppTextStyles.bodyMediumBold)),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color:
                                      gradeColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(grd,
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
                                  borderRadius:
                                      BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct / 100,
                                    minHeight: 6,
                                    backgroundColor: AppColors.divider,
                                    valueColor:
                                        AlwaysStoppedAnimation(
                                            gradeColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${marks.toInt()}/${total.toInt()}',
                                style: AppTextStyles.labelSmall
                                    .copyWith(
                                        fontWeight: FontWeight.w600),
                              ),
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