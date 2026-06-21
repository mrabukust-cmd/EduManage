import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/widgets/custom_button.dart';
import 'package:school_management_system/core/widgets/custom_text_field.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

// ── Place this file at:
// lib/features/shared/profile/edit_profile_screen.dart
//
// Update route in app_router.dart:
//   GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  // Role-specific
  final _rollCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _qualificationCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = ref.read(authProvider).user?.uid;
    final role = ref.read(authProvider).role;
    if (uid == null) return;

    // Load from users collection
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = userDoc.data() ?? {};

    _nameCtrl.text = data['name'] as String? ?? '';
    _phoneCtrl.text = data['phone'] as String? ?? '';
    _addressCtrl.text = data['address'] as String? ?? '';
    _bioCtrl.text = data['bio'] as String? ?? '';

    // Role-specific
    if (role == 'student') {
      final sDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .get();
      final sData = sDoc.data() ?? {};
      _rollCtrl.text = sData['rollNo'] as String? ?? '';
      _classCtrl.text = sData['class'] as String? ?? '';
    } else if (role == 'teacher') {
      final tDoc = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(uid)
          .get();
      final tData = tDoc.data() ?? {};
      _subjectCtrl.text = tData['subject'] as String? ?? '';
      _qualificationCtrl.text = tData['qualification'] as String? ?? '';
    }

    if (mounted) setState(() => _isFetching = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final uid = ref.read(authProvider).user?.uid;
      final role = ref.read(authProvider).role;
      if (uid == null) return;

      final name = _nameCtrl.text.trim();

      // Update Firebase Auth display name
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);

      // Update users collection
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': name,
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update role-specific collection
      if (role == 'student') {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(uid)
            .update({
          'name': name,
          'rollNo': _rollCtrl.text.trim(),
          'class': _classCtrl.text.trim(),
        });
      } else if (role == 'teacher') {
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(uid)
            .update({
          'name': name,
          'phone': _phoneCtrl.text.trim(),
          'subject': _subjectCtrl.text.trim(),
          'qualification': _qualificationCtrl.text.trim(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _bioCtrl.dispose();
    _rollCtrl.dispose();
    _classCtrl.dispose();
    _subjectCtrl.dispose();
    _qualificationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).role ?? 'student';

    final roleColor = role == 'admin'
        ? AppColors.adminColor
        : role == 'teacher'
            ? AppColors.teacherColor
            : AppColors.studentColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: roleColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Edit Profile',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar section ───────────────────────────
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: roleColor.withOpacity(0.15),
                            child: Icon(Icons.person_rounded,
                                size: 56, color: roleColor),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: roleColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Section: Personal ────────────────────────
                    _SectionLabel(label: 'Personal Information'),
                    const SizedBox(height: 14),

                    CustomTextField(
                      label: 'Full Name',
                      controller: _nameCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Phone Number',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Address',
                      controller: _addressCtrl,
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Bio',
                      hint: 'A short description about yourself',
                      controller: _bioCtrl,
                      prefixIcon: Icons.info_outline_rounded,
                      maxLines: 3,
                    ),

                    // ── Section: Role-specific ───────────────────
                    if (role == 'student') ...[
                      const SizedBox(height: 28),
                      _SectionLabel(label: 'Academic Information'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Roll No',
                              controller: _rollCtrl,
                              prefixIcon: Icons.tag_rounded,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: CustomTextField(
                              label: 'Class',
                              controller: _classCtrl,
                              prefixIcon: Icons.class_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (role == 'teacher') ...[
                      const SizedBox(height: 28),
                      _SectionLabel(label: 'Professional Information'),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Subject',
                        controller: _subjectCtrl,
                        prefixIcon: Icons.subject_rounded,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Qualification',
                        controller: _qualificationCtrl,
                        prefixIcon: Icons.school_outlined,
                      ),
                    ],

                    const SizedBox(height: 32),

                    CustomButton(
                      label: 'Save Changes',
                      onPressed: _save,
                      isLoading: _isLoading,
                      gradient: role == 'admin'
                          ? AppColors.adminGradient
                          : role == 'teacher'
                              ? AppColors.teacherGradient
                              : AppColors.studentGradient,
                    ),

                    const SizedBox(height: 16),

                    // Change password link
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _showChangePasswordDialog(context),
                        icon: const Icon(Icons.lock_outline_rounded,
                            size: 18, color: AppColors.textSecondary),
                        label: Text('Change Password',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Change Password', style: AppTextStyles.headingMedium),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: 'Current Password',
                  controller: currentCtrl,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'New Password',
                  controller: newCtrl,
                  isPassword: true,
                  prefixIcon: Icons.lock_reset_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Confirm Password',
                  controller: confirmCtrl,
                  isPassword: true,
                  prefixIcon: Icons.lock_reset_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != newCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialog(() => loading = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser!;
                        final cred = EmailAuthProvider.credential(
                          email: user.email!,
                          password: currentCtrl.text,
                        );
                        await user.reauthenticateWithCredential(cred);
                        await user.updatePassword(newCtrl.text);
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  const Text('Password changed successfully'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        setDialog(() => loading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.message ?? 'Error'),
                            backgroundColor: AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.sectionTitle),
      ],
    );
  }
}