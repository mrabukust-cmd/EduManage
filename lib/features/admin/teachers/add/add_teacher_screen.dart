import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../../../../core/widgets/class_multi_select_field.dart';

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
  final _subjectCtrl = TextEditingController();
  final _qualificationCtrl = TextEditingController();
  List<String> _selectedClasses = []; // FIX: was a comma-separated free-
  // text controller (_classesCtrl). Free text let admins type "Grade 9A"
  // for one teacher and "9A" for another, which silently broke
  // TeacherRepository.watchAssignedClassNames (exact-match against the
  // `classes` collection) the same way it broke student attendance — see
  // core/widgets/class_multi_select_field.dart for the full rationale.
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _subjectCtrl.dispose();
    _qualificationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // FIXED: routed through AuthNotifier.adminCreateUser, which uses a
    // secondary FirebaseApp instance so the admin's session is preserved.
    final error = await ref.read(authProvider.notifier).adminCreateUser(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: 'teacher',
          extraData: {
            'phone': _phoneCtrl.text.trim(),
            'subject': _subjectCtrl.text.trim(),
            'qualification': _qualificationCtrl.text.trim(),
            'classes': _selectedClasses, // exact matches to classes.name
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('${_nameCtrl.text.trim()} has been added successfully.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    // Admin remains logged in — no need to route to /login.
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
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.teacherColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.teacherColor.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded, color: AppColors.teacherColor, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Creating a teacher account. They will be able to login immediately. You will stay signed in as admin.',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              CustomTextField(
                label: 'Full Name',
                controller: _nameCtrl,
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
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
                validator: (v) => v == null || v.trim().isEmpty ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Subject',
                      controller: _subjectCtrl,
                      prefixIcon: Icons.subject_rounded,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomTextField(
                      label: 'Qualification',
                      controller: _qualificationCtrl,
                      prefixIcon: Icons.school_outlined,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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