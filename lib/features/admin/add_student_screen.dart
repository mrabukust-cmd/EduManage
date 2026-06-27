import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/widgets/class_dropdown.dart';
import 'package:school_management_system/core/widgets/custom_button.dart';
import 'package:school_management_system/core/widgets/custom_text_field.dart';
import 'package:school_management_system/data/services/notification_helper.dart';
import 'package:school_management_system/data/services/roll_number_service.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();

  String? _selectedClass;
  String _rollPreview = '—';
  bool _loadingPreview = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _onClassChanged(String? className) async {
    setState(() {
      _selectedClass = className;
      _rollPreview = '—';
    });
    if (className == null || className.isEmpty) return;
    setState(() => _loadingPreview = true);
    final preview =
        await RollNumberService.instance.peekNextRollNo(className);
    if (mounted) {
      setState(() {
        _rollPreview = preview;
        _loadingPreview = false;
      });
    }
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null || _selectedClass!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class')),
      );
      return;
    }

    setState(() => _isSaving = true);

    String rollNo;
    try {
      rollNo = await RollNumberService.instance.nextRollNo(_selectedClass!);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate roll number: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    final name = _nameCtrl.text.trim();
    final error = await ref.read(authProvider.notifier).adminCreateUser(
          name: name,
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: 'student',
          extraData: {
            'rollNo': rollNo,
            'class': _selectedClass,
            'section': '',
            'contact': _contactCtrl.text.trim(),
          },
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }

    // ── Notify the newly created student ─────────────────────────────────
    try {
      final snap = await FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: _emailCtrl.text.trim())
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await AppNotifications.onStudentAdded(
          studentUid: snap.docs.first.id,
          studentName: name,
          className: _selectedClass!,
          rollNo: rollNo,
        );
      }
    } catch (_) {
      // Non-fatal — student account was created successfully.
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name added — Roll No $rollNo'),
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
      appBar: AppBar(
        backgroundColor: AppColors.adminColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Add Student',
            style:
                AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.adminColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.adminColor.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded,
                        color: AppColors.adminColor, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Creating a student account. They will be able to '
                        'login immediately. You will stay signed in as admin.',
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
                    v == null || v.trim().isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email Address',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email required';
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
              ClassDropdownField(
                value: _selectedClass,
                onChanged: _onClassChanged,
              ),
              const SizedBox(height: 10),
              _RollPreviewChip(
                preview: _rollPreview,
                loading: _loadingPreview,
                hasClass: _selectedClass != null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Contact',
                controller: _contactCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_rounded,
              ),
              const SizedBox(height: 28),
              CustomButton(
                label: 'Create Student Account',
                isLoading: _isSaving,
                gradient: AppColors.adminGradient,
                onPressed: _saveStudent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RollPreviewChip extends StatelessWidget {
  final String preview;
  final bool loading;
  final bool hasClass;

  const _RollPreviewChip({
    required this.preview,
    required this.loading,
    required this.hasClass,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: hasClass ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.adminColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.adminColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.tag_rounded,
                size: 16, color: AppColors.adminColor.withOpacity(0.8)),
            const SizedBox(width: 8),
            Text(
              'Roll No will be assigned: ',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            if (loading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: AppColors.adminColor),
              )
            else
              Text(
                preview,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.adminColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const Spacer(),
            Text('auto-generated',
                style: AppTextStyles.labelTiny
                    .copyWith(color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}