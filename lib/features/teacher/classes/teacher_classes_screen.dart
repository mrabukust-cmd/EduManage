import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/data/providers/api_providers.dart';
import 'package:school_management_system/data/repositories/student_repository.dart';
import 'package:school_management_system/data/repositories/teacher_repo.dart';
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
          : StreamBuilder<List<String>>(
              stream: TeacherRepository.instance.watchAssignedClassNames(
                uid: uid,
                teacherName: teacherName,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final assignedClasses = snap.data ?? [];

                if (assignedClasses.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(apiClassesProvider);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Center(
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
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(apiClassesProvider);
                  },
                  child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: assignedClasses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _ClassTile(
                      className: assignedClasses[index],
                      teacherName: teacherName,
                    );
                  },
                ),
              );
            },
          ),
    );
  }
}

// ── Class Tile ─────────────────────────────────────────────────────────────────
class _ClassTile extends StatelessWidget {
  final String className;
  final String teacherName;

  const _ClassTile({required this.className, required this.teacherName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Fetch matching class info
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

        return StreamBuilder<int>(
          // Live student count via StudentRepository
          stream: StudentRepository.instance.watchCountByClass(className),
          builder: (context, studentSnap) {
            final studentCount = studentSnap.data ?? 0;

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
                          color: AppColors.teacherColor.withValues(alpha: 0.12),
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
                          color: AppColors.teacherColor.withValues(alpha: 0.1),
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