import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

// ── Place this file at:
// lib/features/shared/help/help_support_screen.dart
//
// Update route in app_router.dart, replacing the placeholder:
//   GoRoute(path: '/help', builder: (_, __) => const HelpSupportScreen()),

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  int? _expandedIndex;

  static const _faqs = [
    (
      'How do I reset my password?',
      'Go to Profile → Change Password, enter your current password '
          'and choose a new one. If you\'ve forgotten your current '
          'password, contact your school administrator to have it reset.'
    ),
    (
      'Why can\'t I see my class schedule?',
      'Your timetable only appears once the admin has assigned you to a '
          'class and a teacher has added time slots for that class. If '
          'it\'s still empty after a day or two, ask your admin to check '
          'your class assignment.'
    ),
    (
      'My attendance percentage looks wrong.',
      'Attendance is calculated only from days your teacher has actually '
          'marked. If a day is missing, it usually means the teacher '
          'hasn\'t submitted attendance for that day yet — it is not '
          'counted as absent until it\'s recorded.'
    ),
    (
      'How do parents link to a student account?',
      'A parent registers normally and selects "Parent" as their role. '
          'An admin then approves the account and links it to the '
          'correct student from the Pending Approvals screen. Until '
          'that link is made, no child data will be visible.'
    ),
    (
      'I\'m a teacher — why don\'t I see any classes?',
      'Classes are assigned by the admin. Until at least one class is '
          'assigned to your account, screens like Attendance, Grades and '
          'Assignments will show an empty state. Ask your admin to '
          'assign you to a class.'
    ),
    (
      'How do I update my profile photo?',
      'Open Profile, tap the small camera icon on your avatar, and '
          'choose a photo from your gallery. It uploads automatically.'
    ),
  ];

  Color get _roleColor {
    final role = ref.read(authProvider).role ?? 'student';
    return switch (role) {
      'admin' => AppColors.adminColor,
      'teacher' => AppColors.teacherColor,
      _ => AppColors.studentColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: roleColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Help & Support',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Quick contact cards ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ContactTile(
                  icon: Icons.email_rounded,
                  label: 'Email Us',
                  color: roleColor,
                  onTap: () => _showContactSheet(
                    context,
                    title: 'Email Support',
                    message:
                        'Send your question to support@edumanage.app and '
                        'our team will get back to you within 1-2 working '
                        'days.',
                    icon: Icons.email_rounded,
                    color: roleColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContactTile(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Live Chat',
                  color: AppColors.accent,
                  onTap: () => _showContactSheet(
                    context,
                    title: 'Live Chat',
                    message:
                        'Live chat support is coming soon. For now, '
                        'please reach out via email or contact your '
                        'school administrator directly.',
                    icon: Icons.chat_bubble_rounded,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContactTile(
                  icon: Icons.phone_rounded,
                  label: 'Call Admin',
                  color: AppColors.success,
                  onTap: () => _showContactSheet(
                    context,
                    title: 'Contact Your School',
                    message:
                        'For account approvals, class assignments, or '
                        'urgent issues, contact your school\'s admin '
                        'office directly — they manage these accounts.',
                    icon: Icons.phone_rounded,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),
          Text('Frequently Asked Questions', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),

          ..._faqs.asMap().entries.map((entry) {
            final i = entry.key;
            final (question, answer) = entry.value;
            final isExpanded = _expandedIndex == i;
            return _FaqTile(
              question: question,
              answer: answer,
              isExpanded: isExpanded,
              color: roleColor,
              onTap: () => setState(
                  () => _expandedIndex = isExpanded ? null : i),
            );
          }),

          const SizedBox(height: 28),

          // ── Feedback card ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.feedback_rounded, color: Colors.white, size: 26),
                const SizedBox(height: 10),
                Text('Still need help?',
                    style: AppTextStyles.bodyMediumBold
                        .copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  'Send us details about the issue you\'re facing and '
                  'we\'ll look into it.',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showContactSheet(
                      context,
                      title: 'Send Feedback',
                      message:
                          'Feedback submission from within the app is '
                          'coming soon. For now, please email '
                          'support@edumanage.app with details of the '
                          'issue and a screenshot if possible.',
                      icon: Icons.feedback_rounded,
                      color: AppColors.primary,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Send Feedback',
                        style: AppTextStyles.bodyMediumBold
                            .copyWith(color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showContactSheet(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 52,
              height: 52,
              decoration:
                  BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headingMedium),
            const SizedBox(height: 10),
            Text(message,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary, height: 1.6)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(sheetCtx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Got it',
                    style: AppTextStyles.bodyMediumBold
                        .copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contact tile ──────────────────────────────────────────────────────────────
class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelTiny.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FAQ tile ───────────────────────────────────────────────────────────────────
class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  final bool isExpanded;
  final Color color;
  final VoidCallback onTap;

  const _FaqTile({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(question, style: AppTextStyles.bodyMediumBold),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: color, size: 22),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  answer,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textSecondary, height: 1.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}