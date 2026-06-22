import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/admin/student_list/manage_parents_sheet.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
class StudentModel {
  final String id, name, rollNo, grade, section, contact;
  StudentModel({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.grade,
    required this.section,
    required this.contact,
  });
}

// ── Provider ──────────────────────────────────────────────────────────────────
final studentSearchProvider = StateProvider<String>((ref) => '');
final selectedGradeProvider = StateProvider<String>((ref) => 'All');

final studentsStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance
      .collection('students')
      .orderBy('name')
      .snapshots();
});

// ── Screen ────────────────────────────────────────────────────────────────────
class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  static const _grades = ['All', 'Grade 8', 'Grade 9', 'Grade 10'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(studentSearchProvider);
    final selectedGrade = ref.watch(selectedGradeProvider);
    final studentsSnap = ref.watch(studentsStreamProvider);

    final filtered = studentsSnap.when(
      data: (snapshot) {
        return snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return StudentModel(
                id: doc.id,
                name: data['name'] as String? ?? 'Unknown',
                rollNo: data['rollNo'] as String? ?? '-',
                grade: data['class'] as String? ?? 'Unknown',
                section: data['section'] as String? ?? '-',
                contact: data['contact'] as String? ?? '-',
              );
            })
            .where((s) {
              final matchGrade =
                  selectedGrade == 'All' || s.grade == selectedGrade;
              final matchQuery =
                  s.name.toLowerCase().contains(query.toLowerCase()) ||
                  s.rollNo.contains(query);
              return matchGrade && matchQuery;
            })
            .toList();
      },
      loading: () => [],
      error: (_, __) => [],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Students',
          style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            onPressed: () => context.push('/admin/home/students/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filter ─────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                // Search
                TextField(
                  onChanged: (v) =>
                      ref.read(studentSearchProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'Search by name or roll no...',
                    hintStyle: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white54,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white54,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 12),
                // Grade Filter
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _grades.map((g) {
                      final isSelected = selectedGrade == g;
                      return GestureDetector(
                        onTap: () =>
                            ref.read(selectedGradeProvider.notifier).state = g,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            g,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Count ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  '${filtered.length} students',
                  style: AppTextStyles.labelMedium,
                ),
              ],
            ),
          ),

          // ── List ─────────────────────────────────────────────
          Expanded(
            child: studentsSnap.when(
              data: (_) => filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No students found',
                        style: AppTextStyles.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _StudentCard(student: filtered[i]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Failed to load students',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Student Card ──────────────────────────────────────────────────────────────
class _StudentCard extends StatelessWidget {
  final StudentModel student;
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.studentColor.withOpacity(0.12),
            child: Text(
              student.name.substring(0, 1),
              style: AppTextStyles.bodyMediumBold.copyWith(
                color: AppColors.studentColor,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: AppTextStyles.bodyMediumBold),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Badge(
                      label: 'Roll ${student.rollNo}',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    _Badge(
                      label: '${student.grade} – ${student.section}',
                      color: AppColors.studentColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textSecondary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (v) {
              if (v == 'view') context.push('/admin/students/${student.id}');
              if (v == 'edit')
                context.push('/admin/students/${student.id}/edit');
              if (v == 'parents') {
                ManageParentsSheet.show(
                  context,
                  studentId: student.id,
                  studentName: student.name,
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Text('View Profile')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'parents',
                child: Text('Manage Parents'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelTiny.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
