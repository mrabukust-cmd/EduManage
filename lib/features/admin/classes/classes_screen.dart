import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/data/models/class_model.dart';
import 'package:school_management_system/data/models/teacher_model.dart';
import 'package:school_management_system/data/providers/repository_providers.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  void _showAddClassSheet(BuildContext context, WidgetRef ref) {
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) => StatefulBuilder(
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
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
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

                  Text('Class Teacher', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 8),

                  ref.watch(approvedTeachersProvider).when(
                    loading: () => Container(
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
                    ),
                    error: (_, __) => Text(
                      'Failed to load teachers',
                      style: AppTextStyles.errorText,
                    ),
                    data: (teachers) {
                      if (teachers.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.warning,
                                size: 18,
                              ),
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
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              'None',
                              style: TextStyle(
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                          ...teachers.map((teacher) {
                            final name = teacher.name.isNotEmpty ? teacher.name : 'Unknown';
                            final subject = teacher.subject;
                            return DropdownMenuItem<String>(
                              value: teacher.id,
                              child: Text(
                                subject.isNotEmpty ? '$name — $subject' : name,
                                style: AppTextStyles.bodyMedium,
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
                              final teacher =
                                  teachers.firstWhere((t) => t.id == id);
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
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final rawName = nameCtrl.text.trim();

                      setSheetState(() => loading = true);
                      try {
                        final classRepo = ref.read(classRepositoryProvider);
                        final exists = await classRepo.existsByName(rawName);
                        if (exists) {
                          if (sheetContext.mounted) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(
                                content: Text('Class "$rawName" already exists.'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                          setSheetState(() => loading = false);
                          return;
                        }

                        final newClass = ClassModel(
                          id: '',
                          name: rawName,
                          classTeacher: selectedTeacherName ?? '',
                          teacherId: selectedTeacherId ?? '',
                          createdAt: DateTime.now(),
                        );

                        await classRepo.create(newClass);

                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Class "$rawName" created successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (sheetContext.mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add class: $e'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                          setSheetState(() => loading = false);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.adminColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.onPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Classes',
          style: AppTextStyles.headingMedium.copyWith(color: AppColors.onPrimary),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClassSheet(context, ref),
        backgroundColor: AppColors.adminColor,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Class',
          style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.onPrimary),
        ),
      ),
      body: classesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load classes: $e',
            style: AppTextStyles.errorText,
          ),
        ),
        data: (classes) {
          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.class_outlined,
                    size: 64,
                    color: AppColors.textHint,
                  ),
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
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

class _ClassCard extends ConsumerWidget {
  final String docId, name, classTeacher;

  const _ClassCard({
    required this.docId,
    required this.name,
    required this.classTeacher,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(studentCountByClassProvider(name));
    final count = countAsync.valueOrNull ?? 0;

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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    name,
                    style: AppTextStyles.labelTiny.copyWith(color: AppColors.onPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.onPrimary.withValues(alpha: 0.7),
                  size: 18,
                ),
                onSelected: (v) {
                  if (v == 'delete') {
                    ref.read(classRepositoryProvider).delete(docId);
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
            style: AppTextStyles.bodyMediumBold.copyWith(
              color: AppColors.onPrimary,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                color: AppColors.onPrimary.withValues(alpha: 0.7),
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  classTeacher,
                  style: AppTextStyles.labelTiny.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.people_outline_rounded,
                color: AppColors.onPrimary.withValues(alpha: 0.7),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '$count student${count == 1 ? '' : 's'}',
                style: AppTextStyles.labelTiny.copyWith(
                  color: AppColors.onPrimary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}