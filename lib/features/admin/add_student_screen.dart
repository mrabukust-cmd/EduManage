import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final _passwordCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  bool _isSaving = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _rollCtrl.dispose();
    _classCtrl.dispose();
    _sectionCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      // Step 1: Remember the current admin's credentials
      final currentAdmin = FirebaseAuth.instance.currentUser;
      if (currentAdmin == null) throw Exception('Admin not logged in');

      // Step 2: Create Firebase Auth account for the student
      // We create via a secondary app approach — here we use the REST API trick:
      // Sign in with the student email creates a new user, then we restore admin.
      // Simplest: create the user, restore admin session with token refresh.

      final adminEmail = currentAdmin.email!;

      // Create student auth account
      // Note: This will sign out admin temporarily — we restore immediately
      UserCredential studentCred;
      try {
        // We need admin's password to restore — but we don't have it stored.
        // Best approach: use Admin SDK (not available client-side).
        // Client-side workaround: create user doesn't sign in if we use the
        // createUser call carefully. Unfortunately Firebase client SDK always
        // signs in the new user. So we save admin's ID token first.
        final adminIdToken = await currentAdmin.getIdToken();

        studentCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

        await studentCred.user!.updateDisplayName(_nameCtrl.text.trim());

        // Create Firestore docs for the student
        await FirebaseFirestore.instance.collection('users').doc(studentCred.user!.uid).set({
          'uid': studentCred.user!.uid,
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'role': 'student',
          'approved': true, // admin is adding => auto approved
          'photoUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance.collection('students').doc(studentCred.user!.uid).set({
          'uid': studentCred.user!.uid,
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'rollNo': _rollCtrl.text.trim(),
          'class': _classCtrl.text.trim(),
          'section': _sectionCtrl.text.trim(),
          'contact': _contactCtrl.text.trim(),
          'approved': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Step 3: Sign the student out and restore admin session
        await FirebaseAuth.instance.signOut();
        // Re-sign in admin — we need admin's email but not password here.
        // Use the stored token to restore:
        // Since we can't restore without password client-side,
        // we prompt admin to sign in again OR we use a trick:
        // Store admin credentials temporarily (not secure for prod).
        // For this app, we show a dialog telling admin to re-login.
        // Better UX: just sign admin back in using their stored session.

        if (mounted) {
          _showSuccessAndReloginPrompt();
        }
      } catch (createError) {
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'Failed to create student account.';
      if (e.code == 'email-already-in-use') msg = 'This email is already registered.';
      if (e.code == 'weak-password') msg = 'Password must be at least 6 characters.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
      setState(() => _isSaving = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
      setState(() => _isSaving = false);
    }
  }

  void _showSuccessAndReloginPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
            SizedBox(width: 10),
            Text(
              'Student Added!',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_nameCtrl.text.trim()} has been added successfully.',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will need to sign in again as admin because Firebase signs in the new user automatically.',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to login — admin will re-authenticate
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK, Sign In Again',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );
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
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
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
                  border: Border.all(color: AppColors.adminColor.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded, color: AppColors.adminColor, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Creating a student account. They will be able to login immediately.',
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
                validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
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
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Roll No',
                      controller: _rollCtrl,
                      prefixIcon: Icons.confirmation_number_outlined,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomTextField(
                      label: 'Class',
                      controller: _classCtrl,
                      prefixIcon: Icons.class_rounded,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Section',
                      controller: _sectionCtrl,
                      prefixIcon: Icons.layers_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomTextField(
                      label: 'Contact',
                      controller: _contactCtrl,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_rounded,
                    ),
                  ),
                ],
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