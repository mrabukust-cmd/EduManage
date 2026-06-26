import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/constants/app_strings.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

// ── Place this file at:
// lib/features/shared/legal/privacy_policy_screen.dart
//
// Add to app_router.dart:
//   GoRoute(path: '/legal/privacy',
//       builder: (_, __) => const PrivacyPolicyScreen()),
//
// Content is written specifically for a school management context
// (admin/teacher/student/parent roles, attendance, grades, fees,
// Firebase-backed storage) rather than generic boilerplate. Replace the
// placeholder contact email / school name before shipping to a real
// institution, and have your school's data-protection officer or legal
// counsel review before publishing.

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  static const _lastUpdated = 'June 2026';
  static const _supportEmail = 'privacy@edumanage.app';

  Color _roleColor(WidgetRef ref) {
    final role = ref.read(authProvider).role ?? 'student';
    return switch (role) {
      'admin' => AppColors.adminColor,
      'teacher' => AppColors.teacherColor,
      _ => AppColors.studentColor,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleColor = _roleColor(ref);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: roleColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Privacy Policy',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          _HeaderBlock(
            icon: Icons.privacy_tip_rounded,
            color: roleColor,
            title: '${AppStrings.appName} Privacy Policy',
            subtitle: 'Last updated: $_lastUpdated',
          ),
          const SizedBox(height: 24),

          const _Paragraph(
            'This Privacy Policy explains how ${AppStrings.appName} ("the App") '
            'collects, uses, stores, and protects information belonging to '
            'administrators, teachers, students, and parents/guardians who use '
            'the App as part of their school\'s operations. By using the App, '
            'you agree to the practices described here.',
          ),

          _SectionTitle(title: '1. Who This Policy Covers', color: roleColor),
          const _Paragraph(
            'The App is used by four types of accounts: school Admins, '
            'Teachers, Students, and Parents/Guardians. Each role sees and can '
            'enter different information, as described below. A child\'s data '
            'is created and managed primarily by the school Admin and the '
            'child\'s teachers — students and parents have limited, read-mostly '
            'access scoped to their own records.',
          ),

          _SectionTitle(title: '2. Information We Collect', color: roleColor),
          const _Bullet('Account information: name, email address, phone '
              'number, role (admin/teacher/student/parent), and a profile '
              'photo if you choose to upload one.'),
          const _Bullet('Academic records: class/section assignment, roll '
              'number, attendance entries, exam results, grades, and '
              'assignment submissions.'),
          const _Bullet('Financial records: fee amounts, due dates, and '
              'payment status, visible only to the relevant student\'s '
              'family and to school Admins.'),
          const _Bullet('Communication data: notices, announcements, and '
              'in‑app notifications sent to your account.'),
          const _Bullet('Device information: a push‑notification token used '
              'to deliver alerts to your device, and basic technical data '
              '(app version, platform) needed to keep the App working.'),
          const _Bullet('Parent–child links: which parent account(s) are '
              'connected to which student account(s), set up by the school '
              'Admin during approval.'),

          _SectionTitle(title: '3. How We Use Your Information', color: roleColor),
          const _Bullet('To operate core features: attendance tracking, '
              'grading, timetables, fee tracking, and notices.'),
          const _Bullet('To let parents view their own child\'s attendance, '
              'results, and fee status — and nothing belonging to other '
              'students.'),
          const _Bullet('To send notices and alerts relevant to your role '
              '(e.g. exam schedules, fee reminders, attendance warnings).'),
          const _Bullet('To verify identity during sign‑in and to approve '
              'new student, teacher, and parent registrations.'),
          const _Bullet('To maintain the security and integrity of school '
              'records (e.g. preventing duplicate attendance entries).'),
          const _Paragraph(
            'We do not use student, parent, or teacher data for advertising, '
            'and we do not sell personal information to third parties.',
          ),

          _SectionTitle(title: '4. Children\'s Information', color: roleColor),
          const _Paragraph(
            'Student accounts may belong to minors. Student profiles, '
            'attendance, and academic records are created and controlled by '
            'the school Admin, not self‑registered with sensitive data by the '
            'child. Parents/guardians can view their linked child\'s academic '
            'and attendance information at any time. If you are a parent and '
            'believe information about your child is inaccurate or should be '
            'removed, contact your school\'s Admin or use the contact details '
            'in Section 9.',
          ),

          _SectionTitle(
              title: '5. Who Can See What', color: roleColor),
          const _Bullet('Admins can see and manage all student, teacher, '
              'and parent records at their school.'),
          const _Bullet('Teachers can see students, attendance, grades, and '
              'assignments for the classes they are assigned to — not the '
              'whole school.'),
          const _Bullet('Students can see their own attendance, results, '
              'assignments, timetable, and notices — not other students\' '
              'records.'),
          const _Bullet('Parents can see only the records of the child(ren) '
              'linked to their account by the school Admin.'),

          _SectionTitle(title: '6. Data Storage & Security', color: roleColor),
          const _Paragraph(
            'Data is stored using Firebase (Firestore, Authentication, and '
            'Storage), a cloud platform with industry‑standard security '
            'practices including encryption in transit. Access to each '
            'record is restricted by role using server‑side security rules, '
            'so, for example, a student account cannot read another '
            'student\'s attendance or fee records even by guessing an ID. '
            'Passwords are never stored in plain text — authentication is '
            'handled entirely by Firebase Authentication.',
          ),

          _SectionTitle(title: '7. Data Retention', color: roleColor),
          const _Paragraph(
            'Academic and attendance records are retained for as long as '
            'the school chooses to keep them, consistent with standard '
            'school record‑keeping practices. If an account is rejected '
            'during the approval process, its profile data is deleted. If '
            'you would like your account\'s data removed after leaving the '
            'school, contact your school Admin, who can action this on your '
            'behalf, or reach us directly using the details in Section 9.',
          ),

          _SectionTitle(
              title: '8. Changes to This Policy', color: roleColor),
          const _Paragraph(
            'We may update this Privacy Policy from time to time to reflect '
            'changes in the App or in applicable law. We will update the '
            '"Last updated" date above when changes are made. Continued use '
            'of the App after changes take effect means you accept the '
            'revised policy.',
          ),

          _SectionTitle(title: '9. Contact Us', color: roleColor),
          const _Paragraph(
            'If you have questions about this Privacy Policy or how your '
            'data is handled, please contact your school administrator '
            'first, since they manage your account directly. You can also '
            'reach the App\'s support team at:',
          ),
          _ContactChip(email: _supportEmail, color: roleColor),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Shared building blocks (also used by TermsOfServiceScreen) ───────────────

class _HeaderBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _HeaderBlock({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMediumBold),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;
  const _Paragraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.textSecondary, height: 1.6),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: AppColors.textHint, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final String email;
  final Color color;
  const _ContactChip({required this.email, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.email_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            email,
            style: AppTextStyles.bodyMediumBold.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}