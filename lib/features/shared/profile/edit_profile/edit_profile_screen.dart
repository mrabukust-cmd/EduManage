import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/constants/app_subjects.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/widgets/custom_button.dart';
import 'package:school_management_system/core/widgets/custom_text_field.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

// ── Place this file at:
// lib/features/shared/profile/edit_profile/edit_profile_screen.dart
//
// Update route in app_router.dart:
//   GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
//
// CHANGE 1: Student "Roll No" and "Class" are admin-managed values (set when
// the admin creates/edits the student record — see AddStudentScreen,
// ClassDropdownField, RollNumberService). They were previously shown as
// editable CustomTextFields here, which let a student silently change
// their own roll number / class on this screen with zero validation and
// no write-back consistency with `class_counters` or the `classes`
// collection. They are now displayed as read-only info chips with a
// small "Set by admin" note instead.
//
// CHANGE 2: Teacher "Subject" is also admin-managed (assigned via
// ClassMultiSelectField / the subject multi-select on AddTeacherScreen,
// and used elsewhere for exact-match Firestore queries like
// `where('subjects', arrayContains: subject)` on the Timetable and
// Assignments screens). A teacher could previously free-type a subject
// here that didn't match anything in AppSubjects.allSubjects, silently
// breaking those queries. Subject is now shown as the same locked
// read-only chip used for Roll No / Class — never editable here.
//
// CHANGE 3: Teacher "Qualification" is still teacher-editable (unlike
// Subject), but is now a dropdown sourced from AppQualifications.all
// instead of a free-text field, for the same reason every other
// "pick one of a fixed set of values" field in this app (Class, Subject)
// is a dropdown rather than free text — consistency + no typo drift.

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

  // Teacher's subject — LOCKED. Read from Firestore, never edited, never
  // sent back on save. Handles both the new `subjects` array field and
  // the legacy single `subject` string field (see AuthRepository.adminCreateUser).
  String _subjectDisplay = '';

  // Teacher's qualification — still editable, but now via a dropdown
  // constrained to AppQualifications.all instead of free text.
  String? _selectedQualification;

  // Student academic info — READ-ONLY now, populated from Firestore,
  // never sent back on save.
  String _rollNo = '';
  String _className = '';
  String _section = '';

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
      _rollNo = sData['rollNo'] as String? ?? '';
      _className = sData['class'] as String? ?? '';
      _section = sData['section'] as String? ?? '';
    } else if (role == 'teacher') {
      final tDoc = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(uid)
          .get();
      final tData = tDoc.data() ?? {};

      // Prefer the new `subjects` array; fall back to the legacy single
      // `subject` string field for teachers created before that change.
      final subjectsList = (tData['subjects'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          <String>[];
      _subjectDisplay = subjectsList.isNotEmpty
          ? subjectsList.join(', ')
          : (tData['subject'] as String? ?? '');

      final storedQualification = tData['qualification'] as String? ?? '';
      // Only pre-select it in the dropdown if it's one of the known
      // values — an old/free-text qualification from before this screen
      // had a dropdown would otherwise crash DropdownButtonFormField.
      _selectedQualification =
          AppQualifications.all.contains(storedQualification)
              ? storedQualification
              : null;
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

      // Update role-specific collection.
      // NOTE: rollNo/class are intentionally NEVER written here anymore —
      // they are admin-managed fields (see header comment).
      if (role == 'student') {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(uid)
            .update({'name': name});
      } else if (role == 'teacher') {
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(uid)
            .update({
          'name': name,
          'phone': _phoneCtrl.text.trim(),
          // 'subject'/'subjects' intentionally NEVER written here — see
          // header comment (admin-managed, locked in the UI below).
          'qualification': _selectedQualification ?? '',
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
                    _SectionLabel(label: 'Personal Information', color: roleColor),
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

                    // ── Section: Academic (STATIC — admin managed) ──
                    if (role == 'student') ...[
                      const SizedBox(height: 28),
                      _SectionLabel(
                          label: 'Academic Information', color: roleColor),
                      const SizedBox(height: 6),
                      Text(
                        'Managed by your school administrator',
                        style: AppTextStyles.labelTiny
                            .copyWith(color: AppColors.textHint),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ReadOnlyInfoChip(
                              icon: Icons.tag_rounded,
                              label: 'Roll No',
                              value: _rollNo.isEmpty ? 'Not set' : _rollNo,
                              color: roleColor,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ReadOnlyInfoChip(
                              icon: Icons.class_rounded,
                              label: 'Class',
                              value: [
                                _className,
                                _section,
                              ].where((s) => s.isNotEmpty).join(' – ').let(
                                  (s) => s.isEmpty ? 'Not assigned' : s),
                              color: roleColor,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (role == 'teacher') ...[
                      const SizedBox(height: 28),
                      _SectionLabel(
                          label: 'Professional Information', color: roleColor),
                      const SizedBox(height: 6),
                      Text(
                        'Subject is assigned by your school administrator',
                        style: AppTextStyles.labelTiny
                            .copyWith(color: AppColors.textHint),
                      ),
                      const SizedBox(height: 14),

                      // Subject — LOCKED, same pattern as student Roll No / Class.
                      _ReadOnlyInfoChip(
                        icon: Icons.subject_rounded,
                        label: 'Subject',
                        value: _subjectDisplay.isEmpty
                            ? 'Not set'
                            : _subjectDisplay,
                        color: roleColor,
                      ),
                      const SizedBox(height: 16),

                      // Qualification — editable, but constrained to a
                      // fixed dropdown instead of free text.
                      _QualificationDropdown(
                        value: _selectedQualification,
                        color: roleColor,
                        onChanged: (v) =>
                            setState(() => _selectedQualification = v),
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

// ─────────────────────────────────────────────────────────────────────────────
// Helper extension (avoids extra import just for a one-liner)
// ─────────────────────────────────────────────────────────────────────────────
extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.sectionTitle),
      ],
    );
  }
}

// ── Read-only academic info chip ──────────────────────────────────────────────
//
// Replaces the previously-editable Roll No / Class CustomTextFields for
// students. Visually distinct from an input (locked icon, no border/fill
// that implies tappability) so it reads as "this is information", not
// "this is a field you forgot to fill in".
class _ReadOnlyInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ReadOnlyInfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color.withOpacity(0.8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelTiny.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.lock_outline_rounded,
                  size: 13, color: AppColors.textHint),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.bodyMediumBold.copyWith(
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Qualification dropdown ────────────────────────────────────────────────────
//
// Same purpose as ClassDropdownField / ClassMultiSelectField elsewhere in
// the app: replaces a free-text field for a value that should only ever
// be one of a known fixed set (AppQualifications.all), so it can't drift
// out of sync with whatever AddTeacherScreen / admin tooling expects.
class _QualificationDropdown extends StatelessWidget {
  final String? value;
  final Color color;
  final ValueChanged<String?> onChanged;

  const _QualificationDropdown({
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Qualification',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              borderSide: BorderSide(color: color, width: 2),
            ),
          ),
          hint: const Text(
            'Select qualification',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.textHint,
            ),
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
      ],
    );
  }
}