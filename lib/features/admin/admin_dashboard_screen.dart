import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/constants/stat_card.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';
import '../../../core/router/route_names.dart';
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
                              const Text(
                                'Good morning 👋',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.displayName ?? 'Admin',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.push(RouteNames.profile),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: user?.photoURL != null
                                  ? ClipOval(
                                      child: Image.network(user!.photoURL!,
                                          fit: BoxFit.cover),
                                    )
                                  : const Icon(Icons.person_rounded,
                                      color: Colors.white, size: 26),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            title: const Text(
              'Admin Dashboard',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            titleTextStyle: const TextStyle(color: Colors.white),
          ),

          // ── Body content ──────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats grid
                _buildStatsGrid(),
                const SizedBox(height: 28),

                // Quick actions
                const SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 14),
                _buildQuickActions(context),
                const SizedBox(height: 28),

                // Recent notices
                const SectionHeader(
                  title: 'Recent Notices',
                  actionLabel: 'See all',
                ),
                const SizedBox(height: 14),
                _buildRecentNotices(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
      builder: (context, studentSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('teachers').snapshots(),
          builder: (context, teacherSnap) {
            final studentCount =
                studentSnap.data?.docs.length.toString() ?? '...';
            final teacherCount =
                teacherSnap.data?.docs.length.toString() ?? '...';

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
                  value: '6',
                  icon: Icons.class_rounded,
                  gradient: AppColors.studentGradient,
                ),
                StatCard(
                  label: 'Notices',
                  value: '12',
                  icon: Icons.campaign_rounded,
                  gradient: AppColors.primaryGradient,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
  final actions = [
      _Action('Add Student', Icons.person_add_rounded, AppColors.adminColor),
      _Action('Add Teacher', Icons.person_add_alt_1_rounded, AppColors.teacherColor),
      _Action('New Notice', Icons.edit_document, AppColors.primary),
      _Action('Reports', Icons.bar_chart_rounded, AppColors.accent),
      _Action('Timetable', Icons.calendar_month_rounded, AppColors.warning),
      _Action('Settings', Icons.settings_rounded, AppColors.textSecondary),
      _Action('Approvals', Icons.fact_check_rounded, AppColors.success),
        _Action('Fix Class Names', Icons.merge_type_rounded, AppColors.danger), 
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
      itemBuilder: (context, i) => QuickActionCard(
        label: actions[i].label,
        icon: actions[i].icon,
        color: actions[i].color,
        onTap: () {
          switch (actions[i].label) {
            case 'Add Student':
              context.push('/admin/home/students/add');
              break;
            case 'Add Teacher':
              context.push('/admin/home/teachers/add');
              break;
            case 'Reports':
              context.push('/admin/home/reports');
              break;
            case 'Timetable':
              context.push('/admin/home/timetable');
              break;
            case 'Settings':
              context.push('/admin/home/settings');
              break;
            case 'Approvals':
              context.push('/admin/home/approvals');
              break;
            case 'Fix Class Names':                              // NEW
              context.push('/admin/home/fix-class-names');       // NEW
              break;                                             // NEW
          }
        },
      ),
    );
  }

  Widget _buildRecentNotices() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notices')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _EmptyCard(
            icon: Icons.campaign_outlined,
            message: 'No notices yet. Add one!',
          );
        }
        return Column(
          children: snap.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _NoticeCard(
              title: data['title'] ?? '',
              body: data['body'] ?? '',
              type: data['type'] ?? 'general',
            );
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
  const _Action(this.label, this.icon, this.color);
}

class _NoticeCard extends StatelessWidget {
  final String title;
  final String body;
  final String type;

  const _NoticeCard({
    required this.title,
    required this.body,
    required this.type,
  });

  Color get _typeColor {
    switch (type) {
      case 'urgent':
        return AppColors.danger;
      case 'exam':
        return AppColors.warning;
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.1),
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
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              type.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}