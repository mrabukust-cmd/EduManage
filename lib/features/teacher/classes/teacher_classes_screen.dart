import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

class TeacherClassesScreen extends ConsumerWidget {
  const TeacherClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final uid = user?.uid;
    final teacherName = user?.displayName ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.teacherColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Classes',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : _AssignedClassesList(uid: uid, teacherName: teacherName),
    );
  }
}

// ── Assigned Classes List ──────────────────────────────────────────────────────
class _AssignedClassesList extends StatefulWidget {
  final String uid;
  final String teacherName;

  const _AssignedClassesList({required this.uid, required this.teacherName});

  @override
  State<_AssignedClassesList> createState() => _AssignedClassesListState();
}

class _AssignedClassesListState extends State<_AssignedClassesList> {
  List<String> _assignedClassNames = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignedClasses();
  }

  /// Loads the teacher's assigned class names using the same two-step
  /// fallback logic used throughout the app (teacher_repo.dart,
  /// attendence_screen.dart, teacher_home_screen.dart):
  ///   1. `teachers/{uid}.classes` array  (set by admin via ClassMultiSelectField)
  ///   2. `classes` collection where `classTeacher == teacherName`  (legacy)
  Future<void> _loadAssignedClasses() async {
    try {
      final db = FirebaseFirestore.instance;

      final teacherDoc = await db.collection('teachers').doc(widget.uid).get();
      final data = teacherDoc.data();

      List<String> classes = (data?['classes'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          [];

      if (classes.isEmpty && widget.teacherName.trim().isNotEmpty) {
        final classSnap = await db
            .collection('classes')
            .where('classTeacher', isEqualTo: widget.teacherName.trim())
            .get();
        classes = classSnap.docs
            .map((d) => (d.data()['name'] as String? ?? '').trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      classes.sort();

      if (mounted) {
        setState(() {
          _assignedClassNames = classes;
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

    if (_assignedClassNames.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.class_outlined,
                  size: 64, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(
                'No classes assigned yet.\nAsk admin to assign you to a class.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      itemCount: _assignedClassNames.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _ClassTile(
          className: _assignedClassNames[index],
          teacherName: widget.teacherName,
        );
      },
    );
  }
}

// ── Class Tile ─────────────────────────────────────────────────────────────────
//
// Fetches the class doc and live student count from Firestore so each
// tile shows real data (section, class teacher, student count).
class _ClassTile extends StatelessWidget {
  final String className;
  final String teacherName;

  const _ClassTile({required this.className, required this.teacherName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Fetch the matching class doc(s) by name
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where('name', isEqualTo: className)
          .limit(1)
          .snapshots(),
      builder: (context, classSnap) {
        final classData = classSnap.hasData && classSnap.data!.docs.isNotEmpty
            ? classSnap.data!.docs.first.data() as Map<String, dynamic>
            : <String, dynamic>{};

        final section = classData['section'] as String? ?? '';
        final classTeacher =
            classData['classTeacher'] as String? ?? teacherName;

        return StreamBuilder<QuerySnapshot>(
          // Live student count for this class
          stream: FirebaseFirestore.instance
              .collection('students')
              .where('class', isEqualTo: className)
              .snapshots(),
          builder: (context, studentSnap) {
            final studentCount = studentSnap.data?.docs.length ?? 0;

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
                  // Class name + student count badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.teacherColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.class_rounded,
                            color: AppColors.teacherColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(className,
                            style: AppTextStyles.bodyMediumBold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.teacherColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$studentCount student${studentCount == 1 ? '' : 's'}',
                          style: AppTextStyles.labelTiny.copyWith(
                            color: AppColors.teacherColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 14),

                  // Section row
                  if (section.isNotEmpty)
                    _InfoRow(
                      icon: Icons.layers_rounded,
                      label: 'Section',
                      value: section,
                    ),

                  // Class teacher row
                  _InfoRow(
                    icon: Icons.person_rounded,
                    label: 'Class Teacher',
                    value: classTeacher.isNotEmpty ? classTeacher : 'Unassigned',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textSecondary)),
          Expanded(
            child: Text(value,
                style: AppTextStyles.labelSmall
                    .copyWith(fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}