import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authProvider).user?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.teacherColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Assignments',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, uid),
        backgroundColor: AppColors.teacherColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('New Assignment',
            style: AppTextStyles.bodyMediumBold.copyWith(color: Colors.white)),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('assignments')
                  .where('teacherId', isEqualTo: uid)
                  .orderBy('dueDate')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assignment_outlined,
                            size: 64, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        Text(
                          'No assignments yet.\nTap "New Assignment" to create one.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snap.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
                    final overdue =
                        dueDate != null && dueDate.isBefore(DateTime.now());
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.cardShadow,
                        border: overdue
                            ? Border.all(color: AppColors.danger.withOpacity(0.4))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.teacherColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.assignment_rounded,
                                color: AppColors.teacherColor),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['title'] ?? '',
                                    style: AppTextStyles.bodyMediumBold),
                                const SizedBox(height: 3),
                                Text(
                                  '${data['className'] ?? ''} · ${data['subject'] ?? ''}',
                                  style: AppTextStyles.labelSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dueDate != null
                                      ? 'Due ${DateFormat('MMM d, yyyy').format(dueDate)}'
                                      : 'No due date',
                                  style: AppTextStyles.labelTiny.copyWith(
                                    color: overdue
                                        ? AppColors.danger
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.danger),
                            onPressed: () => FirebaseFirestore.instance
                                .collection('assignments')
                                .doc(docs[i].id)
                                .delete(),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _showAddSheet(BuildContext context, String? teacherId) {
    if (teacherId == null) return;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? dueDate;
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('New Assignment', style: AppTextStyles.headingMedium),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Title',
                  controller: titleCtrl,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Description',
                  controller: descCtrl,
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Class',
                        hint: 'e.g. Grade 9A',
                        controller: classCtrl,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CustomTextField(
                        label: 'Subject',
                        controller: subjectCtrl,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: sheetContext,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setSheetState(() => dueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: AppColors.textHint, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          dueDate != null
                              ? DateFormat('MMM d, yyyy').format(dueDate!)
                              : 'Select due date',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: dueDate != null
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Create Assignment',
                  isLoading: loading,
                  gradient: AppColors.teacherGradient,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (dueDate == null) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(content: Text('Please select a due date')),
                      );
                      return;
                    }
                    setSheetState(() => loading = true);
                    await FirebaseFirestore.instance.collection('assignments').add({
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'className': classCtrl.text.trim(),
                      'subject': subjectCtrl.text.trim(),
                      'teacherId': teacherId,
                      'dueDate': Timestamp.fromDate(dueDate!),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}