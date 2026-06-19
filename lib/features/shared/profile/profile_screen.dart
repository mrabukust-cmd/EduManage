import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final role = authState.role; // 'admin' | 'teacher' | 'student'

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
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white), onPressed: () => context.pop()),
        title: Text('Profile', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile Header ──────────────────────────────────
            Container(
              color: roleColor,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white30,
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 52),
                  ),
                  const SizedBox(height: 14),
                  Text(user?.displayName ?? 'User Name', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      role == 'admin' ? 'Administrator' : role == 'teacher' ? 'Teacher' : 'Student',
                      style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Info Section ────────────────────────────────────
            _SectionCard(
              title: 'Personal Information',
              children: [
                _InfoRow(icon: Icons.email_rounded, label: 'Email', value: user?.email ?? 'user@example.com'),
                _InfoRow(icon: Icons.phone_rounded, label: 'Phone', value: '+92 300 1234567'),
                _InfoRow(icon: Icons.location_on_rounded, label: 'Address', value: 'Kohat, KPK, Pakistan'),
                if (role == 'student') ...[
                  _InfoRow(icon: Icons.class_rounded, label: 'Class', value: 'Grade 9 – Section A'),
                  _InfoRow(icon: Icons.badge_rounded, label: 'Roll No', value: '001'),
                ],
                if (role == 'teacher') ...[
                  _InfoRow(icon: Icons.subject_rounded, label: 'Subject', value: 'Mathematics & Physics'),
                  _InfoRow(icon: Icons.class_rounded, label: 'Classes', value: 'Grade 8, 9, 10'),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // ── Settings Section ────────────────────────────────
            _SectionCard(
              title: 'Settings',
              children: [
                _SettingRow(icon: Icons.notifications_rounded, label: 'Notifications', onTap: () => context.push('/settings/notifications')),
                _SettingRow(icon: Icons.lock_rounded, label: 'Change Password', onTap: () => context.push('/settings/password')),
                _SettingRow(icon: Icons.language_rounded, label: 'Language', onTap: () => context.push('/settings/language')),
                _SettingRow(icon: Icons.help_rounded, label: 'Help & Support', onTap: () => context.push('/help')),
                _SettingRow(icon: Icons.info_rounded, label: 'About App', onTap: () => context.push('/about')),
              ],
            ),

            const SizedBox(height: 16),

            // ── Logout ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ref.read(authProvider.notifier).signOut();
                            },
                            child: const Text('Logout', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: Text('Logout', style: AppTextStyles.bodyMediumBold.copyWith(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text(title, style: AppTextStyles.sectionTitle),
            ),
            const Divider(height: 1, color: AppColors.divider),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text('$label:', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}