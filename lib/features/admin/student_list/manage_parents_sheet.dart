import 'package:flutter/material.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/data/repositories/auth_repository.dart';

/// Bottom sheet shown from a student's "More" menu — lists parents
/// currently linked to this student, lets the admin remove a link or
/// add a new one from approved-but-unlinked parents.
class ManageParentsSheet extends StatelessWidget {
  final String studentId;
  final String studentName;

  const ManageParentsSheet({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  static Future<void> show(BuildContext context, {required String studentId, required String studentName}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ManageParentsSheet(studentId: studentId, studentName: studentName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = AuthRepository.instance;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Linked Parents', style: AppTextStyles.headingMedium),
          const SizedBox(height: 4),
          Text(studentName, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          // ── Currently linked ───────────────────────────────
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: repo.watchParentsForStudent(studentId),
            builder: (context, snap) {
              final parents = snap.data ?? [];
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              if (parents.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('No parents linked yet.',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                );
              }
              return Column(
                children: parents.map((p) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.accent.withOpacity(0.12),
                          child: const Icon(Icons.family_restroom_rounded, color: AppColors.accent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['name'] as String, style: AppTextStyles.bodyMediumBold),
                              Text(p['email'] as String, style: AppTextStyles.labelTiny),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.link_off_rounded, color: AppColors.danger, size: 20),
                          tooltip: 'Unlink',
                          onPressed: () => repo.unlinkParentFromStudent(
                            parentId: p['parentId'] as String,
                            studentId: studentId,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 8),
          Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          Text('Add a parent', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),

          // ── Available parents to link ───────────────────────
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: repo.watchAvailableParents(studentId),
            builder: (context, snap) {
              final available = snap.data ?? [];
              if (available.isEmpty) {
                return Text('No unlinked approved parents available.',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint));
              }
              return Column(
                children: available.map((p) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.divider,
                      child: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 18),
                    ),
                    title: Text(p['name'] as String, style: AppTextStyles.bodyMediumBold),
                    subtitle: Text(p['email'] as String, style: AppTextStyles.labelTiny),
                    trailing: TextButton(
                      onPressed: () => repo.linkParentToStudent(
                        parentId: p['parentId'] as String,
                        studentId: studentId,
                      ),
                      child: const Text('Link'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}