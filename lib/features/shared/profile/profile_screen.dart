import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/data/services/cloudinary_service.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Profile data model (assembled from users + role-specific doc)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileData {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String bio;
  final String photoUrl;
  final String role;
  // student-specific
  final String? rollNo;
  final String? className;
  final String? section;
  // teacher-specific
  final String? subject;
  final String? qualification;
  final List<String>? classes;

  const _ProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.bio,
    required this.photoUrl,
    required this.role,
    this.rollNo,
    this.className,
    this.section,
    this.subject,
    this.qualification,
    this.classes,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// FutureProvider: load all profile data in one shot
// ─────────────────────────────────────────────────────────────────────────────

final _profileProvider = FutureProvider.autoDispose<_ProfileData>((ref) async {
  final authState = ref.watch(authProvider);
  final uid = authState.user?.uid;
  final role = authState.role ?? 'student';
  if (uid == null) throw Exception('Not signed in');

  final db = FirebaseFirestore.instance;

  final userDoc = await db.collection('users').doc(uid).get();
  final u = userDoc.data() ?? {};

  String? rollNo, className, section, subject, qualification;
  List<String>? classes;

  if (role == 'student') {
    final sDoc = await db.collection('students').doc(uid).get();
    final s = sDoc.data() ?? {};
    rollNo = s['rollNo'] as String?;
    className = s['class'] as String?;
    section = s['section'] as String?;
  } else if (role == 'teacher') {
    final tDoc = await db.collection('teachers').doc(uid).get();
    final t = tDoc.data() ?? {};
    subject = t['subject'] as String?;
    qualification = t['qualification'] as String?;
    classes = (t['classes'] as List<dynamic>?)?.map((e) => e.toString()).toList();
  }

  return _ProfileData(
    name: u['name'] as String? ?? authState.user?.displayName ?? 'User',
    email: u['email'] as String? ?? authState.user?.email ?? '',
    phone: u['phone'] as String? ?? '',
    address: u['address'] as String? ?? '',
    bio: u['bio'] as String? ?? '',
    photoUrl: u['photoUrl'] as String? ?? authState.user?.photoURL ?? '',
    role: role,
    rollNo: rollNo,
    className: className,
    section: section,
    subject: subject,
    qualification: qualification,
    classes: classes,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _uploadingPhoto = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Color get _roleColor {
    final role = ref.read(authProvider).role ?? 'student';
    return switch (role) {
      'admin' => AppColors.adminColor,
      'teacher' => AppColors.teacherColor,
      _ => AppColors.studentColor,
    };
  }

  Gradient get _roleGradient {
    final role = ref.read(authProvider).role ?? 'student';
    return switch (role) {
      'admin' => AppColors.adminGradient,
      'teacher' => AppColors.teacherGradient,
      _ => AppColors.studentGradient,
    };
  }

  String _roleLabel(String role) => switch (role) {
        'admin' => 'Administrator',
        'teacher' => 'Teacher',
        _ => 'Student',
      };

  // ── Photo upload ────────────────────────────────────────────────────────────

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null) return;

    if (!mounted) return;
    setState(() => _uploadingPhoto = true);

    try {
      final uid = ref.read(authProvider).user?.uid;
      if (uid == null) {
        if (mounted) {
          _showSnack('Please sign in before updating your photo.', AppColors.danger);
        }
        return;
      }

      final file = File(picked.path);
      final url = await CloudinaryService.instance.uploadProfilePhoto(
        file: file,
        uid: uid,
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'photoUrl': url,
      });
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);

      ref.invalidate(_profileProvider);

      if (mounted) {
        _showSnack('Profile photo updated', AppColors.success);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Upload failed: $e', AppColors.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text('You will be returned to the login screen.',
            style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ref.read(authProvider.notifier).signOut();
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(_profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load profile',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ),
        data: (profile) => FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(profile),
              SliverToBoxAdapter(child: _buildBody(profile)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Collapsing hero app bar ─────────────────────────────────────────────────

  Widget _buildAppBar(_ProfileData profile) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      elevation: 0,
      backgroundColor: _roleColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
          onPressed: () => context.push('/profile/edit'),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHero(profile),
      ),
      title: Text(
        profile.name,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHero(_ProfileData profile) {
    return Container(
      decoration: BoxDecoration(gradient: _roleGradient),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            // ── Avatar with upload button ──────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Glow ring
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white.withOpacity(0.35), width: 3),
                  ),
                ),
                // Avatar
                SizedBox(
                  width: 108,
                  height: 108,
                  child: ClipOval(
                    child: _uploadingPhoto
                        ? Container(
                            color: Colors.white24,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            ),
                          )
                        : profile.photoUrl.isNotEmpty
                            ? Image.network(
                                profile.photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _avatarFallback(profile.name),
                              )
                            : _avatarFallback(profile.name),
                  ),
                ),
                // Upload button
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: _roleColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Name
            Text(
              profile.name,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 6),

            // Role badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _roleLabel(profile.role),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Email
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.email_rounded,
                    size: 14, color: Colors.white60),
                const SizedBox(width: 6),
                Text(
                  profile.email,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: Colors.white24,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody(_ProfileData profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats row (for student/teacher) ─────────────────
          if (profile.role == 'student')
            _buildStudentStats(profile),
          if (profile.role == 'teacher')
            _buildTeacherStats(profile),

          const SizedBox(height: 24),

          // ── Bio ───────────────────────────────────────────────
          if (profile.bio.isNotEmpty) ...[
            _SectionCard(
              title: 'About',
              icon: Icons.person_outline_rounded,
              color: _roleColor,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Text(
                    profile.bio,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary, height: 1.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── Personal Information ──────────────────────────────
          _SectionCard(
            title: 'Personal Information',
            icon: Icons.badge_outlined,
            color: _roleColor,
            children: [
              _InfoRow(
                icon: Icons.phone_rounded,
                label: 'Phone',
                value: profile.phone.isEmpty ? 'Not set' : profile.phone,
                isEmpty: profile.phone.isEmpty,
              ),
              _InfoRow(
                icon: Icons.location_on_rounded,
                label: 'Address',
                value: profile.address.isEmpty ? 'Not set' : profile.address,
                isEmpty: profile.address.isEmpty,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Academic / Professional ────────────────────────────
          if (profile.role == 'student')
            _buildStudentAcademic(profile),
          if (profile.role == 'teacher')
            _buildTeacherProfessional(profile),

          if (profile.role != 'admin') const SizedBox(height: 16),

          // ── Settings ──────────────────────────────────────────
          _SectionCard(
            title: 'Settings',
            icon: Icons.settings_outlined,
            color: _roleColor,
            children: [
              _SettingRow(
                icon: Icons.lock_rounded,
                label: 'Change Password',
                color: _roleColor,
                onTap: () => context.push('/settings/password'),
              ),
              _SettingRow(
                icon: Icons.notifications_rounded,
                label: 'Notifications',
                color: _roleColor,
                onTap: () => context.push('/settings/notifications'),
              ),
              _SettingRow(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                color: _roleColor,
                onTap: () => context.push('/help'),
              ),
              _SettingRow(
                icon: Icons.info_outline_rounded,
                label: 'About App',
                color: _roleColor,
                onTap: () => context.push('/about'),
                showDivider: false,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Logout ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
              label: const Text(
                'Log Out',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Student stats row ──────────────────────────────────────────────────────

  Widget _buildStudentStats(_ProfileData profile) {
    final uid = ref.read(authProvider).user?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: uid)
          .snapshots(),
      builder: (context, attSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('results')
              .where('studentId', isEqualTo: uid)
              .snapshots(),
          builder: (context, resSnap) {
            final attDocs = attSnap.data?.docs ?? [];
            int present = 0;
            for (final d in attDocs) {
              if ((d.data() as Map<String, dynamic>)['status'] == 'present') {
                present++;
              }
            }
            final attPct = attDocs.isEmpty
                ? 0
                : ((present / attDocs.length) * 100).round();

            final resDocs = resSnap.data?.docs ?? [];
            double totalPct = 0;
            for (final d in resDocs) {
              totalPct +=
                  ((d.data() as Map<String, dynamic>)['percentage'] as num?)
                          ?.toDouble() ??
                      0;
            }
            final avg =
                resDocs.isEmpty ? 0.0 : totalPct / resDocs.length;

            return Row(
              children: [
                _StatTile(
                  value: '$attPct%',
                  label: 'Attendance',
                  icon: Icons.how_to_reg_rounded,
                  color: attPct >= 75
                      ? AppColors.success
                      : AppColors.danger,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  value: avg == 0 ? '--' : '${avg.toStringAsFixed(0)}%',
                  label: 'Avg Grade',
                  icon: Icons.bar_chart_rounded,
                  color: _roleColor,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  value: '${resDocs.length}',
                  label: 'Results',
                  icon: Icons.assignment_turned_in_rounded,
                  color: AppColors.accent,
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Teacher stats row ───────────────────────────────────────────────────────

  Widget _buildTeacherStats(_ProfileData profile) {
    final uid = ref.read(authProvider).user?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('assignments')
          .where('teacherId', isEqualTo: uid)
          .snapshots(),
      builder: (context, assignSnap) {
        final classCount = profile.classes?.length ?? 0;
        final assignCount = assignSnap.data?.docs.length ?? 0;

        return Row(
          children: [
            _StatTile(
              value: '$classCount',
              label: 'Classes',
              icon: Icons.class_rounded,
              color: AppColors.teacherColor,
            ),
            const SizedBox(width: 12),
            _StatTile(
              value: '$assignCount',
              label: 'Assignments',
              icon: Icons.assignment_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            _StatTile(
              value: profile.subject?.isNotEmpty == true
                  ? profile.subject!.split(' ').first
                  : '--',
              label: 'Subject',
              icon: Icons.subject_rounded,
              color: AppColors.accent,
            ),
          ],
        );
      },
    );
  }

  // ── Student academic section ────────────────────────────────────────────────

  Widget _buildStudentAcademic(_ProfileData profile) {
    return _SectionCard(
      title: 'Academic Information',
      icon: Icons.school_outlined,
      color: _roleColor,
      children: [
        _InfoRow(
          icon: Icons.class_rounded,
          label: 'Class',
          value: [profile.className, profile.section]
              .where((s) => s != null && s.isNotEmpty)
              .join(' – ')
              .let((s) => s.isEmpty ? 'Not assigned' : s),
          isEmpty: profile.className == null || profile.className!.isEmpty,
        ),
        _InfoRow(
          icon: Icons.badge_rounded,
          label: 'Roll No',
          value: profile.rollNo?.isEmpty != false ? 'Not set' : profile.rollNo!,
          isEmpty: profile.rollNo == null || profile.rollNo!.isEmpty,
        ),
      ],
    );
  }

  // ── Teacher professional section ─────────────────────────────────────────────

  Widget _buildTeacherProfessional(_ProfileData profile) {
    final classList = profile.classes ?? [];
    return _SectionCard(
      title: 'Professional Information',
      icon: Icons.work_outline_rounded,
      color: _roleColor,
      children: [
        _InfoRow(
          icon: Icons.subject_rounded,
          label: 'Subject',
          value: profile.subject?.isEmpty != false ? 'Not set' : profile.subject!,
          isEmpty: profile.subject == null || profile.subject!.isEmpty,
        ),
        _InfoRow(
          icon: Icons.school_rounded,
          label: 'Qualification',
          value: profile.qualification?.isEmpty != false
              ? 'Not set'
              : profile.qualification!,
          isEmpty:
              profile.qualification == null || profile.qualification!.isEmpty,
        ),
        if (classList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.class_rounded,
                        size: 18, color: _roleColor),
                    const SizedBox(width: 10),
                    Text('Classes',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: classList
                      .map((c) => _ClassChip(label: c, color: _roleColor))
                      .toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper extension (avoids import)
// ─────────────────────────────────────────────────────────────────────────────

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelTiny,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Text(title, style: AppTextStyles.sectionTitle),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.divider),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isEmpty;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isEmpty ? AppColors.textHint : AppColors.textPrimary,
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyMedium),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ClassChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ClassChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelTiny.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

 //STEP 7 ─ Display the Cloudinary URL anywhere an image is shown
// ──────────────────────────────────────────────────────────────
// The URL returned is a standard HTTPS link — just pass it to Image.network:
//
//   Image.network(
//     profile.photoUrl,
//     fit: BoxFit.cover,
//     // Add a resize transformation right in the URL for thumbnails:
//     // replace '/upload/' with '/upload/w_100,h_100,c_fill,g_face/'
//     errorBuilder: (_, __, ___) => _avatarFallback(profile.name),
//   )