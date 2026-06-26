import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
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
 
                // FIX: removed .orderBy('dueDate') — causes Firestore to
                // silently drop docs or error when any doc has null dueDate,
                // which made the list flash briefly then disappear.
                // Sorting is now done in Dart after the data arrives.
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('assignments')
                      .where('className', isEqualTo: className.trim())
                      .snapshots(),
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
 
                    final docs = snap.data?.docs ?? [];
 
                    if (docs.isEmpty) {
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
 
                    // Sort by dueDate ascending in Dart; nulls go last
                    final sorted = List.of(docs)
                      ..sort((a, b) {
                        final aTs =
                            (a.data() as Map<String, dynamic>)['dueDate']
                                as Timestamp?;
                        final bTs =
                            (b.data() as Map<String, dynamic>)['dueDate']
                                as Timestamp?;
                        if (aTs == null && bTs == null) return 0;
                        if (aTs == null) return 1;
                        if (bTs == null) return -1;
                        return aTs.compareTo(bTs);
                      });
 
                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final data =
                            sorted[i].data() as Map<String, dynamic>;
                        final dueDate =
                            (data['dueDate'] as Timestamp?)?.toDate();
                        final overdue = dueDate != null &&
                            dueDate.isBefore(DateTime.now());
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppColors.cardShadow,
                            border: overdue
                                ? Border.all(
                                    color: AppColors.danger.withOpacity(0.4))
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
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      data['subject'] as String? ?? '',
                                      style: AppTextStyles.labelTiny.copyWith(
                                          color: AppColors.studentColor,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (dueDate != null)
                                    Text(
                                      'Due ${DateFormat('MMM d').format(dueDate)}',
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
                              Text(data['title'] as String? ?? '',
                                  style: AppTextStyles.bodyMediumBold),
                              if ((data['description'] ?? '')
                                  .toString()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  data['description'] as String,
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