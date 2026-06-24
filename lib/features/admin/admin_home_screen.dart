import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _AdminHeader(userName: user?.displayName ?? 'Admin'),
            ),

            // ── Stats Row ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('students').snapshots(),
                        builder: (context, snap) {
                          final count = snap.hasData ? snap.data!.docs.length : null;
                          return _StatCard(
                            label: 'Students',
                            value: count?.toString() ?? '...',
                            icon: Icons.school_rounded,
                            color: AppColors.studentColor,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('teachers').snapshots(),
                        builder: (context, snap) {
                          final count = snap.hasData ? snap.data!.docs.length : null;
                          return _StatCard(
                            label: 'Teachers',
                            value: count?.toString() ?? '...',
                            icon: Icons.person_rounded,
                            color: AppColors.teacherColor,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
                        builder: (context, snap) {
                          final count = snap.hasData ? snap.data!.docs.length : null;
                          return _StatCard(
                            label: 'Classes',
                            value: count?.toString() ?? '...',
                            icon: Icons.class_rounded,
                            color: AppColors.adminColor,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Quick Actions ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Quick Actions', style: AppTextStyles.sectionTitle),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  children: [
                    _QuickAction(icon: Icons.person_add_rounded, label: 'Add Student', color: AppColors.studentColor, onTap: () => context.push('/admin/home/students/add')),
                    _QuickAction(icon: Icons.person_add_alt_1_rounded, label: 'Add Teacher', color: AppColors.teacherColor, onTap: () => context.push('/admin/home/teachers/add')),
                    _QuickAction(icon: Icons.class_rounded, label: 'Manage Classes', color: AppColors.adminColor, onTap: () => context.push('/admin/home/classes')),
                    _QuickAction(icon: Icons.calendar_month_rounded, label: 'Timetable', color: AppColors.primary, onTap: () => context.push('/admin/home/timetable')),
                    _QuickAction(icon: Icons.attach_money_rounded, label: 'Fees', color: AppColors.warning, onTap: () => context.push('/admin/home/fees')),
                    _QuickAction(icon: Icons.announcement_rounded, label: 'Notices', color: AppColors.accent, onTap: () => context.push('/admin/home/notices')),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Recent Activity ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Recent Activity', style: AppTextStyles.sectionTitle),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverList(
              delegate: SliverChildListDelegate([
              _buildPendingApprovals(),
                const SizedBox(height: 32),
              ]),
            ),
          ],
        ),
      ),

      // ── Bottom Nav ──────────────────────────────────────────────
      bottomNavigationBar: const _AdminBottomNav(currentIndex: 0),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────
class _AdminHeader extends StatelessWidget {
  final String userName;
  const _AdminHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good Morning,', style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(userName, style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
                ],
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
                const SizedBox(width: 10),
                Text('Search students, teachers...', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ───────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.statValue),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action ────────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Activity Item ────────────────────────────────────────────────────────────
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle, time;
  const _ActivityItem({required this.icon, required this.color, required this.title, required this.subtitle, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMediumBold),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.labelSmall),
              ],
            ),
          ),
          Text(time, style: AppTextStyles.labelTiny),
        ],
      ),
    );
  }
}

// ── Notice Card ──────────────────────────────────────────────────────────────
class _NoticeCard extends StatelessWidget {
  final String title, body, type;
  const _NoticeCard({required this.title, required this.body, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyMediumBold),
          const SizedBox(height: 6),
          Text(body, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

// ── Empty Card ───────────────────────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 28),
          const SizedBox(height: 8),
          Text(message, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

// ── Bottom Nav ───────────────────────────────────────────────────────────────
class _AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  const _AdminBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: AppColors.cardBg,
      elevation: 12,
      selectedLabelStyle: AppTextStyles.navLabel,
      unselectedLabelStyle: AppTextStyles.navLabel,
      onTap: (i) {
        switch (i) {
          case 0: context.go('/admin/home'); break;
          case 1: context.go('/admin/home/students'); break;
          case 2: context.go('/admin/home/teachers'); break;
          case 3: context.go('/admin/home/reports'); break;
          case 4: context.go('/admin/home/settings'); break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.school_rounded), label: 'Students'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Teachers'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
      ],
    );
  }
}

Widget _buildPendingApprovals() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .where('approved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots(),
    builder: (context, snap) {
      final docs = snap.data?.docs ?? [];
      if (docs.isEmpty) {
        return _EmptyCard(
          icon: Icons.check_circle_outline_rounded,
          message: 'No pending approvals.',
        );
      }
      return Column(
        children: docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name'] as String? ?? 'Unknown';
          final role = data['role'] as String? ?? 'student';
          final Color color = role == 'teacher'
              ? AppColors.teacherColor
              : role == 'parent'
                  ? AppColors.accent
                  : AppColors.studentColor;
          return _NoticeCard(
            title: '$name is waiting for approval',
            body: '${role[0].toUpperCase()}${role.substring(1)} registration pending',
            type: role,
          );
        }).toList(),
      );
    },
  );
}

Widget _buildPendingStream() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .where('approved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(4)
        .snapshots(),
    builder: (context, snap) {
      final docs = snap.data?.docs ?? [];
      if (docs.isEmpty) {
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppColors.cardShadow,
          ),
          child: const Text('No pending approvals — all caught up!',
              style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
        );
      }
      return Column(
        children: docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name'] as String? ?? 'Unknown';
          final role = data['role'] as String? ?? 'student';
          final Color color = role == 'teacher'
              ? AppColors.teacherColor
              : role == 'parent'
                  ? AppColors.accent
                  : AppColors.studentColor;
          return _ActivityItem(
            icon: Icons.person_add_rounded,
            color: color,
            title: '$name awaiting approval',
            subtitle: '${role[0].toUpperCase()}${role.substring(1)} · Tap Approvals to review',
            time: '',
          );
        }).toList(),
      );
    },
  );
}