import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/data/models/class_model.dart';
import 'package:school_management_system/data/models/teacher_model.dart';
import 'package:school_management_system/data/repositories/class_repo.dart';
import 'package:school_management_system/data/repositories/student_repository.dart';
import 'package:school_management_system/data/repositories/teacher_repo.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  void _showAddClassSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    String? selectedTeacherId;
    String? selectedTeacherName;
    bool loading = false;
    final formKey = GlobalKey<FormState>();

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
                Text('Add Class', style: AppTextStyles.headingMedium),
                const SizedBox(height: 6),
                Text(
                  'Use a single name that includes the section, e.g. "Grade 9 - A"',
                  style:
                      AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Class Name',
                  hint: 'e.g. Grade 9 - A',
                  controller: nameCtrl,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                const Text(
                  'Class Teacher',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<TeacherModel>>(
                  stream: TeacherRepository.instance.watchAll(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    final teachers = (snap.data ?? [])
                        .where((t) => t.isApproved)
                        .toList();

                    if (teachers.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppColors.warning, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No approved teachers yet. You can assign one later.',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: selectedTeacherId,
                      decoration: InputDecoration(
                        hintText: 'Select a teacher (optional)',
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            'None',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.textHint),
                          ),
                        ),
                        ...teachers.map((teacher) {
                          final name = teacher.name.isNotEmpty ? teacher.name : 'Unknown';
                          final subject = teacher.subject;
                          return DropdownMenuItem<String>(
                            value: teacher.id,
                            child: Text(
                              subject.isNotEmpty ? '$name — $subject' : name,
                              style: const TextStyle(
                                  fontFamily: 'Poppins', fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (id) {
                        setSheetState(() {
                          selectedTeacherId = id;
                          if (id == null) {
                            selectedTeacherName = '';
                          } else {
                            final teacher = teachers
                                .firstWhere((t) => t.id == id);
                            selectedTeacherName = teacher.name;
                          }
                        });
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),
                CustomButton(
                  label: 'Save Class',
                  isLoading: loading,
                  gradient: AppColors.adminGradient,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setSheetState(() => loading = true);
                    await ClassRepository.instance.create(
                      ClassModel(
                        id: '',
                        name: nameCtrl.text.trim(),
                        classTeacher: selectedTeacherName ?? '',
                        classTeacherId: selectedTeacherId ?? '',
                      ),
                    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.adminColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Classes',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClassSheet(context),
        backgroundColor: AppColors.adminColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Class',
            style:
                AppTextStyles.bodyMediumBold.copyWith(color: Colors.white)),
      ),
      body: StreamBuilder<List<ClassModel>>(
        stream: ClassRepository.instance.watchAll(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final classes = snap.data ?? [];
          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.class_outlined,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text(
                    'No classes yet.\nTap "Add Class" to create one.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: classes.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, i) {
              final classItem = classes[i];
              return _ClassCard(
                docId: classItem.id,
                name: classItem.name,
                classTeacher: classItem.classTeacher.isEmpty
                    ? 'Unassigned'
                    : classItem.classTeacher,
              );
            },
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String docId, name, classTeacher;
  const _ClassCard({
    required this.docId,
    required this.name,
    required this.classTeacher,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: StudentRepository.instance.watchCountByClass(name),
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.adminGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.cardShadow,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        name,
                        style: AppTextStyles.labelTiny
                            .copyWith(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded,
                        color: Colors.white70, size: 18),
                    onSelected: (v) {
                      if (v == 'delete') {
                        ClassRepository.instance.delete(docId);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                name,
                style: AppTextStyles.bodyMediumBold
                    .copyWith(color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_rounded,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      classTeacher,
                      style: AppTextStyles.labelTiny
                          .copyWith(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.people_outline_rounded,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$count student${count == 1 ? '' : 's'}',
                    style: AppTextStyles.labelTiny
                        .copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}