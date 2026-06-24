import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/data/models/student_model.dart';
import 'package:school_management_system/features/admin/student_list/manage_parents_sheet.dart';

// ── Providers ──────────────────────────────────────────────────────────────────
final studentSearchProvider = StateProvider<String>((ref) => '');
final selectedGradeProvider = StateProvider<String>((ref) => 'All');

final studentsStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance
      .collection('students')
      .orderBy('name')
      .snapshots();
});

/// Streams every distinct class name from the `classes` collection,
/// sorted exactly as they were entered (alphabetical by `name`).
/// This replaces the old hardcoded ['All', 'Grade 8', 'Grade 9', 'Grade 10'].
final classNamesProvider = StreamProvider<List<String>>((ref) {
  return FirebaseFirestore.instance
      .collection('classes')
      .orderBy('name')
      .snapshots()
      .map((snap) {
    final names = snap.docs
        .map((d) => (d.data())['name'] as String? ?? '')
        .where((n) => n.trim().isNotEmpty)
        .toList();
    return names;
  });
});

// ── Screen ────────────────────────────────────────────────────────────────────
class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(studentSearchProvider);
    final selectedGrade = ref.watch(selectedGradeProvider);
    final studentsSnap = ref.watch(studentsStreamProvider);
    final classNamesAsync = ref.watch(classNamesProvider);

    // Build the filter list: always starts with "All", then real class names
    final filterChips = classNamesAsync.when(
      data: (names) => ['All', ...names],
      loading: () => ['All'],
      error: (_, __) => ['All'],
    );

    final filtered = studentsSnap.when(
      data: (snapshot) {
        return snapshot.docs
            .map((doc) => StudentModel.fromDoc(doc))
            .where((s) {
              final matchGrade =
                  selectedGrade == 'All' || s.className == selectedGrade;
              final matchQuery =
                  s.name.toLowerCase().contains(query.toLowerCase()) ||
                  s.rollNo.contains(query);
              return matchGrade && matchQuery;
            })
            .toList();
      },
      loading: () => <StudentModel>[],
      error: (_, __) => <StudentModel>[],
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

                // ── Dynamic class filter chips ──────────────
                SizedBox(
                  height: 36,
                  child: classNamesAsync.when(
                    loading: () => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white54,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (_) => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filterChips.length,
                      itemBuilder: (context, i) {
                        final g = filterChips[i];
                        final isSelected = selectedGrade == g;
                        return GestureDetector(
                          onTap: () => ref
                              .read(selectedGradeProvider.notifier)
                              .state = g,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? Colors.white : Colors.white24,
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
                      },
                    ),
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
                  '${filtered.length} student${filtered.length == 1 ? '' : 's'}',
                  style: AppTextStyles.labelMedium,
                ),
                if (selectedGrade != 'All') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      selectedGrade,
                      style: AppTextStyles.labelTiny.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => ref
                        .read(selectedGradeProvider.notifier)
                        .state = 'All',
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),

          // ── List ─────────────────────────────────────────────
          Expanded(
            child: studentsSnap.when(
              data: (_) => filtered.isEmpty
                  ? _EmptyState(
                      selectedGrade: selectedGrade,
                      query: query,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _StudentCard(student: filtered[i]),
                    ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
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

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String selectedGrade;
  final String query;
  const _EmptyState({required this.selectedGrade, required this.query});

  @override
  Widget build(BuildContext context) {
    final isFiltered = selectedGrade != 'All' || query.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered
                  ? Icons.search_off_rounded
                  : Icons.people_outline_rounded,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'No students match your search.'
                  : 'No students yet.\nTap + to add one.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
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
              student.name.isNotEmpty ? student.name.substring(0, 1) : '?',
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
                const SizedBox(height: 2),
                Text(
                  student.email,
                  style: AppTextStyles.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Badge(
                      label: 'Roll ${student.rollNo}',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: _Badge(
                        label: student.className.isEmpty
                            ? 'No class'
                            : student.section.isEmpty
                                ? student.className
                                : '${student.className} – ${student.section}',
                        color: AppColors.studentColor,
                      ),
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
              if (v == 'parents') {
                ManageParentsSheet.show(
                  context,
                  studentId: student.id,
                  studentName: student.name,
                );
              }
              if (v == 'delete') {
                _confirmDelete(context, student);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'parents', child: Text('Manage Parents')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, StudentModel student) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete student?'),
        content: Text(
            'This will permanently remove ${student.name} from the system.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseFirestore.instance
                  .collection('students')
                  .doc(student.id)
                  .delete();
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
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
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}