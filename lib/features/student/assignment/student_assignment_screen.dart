import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/data/models/assignment_model.dart';
import 'package:school_management_system/data/repositories/assignment_repo.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

class StudentAssignmentsScreen extends ConsumerWidget {
  const StudentAssignmentsScreen({super.key});

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
        title: Text('Assignments',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .doc(uid)
                  .snapshots(),
              builder: (context, studentSnap) {
                if (studentSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final studentData =
                    studentSnap.data?.data() as Map<String, dynamic>?;
                final className =
                    studentData?['class'] as String?;

                if (className == null || className.trim().isEmpty) {
                  return Center(
                    child: Text(
                      'No class assigned yet.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  );
                }

                return StreamBuilder<List<AssignmentModel>>(
                  stream: AssignmentRepository.instance.watchByClass(className.trim()),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snap.hasError) {
                      return Center(
                        child: Text(
                          'Could not load assignments.',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    final assignments = snap.data ?? [];

                    if (assignments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.assignment_turned_in_outlined,
                                size: 64, color: AppColors.textHint),
                            const SizedBox(height: 16),
                            Text(
                              'No assignments right now.\nCheck back later!',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: assignments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final assignment = assignments[i];
                        final overdue = assignment.isOverdue;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppColors.cardShadow,
                            border: overdue
                                ? Border.all(
                                    color: AppColors.danger.withValues(alpha: 0.4))
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.studentColor
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      assignment.subject,
                                      style: AppTextStyles.labelTiny.copyWith(
                                          color: AppColors.studentColor,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (assignment.dueDate != null)
                                    Text(
                                      'Due ${DateFormat('MMM d').format(assignment.dueDate!)}',
                                      style: AppTextStyles.labelTiny.copyWith(
                                        color: overdue
                                            ? AppColors.danger
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  else
                                    Text(
                                      'No due date',
                                      style: AppTextStyles.labelTiny.copyWith(
                                          color: AppColors.textHint),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(assignment.title,
                                  style: AppTextStyles.bodyMediumBold),
                              if (assignment.description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  assignment.description,
                                  style: AppTextStyles.labelSmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}