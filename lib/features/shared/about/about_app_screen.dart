import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/constants/app_strings.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';


class AboutAppScreen extends ConsumerWidget {
  const AboutAppScreen({super.key});

  static const _version = '1.0.0';
  static const _buildNumber = '1';

  static const _features = [
    ('Multi-Role Access', Icons.groups_rounded,
        'Dedicated experiences for admins, teachers, students and parents.'),
    ('Attendance Tracking', Icons.how_to_reg_rounded,
        'Mark and review attendance with daily, monthly and overall views.'),
    ('Grades & Results', Icons.bar_chart_rounded,
        'Record exam results and track performance over time.'),
    ('Timetable Management', Icons.schedule_rounded,
        'Class-wise schedules visible to teachers, students and parents.'),
    ('Fee Management', Icons.account_balance_wallet_rounded,
        'Track payments, dues and collection summaries.'),
    ('Notices & Announcements', Icons.campaign_rounded,
        'School-wide updates delivered straight to every account.'),
  ];

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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            elevation: 0,
            backgroundColor: roleColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [roleColor, roleColor.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 1.5),
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          AppStrings.appName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.appTagline,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Version card ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _VersionStat(label: 'Version', value: _version),
                      ),
                      Container(width: 1, height: 32, color: AppColors.divider),
                      Expanded(
                        child: _VersionStat(label: 'Build', value: _buildNumber),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text('What you can do', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 12),

                ..._features.map((f) => _FeatureRow(
                      title: f.$1,
                      icon: f.$2,
                      description: f.$3,
                      color: roleColor,
                    )),

                const SizedBox(height: 24),
                Text('Legal', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      _LinkRow(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        onTap: () => context.push('/legal/privacy'),
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _LinkRow(
                        icon: Icons.description_outlined,
                        label: 'Terms of Service',
                        onTap: () => context.push('/legal/terms'),
                        showDivider: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.favorite_rounded,
                          color: roleColor.withOpacity(0.6), size: 20),
                      const SizedBox(height: 8),
                      Text(
                        'Built for schools, by educators and engineers.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textHint),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '© ${DateTime.now().year} ${AppStrings.appName}. All rights reserved.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelTiny
                            .copyWith(color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

}

// ── Version stat ──────────────────────────────────────────────────────────────
class _VersionStat extends StatelessWidget {
  final String label;
  final String value;
  const _VersionStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.statValue),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.labelTiny),
      ],
    );
  }
}

// ── Feature row ───────────────────────────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _FeatureRow({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
                BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMediumBold),
                const SizedBox(height: 3),
                Text(description,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Link row ──────────────────────────────────────────────────────────────────
class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}