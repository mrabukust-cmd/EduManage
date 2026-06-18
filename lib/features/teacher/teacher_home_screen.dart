import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

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
              child: _TeacherHeader(userName: user?.displayName ?? 'Teacher'),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Today's Classes ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Classes", style: AppTextStyles.sectionTitle),
                    TextButton(onPressed: () => context.push('/teacher/timetable'), child: const Text('See All')),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: const [
                    _ClassCard(subject: 'Mathematics', grade: 'Grade 9A', time: '08:00 – 09:00', room: 'Room 101', status: ClassStatus.ongoing),
                    _ClassCard(subject: 'Physics', grade: 'Grade 10B', time: '10:00 – 11:00', room: 'Room 204', status: ClassStatus.upcoming),
                    _ClassCard(subject: 'Mathematics', grade: 'Grade 8C', time: '12:00 – 01:00', room: 'Room 101', status: ClassStatus.upcoming),
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
                child: Row(
                  children: [
                    _ActionTile(icon: Icons.how_to_reg_rounded, label: 'Attendance', color: AppColors.teacherColor, onTap: () => context.push('/teacher/attendance')),
                    const SizedBox(width: 12),
                    _ActionTile(icon: Icons.assignment_rounded, label: 'Assignments', color: AppColors.primary, onTap: () => context.push('/teacher/assignments')),
                    const SizedBox(width: 12),
                    _ActionTile(icon: Icons.grade_rounded, label: 'Grades', color: AppColors.accent, onTap: () => context.push('/teacher/grades')),
                    const SizedBox(width: 12),
                    _ActionTile(icon: Icons.chat_rounded, label: 'Messages', color: AppColors.warning, onTap: () => context.push('/teacher/messages')),
                    const SizedBox(width: 12),
                    _ActionTile(icon: Icons.logout_rounded, label: 'Logout', color: AppColors.danger, onTap: () => context.push('/onboarding')),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Pending Tasks ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Pending Tasks', style: AppTextStyles.sectionTitle),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverList(
              delegate: SliverChildListDelegate([
                _TaskItem(title: 'Mark attendance – Grade 9A', subtitle: 'Due today', icon: Icons.how_to_reg_rounded, color: AppColors.teacherColor, isDone: false),
                _TaskItem(title: 'Grade assignment – Grade 10B', subtitle: '5 submissions pending', icon: Icons.assignment_rounded, color: AppColors.primary, isDone: false),
                _TaskItem(title: 'Submit monthly report', subtitle: 'Due Jun 30', icon: Icons.description_rounded, color: AppColors.accent, isDone: true),
                const SizedBox(height: 32),
              ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _TeacherBottomNav(currentIndex: 0),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────
class _TeacherHeader extends StatelessWidget {
  final String userName;
  const _TeacherHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.teacherGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back,', style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(userName, style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text('Monday, June 16', style: AppTextStyles.labelMedium.copyWith(color: Colors.white60)),
            ],
          ),
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Class Card ───────────────────────────────────────────────────────────────
enum ClassStatus { ongoing, upcoming, done }

class _ClassCard extends StatelessWidget {
  final String subject, grade, time, room;
  final ClassStatus status;
  const _ClassCard({required this.subject, required this.grade, required this.time, required this.room, required this.status});

  @override
  Widget build(BuildContext context) {
    final isOngoing = status == ClassStatus.ongoing;
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOngoing ? AppColors.teacherColor : AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOngoing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: Text('Ongoing', style: AppTextStyles.labelTiny.copyWith(color: Colors.white)),
            ),
          const Spacer(),
          Text(subject, style: AppTextStyles.bodyMediumBold.copyWith(color: isOngoing ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(grade, style: AppTextStyles.labelSmall.copyWith(color: isOngoing ? Colors.white70 : AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(time, style: AppTextStyles.labelTiny.copyWith(color: isOngoing ? Colors.white60 : AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Action Tile ──────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(label, style: AppTextStyles.labelTiny.copyWith(color: color), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Task Item ────────────────────────────────────────────────────────────────
class _TaskItem extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final bool isDone;
  const _TaskItem({required this.title, required this.subtitle, required this.icon, required this.color, required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle_rounded : icon, color: isDone ? AppColors.success : color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMediumBold.copyWith(decoration: isDone ? TextDecoration.lineThrough : null)),
                Text(subtitle, style: AppTextStyles.labelSmall),
              ],
            ),
          ),
          if (!isDone) const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

// ── Bottom Nav ───────────────────────────────────────────────────────────────
class _TeacherBottomNav extends StatelessWidget {
  final int currentIndex;
  const _TeacherBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.teacherColor,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: AppColors.cardBg,
      elevation: 12,
      onTap: (i) {
        switch (i) {
          case 0: context.go('/teacher/home'); break;
          case 1: context.go('/teacher/classes'); break;
          case 2: context.go('/teacher/attendance'); break;
          case 3: context.go('/teacher/grades'); break;
          case 4: context.go('/teacher/profile'); break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.class_rounded), label: 'Classes'),
        BottomNavigationBarItem(icon: Icon(Icons.how_to_reg_rounded), label: 'Attendance'),
        BottomNavigationBarItem(icon: Icon(Icons.grade_rounded), label: 'Grades'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}