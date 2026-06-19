import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/widgets/custom_button.dart';
import 'package:school_management_system/core/widgets/custom_text_field.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  bool _isSaving = false;

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('students').add({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'rollNo': _rollCtrl.text.trim(),
        'class': _classCtrl.text.trim(),
        'section': _sectionCtrl.text.trim(),
        'contact': _contactCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add student: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _rollCtrl.dispose();
    _classCtrl.dispose();
    _sectionCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Add Student', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                label: 'Full Name',
                controller: _nameCtrl,
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email',
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
                label: 'Roll No',
                controller: _rollCtrl,
                prefixIcon: Icons.confirmation_number_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'Roll number required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Class',
                controller: _classCtrl,
                prefixIcon: Icons.class_rounded,
                validator: (v) => v == null || v.trim().isEmpty ? 'Class required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Section',
                controller: _sectionCtrl,
                prefixIcon: Icons.layers_rounded,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Contact',
                controller: _contactCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_rounded,
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Save Student',
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
