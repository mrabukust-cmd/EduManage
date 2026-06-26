import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/constants/app_strings.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

// ── Place this file at:
// lib/features/shared/legal/terms_of_service_screen.dart
//
// Add to app_router.dart:
//   GoRoute(path: '/legal/terms',
//       builder: (_, __) => const TermsOfServiceScreen()),
//
// Reuses the shared _HeaderBlock / _SectionTitle / _Paragraph / _Bullet
// widgets defined as private classes in privacy_policy_screen.dart by
// redeclaring lightweight equivalents here, since those are file-private.
// Kept intentionally simple/duplicated rather than extracting a shared
// widgets file, to keep this change self-contained — extract to
// core/widgets/legal_text_blocks.dart later if a third legal screen is
// ever added.

class TermsOfServiceScreen extends ConsumerWidget {
  const TermsOfServiceScreen({super.key});

  static const _lastUpdated = 'June 2026';
  static const _supportEmail = 'support@edumanage.app';

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
        title: Text('Terms of Service',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          _TosHeaderBlock(
            icon: Icons.description_rounded,
            color: roleColor,
            title: '${AppStrings.appName} Terms of Service',
            subtitle: 'Last updated: $_lastUpdated',
          ),
          const SizedBox(height: 24),

          const _TosParagraph(
            'These Terms of Service ("Terms") govern your use of '
            '${AppStrings.appName} ("the App"), a school management '
            'platform used by school Admins, Teachers, Students, and '
            'Parents/Guardians. By creating an account or using the App, '
            'you agree to these Terms. If you are a student under the age '
            'required to agree to terms in your jurisdiction, a parent, '
            'guardian, or school administrator must accept these Terms on '
            'your behalf.',
          ),

          _TosSectionTitle(title: '1. Accounts & Roles', color: roleColor),
          const _TosBullet('Admin accounts are created only by an '
              'existing administrator — there is no public sign‑up for '
              'the Admin role.'),
          const _TosBullet('Teacher, Student, and Parent accounts may '
              'self‑register but remain inactive until approved by a '
              'school Admin.'),
          const _TosBullet('You are responsible for keeping your login '
              'credentials confidential and for all activity that occurs '
              'under your account.'),
          const _TosBullet('Parent accounts are linked to a specific '
              'student by the school Admin; you may only view information '
              'for student(s) actually linked to your account.'),

          _TosSectionTitle(
              title: '2. Acceptable Use', color: roleColor),
          const _TosParagraph(
            'The App is provided for legitimate school administration '
            'purposes only. You agree not to:',
          ),
          const _TosBullet('Attempt to access another user\'s account, '
              'another student\'s records, or any data you are not '
              'authorized to view.'),
          const _TosBullet('Enter false attendance, grades, fee records, '
              'or other academic data.'),
          const _TosBullet('Use the App to harass, defame, or share '
              'inappropriate content with other users via notices or any '
              'in‑app communication feature.'),
          const _TosBullet('Attempt to reverse‑engineer, disrupt, or gain '
              'unauthorized access to the App\'s systems or Firebase '
              'backend.'),
          const _TosBullet('Share your login credentials with anyone '
              'else, including other students, parents, or staff.'),

          _TosSectionTitle(
              title: '3. Academic & Administrative Data', color: roleColor),
          const _TosParagraph(
            'Attendance, grades, fee, and timetable data entered into the '
            'App by Admins and Teachers is considered an official record '
            'for use within the school\'s own processes. The App is a tool '
            'for recording and viewing this information — it does not '
            'replace your school\'s official policies on grading, '
            'attendance requirements, or fee deadlines, which remain '
            'governed by the school itself, not by these Terms.',
          ),

          _TosSectionTitle(
              title: '4. Roles & Responsibilities', color: roleColor),
          const _TosBullet('School Admins are responsible for approving '
              'accounts, assigning classes correctly, and managing the '
              'accuracy of student/teacher/parent records.'),
          const _TosBullet('Teachers are responsible for the accuracy of '
              'attendance and grades they submit for their assigned '
              'classes.'),
          const _TosBullet('Students and Parents are responsible for '
              'reviewing their own records and promptly reporting '
              'discrepancies to the school Admin.'),

          _TosSectionTitle(title: '5. Availability', color: roleColor),
          const _TosParagraph(
            'We aim to keep the App available and reliable, but the App '
            'is provided "as is" without guarantee of uninterrupted '
            'availability. Features that depend on third‑party '
            'infrastructure (such as push notifications) may occasionally '
            'be delayed or unavailable for reasons outside our control.',
          ),

          _TosSectionTitle(
              title: '6. Suspension & Termination', color: roleColor),
          const _TosParagraph(
            'A school Admin may reject a pending registration or remove '
            'an existing account at their discretion — for example, when a '
            'student leaves the school or a teacher\'s employment ends. We '
            'may also suspend access to the App if these Terms are '
            'violated, or as required to protect the security or integrity '
            'of the platform.',
          ),

          _TosSectionTitle(
              title: '7. Limitation of Liability', color: roleColor),
          const _TosParagraph(
            'The App is a record‑keeping and communication tool. To the '
            'fullest extent permitted by law, we are not liable for '
            'decisions made by a school based on data recorded in the App '
            '(such as attendance‑based or fee‑based decisions), nor for '
            'indirect or consequential damages arising from use of the '
            'App. Nothing in these Terms limits liability that cannot be '
            'limited under applicable law.',
          ),

          _TosSectionTitle(title: '8. Changes to These Terms', color: roleColor),
          const _TosParagraph(
            'We may update these Terms from time to time. We will update '
            'the "Last updated" date above when changes are made. '
            'Continuing to use the App after changes take effect means you '
            'accept the revised Terms. If you do not agree with the '
            'updated Terms, you should stop using the App and contact your '
            'school Admin.',
          ),

          _TosSectionTitle(title: '9. Contact Us', color: roleColor),
          const _TosParagraph(
            'Questions about these Terms can be directed to your school '
            'administrator, or to the App\'s support team at:',
          ),
          _TosContactChip(email: _supportEmail, color: roleColor),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Local shared building blocks (Tos-prefixed to avoid any cross-file
// private-class confusion with privacy_policy_screen.dart) ──────────────────

class _TosHeaderBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _TosHeaderBlock({
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

class _TosSectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _TosSectionTitle({required this.title, required this.color});

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

class _TosParagraph extends StatelessWidget {
  final String text;
  const _TosParagraph(this.text);

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

class _TosBullet extends StatelessWidget {
  final String text;
  const _TosBullet(this.text);

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

class _TosContactChip extends StatelessWidget {
  final String email;
  final Color color;
  const _TosContactChip({required this.email, required this.color});

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