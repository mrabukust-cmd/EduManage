import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/data/services/notification_helper.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../../../../core/widgets/class_multi_select_field.dart';
import 'package:school_management_system/core/constants/app_subjects.dart';

class AddTeacherScreen extends ConsumerStatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  ConsumerState<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends ConsumerState<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  List<String> _selectedClasses = [];
  List<String> _selectedSubjects = [];
  String? _selectedQualification;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one subject.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_selectedQualification == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a qualification.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    final error = await ref.read(authProvider.notifier).adminCreateUser(
          name: name,
          email: email,
          password: _passwordCtrl.text,
          role: 'teacher',
          extraData: {
            'phone': _phoneCtrl.text.trim(),
            'subjects': _selectedSubjects,
            'qualification': _selectedQualification,
            'classes': _selectedClasses,
          },
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }

    // ── Send welcome notification to the new teacher ─────────────────────
    // Look up the uid that was just created via the teachers collection.
    try {
      final snap = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await AppNotifications.onTeacherAdded(
          teacherUid: snap.docs.first.id,
          teacherName: name,
        );
      }
    } catch (_) {
      // Non-fatal — account was created; notification is best-effort.
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name has been added successfully.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.teacherColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Add Teacher',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.teacherColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.teacherColor.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded,
                        color: AppColors.teacherColor, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Creating a teacher account. They will be able to login '
                        'immediately. You will stay signed in as admin.',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              CustomTextField(
                label: 'Full Name',
                controller: _nameCtrl,
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email Address',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Login Password',
                hint: 'Min. 6 characters',
                controller: _passwordCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Password required';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Phone',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),

              // Qualification
              _QualificationDropdown(
                value: _selectedQualification,
                onChanged: (v) => setState(() => _selectedQualification = v),
              ),
              const SizedBox(height: 16),

              // Subjects
              _SubjectMultiSelect(
                selected: _selectedSubjects,
                onChanged: (v) => setState(() => _selectedSubjects = v),
              ),
              const SizedBox(height: 16),

              // Classes
              ClassMultiSelectField(
                selected: _selectedClasses,
                onChanged: (v) => setState(() => _selectedClasses = v),
              ),
              const SizedBox(height: 28),

              CustomButton(
                label: 'Create Teacher Account',
                onPressed: _save,
                isLoading: _loading,
                gradient: AppColors.teacherGradient,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Qualification dropdown ─────────────────────────────────────────────────────
class _QualificationDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _QualificationDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Qualification',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: const Text(
                'Select qualification',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.textHint),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary),
              borderRadius: BorderRadius.circular(14),
              items: AppQualifications.all
                  .map((q) => DropdownMenuItem(
                        value: q,
                        child: Text(q,
                            style: const TextStyle(
                                fontFamily: 'Poppins', fontSize: 14)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Subject multi-select ───────────────────────────────────────────────────────
class _SubjectMultiSelect extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _SubjectMultiSelect(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final subjects = AppSubjects.allSubjects;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subjects Taught',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subjects.map((subject) {
              final isSelected = selected.contains(subject);
              return GestureDetector(
                onTap: () {
                  final next = List<String>.from(selected);
                  if (isSelected) {
                    next.remove(subject);
                  } else {
                    next.add(subject);
                  }
                  onChanged(next);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.teacherColor
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.teacherColor
                          : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        subject,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (selected.isEmpty) ...[
          const SizedBox(height: 6),
          const Text(
            'No subjects selected yet — tap to assign.',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textHint),
          ),
        ],
      ],
    );
  }
}