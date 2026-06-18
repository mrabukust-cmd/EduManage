import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';


// ── Model ─────────────────────────────────────────────────────────────────────
class StudentModel {
  final String id, name, rollNo, grade, section, contact;
  StudentModel({required this.id, required this.name, required this.rollNo, required this.grade, required this.section, required this.contact});
}

// ── Provider ──────────────────────────────────────────────────────────────────
final studentSearchProvider = StateProvider<String>((ref) => '');
final selectedGradeProvider  = StateProvider<String>((ref) => 'All');

final studentsProvider = Provider<List<StudentModel>>((ref) => _mockStudents());

List<StudentModel> _mockStudents() => [
  StudentModel(id: '1', name: 'Ali Khan', rollNo: '001', grade: 'Grade 9', section: 'A', contact: '+92 300 1234567'),
  StudentModel(id: '2', name: 'Sara Noor', rollNo: '002', grade: 'Grade 9', section: 'A', contact: '+92 301 2345678'),
  StudentModel(id: '3', name: 'Usman Tariq', rollNo: '003', grade: 'Grade 10', section: 'B', contact: '+92 302 3456789'),
  StudentModel(id: '4', name: 'Ayesha Malik', rollNo: '004', grade: 'Grade 8', section: 'C', contact: '+92 303 4567890'),
  StudentModel(id: '5', name: 'Bilal Ahmed', rollNo: '005', grade: 'Grade 10', section: 'A', contact: '+92 304 5678901'),
  StudentModel(id: '6', name: 'Fatima Rizvi', rollNo: '006', grade: 'Grade 8', section: 'B', contact: '+92 305 6789012'),
  StudentModel(id: '7', name: 'Zain Abbas', rollNo: '007', grade: 'Grade 9', section: 'B', contact: '+92 306 7890123'),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  static const _grades = ['All', 'Grade 8', 'Grade 9', 'Grade 10'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query         = ref.watch(studentSearchProvider);
    final selectedGrade = ref.watch(selectedGradeProvider);
    final allStudents   = ref.watch(studentsProvider);

    final filtered = allStudents.where((s) {
      final matchGrade = selectedGrade == 'All' || s.grade == selectedGrade;
      final matchQuery = s.name.toLowerCase().contains(query.toLowerCase()) || s.rollNo.contains(query);
      return matchGrade && matchQuery;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white), onPressed: () => context.pop()),
        title: Text('Students', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            onPressed: () => context.push('/admin/students/add'),
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
                  onChanged: (v) => ref.read(studentSearchProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'Search by name or roll no...',
                    hintStyle: AppTextStyles.labelMedium.copyWith(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                        onTap: () => ref.read(selectedGradeProvider.notifier).state = g,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(g, style: AppTextStyles.labelSmall.copyWith(color: isSelected ? AppColors.primary : Colors.white, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
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
                Text('${filtered.length} students', style: AppTextStyles.labelMedium),
              ],
            ),
          ),

          // ── List ─────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('No students found', style: AppTextStyles.bodyMedium))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _StudentCard(student: filtered[i]),
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
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.studentColor.withOpacity(0.12),
            child: Text(
              student.name.substring(0, 1),
              style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.studentColor, fontSize: 18),
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
                    _Badge(label: 'Roll ${student.rollNo}', color: AppColors.primary),
                    const SizedBox(width: 8),
                    _Badge(label: '${student.grade} – ${student.section}', color: AppColors.studentColor),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) {
              if (v == 'view') context.push('/admin/students/${student.id}');
              if (v == 'edit') context.push('/admin/students/${student.id}/edit');
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Text('View Profile')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
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
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: AppTextStyles.labelTiny.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}