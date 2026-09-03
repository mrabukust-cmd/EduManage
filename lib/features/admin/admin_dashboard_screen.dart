import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/constants/stat_card.dart';
import 'package:school_management_system/core/router/route_names.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/data/models/notice_model.dart';
import 'package:school_management_system/data/providers/repository_providers.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.adminColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.adminGradient,
                ),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good morning 👋',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.onPrimary.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.displayName ?? 'Admin',
                                style: AppTextStyles.headingLarge.copyWith(
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.push(RouteNames.profile),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.onPrimary.withValues(alpha: 0.2),
                              child: user?.photoURL != null
                                  ? ClipOval(
                                      child: Image.network(
                                        user!.photoURL!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_rounded,
                                      color: AppColors.onPrimary,
                                      size: 26,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            title: Text(
              'Admin Dashboard',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.onPrimary),
            ),
          ),

          // ── Body content ──────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats grid driven by Riverpod repository providers
                _buildStatsGrid(ref),
                const SizedBox(height: 28),

                // Quick actions
                const SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 14),
                _buildQuickActions(context, ref),
                const SizedBox(height: 28),

                // Recent notices
                const SectionHeader(
                  title: 'Recent Notices',
                  actionLabel: 'See all',
                ),
                const SizedBox(height: 14),
                _buildRecentNotices(ref),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(WidgetRef ref) {
    final studentCount =
        ref.watch(studentsTotalCountProvider).valueOrNull?.toString() ?? '...';
    final teacherCount =
        ref.watch(teachersTotalCountProvider).valueOrNull?.toString() ?? '...';
    final classCount =
        ref.watch(classesCountProvider).valueOrNull?.toString() ?? '...';
    final noticeCount =
        ref.watch(noticesTotalCountProvider).valueOrNull?.toString() ?? '...';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.2,
      children: [
        StatCard(
          label: 'Total Students',
          value: studentCount,
          icon: Icons.people_rounded,
          gradient: AppColors.adminGradient,
        ),
        StatCard(
          label: 'Total Teachers',
          value: teacherCount,
          icon: Icons.school_rounded,
          gradient: AppColors.teacherGradient,
        ),
        StatCard(
          label: 'Classes',
          value: classCount,
          icon: Icons.class_rounded,
          gradient: AppColors.studentGradient,
        ),
        StatCard(
          label: 'Notices',
          value: noticeCount,
          icon: Icons.campaign_rounded,
          gradient: AppColors.primaryGradient,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    final classCountAsync = ref.watch(classesCountProvider);
    final hasClasses = (classCountAsync.valueOrNull ?? 0) > 0;

    final actions = [
      const _Action('Add Student', Icons.person_add_rounded, AppColors.adminColor),
      const _Action('Add Teacher', Icons.person_add_alt_1_rounded, AppColors.teacherColor),
      const _Action('New Notice', Icons.edit_document, AppColors.primary),
      const _Action('Reports', Icons.bar_chart_rounded, AppColors.accent),
      const _Action('Timetable', Icons.calendar_month_rounded, AppColors.warning),
      const _Action('Approvals', Icons.fact_check_rounded, AppColors.success),
      const _Action('Fix Classes', Icons.merge_type_rounded, AppColors.danger),
      _Action(
        'Setup Classes',
        Icons.auto_fix_high_rounded,
        hasClasses ? AppColors.textSecondary : AppColors.warning,
        badge: hasClasses ? null : '!',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, i) {
        final action = actions[i];
        return Stack(
          clipBehavior: Clip.none,
          children: [
            QuickActionCard(
              label: action.label,
              icon: action.icon,
              color: action.color,
              onTap: () => _handleAction(context, action.label),
            ),
            if (action.badge != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '!',
                      style: AppTextStyles.labelTiny.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _handleAction(BuildContext context, String label) {
    switch (label) {
      case 'Add Student':
        context.push('/admin/home/students/add');
        break;
      case 'Add Teacher':
        context.push('/admin/home/teachers/add');
        break;
      case 'New Notice':
        context.push('/admin/home/notices');
        break;
      case 'Reports':
        context.push('/admin/home/reports');
        break;
      case 'Timetable':
        context.push('/admin/home/timetable');
        break;
      case 'Approvals':
        context.push('/admin/home/approvals');
        break;
      case 'Fix Classes':
        context.push('/admin/home/fix-class-names');
        break;
      case 'Setup Classes':
        context.push('/admin/home/seed-classes');
        break;
    }
  }

  Widget _buildRecentNotices(WidgetRef ref) {
    final noticesAsync = ref.watch(noticesStreamProvider);

    return noticesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const _EmptyCard(
        icon: Icons.campaign_outlined,
        message: 'Could not load notices.',
      ),
      data: (notices) {
        if (notices.isEmpty) {
          return const _EmptyCard(
            icon: Icons.campaign_outlined,
            message: 'No notices yet. Add one!',
          );
        }
        final recent = notices.take(3).toList();
        return Column(
          children: recent.map((notice) {
            return _NoticeCard(notice: notice);
          }).toList(),
        );
      },
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final Color color;
  final String? badge;
  const _Action(this.label, this.icon, this.color, {this.badge});
}

class _NoticeCard extends StatelessWidget {
  final NoticeModel notice;

  const _NoticeCard({required this.notice});

  Color get _typeColor {
    switch (notice.category.toLowerCase()) {
      case 'urgent':
      case 'exam':
        return AppColors.warning;
      case 'holiday':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.campaign_rounded, color: _typeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: AppTextStyles.bodyMediumBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  notice.description,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              notice.category.toUpperCase(),
              style: AppTextStyles.labelTiny.copyWith(
                fontWeight: FontWeight.w700,
                color: _typeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.labelMedium,
          ),
        ],
      ),
    );
  }
}